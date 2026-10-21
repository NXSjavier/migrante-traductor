import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads and runs our own translation packs.
///
/// A pack is a folder with `manifest.json`, `encoder.onnx`, `decoder.onnx` and
/// `vocab.tsv`. Nothing here depends on Google Play Services: the files come
/// from a plain HTTPS server and the model runs inside the app.
class OfflineEngine {
  static const MethodChannel _channel = MethodChannel('migrante/offline_engine');

  /// Where the packs live. Override while developing with
  /// `--dart-define=PACK_BASE_URL=http://10.0.2.2:8765`.
  static const String baseUrl = String.fromEnvironment(
    'PACK_BASE_URL',
    defaultValue:
        'https://github.com/NXSjavier/migrante-traductor/releases/download/packs-v1',
  );

  static String packIdFor(String source, String target) => '$source-$target';

  /// Release assets are flat files (`es-en-encoder.onnx`), so the pack id is
  /// part of the file name instead of a sub folder.
  static String assetUrl(String packId, String name) => '$baseUrl/$packId-$name';

  static Future<Directory> _packsRoot() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/packs');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> packDir(String id) async {
    final root = await _packsRoot();
    return Directory('${root.path}/$id');
  }

  /// True when every file listed in the manifest is present at its exact size.
  static Future<bool> isInstalled(String id) async {
    final manifest = await _localManifest(id);
    if (manifest == null) return false;

    final dir = await packDir(id);
    final files = manifest['files'];
    if (files is! Map) return false;

    for (final entry in files.entries) {
      final file = File('${dir.path}/${entry.key}');
      if (!await file.exists()) return false;
      final expected = ((entry.value as Map)['size'] as num).toInt();
      if (await file.length() != expected) return false;
    }
    return true;
  }

  static Future<Map<String, dynamic>?> _localManifest(String id) async {
    try {
      final dir = await packDir(id);
      final file = File('${dir.path}/manifest.json');
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Total size in bytes of the pack, when the manifest is already known.
  static Future<int?> installedSize(String id) async {
    final manifest = await _localManifest(id);
    if (manifest == null) return null;
    final files = manifest['files'];
    if (files is! Map) return null;
    var total = 0;
    for (final entry in files.values) {
      total += ((entry as Map)['size'] as num).toInt();
    }
    return total;
  }

  static Future<void> downloadPack(
    String id, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await packDir(id);
    await dir.create(recursive: true);

    final manifest = await _fetchJson(Uri.parse(assetUrl(id, 'manifest.json')));
    await File('${dir.path}/manifest.json')
        .writeAsString(jsonEncode(manifest));

    final files = (manifest['files'] as Map).cast<String, dynamic>();
    var total = 0;
    for (final entry in files.values) {
      total += ((entry as Map)['size'] as num).toInt();
    }

    var done = 0;
    onProgress?.call(0, total);

    for (final entry in files.entries) {
      final name = entry.key;
      final info = (entry.value as Map).cast<String, dynamic>();
      final size = (info['size'] as num).toInt();
      final expectedSha = info['sha256'] as String;
      final target = File('${dir.path}/$name');

      if (await target.exists() &&
          await target.length() == size &&
          await _sha256Of(target) == expectedSha) {
        done += size;
        onProgress?.call(done, total);
        continue;
      }

      await _downloadFile(
        Uri.parse(assetUrl(id, name)),
        target,
        size,
        onBytes: (fileBytes) => onProgress?.call(done + fileBytes, total),
      );

      if (await _sha256Of(target) != expectedSha) {
        await target.delete();
        throw Exception('El archivo $name llegó dañado. Se borró para reintentar.');
      }

      done += size;
      onProgress?.call(done, total);
    }
  }

  static Future<void> _downloadFile(
    Uri uri,
    File target,
    int expectedSize, {
    void Function(int bytes)? onBytes,
  }) async {
    final part = File('${target.path}.part');
    var have = await part.exists() ? await part.length() : 0;
    if (have > expectedSize) {
      await part.delete();
      have = 0;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    IOSink? sink;

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'MigranteTraductor');
      if (have > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      }

      final response = await request.close();
      final resumable = response.statusCode == HttpStatus.partialContent;
      if (response.statusCode != HttpStatus.ok && !resumable) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }

      final append = resumable && have > 0;
      if (!append) have = 0;
      onBytes?.call(have);

      sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
      await for (final chunk in response) {
        sink.add(chunk);
        have += chunk.length;
        onBytes?.call(have);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (have != expectedSize) {
        throw Exception('Descarga incompleta: $have de $expectedSize bytes.');
      }

      if (await target.exists()) await target.delete();
      await part.rename(target.path);
    } finally {
      await sink?.close();
      client.close(force: true);
    }
  }

  static Future<Map<String, dynamic>> _fetchJson(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'MigranteTraductor');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('No se pudo leer el paquete (HTTP ${response.statusCode}).');
      }
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  static Future<String> _sha256Of(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Loads the pack into memory. Safe to call repeatedly.
  static Future<void> loadPack(String id) async {
    final pending = _loading;
    if (pending != null) return pending;

    final future = _load(id);
    _loading = future;
    try {
      await future;
    } finally {
      _loading = null;
    }
  }

  static Future<void>? _loading;

  static Future<void> _load(String id) async {
    final dir = await packDir(id);
    await _channel.invokeMethod<bool>('load', {'path': dir.path});
  }

  /// Loads the pack only when the engine is not already in memory.
  static Future<void> ensureLoaded(String id) async {
    if (await isLoaded()) return;
    await loadPack(id);
  }

  static Future<bool> isLoaded() async {
    try {
      return await _channel.invokeMethod<bool>('isLoaded') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> translate(String text) async {
    final result = await _channel.invokeMethod<String>('translate', {
      'text': text,
    });
    return result ?? '';
  }

  static Future<void> unload() async {
    try {
      await _channel.invokeMethod<bool>('unload');
    } catch (_) {
      // Best effort.
    }
  }

  static Future<void> deletePack(String id) async {
    await unload();
    final dir = await packDir(id);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
