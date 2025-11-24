import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen del chat a Firebase Storage
  /// Retorna la URL de descarga
  Future<String> uploadChatImage({
    required String conversationId,
    required dynamic imageFile, // File para móvil, Uint8List para web
    String? fileName,
  }) async {
    try {
      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'image_$timestamp.jpg';
      
      // Ruta en Storage
      final path = 'chat_images/$conversationId/$name';
      final ref = _storage.ref().child(path);

      // Metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Subir según plataforma
      TaskSnapshot uploadTask;
      if (kIsWeb) {
        // Web: imageFile es Uint8List
        uploadTask = await ref.putData(imageFile as Uint8List, metadata);
      } else {
        // Móvil: imageFile es File
        uploadTask = await ref.putFile(imageFile as File, metadata);
      }

      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Elimina una imagen del chat
  Future<void> deleteChatImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Si falla al eliminar, no es crítico
      debugPrint('Error al eliminar imagen: $e');
    }
  }

  /// Obtiene el progreso de subida (para futuros usos)
  Stream<double> uploadChatImageWithProgress({
    required String conversationId,
    required dynamic imageFile,
    String? fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = fileName ?? 'image_$timestamp.jpg';
    final path = 'chat_images/$conversationId/$name';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(contentType: 'image/jpeg');

    UploadTask uploadTask;
    if (kIsWeb) {
      uploadTask = ref.putData(imageFile as Uint8List, metadata);
    } else {
      uploadTask = ref.putFile(imageFile as File, metadata);
    }

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
