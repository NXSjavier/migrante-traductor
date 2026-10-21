import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// System notifications for the offline model download, so the user can leave
/// the app and still know what is happening.
class DownloadNotifier {
  DownloadNotifier._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _progressId = 1001;
  static const int _resultId = 1002;

  static const String _channelId = 'model_download';
  static const String _channelName = 'Descarga de idiomas';

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  /// Android 13+ needs the runtime permission. Denying it only means no
  /// notifications: the download keeps working.
  static Future<void> ensurePermission() async {
    try {
      if (await Permission.notification.isGranted) return;
      await Permission.notification.request();
    } catch (_) {
      // Permission handler unavailable (e.g. desktop): ignore.
    }
  }

  static Future<void> showProgress(String status) async {
    try {
      await _ensureInitialized();
      await _plugin.show(
        _progressId,
        'Descargando idiomas offline',
        status,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription:
                'Muestra el avance de la descarga de los idiomas offline',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showProgress: true,
            indeterminate: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {
      // Never let a notification failure break the download.
    }
  }

  static Future<void> showDone() async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(_progressId);
      await _plugin.show(
        _resultId,
        'Idiomas listos',
        'Ya podés traducir sin internet. Abrí la app y probá.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription:
                'Muestra el avance de la descarga de los idiomas offline',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {
      // Ignore notification errors.
    }
  }

  static Future<void> showError(String message) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(_progressId);
      await _plugin.show(
        _resultId,
        'No se pudieron descargar los idiomas',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription:
                'Muestra el avance de la descarga de los idiomas offline',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {
      // Ignore notification errors.
    }
  }

  /// Removes the ongoing progress notification (finished, cancelled or the
  /// models were already installed when the app started).
  static Future<void> cancelProgress() async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(_progressId);
    } catch (_) {
      // Ignore notification errors.
    }
  }
}
