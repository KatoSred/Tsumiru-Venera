// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Image provider adapter for Tsumiru (created 2026-11-20).
// Replaces venera's ReaderImageProvider/BaseImageProvider for the vendored
// reader. M1: file:// and plain HTTP(S) download with chunk events and 3
// retries; M2 will align cache keys with Tsumiru's cache layer and implement
// [enableCrop].

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;

/// Image provider for the vendored reader.
///
/// [url] is an `http(s)://` or `file://` image URL; [headers] are forwarded
/// to HTTP requests; [enableCrop] is reserved for M2 (page-crop support).
class TsumiruImageProvider extends ImageProvider<TsumiruImageProvider> {
  const TsumiruImageProvider(
    this.url, {
    this.headers = const {},
    this.enableCrop = false,
  });

  final String url;

  final Map<String, String> headers;

  final bool enableCrop;

  static const int _maxRetries = 3;

  Future<Uint8List> _loadBytes(
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    Uint8List bytes;
    if (url.startsWith('file://')) {
      final file = File(url.substring('file://'.length));
      if (!await file.exists()) {
        throw StateError('Image file not found: $url');
      }
      bytes = await file.readAsBytes();
      chunkEvents.add(const ImageChunkEvent(
        cumulativeBytesLoaded: 0,
        expectedTotalBytes: null,
      ));
    } else {
      var lastError = Object();
      for (var attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: headers,
          );
          if (response.statusCode != 200) {
            throw HttpException('HTTP ${response.statusCode} for $url');
          }
          bytes = response.bodyBytes;
          final total = int.tryParse(
            response.headers['content-length'] ?? '',
          );
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: bytes.length,
            expectedTotalBytes: total,
          ));
          return bytes;
        } catch (e) {
          lastError = e;
          if (attempt < _maxRetries) {
            await Future<void>.delayed(
              Duration(milliseconds: 300 * attempt),
            );
          }
        }
      }
      throw lastError;
    }
    return bytes;
  }

  Future<ui.Codec> _loadAsync(
    TsumiruImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);
    final bytes = await _loadBytes(chunkEvents);
    if (bytes.isEmpty) {
      throw StateError('Empty response body: $url');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    return descriptor.instantiateCodec();
  }

  @override
  ImageStreamCompleter loadImage(
    TsumiruImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
        );
      },
    );
  }

  @override
  Future<TsumiruImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<TsumiruImageProvider>(this);
  }

  @override
  bool operator ==(Object other) =>
      other is TsumiruImageProvider &&
      other.url == url &&
      other.enableCrop == enableCrop;

  @override
  int get hashCode => Object.hash(url, enableCrop);

  @override
  String toString() => 'TsumiruImageProvider("$url")';
}
