import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignInAccount account;

  GoogleDriveService(this.account);

  Future<drive.DriveApi> getDriveApi() async {
    final googleAuth = await account.authentication;
    final headers = {
      'Authorization': 'Bearer ${googleAuth.accessToken}',
    };
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<List<drive.File>> listFolders() async {
    final driveApi = await getDriveApi();
    final result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and trashed = false",
      $fields: 'files(id, name)',
    );
    return result.files ?? [];
  }

  Future<drive.File?> createFolder(String name) async {
    final driveApi = await getDriveApi();
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';
    final result = await driveApi.files.create(folder);
    return result;
  }

  Future<String?> uploadImageAndGetPublicUrl(PlatformFile file, String folderId) async {
    try {
      final driveApi = await getDriveApi();
      final driveFile = drive.File()
        ..name = file.name
        ..parents = [folderId];
      
      final fileBytes = await _readFileBytes(file);
      if (fileBytes == null) {
        throw Exception("No se pudieron leer los bytes del archivo");
      }

      final stream = http.ByteStream.fromBytes(fileBytes);
      final contentType = _getContentType(file.name);
      
      final media = drive.Media(
        stream,
        fileBytes.length,
        contentType: contentType,
      );
      
      final result = await driveApi.files.create(driveFile, uploadMedia: media, $fields: 'id');

      if (result.id == null) throw Exception("File creation failed, no ID returned.");

      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';
      await driveApi.permissions.create(permission, result.id!);

      // USAR LA MISMA URL QUE EN LA APLICACIÓN PYTHON - Compatible con Outlook
      return 'https://lh3.googleusercontent.com/d/${result.id}';
      
    } catch (e) {
      debugPrint("Error en uploadImageAndGetPublicUrl: $e");
      rethrow;
    }
  }

  // Método para listar imágenes en una carpeta (como en Python)
  Future<List<DriveImage>> listImagesInFolder(String folderId) async {
    try {
      final driveApi = await getDriveApi();
      final result = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType contains 'image/' and trashed=false",
        $fields: 'files(id, name)',
      );

      final images = <DriveImage>[];
      for (final file in result.files ?? []) {
        final imageUrl = 'https://lh3.googleusercontent.com/d/${file.id}';
        images.add(DriveImage(
          id: file.id!,
          name: file.name ?? 'Sin nombre',
          url: imageUrl,
        ));
      }
      
      // Ordenar alfabéticamente
      images.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return images;
    } catch (e) {
      debugPrint("Error listando imágenes: $e");
      rethrow;
    }
  }

  // Método auxiliar para leer los bytes del archivo
  Future<List<int>?> _readFileBytes(PlatformFile file) async {
    try {
      if (file.bytes != null) {
        return file.bytes;
      } else if (file.path != null) {
        final fileObj = File(file.path!);
        return await fileObj.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint("Error leyendo bytes del archivo: $e");
      return null;
    }
  }

  // Método para determinar el content-type
  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }
}

class DriveImage {
  final String id;
  final String name;
  final String url;

  DriveImage({required this.id, required this.name, required this.url});
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}