package com.migrante.migrante_traductor.engine

import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.File
import java.util.concurrent.Executors

/**
 * Owns the offline translation model.
 *
 * Loading a pack takes a few hundred milliseconds and translating a sentence
 * around one second, so everything runs on a single background thread and
 * results are posted back to the main thread.
 */
object EngineManager {
    private const val TAG = "OfflineEngine"

    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "offline-engine").apply { priority = Thread.NORM_PRIORITY - 1 }
    }
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var translator: MarianTranslator? = null

    @Volatile
    private var loadedPath: String? = null

    val isLoaded: Boolean get() = translator != null

    fun load(dir: File, onDone: (Throwable?) -> Unit) {
        executor.execute {
            try {
                val encoder = File(dir, "encoder.onnx")
                val decoder = File(dir, "decoder.onnx")
                val vocab = File(dir, "vocab.tsv")
                require(encoder.exists() && decoder.exists() && vocab.exists()) {
                    "Faltan archivos del paquete en ${dir.absolutePath}"
                }

                if (translator != null && loadedPath == dir.absolutePath) {
                    main.post { onDone(null) }
                    return@execute
                }

                translator?.close()
                translator = null

                val started = System.currentTimeMillis()
                val tokenizer = UnigramTokenizer.load(vocab)
                val engine = MarianTranslator(
                    encoderPath = encoder.absolutePath,
                    decoderPath = decoder.absolutePath,
                    tokenizer = tokenizer,
                )
                translator = engine
                loadedPath = dir.absolutePath
                Log.i(TAG, "pack cargado en ${System.currentTimeMillis() - started} ms (${tokenizer.size} tokens)")
                main.post { onDone(null) }
            } catch (error: Throwable) {
                Log.e(TAG, "no se pudo cargar el paquete", error)
                main.post { onDone(error) }
            }
        }
    }

    fun translate(text: String, onDone: (String?, Throwable?) -> Unit) {
        val engine = translator
        if (engine == null) {
            onDone(null, IllegalStateException("El motor offline no está cargado"))
            return
        }
        executor.execute {
            try {
                val started = System.currentTimeMillis()
                val output = engine.translate(text)
                Log.d(TAG, "traducido en ${System.currentTimeMillis() - started} ms: $output")
                main.post { onDone(output, null) }
            } catch (error: Throwable) {
                Log.e(TAG, "falló la traducción", error)
                main.post { onDone(null, error) }
            }
        }
    }

    fun unload() {
        executor.execute {
            translator?.close()
            translator = null
            loadedPath = null
        }
    }
}
