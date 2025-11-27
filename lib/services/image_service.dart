import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class ImageService {
  static Future<List<Map<String, String>>> pickMultipleImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true, // CRÍTICO: Permite seleccionar múltiples imágenes
        withData: true, // Importante: Lee los bytes del archivo
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.map((file) {
          // Codificar a Base64
          String base64String = base64Encode(file.bytes!);
          String extension = file.extension ?? 'png';
          String mimeType = 'image/$extension';
          
          return {
            'filename': file.name,
            'base64': base64String,
            'mimeType': mimeType,
            'cid': 'img_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al seleccionar imágenes: $e');
    }
  }

  // Convertir imagen a formato Data URI para HTML incrustado
  static String convertToDataUri(String base64String, String mimeType) {
    return 'data:$mimeType;base64,$base64String';
  }
}