import 'dart:convert';
import 'dart:io';

/// Online translation used when the ML Kit offline models are not installed.
///
/// The offline path stays the preferred one: this is only a safety net so the
/// app keeps translating on phones where Google Play Services refuses to
/// download the models.
class OnlineTranslator {
  static const Duration _timeout = Duration(seconds: 15);

  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': from,
        'tl': to,
        'dt': 't',
        'q': text,
      });

      final request = await client.getUrl(uri).timeout(_timeout);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
      );

      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }

      final body =
          await response.transform(utf8.decoder).join().timeout(_timeout);
      final decoded = jsonDecode(body);

      final chunks = decoded is List && decoded.isNotEmpty ? decoded[0] : null;
      if (chunks is! List) {
        throw Exception('Respuesta inesperada del servidor');
      }

      final buffer = StringBuffer();
      for (final chunk in chunks) {
        if (chunk is List && chunk.isNotEmpty && chunk[0] is String) {
          buffer.write(chunk[0]);
        }
      }

      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw Exception('El servidor devolvió una traducción vacía');
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }
}
