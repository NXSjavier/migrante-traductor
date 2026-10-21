import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'download_notifier.dart';
import 'offline_engine.dart';
import 'online_translator.dart';

class TranslationService extends ChangeNotifier {
  final OnlineTranslator _online = OnlineTranslator();

  bool _isModelDownloaded = false;
  bool _isDownloading = false;
  bool _isTranslating = false;
  bool _isOnlineMode = false;
  double? _downloadProgress;
  String _sourceLanguage = 'es';
  String _targetLanguage = 'en';
  String? _error;
  String? _downloadStatus;
  DateTime? _lastModelCheck;

  /// Avoids checking the pack on every keystroke of the live translation.
  bool get _canRecheckModel {
    final last = _lastModelCheck;
    if (last == null) return true;
    return DateTime.now().difference(last) > const Duration(seconds: 15);
  }

  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'zh': '中文 (Chino)',
    'ja': '日本語 (Japonés)',
    'ko': '한국어 (Coreano)',
    'ru': 'Русский (Ruso)',
    'ar': 'العربية (Árabe)',
    'hi': 'हिन्दी (Hindi)',
  };

  /// Packs that exist today; the rest fall back to the online translator.
  static const Set<String> availablePacks = {'es-en'};

  bool get isModelDownloaded => _isModelDownloaded;
  bool get isDownloading => _isDownloading;
  bool get isTranslating => _isTranslating;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  String? get error => _error;
  String? get downloadStatus => _downloadStatus;
  double? get downloadProgress => _downloadProgress;
  bool get isOnlineMode => _isOnlineMode;
  Map<String, String> get languages => supportedLanguages;

  String get packId => OfflineEngine.packIdFor(_sourceLanguage, _targetLanguage);

  bool get hasPackForCurrentPair => availablePacks.contains(packId);

  String languageName(String code) => supportedLanguages[code] ?? code;

  Future<void> initialize() async {
    await checkModel();

    // A download started in a previous run may have finished while the app was
    // closed: clear the stale progress notification.
    if (_isModelDownloaded) {
      await DownloadNotifier.cancelProgress();
      _downloadStatus ??= 'Los idiomas ya están instalados.';
      notifyListeners();

      // Warm the engine up in the background so the first sentence is not slow.
      unawaited(
        OfflineEngine.loadPack(packId).catchError((Object error) {
          if (kDebugMode) debugPrint('No se pudo precargar el motor: $error');
        }),
      );
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> checkModel() async {
    try {
      final installed = await OfflineEngine.isInstalled(packId);
      _isModelDownloaded = installed;

      if (installed) {
        _downloadStatus ??= 'Los idiomas ya están instalados.';
      }
    } catch (e) {
      _isModelDownloaded = false;
      if (kDebugMode) debugPrint('No se pudo verificar el paquete: $e');
    } finally {
      _lastModelCheck = DateTime.now();
      notifyListeners();
    }
  }

  /// Downloads the language pack for the current pair.
  Future<void> downloadModel() async {
    if (_isDownloading) return;

    if (!hasPackForCurrentPair) {
      _error = 'Todavía no hay paquete offline para '
          '${languageName(_sourceLanguage)} → ${languageName(_targetLanguage)}.\n\n'
          'Por ahora la app traduce ese par por internet. Los paquetes offline '
          'disponibles son: Español → English.';
      notifyListeners();
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0;
    _error = null;
    _downloadStatus = 'Conectando...';
    notifyListeners();

    await DownloadNotifier.ensurePermission();
    await DownloadNotifier.showProgress('Descargando idiomas offline...');

    var lastShownPercent = -1;

    try {
      if (!await _hasInternet()) {
        throw Exception('No hay conexión a internet.\n\n'
            'Conectate a Wi-Fi o datos y volvé a intentar.');
      }

      final free = await freeStorageBytes();
      if (free != null && free < 350 * 1024 * 1024) {
        throw Exception(
          'Falta espacio: hay ${free ~/ (1024 * 1024)} MB libres y el paquete '
          'necesita ~110 MB más el espacio temporal.\n\n'
          'Liberá al menos 400 MB e intentá de nuevo.',
        );
      }

      await OfflineEngine.downloadPack(
        packId,
        onProgress: (received, total) {
          if (total <= 0) return;
          _downloadProgress = (received / total).clamp(0.0, 1.0);
          final percent = (_downloadProgress! * 100).round();
          _downloadStatus = 'Descargando $percent% '
              '(${received ~/ (1024 * 1024)} de ${total ~/ (1024 * 1024)} MB)';

          // The UI listens to this notifier: repaint once per percent, not per chunk.
          if (percent != lastShownPercent) {
            lastShownPercent = percent;
            notifyListeners();
          }
        },
      );

      _downloadStatus = 'Verificando el paquete...';
      notifyListeners();

      await OfflineEngine.loadPack(packId);

      _isModelDownloaded = true;
      _downloadProgress = 1;
      _downloadStatus = '¡Listo! Ya podés traducir sin internet.';
      await DownloadNotifier.showDone();
    } on TimeoutException {
      _error = 'La descarga tardó demasiado y se cortó.\n\n'
          'Probá de nuevo con mejor conexión.';
      await DownloadNotifier.showError('La descarga tardó demasiado.');
    } catch (e) {
      _error = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      await DownloadNotifier.showError(
        'No se completó la descarga. Abrí la app para ver el detalle.',
      );
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final lookup = await InternetAddress.lookup('github.com')
          .timeout(const Duration(seconds: 8));
      return lookup.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteModels() async {
    try {
      await OfflineEngine.deletePack(packId);
      _isModelDownloaded = false;
      _downloadProgress = null;
      _downloadStatus = null;
    } catch (e) {
      _error = 'No se pudo borrar el paquete: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Clears a half-downloaded pack and tries again from scratch.
  Future<void> resetAndDownload() async {
    if (_isDownloading) return;
    await DownloadNotifier.cancelProgress();
    await deleteModels();
    _error = null;
    await downloadModel();
  }

  static const MethodChannel _diagnostics =
      MethodChannel('migrante/diagnostics');

  Future<int?> freeStorageBytes() async {
    if (!Platform.isAndroid) return null;
    try {
      final result =
          await _diagnostics.invokeMapMethod<String, dynamic>('storage');
      return (result?['freeBytes'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Full report the user can copy and send when something fails.
  Future<String> diagnosticsText() async {
    final buffer = StringBuffer()
      ..writeln('Migrante Traductor · diagnóstico')
      ..writeln('Versión: 1.1.0')
      ..writeln('Android: ${Platform.operatingSystemVersion}')
      ..writeln('Idiomas: $_sourceLanguage → $_targetLanguage')
      ..writeln('Paquete: $packId');

    final installed = await OfflineEngine.isInstalled(packId);
    buffer.writeln('Paquete offline: ${installed ? 'instalado' : 'no instalado'}');

    final size = await OfflineEngine.installedSize(packId);
    if (size != null) {
      buffer.writeln('Tamaño del paquete: ${size ~/ (1024 * 1024)} MB');
    }

    buffer.writeln('Motor cargado: ${await OfflineEngine.isLoaded() ? 'sí' : 'no'}');

    final free = await freeStorageBytes();
    if (free != null) {
      buffer.writeln('Almacenamiento libre: ${free ~/ (1024 * 1024)} MB');
    }

    buffer.writeln('Internet: ${await _hasInternet() ? 'sí' : 'no'}');
    buffer.writeln('Servidor: ${OfflineEngine.baseUrl}');

    if (_error != null) {
      buffer.writeln('Último error: $_error');
    }

    return buffer.toString();
  }

  Future<void> setLanguages(String source, String target) async {
    if (source == target) return;
    _sourceLanguage = source;
    _targetLanguage = target;
    _error = null;
    _downloadStatus = null;
    _downloadProgress = null;
    _isModelDownloaded = false;
    notifyListeners();

    await OfflineEngine.unload();
    await checkModel();
  }

  void swapLanguages() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;

    _error = null;
    _downloadStatus = null;
    _downloadProgress = null;
    _isModelDownloaded = false;
    notifyListeners();

    OfflineEngine.unload();
    checkModel();
  }

  /// Translates with the offline pack when it is installed, and falls back to
  /// an online request otherwise.
  Future<String> translate(String text) async {
    if (text.trim().isEmpty) return '';

    if (!_isModelDownloaded && _canRecheckModel) {
      await checkModel();
    }

    _isTranslating = true;
    _error = null;
    notifyListeners();

    try {
      if (_isModelDownloaded) {
        try {
          _isOnlineMode = false;
          // Loading the model takes a few seconds the first time, then it stays
          // warm for the rest of the session.
          await OfflineEngine.ensureLoaded(packId);
          return await OfflineEngine.translate(text);
        } catch (offlineError) {
          // The pack is there but the engine failed: keep the app usable.
          if (kDebugMode) debugPrint('Engine offline falló: $offlineError');
          _isOnlineMode = true;
          return await _online.translate(
            text: text,
            from: _sourceLanguage,
            to: _targetLanguage,
          );
        }
      }

      _isOnlineMode = true;
      return await _online.translate(
        text: text,
        from: _sourceLanguage,
        to: _targetLanguage,
      );
    } catch (e) {
      _error = 'No se pudo traducir. Revisá la conexión.\n\nDetalle: $e';
      rethrow;
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    OfflineEngine.unload();
    super.dispose();
  }
}
