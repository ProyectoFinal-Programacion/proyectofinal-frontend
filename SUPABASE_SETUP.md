# Guía: Migración a Supabase Storage

Esta guía te muestra cómo completar la migración de Firebase Storage a Supabase Storage para evitar costos.

## ✅ Ya Completado

- ✅ Dependencia `supabase_flutter` agregada a `pubspec.yaml`
- ✅ `StorageService` migrado de Firebase a Supabase
- ✅ Código de inicialización agregado en `main.dart`

## 📋 Pasos Pendientes

### 1. Crear Cuenta y Proyecto en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea una cuenta gratuita
3. Crea un nuevo proyecto
4. Guarda las siguientes credenciales que aparecerán:
   - **Project URL** (ej: `https://tuproyecto.supabase.co`)
   - **Anon Key** (clave pública)

### 2. Crear Bucket de Almacenamiento

1. En tu proyecto de Supabase, ve a **Storage** en el menú lateral
2. Haz clic en **Create a new bucket**
3. Nombra el bucket: `chat-images`
4. Configura como **Público** (para que las URLs sean accesibles)
5. Haz clic en **Create bucket**

### 3. Configurar Políticas de Seguridad (Storage Policies)

Para que las imágenes puedan ser subidas y accedidas, necesitas configurar políticas:

1. En Storage, selecciona el bucket `chat-images`
2. Ve a la pestaña **Policies**
3. Crea las siguientes políticas:

#### Política para SUBIR (INSERT)
```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-images');
```

#### Política para LEER (SELECT) - Público
```sql
CREATE POLICY "Allow public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat-images');
```

#### Política para ELIMINAR (DELETE)
```sql
CREATE POLICY "Allow authenticated deletes"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'chat-images');
```

> **Nota**: Si solo quieres permitir uploads sin autenticación (desarrollo), puedes usar `TO public` en lugar de `TO authenticated`.

### 4. Actualizar Credenciales en `main.dart`

Abre `lib/main.dart` y reemplaza estas líneas:

```dart
await Supabase.initialize(
  url: 'TU_SUPABASE_URL_AQUI', // ← Reemplaza con tu URL
  anonKey: 'TU_SUPABASE_ANON_KEY_AQUI', // ← Reemplaza con tu anon key
);
```

**Ejemplo:**
```dart
await Supabase.initialize(
  url: 'https://xyzcompany.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

### 5. Instalar Dependencias

Ejecuta en la terminal:

```bash
flutter pub get
```

### 6. Verificar que Funcione

Tu aplicación ya está lista para usar Supabase Storage. El código existente que usa `StorageService` funcionará sin cambios.

**Ejemplo de uso (ya existente en tu código):**

```dart
final storageService = StorageService();
final imageUrl = await storageService.uploadChatImage(
  conversationId: 'conv_123',
  imageFile: myImageFile,
);
```

## 📊 Comparación: Firebase vs Supabase

| Característica | Firebase Storage | Supabase Storage |
|----------------|------------------|------------------|
| **Almacenamiento** | 5GB gratis | 1GB gratis |
| **Transferencia** | 1GB/día gratis | 2GB/mes gratis |
| **Costo extra** | $0.026/GB | Gratis hasta límites |
| **URLs públicas** | ✅ | ✅ |
| **CDN** | ✅ | ✅ |

## 🎯 Ventajas de Supabase

1. **Plan gratuito generoso** - 1GB de almacenamiento permanente
2. **Sin sorpresas en costos** - Límites claros en plan gratuito
3. **Fácil de escalar** - Planes predecibles a $25/mes para 100GB
4. **Mismo rendimiento** - CDN global incluido

## 🔄 Migrar Imágenes Existentes (Opcional)

Si ya tienes imágenes en Firebase Storage y quieres migrarlas:

1. Descarga todas las imágenes de Firebase Storage
2. Súbelas manualmente a Supabase usando el panel web
3. Actualiza las URLs en Firestore

> **Nota**: Para una app nueva o con pocas imágenes, es más simple empezar desde cero con Supabase.

## ❓ Troubleshooting

### Error: "RLS policy violation"
- **Solución**: Verifica que las políticas de seguridad estén configuradas correctamente

### Error: "Bucket not found"
- **Solución**: Asegúrate de que el bucket `chat-images` esté creado en Supabase

### Error: "Invalid JWT"
- **Solución**: Verifica que las credenciales en `main.dart` sean correctas

## 📞 Contacto

Si necesitas ayuda adicional, revisa la [documentación de Supabase Storage](https://supabase.com/docs/guides/storage).

---

**¡Listo!** Ahora tu app usará Supabase Storage sin costos. 🎉
