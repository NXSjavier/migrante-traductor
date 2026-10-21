package com.migrante.migrante_traductor.engine

import java.io.File

/**
 * Minimal SentencePiece Unigram tokenizer.
 *
 * The exported Marian models use a Metaspace pre-tokenizer and no normalizer,
 * so the whole pipeline reduces to: collapse whitespace, mark every word start
 * with U+2581 and run Viterbi over the vocabulary.
 *
 * Vocabulary file format: one `piece<TAB>score` per line, where the line order
 * defines the token id. Pieces are escaped with a backslash.
 */
class UnigramTokenizer private constructor(
    private val pieces: Array<String>,
    private val scores: FloatArray,
    private val ids: HashMap<String, Int>,
    private val maxPieceChars: Int,
) {
    companion object {
        const val SPACE = '\u2581'
        private const val UNK_PENALTY = -100f

        fun load(file: File): UnigramTokenizer {
            val pieceList = ArrayList<String>(66_000)
            val scoreList = ArrayList<Float>(66_000)
            var longest = 1

            file.bufferedReader(Charsets.UTF_8).useLines { lines ->
                for (line in lines) {
                    if (line.isEmpty()) continue
                    val tab = line.lastIndexOf('\t')
                    if (tab <= 0) continue
                    val piece = unescape(line.substring(0, tab))
                    pieceList.add(piece)
                    scoreList.add(line.substring(tab + 1).toFloat())
                    if (piece.length > longest) longest = piece.length
                }
            }

            val pieces = pieceList.toTypedArray()
            val index = HashMap<String, Int>(pieces.size * 2)
            for (i in pieces.indices) index[pieces[i]] = i

            return UnigramTokenizer(
                pieces = pieces,
                scores = scoreList.toFloatArray(),
                ids = index,
                maxPieceChars = minOf(longest, 24),
            )
        }

        private fun unescape(raw: String): String {
            if (raw.indexOf('\\') < 0) return raw
            val out = StringBuilder(raw.length)
            var i = 0
            while (i < raw.length) {
                val c = raw[i]
                if (c == '\\' && i + 1 < raw.length) {
                    when (raw[i + 1]) {
                        't' -> out.append('\t')
                        'n' -> out.append('\n')
                        'r' -> out.append('\r')
                        '\\' -> out.append('\\')
                        else -> out.append(raw[i + 1])
                    }
                    i += 2
                } else {
                    out.append(c)
                    i++
                }
            }
            return out.toString()
        }
    }

    val size: Int get() = pieces.size

    fun piece(id: Int): String = pieces[id]

    /** Encodes text into model token ids. Unknown characters are dropped. */
    fun encode(text: String): LongArray {
        val normalized = normalize(text)
        if (normalized.isEmpty()) return LongArray(0)

        val n = normalized.length
        val best = FloatArray(n + 1) { Float.NEGATIVE_INFINITY }
        val bestLen = IntArray(n + 1)
        best[0] = 0f

        for (i in 0 until n) {
            val from = best[i]
            if (from == Float.NEGATIVE_INFINITY) continue

            val maxLen = minOf(maxPieceChars, n - i)
            var matchedSingle = false
            for (len in maxLen downTo 1) {
                val id = ids[normalized.substring(i, i + len)] ?: continue
                if (len == 1) matchedSingle = true
                val score = from + scores[id]
                if (score > best[i + len]) {
                    best[i + len] = score
                    bestLen[i + len] = len
                }
            }

            if (!matchedSingle) {
                val score = from + UNK_PENALTY
                if (score > best[i + 1]) {
                    best[i + 1] = score
                    bestLen[i + 1] = 1
                }
            }
        }

        val out = ArrayList<Long>(n)
        var pos = n
        while (pos > 0) {
            val len = bestLen[pos]
            if (len <= 0) break
            val start = pos - len
            val id = ids[normalized.substring(start, pos)]
            if (id != null) out.add(id.toLong())
            pos = start
        }
        out.reverse()
        return out.toLongArray()
    }

    /** Turns model ids back into text. */
    fun decode(ids: LongArray): String {
        val sb = StringBuilder(ids.size * 4)
        for (raw in ids) {
            val id = raw.toInt()
            if (id < 0 || id >= pieces.size) continue
            val piece = pieces[id]
            if (piece == "</s>" || piece == "<pad>" || piece == "<unk>") continue
            sb.append(piece)
        }
        return sb.toString().replace(SPACE, ' ').trim()
    }

    private fun normalize(text: String): String {
        val collapsed = StringBuilder(text.length + 2)
        var pendingSpace = false
        for (c in text) {
            if (c.isWhitespace()) {
                pendingSpace = collapsed.isNotEmpty()
            } else {
                if (pendingSpace) {
                    collapsed.append(' ')
                    pendingSpace = false
                }
                collapsed.append(c)
            }
        }
        if (collapsed.isEmpty()) return ""
        val spaced = StringBuilder(collapsed.length + 1)
        spaced.append(SPACE)
        for (c in collapsed) {
            spaced.append(if (c == ' ') SPACE else c)
        }
        return spaced.toString()
    }
}
