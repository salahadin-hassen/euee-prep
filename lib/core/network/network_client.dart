import 'dart:convert';
import 'dart:io';

/// Minimal HTTP abstraction for the app's backend calls.
///
/// The app deliberately has no third-party networking dependency: this wraps
/// `dart:io`'s [HttpClient] so catalog reads and ZIP downloads share one
/// seam — and so tests can script responses without touching the network.
abstract interface class NetworkClient {
  /// GETs [uri] and returns the response body as UTF-8 text.
  ///
  /// Throws [HttpStatusException] for non-200 responses and
  /// [NetworkRequestException] for connection-level failures.
  Future<String> getString(Uri uri);

  /// GETs [uri] and streams the response body into [destination].
  ///
  /// The body is never buffered in memory as a whole — chunks are written to
  /// disk as they arrive, which keeps peak memory flat on low-end devices.
  /// [onProgress] reports cumulative [receivedBytes] and the total size when
  /// the server provides a content length (otherwise `null`).
  Future<void> downloadToFile(
    Uri uri, {
    required File destination,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  });
}

/// Connection-level failure: DNS, TLS, socket reset, or no route to host.
class NetworkRequestException implements Exception {
  NetworkRequestException(this.uri, [this.cause]);

  final Uri uri;
  final Object? cause;

  @override
  String toString() => 'NetworkRequestException: GET $uri failed ($cause)';
}

/// The server answered with a non-200 status code.
class HttpStatusException implements Exception {
  HttpStatusException(this.uri, this.statusCode);

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'HttpStatusException: GET $uri returned $statusCode';
}

/// The device ran out of space while writing the response to disk (ENOSPC).
class InsufficientStorageException implements Exception {
  const InsufficientStorageException();

  @override
  String toString() => 'InsufficientStorageException: no space left on device';
}

/// POSIX `ENOSPC` — the errno reported when a write fails for lack of space.
const int _enospc = 28;

/// [NetworkClient] implementation backed by `dart:io`'s [HttpClient].
class IoNetworkClient implements NetworkClient {
  IoNetworkClient({this.connectionTimeout = const Duration(seconds: 30)});

  /// Timeout applied while establishing the connection.
  final Duration connectionTimeout;

  @override
  Future<String> getString(Uri uri) async {
    final client = _newClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpStatusException(uri, response.statusCode);
      }
      return await response.transform(utf8.decoder).join();
    } on SocketException catch (e) {
      throw NetworkRequestException(uri, e);
    } on HttpException catch (e) {
      throw NetworkRequestException(uri, e);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> downloadToFile(
    Uri uri, {
    required File destination,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final client = _newClient();
    RandomAccessFile? handle;
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpStatusException(uri, response.statusCode);
      }

      final total = response.contentLength >= 0 ? response.contentLength : null;
      await destination.parent.create(recursive: true);
      handle = await destination.open(mode: FileMode.write);
      var received = 0;
      await for (final chunk in response) {
        await handle.writeFrom(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await handle.flush();
    } on SocketException catch (e) {
      throw NetworkRequestException(uri, e);
    } on HttpException catch (e) {
      throw NetworkRequestException(uri, e);
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == _enospc) {
        throw const InsufficientStorageException();
      }
      rethrow;
    } finally {
      if (handle != null) {
        try {
          await handle.close();
        } catch (_) {
          // Best effort — the file is being cleaned up by the caller anyway.
        }
      }
      client.close(force: true);
    }
  }

  HttpClient _newClient() {
    final client = HttpClient()..connectionTimeout = connectionTimeout;
    // Never transparently decompress: the byte count on disk must match the
    // catalog's size_bytes for progress reporting to be truthful.
    client.autoUncompress = false;
    return client;
  }
}
