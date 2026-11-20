// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Image provider adapter for Tsumiru (created 2026-11-20).
// Replaces venera's ReaderImageProvider/BaseImageProvider for the vendored
// reader. M2: bytes flow through Tsumiru's flutter_cache_manager so both
// reader engines share one cache (cacheKey aligned with ServerImage);
// chunk events feed ComicImage's progress UI; decode size capped at the
// descriptor level (replaces venera's dynamic imageCache resizing);
// page-crop is handled by the factory returning Tsumiru's
// CroppedImageProvider instead (see VeneraEngineScreen, M4).

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Image provider for the vendored reader.
///
/// [url] is an `http(s)://` or `file://` image URL. [headers] are forwarded
/// to HTTP requests (Tsumiru auth headers — see ServerImage). [cacheKey]
/// must match the key ServerImage would use so both engines hit the same
/// flutter_cache_manager entry. [targetWidth]/[targetHeight] cap the decoded
/// texture size (one dimension preserves aspect ratio).
class TsumiruImageProvider extends ImageProvider<TsumiruImageProvider> {
  const TsumiruImageProvider(
    this.url, {
    this.headers = const {},
    this.cacheKey,
    this.cacheManager,
    this.targetWidth,
    this.targetHeight,
    this.maxRetries = 3,
  });

  final String url;

  final Map<String, String> headers;

  /// Cache key shared with ServerImage; defaults to [url].
  final String? cacheKey;

  final CacheManager? cacheManager;

  /// Display-pixel decode caps (logical × DPR); one dimension preserves
  /// aspect ratio at the codec level.
  final int? targetWidth;
  final int? targetHeight;

  final int maxRetries;

  CacheManager get _manager => cacheManager ?? DefaultCacheManager();

  String get _key => cacheKey ?? url;

  Future<Uint8List> _loadBytes(
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    if (url.startsWith('file://')) {
      final file = File(Uri.parse(url).toFilePath());
      if (!await file.exists()) {
        throw StateError('Image file not found: $url');
      }
      final bytes = await file.readAsBytes();
      chunkEvents.add(ImageChunkEvent(
        cumulativeBytesLoaded: bytes.length,
        expectedTotalBytes: bytes.length,
      ));
      return bytes;
    }

    var lastError = Object();
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        Uint8List? bytes;
        await for (final response in _manager.getFileStream(
          url,
          key: _key,
          headers: headers,
          withProgress: true,
        )) {
          if (response is DownloadProgress) {
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: response.downloaded,
              expectedTotalBytes: response.totalSize,
            ));
          }
          if (response is FileInfo) {
            bytes = await response.file.readAsBytes();
          }
        }
        if (bytes == null || bytes.isEmpty) {
          throw StateError('Empty response body: $url');
        }
        chunkEvents.add(ImageChunkEvent(
          cumulativeBytesLoaded: bytes.length,
          expectedTotalBytes: bytes.length,
        ));
        return bytes;
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
        }
      }
    }
    throw lastError;
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
    // Cap decoded texture size here (replaces venera's global
    // imageCache.maximumSizeBytes tuning); one dimension preserves aspect.
    return descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
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
      other._key == _key &&
      other.targetWidth == targetWidth &&
      other.targetHeight == targetHeight;

  @override
  int get hashCode => Object.hash(url, _key, targetWidth, targetHeight);

  @override
  String toString() => 'TsumiruImageProvider("$url")';
}
