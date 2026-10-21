package com.migrante.migrante_traductor.engine

import ai.onnxruntime.OnnxJavaType
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.nio.LongBuffer

/**
 * Runs an exported Marian (OPUS-MT) model with ONNX Runtime.
 *
 * The decoder is the "merged" export: one graph that accepts the key/value
 * cache. Cross-attention keys and values are computed once on the first step
 * and reused, which is what the model expects; only the decoder cache grows.
 */
class MarianTranslator(
    encoderPath: String,
    decoderPath: String,
    private val tokenizer: UnigramTokenizer,
    private val maxNewTokens: Int = 128,
    private val startTokenId: Long = 65000L,
    private val eosTokenId: Long = 0L,
) : AutoCloseable {

    private data class Cache(val data: FloatArray, val shape: LongArray)

    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private val encoder: OrtSession
    private val decoder: OrtSession

    private val decoderInputNames: List<String>
    private val decoderOutputNames: List<String>
    private val layers: Int
    private val heads: Int
    private val headDim: Int

    init {
        val options = OrtSession.SessionOptions()
        options.setIntraOpNumThreads(Runtime.getRuntime().availableProcessors().coerceIn(2, 4))
        options.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
        encoder = env.createSession(encoderPath, options)
        decoder = env.createSession(decoderPath, options)

        decoderInputNames = decoder.inputNames.toList()
        decoderOutputNames = decoder.outputNames.toList()

        val sample = decoderInputNames.first { it.startsWith("past_key_values.") }
        // past_key_values.<layer>.decoder.key -> [batch, heads, seq, headDim]
        layers = decoderInputNames
            .filter { it.startsWith("past_key_values.") && it.endsWith(".decoder.key") }
            .map { it.split('.')[1].toInt() }
            .maxOrNull()?.plus(1) ?: 0
        val info = decoder.inputInfo[sample]?.info as? TensorInfo
        val shape = info?.shape
        heads = if (shape != null && shape.size > 3) shape[1].toInt() else 8
        headDim = if (shape != null && shape.size > 3) shape[3].toInt() else 64
    }

    fun translate(text: String): String {
        val encoded = tokenizer.encode(text)
        if (encoded.isEmpty()) return ""

        // Marian was trained with the end-of-sequence token closing the source
        // sentence. Without it the decoder degrades into repeated words.
        val sourceIds = LongArray(encoded.size + 1) { index ->
            if (index < encoded.size) encoded[index] else eosTokenId
        }

        val masked = sourceIds.size
        val idsTensor = OnnxTensor.createTensor(
            env, LongBuffer.wrap(sourceIds), longArrayOf(1, masked.toLong()),
        )
        val mask = LongArray(masked) { 1L }
        val maskTensor = OnnxTensor.createTensor(
            env, LongBuffer.wrap(mask), longArrayOf(1, masked.toLong()),
        )

        var hidden: OnnxTensor? = null
        var maskForDecoder: OnnxTensor? = null
        var encodedResult: OrtSession.Result? = null
        try {
            encodedResult = encoder.run(mapOf("input_ids" to idsTensor, "attention_mask" to maskTensor))
            hidden = encodedResult.get("last_hidden_state").orElseThrow() as OnnxTensor
            maskForDecoder = OnnxTensor.createTensor(
                env, LongBuffer.wrap(mask), longArrayOf(1, masked.toLong()),
            )
            return decode(hidden, maskForDecoder, masked)
        } finally {
            idsTensor.close()
            maskTensor.close()
            maskForDecoder?.close()
            hidden?.close()
            encodedResult?.close()
        }
    }

    private fun decode(encoderHidden: OnnxTensor, encoderMask: OnnxTensor, sourceLength: Int): String {
        var decoderCache: Array<Cache?> = arrayOfNulls(layers * 2)
        var crossCache: Array<Cache?> = arrayOfNulls(layers * 2)

        var current = longArrayOf(startTokenId)
        val produced = ArrayList<Long>(maxNewTokens)

        for (step in 0 until maxNewTokens) {
            val useCache = step > 0
            val feeds = HashMap<String, OnnxTensor>(decoderInputNames.size * 2)

            val selfPast = arrayOfNulls<OnnxTensor>(layers * 2)
            val crossPast = arrayOfNulls<OnnxTensor>(layers * 2)

            try {
                for (layer in 0 until layers) {
                    selfPast[layer * 2] = cacheTensor(decoderCache[layer * 2], heads, headDim)
                    selfPast[layer * 2 + 1] = cacheTensor(decoderCache[layer * 2 + 1], heads, headDim)
                    crossPast[layer * 2] = cacheTensor(crossCache[layer * 2], heads, headDim)
                    crossPast[layer * 2 + 1] = cacheTensor(crossCache[layer * 2 + 1], heads, headDim)
                }

                feeds["input_ids"] = OnnxTensor.createTensor(
                    env, LongBuffer.wrap(current), longArrayOf(1, current.size.toLong()),
                )
                feeds["encoder_hidden_states"] = encoderHidden
                feeds["encoder_attention_mask"] = encoderMask
                feeds["use_cache_branch"] = booleanTensor(useCache)

                for (layer in 0 until layers) {
                    feeds["past_key_values.$layer.decoder.key"] = selfPast[layer * 2]!!
                    feeds["past_key_values.$layer.decoder.value"] = selfPast[layer * 2 + 1]!!
                    feeds["past_key_values.$layer.encoder.key"] = crossPast[layer * 2]!!
                    feeds["past_key_values.$layer.encoder.value"] = crossPast[layer * 2 + 1]!!
                }

                var nextId = eosTokenId
                decoder.run(feeds).use { result ->
                    val logits = result.get("logits").orElseThrow() as OnnxTensor
                    val buffer = logits.floatBuffer
                    val vocab = buffer.remaining()
                    var bestId = 0
                    var bestScore = Float.NEGATIVE_INFINITY
                    val offset = (buffer.position() / vocab) * vocab
                    for (i in 0 until vocab) {
                        val score = buffer.get(offset + i)
                        if (score > bestScore) {
                            bestScore = score
                            bestId = i
                        }
                    }
                    nextId = bestId.toLong()

                    val newSelf = arrayOfNulls<Cache>(layers * 2)
                    val newCross = arrayOfNulls<Cache>(layers * 2)
                    for (layer in 0 until layers) {
                        newSelf[layer * 2] = readCache(result, "present.$layer.decoder.key")
                        newSelf[layer * 2 + 1] = readCache(result, "present.$layer.decoder.value")
                        if (step == 0) {
                            newCross[layer * 2] = readCache(result, "present.$layer.encoder.key")
                            newCross[layer * 2 + 1] = readCache(result, "present.$layer.encoder.value")
                        }
                    }
                    decoderCache = newSelf
                    if (step == 0) crossCache = newCross
                }

                if (nextId == eosTokenId) break
                produced.add(nextId)
                current = longArrayOf(nextId)
            } finally {
                // The encoder tensors belong to the caller: never close them here.
                feeds.values.forEach { tensor ->
                    if (tensor !== encoderHidden && tensor !== encoderMask) tensor.close()
                }
            }
        }

        return tokenizer.decode(produced.toLongArray())
    }

    private fun cacheTensor(cache: Cache?, heads: Int, headDim: Int): OnnxTensor {
        val seq = cache?.shape?.get(2) ?: 0L
        val data = cache?.data ?: FloatArray(0)
        return OnnxTensor.createTensor(
            env,
            FloatBuffer.wrap(data),
            longArrayOf(1, heads.toLong(), seq, headDim.toLong()),
        )
    }

    private fun readCache(result: OrtSession.Result, name: String): Cache {
        val tensor = result.get(name).orElseThrow() as OnnxTensor
        val buffer = tensor.floatBuffer
        val data = FloatArray(buffer.remaining())
        buffer.get(data)
        return Cache(data, tensor.info.shape)
    }

    private fun booleanTensor(value: Boolean): OnnxTensor {
        val buffer = ByteBuffer.allocateDirect(1).order(ByteOrder.nativeOrder())
        buffer.put(if (value) 1 else 0)
        buffer.rewind()
        return OnnxTensor.createTensor(env, buffer, longArrayOf(1), OnnxJavaType.BOOL)
    }

    override fun close() {
        encoder.close()
        decoder.close()
    }
}
