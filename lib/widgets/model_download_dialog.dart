import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/translation_service.dart';

/// Shows the offline language download with a visible percentage, elapsed time
/// and a concrete reason when it fails.
///
/// ML Kit does not report real download bytes (Google Play Services handles the
/// transfer), so the percentage is a time-based estimate. It keeps moving for
/// as long as the download runs and only reaches 100% when ML Kit confirms the
/// model is installed.
class ModelDownloadDialog extends StatefulWidget {
  const ModelDownloadDialog({super.key});

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  Timer? _ticker;
  final Stopwatch _total = Stopwatch();
  final Stopwatch _phase = Stopwatch();

  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDownload());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Real progress when the server reports bytes, time based estimate otherwise.
  double _estimate(TranslationService service) {
    if (service.isModelDownloaded && !service.isDownloading) return 1;

    final real = service.downloadProgress;
    if (real != null) return real.clamp(0.0, 1.0);

    final seconds = _phase.elapsed.inMilliseconds / 1000.0;
    final ratio = 1 - math.exp(-seconds / 30);
    return (ratio * 0.95).clamp(0.0, 0.95);
  }

  Future<void> _startDownload() async {
    if (!mounted) return;

    final service = context.read<TranslationService>();
    if (service.isDownloading) {
      // Already running (the dialog was opened from the home banner).
      _startTicker();
      return;
    }

    setState(() {
      _lastStatus = null;
      _total
        ..reset()
        ..start();
      _phase
        ..reset()
        ..start();
    });

    _startTicker();

    await service.downloadModel();

    if (!mounted) return;
    setState(() {
      _total.stop();
      _phase.stop();
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _total
      ..reset()
      ..start();
    _phase
      ..reset()
      ..start();

    _ticker = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final service = context.read<TranslationService>();
      final status = service.downloadStatus;

      setState(() {
        if (status != null && status != _lastStatus) {
          // A new phase started (next language or verification): restart the
          // estimate so the bar reflects the current download.
          _lastStatus = status;
          _phase
            ..reset()
            ..start();
        }

        if (!service.isDownloading) {
          timer.cancel();
          _total.stop();
          _phase.stop();
        }
      });
    });
  }

  Future<void> _showDiagnostics() async {
    final service = context.read<TranslationService>();
    final report = await service.diagnosticsText();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Diagnóstico'),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnóstico copiado')),
              );
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationService>(
      builder: (context, service, _) {
        final hasError = service.error != null && !service.isDownloading;
        final isDone = service.isModelDownloaded && !service.isDownloading;
        final progress = _estimate(service);
        final percent = (progress * 100).round().clamp(0, 100);

        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: Row(
            children: [
              Icon(
                hasError
                    ? Icons.error_outline
                    : isDone
                        ? Icons.cloud_done
                        : Icons.cloud_download,
                color: hasError
                    ? Colors.redAccent
                    : isDone
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Idiomas offline')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.isDownloading || isDone) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDone ? Colors.greenAccent : Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 46,
                        child: Text(
                          '$percent%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isDone ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (service.isDownloading) ...[
                  Text(
                    service.downloadStatus ?? 'Conectando...',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tiempo transcurrido: ${_total.elapsed.inSeconds} s',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Es un paquete de ~110 MB con progreso real. Se descarga una '
                    'sola vez y queda guardado en el teléfono.\n\n'
                    'Podés salir de la app: la descarga sigue y te avisamos con '
                    'una notificación cuando termina.\n\n'
                    'Mientras tanto la app ya traduce por internet.',
                    style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                  ),
                ] else if (hasError) ...[
                  Text(
                    service.error!,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: service.error!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Detalle copiado'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar detalle'),
                    ),
                  ),
                  const Text(
                    'Mientras tanto la app traduce por internet: podés usar '
                    'Texto, Voz y Cámara igual.',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (service.error!.contains('paquete offline')) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Ese par de idiomas todavía no tiene paquete. La app lo '
                      'traduce por internet sin problema.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ] else if (isDone) ...[
                  Text(
                    service.downloadStatus ??
                        'Los idiomas están instalados. Ya podés traducir sin internet.',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ] else ...[
                  const Text(
                    'Descargando los idiomas seleccionados.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!isDone)
              TextButton(
                onPressed: _showDiagnostics,
                child: const Text('Diagnóstico'),
              ),
            if (service.isDownloading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ocultar'),
              ),
            if (hasError)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            if (hasError)
              TextButton(
                onPressed: () async {
                  final service = context.read<TranslationService>();
                  setState(() {
                    _lastStatus = null;
                    _total
                      ..reset()
                      ..start();
                    _phase
                      ..reset()
                      ..start();
                  });
                  _startTicker();
                  await service.resetAndDownload();
                },
                child: const Text('Borrar y reintentar'),
              ),
            if (hasError)
              FilledButton.icon(
                onPressed: () => _startDownload(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            if (isDone)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Listo'),
              ),
          ],
        );
      },
    );
  }
}
