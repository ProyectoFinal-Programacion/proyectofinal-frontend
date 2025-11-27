import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'Chat-images-manovecina';

  /// Sube una imagen del chat a Supabase Storage
  /// Retorna la URL de descarga
  Future<String> uploadChatImage({
    required String conversationId,
    required dynamic imageFile, // File para móvil, Uint8List para web
    String? fileName,
  }) async {
    try {
      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName != null ? path.extension(fileName) : '.jpg';
      final name = 'image_$timestamp$ext';
      
      // Ruta en Storage (incluye conversationId para organizar)
      final filePath = '$conversationId/$name';

      // Subir según plataforma
      if (kIsWeb) {
        // Web: imageFile es Uint8List
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(filePath, imageFile as Uint8List);
      } else {
        // Móvil: imageFile es File
        await _supabase.storage
            .from(_bucketName)
            .upload(filePath, imageFile as File);
      }

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Elimina una imagen del chat
  Future<void> deleteChatImage(String imageUrl) async {
    try {
      // Extraer el path del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Buscar el path después de 'chat-images'
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        await _supabase.storage
            .from(_bucketName)
            .remove([filePath]);
      }
    } catch (e) {
      // Si falla al eliminar, no es crítico
      debugPrint('Error al eliminar imagen: $e');
    }
  }

  /// Obtiene el progreso de subida (para futuros usos)
  /// NOTA: Supabase no soporta nativamente progreso de subida
  /// Esta función está aquí para mantener compatibilidad con tu código existente
  Stream<double> uploadChatImageWithProgress({
    required String conversationId,
    required dynamic imageFile,
    String? fileName,
  }) async* {
    // Emitir 0% al inicio
    yield 0.0;
    
    try {
      // Realizar la subida
      await uploadChatImage(
        conversationId: conversationId,
        imageFile: imageFile,
        fileName: fileName,
      );
      
      // Emitir 100% al finalizar
      yield 1.0;
    } catch (e) {
      rethrow;
    }
  }
}
