/// BBZCloud Mobile - Download Service
/// 
/// Handles file downloads from WebView with progress tracking
/// Downloads are saved to the Downloads directory
/// 
/// @version 1.0.0

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';

/// Download request model
class DownloadRequest {
  final String url;
  final String? filename;
  final Map<String, String>? headers;

  DownloadRequest({
    required this.url,
    this.filename,
    this.headers,
  });
}

/// Download progress callback
typedef DownloadProgressCallback = void Function(int received, int total);

/// Download service for handling file downloads
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Active downloads map (filename -> cancel function)
  final Map<String, void Function()> _activeDownloads = {};

  /// Download a file from URL and save to device
  /// 
  /// Returns the file path on success, null on failure
  Future<String?> downloadFile({
    required BuildContext context,
    required DownloadRequest request,
    DownloadProgressCallback? onProgress,
  }) async {
    String filename = request.filename ?? _extractFilenameFromUrl(request.url);

    try {
      logger.info('Starting download from URL: ${request.url}');
      logger.info('Initial filename: $filename');

      // Check and request storage permissions
      final permissionGranted = await _checkStoragePermissions(context);
      if (!permissionGranted) {
        logger.warning('Storage permission denied');
        _showSnackBar(context, 'Speicherberechtigung verweigert');
        return null;
      }

      // Get download directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        logger.error('Failed to get download directory');
        _showSnackBar(context, 'Download-Verzeichnis nicht verfügbar');
        return null;
      }

      // Show download started toast
      if (context.mounted) {
        _showSnackBar(context, 'Download gestartet: $filename');
      }

      // Perform HTTP request
      final client = http.Client();
      final httpRequest = http.Request('GET', Uri.parse(request.url));
      
      // Add headers if provided
      if (request.headers != null) {
        httpRequest.headers.addAll(request.headers!);
      }
      
      // Add critical headers for schul.cloud and SPA downloads
      // These prevent 403 Forbidden errors
      final uri = Uri.parse(request.url);
      final baseUrl = '${uri.scheme}://${uri.host}';
      
      // Referer header (required for many SPA downloads)
      if (!httpRequest.headers.containsKey('referer')) {
        httpRequest.headers['referer'] = baseUrl;
      }
      
      // Origin header (required for CORS-protected downloads)
      if (!httpRequest.headers.containsKey('origin')) {
        httpRequest.headers['origin'] = baseUrl;
      }
      
      // X-Requested-With (identifies AJAX requests)
      if (!httpRequest.headers.containsKey('x-requested-with')) {
        httpRequest.headers['x-requested-with'] = 'XMLHttpRequest';
      }
      
      // Accept header
      if (!httpRequest.headers.containsKey('accept')) {
        httpRequest.headers['accept'] = '*/*';
      }

      logger.info('Sending HTTP request...');
      final response = await client.send(httpRequest);

      logger.info('Response status: ${response.statusCode}');
      logger.info('Content-Type: ${response.headers['content-type']}');
      logger.info('Content-Length: ${response.headers['content-length']}');

      if (response.statusCode != 200) {
        throw Exception('Download fehlgeschlagen: ${response.statusCode}');
      }

      // Try to extract filename from Content-Disposition header
      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null) {
        // First try UTF-8 encoded filename
        final utf8Pattern = RegExp(r"filename\*=UTF-8''(.+?)(?:;|$)");
        final utf8Match = utf8Pattern.firstMatch(contentDisposition);
        if (utf8Match != null && utf8Match.group(1) != null) {
          filename = Uri.decodeComponent(utf8Match.group(1)!);
          logger.info('Filename from UTF-8 Content-Disposition: $filename');
        } else {
          // Fallback to regular filename with or without quotes
          final filenamePattern = RegExp(r'filename="?([^";]+)"?');
          final filenameMatch = filenamePattern.firstMatch(contentDisposition);
          if (filenameMatch != null && filenameMatch.group(1) != null) {
            filename = filenameMatch.group(1)!.trim();
            logger.info('Filename from Content-Disposition: $filename');
          }
        }
      }

      // Get content length for progress tracking
      final contentLength = response.contentLength ?? 0;
      logger.info('Content length: $contentLength bytes');

      // Download with progress tracking
      final chunks = <int>[];
      int receivedLength = 0;

      await for (final chunk in response.stream) {
        chunks.addAll(chunk);
        receivedLength += chunk.length;

        // Report progress
        if (onProgress != null && contentLength > 0) {
          onProgress(receivedLength, contentLength);
        }

        final percentage = contentLength > 0 
            ? (receivedLength / contentLength * 100).round()
            : 0;
        logger.info('Download progress: $percentage% ($receivedLength/$contentLength)');
      }

      client.close();

      // Validate download
      if (chunks.isEmpty) {
        throw Exception('Keine Daten heruntergeladen');
      }

      // Create file path
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      // Check if file already exists
      if (await file.exists()) {
        // Add timestamp to avoid overwriting
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameParts = filename.split('.');
        if (nameParts.length > 1) {
          final extension = nameParts.last;
          final nameWithoutExt = nameParts.sublist(0, nameParts.length - 1).join('.');
          filename = '${nameWithoutExt}_$timestamp.$extension';
        } else {
          filename = '${filename}_$timestamp';
        }
        logger.info('File exists, using new filename: $filename');
      }

      // Write file
      final finalFilePath = '${directory.path}/$filename';
      final finalFile = File(finalFilePath);
      await finalFile.writeAsBytes(Uint8List.fromList(chunks));

      logger.info('File saved successfully: $finalFilePath');

      // Show success toast
      if (context.mounted) {
        _showSnackBar(
          context,
          'Download abgeschlossen: $filename',
          isSuccess: true,
        );
      }

      return finalFilePath;
    } catch (error, stackTrace) {
      logger.error('Download failed', error, stackTrace);

      // Show error toast
      if (context.mounted) {
        _showSnackBar(
          context,
          'Download fehlgeschlagen: ${error.toString()}',
          isError: true,
        );
      }

      return null;
    } finally {
      _activeDownloads.remove(filename);
    }
  }

  /// Check and request storage permissions
  Future<bool> _checkStoragePermissions(BuildContext context) async {
    // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
    // For Android 10-12 (API 29-32), we use scoped storage
    // For Android 9 and below (API 28-), we need WRITE_EXTERNAL_STORAGE
    
    if (Platform.isAndroid) {
      // Check Android version
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // Android 13+ - no permission needed for app-specific directories
        logger.info('Android 13+ detected, no storage permission needed');
        return true;
      } else if (androidInfo >= 29) {
        // Android 10-12 - scoped storage, check if we have permission
        logger.info('Android 10-12 detected, checking storage permission');
        var status = await Permission.storage.status;
        
        if (!status.isGranted) {
          // Request permission
          status = await Permission.storage.request();
        }
        
        return status.isGranted;
      } else {
        // Android 9 and below - traditional storage permission
        logger.info('Android 9 and below detected, checking storage permission');
        var status = await Permission.storage.status;
        
        if (!status.isGranted) {
          // Request permission
          status = await Permission.storage.request();
          
          if (!status.isGranted) {
            // Show rationale if permanently denied
            if (status.isPermanentlyDenied) {
              if (context.mounted) {
                await _showPermissionDialog(context);
              }
            }
            return false;
          }
        }
        
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need permission for app documents directory
      return true;
    }
    
    return true;
  }

  /// Get Android version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    try {
      // This is a simple approximation - in production you'd use a plugin
      // For now, assume modern Android (33+)
      return 33;
    } catch (e) {
      logger.error('Failed to get Android version', e);
      return 33; // Default to modern Android
    }
  }

  /// Show permission dialog
  Future<void> _showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berechtigung erforderlich'),
        content: const Text(
          'Die App benötigt Zugriff auf den Speicher, um Dateien herunterzuladen. '
          'Bitte erteilen Sie die Berechtigung in den Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  /// Get download directory
  /// 
  /// On Android: Uses public Downloads directory if available, falls back to app documents
  /// On iOS: Uses app documents directory
  Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try to get public Downloads directory
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          logger.info('Using public Downloads directory');
          return directory;
        }
        
        // Fallback to external storage directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadDir = Directory('${externalDir.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          logger.info('Using external storage Downloads directory');
          return downloadDir;
        }
      }
      
      // Fallback to app documents directory (works for both Android and iOS)
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      logger.info('Using app documents Downloads directory');
      return downloadDir;
    } catch (error, stackTrace) {
      logger.error('Failed to get download directory', error, stackTrace);
      return null;
    }
  }

  /// Extract filename from URL
  String _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final filename = path.substring(path.lastIndexOf('/') + 1);

      // If no filename or too generic, create one with timestamp
      if (filename.isEmpty || filename.length < 3) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return 'download_$timestamp';
      }

      // Decode URI component to handle special characters
      return Uri.decodeComponent(filename);
    } catch (error) {
      logger.warning('Failed to extract filename from URL: $error');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'download_$timestamp';
    }
  }

  /// Show snackbar message
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : isSuccess
                ? Colors.green
                : null,
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Cancel an active download
  void cancelDownload(String filename) {
    final cancel = _activeDownloads[filename];
    if (cancel != null) {
      cancel();
      _activeDownloads.remove(filename);
      logger.info('Download cancelled: $filename');
    }
  }

  /// Check if a download is active
  bool isDownloadActive(String filename) {
    return _activeDownloads.containsKey(filename);
  }

  /// Get list of active downloads
  List<String> getActiveDownloads() {
    return _activeDownloads.keys.toList();
  }
}
