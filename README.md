# Migrante Traductor

Traductor para migrantes con texto, voz, cámara y un curso de idiomas por niveles.
Funciona **sin internet** con paquetes de idioma propios, sin depender de Google Play Services.

## Qué hace

- **Texto**: traducción automática mientras escribís.
- **Voz**: reconocimiento y lectura en voz alta (necesita internet, lo provee Google).
- **Cámara**: OCR del texto de un cartel o documento y traducción. El OCR va dentro del APK: funciona sin internet.
- **Aprender**: 8 niveles (A0 a B2), 32 lecciones y 160 frases con audio.
- **Offline**: descarga un paquete de ~110 MB y traduce texto y cámara sin conexión.

## Cómo funciona el modo offline

No usa los modelos de ML Kit: esos los baja y los administra Servicios de Google Play,
y en varios teléfonos (HyperOS, ROMs modificadas) la descarga queda trabada para siempre.

En su lugar, la app baja un **paquete** desde los releases de este repositorio:

```
es-en-encoder.onnx   50 MB   encoder Marian (OPUS-MT) cuantizado int8
es-en-decoder.onnx   57 MB   decoder con caché KV
es-en-vocab.tsv     1.3 MB   vocabulario Unigram (65001 piezas)
es-en-manifest.json          tamaños y SHA-256 de cada archivo
```

Todo corre dentro de la app con **ONNX Runtime** para Android. El progreso de la
descarga es real (bytes), se puede reanudar y cada archivo se verifica por SHA-256.

## Estructura

```
lib/services/offline_engine.dart              descarga, verificación y API del motor
android/app/src/main/kotlin/.../engine/
    UnigramTokenizer.kt                       tokenizador SentencePiece Unigram
    MarianTranslator.kt                       encoder + decoder con greedy search
    EngineManager.kt                          carga y ejecución en segundo plano
lib/services/translation_service.dart         offline si hay paquete, internet si no
```

## Créditos y licencia de los modelos

Los paquetes usan modelos **OPUS-MT** de Helsinki-NLP (`Helsinki-NLP/opus-mt-es-en`),
exportados a ONNX por [Xenova](https://huggingface.co/Xenova), bajo licencia
**CC-BY-4.0**. Se permite el uso comercial citando la fuente.

Cita sugerida:

> Jörg Tiedemann, Helsinki-NLP/OPUS-MT, https://github.com/Helsinki-NLP/OPUS-MT

El código de la app no está licenciado todavía: todos los derechos reservados
hasta que el autor elija una licencia.
