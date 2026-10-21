package com.migrante.migrante_traductor

import android.os.StatFs
import com.migrante.migrante_traductor.engine.EngineManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native side of the app.
 *
 * `migrante/diagnostics` reports the free space so the app can warn before a
 * download. `migrante/offline_engine` runs our own translation packs, which do
 * not depend on Google Play Services at all.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "migrante/diagnostics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "storage" -> {
                        val stat = StatFs(applicationContext.filesDir.absolutePath)
                        result.success(
                            mapOf(
                                "freeBytes" to stat.availableBytes,
                                "totalBytes" to stat.totalBytes
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "migrante/offline_engine")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isLoaded" -> result.success(EngineManager.isLoaded)

                    "load" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("BAD_ARGS", "Falta la ruta del paquete", null)
                            return@setMethodCallHandler
                        }
                        EngineManager.load(File(path)) { error ->
                            if (error == null) {
                                result.success(true)
                            } else {
                                result.error(
                                    "ENGINE_LOAD", error.message ?: "no se pudo cargar", null,
                                )
                            }
                        }
                    }

                    "translate" -> {
                        val text = call.argument<String>("text")
                        if (text.isNullOrBlank()) {
                            result.error("BAD_ARGS", "Falta el texto", null)
                            return@setMethodCallHandler
                        }
                        EngineManager.translate(text) { output, error ->
                            if (output != null) {
                                result.success(output)
                            } else {
                                result.error(
                                    "ENGINE_TRANSLATE", error?.message ?: "falló", null,
                                )
                            }
                        }
                    }

                    "unload" -> {
                        EngineManager.unload()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
