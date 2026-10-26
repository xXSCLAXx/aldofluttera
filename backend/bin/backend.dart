import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart' as backend;

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  print('Backend escuchando en http://localhost:$port');

  await for (final request in server) {
    request.response.headers
      ..contentType = ContentType.json
      ..set('Access-Control-Allow-Origin', '*');

    if (request.method == 'GET' && request.uri.path == '/api/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode(backend.healthResponse()));
    } else if (request.method == 'GET' && request.uri.path == '/api/message') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write(
          jsonEncode(<String, String>{
            'message': 'Backend conectado correctamente',
          }),
        );
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode(<String, String>{'error': 'Ruta no encontrada'}));
    }

    await request.response.close();
  }
}
