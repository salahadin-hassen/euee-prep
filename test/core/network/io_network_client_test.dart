import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/network/network_client.dart';

void main() {
  late HttpServer server;
  late Directory tempDir;
  late IoNetworkClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    tempDir = await Directory.systemTemp.createTemp('network_client_test');
    client = IoNetworkClient(connectionTimeout: const Duration(seconds: 5));
  });

  tearDown(() async {
    await server.close(force: true);
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Temp cleanup is best-effort.
    }
  });

  Uri uri(String path) =>
      Uri.parse('http://${server.address.address}:${server.port}$path');

  group('getString', () {
    test('returns the response body', () async {
      server.listen((request) async {
        request.response.headers.contentType = ContentType.text;
        request.response.write('{"papers":[]}');
        await request.response.close();
      });

      final body = await client.getString(uri('/catalog'));

      expect(body, '{"papers":[]}');
    });

    test('throws HttpStatusException on non-200 responses', () async {
      server.listen((request) async {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      await expectLater(
        client.getString(uri('/missing')),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', HttpStatus.notFound),
        ),
      );
    });

    test('throws NetworkRequestException when the connection is refused',
        () async {
      final deadPort = server.port;
      await server.close(force: true);

      await expectLater(
        client.getString(Uri.parse('http://127.0.0.1:$deadPort/catalog')),
        throwsA(isA<NetworkRequestException>()),
      );
    });
  });

  group('downloadToFile', () {
    test('streams the body to disk and reports progress', () async {
      final payload = List<int>.generate(100, (i) => i % 256);
      server.listen((request) async {
        request.response.headers.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      final destination = File('${tempDir.path}${Platform.pathSeparator}pack.zip');
      final progress = <(int, int?)>[];
      await client.downloadToFile(
        uri('/pack.zip'),
        destination: destination,
        onProgress: (received, total) => progress.add((received, total)),
      );

      expect(await destination.readAsBytes(), payload);
      expect(progress, isNotEmpty);
      final received = progress.map((p) => p.$1).toList();
      final sorted = List<int>.from(received)..sort();
      expect(received, sorted, reason: 'progress must be monotonically increasing');
      expect(received.first, greaterThan(0));
      expect(progress.last.$1, payload.length);
      expect(progress.last.$2, payload.length);
    });

    test('throws HttpStatusException on non-200 responses', () async {
      server.listen((request) async {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
      });

      final destination = File('${tempDir.path}${Platform.pathSeparator}pack.zip');
      await expectLater(
        client.downloadToFile(uri('/pack.zip'), destination: destination),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', HttpStatus.forbidden),
        ),
      );
      expect(await destination.exists(), isFalse);
    });

    test('throws NetworkRequestException when the connection is refused',
        () async {
      final deadPort = server.port;
      await server.close(force: true);

      final destination = File('${tempDir.path}${Platform.pathSeparator}pack.zip');
      await expectLater(
        client.downloadToFile(
          Uri.parse('http://127.0.0.1:$deadPort/pack.zip'),
          destination: destination,
        ),
        throwsA(isA<NetworkRequestException>()),
      );
    });

    test('propagates FileSystemException when the destination path is invalid',
        () async {
      final payload = utf8.encode('x' * 16);
      server.listen((request) async {
        request.response.headers.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      // Point the destination at a path whose parent is an existing *file*,
      // which fails the directory creation/write with a FileSystemException.
      final blockingFile = File('${tempDir.path}${Platform.pathSeparator}blocker')
        ..writeAsStringSync('x');
      final destination =
          File('${blockingFile.path}${Platform.pathSeparator}pack.zip');

      await expectLater(
        client.downloadToFile(uri('/pack.zip'), destination: destination),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
