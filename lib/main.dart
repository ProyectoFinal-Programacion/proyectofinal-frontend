import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  final apiClient = ApiClient(storage: storage);
  final auth = AuthProvider(api: apiClient, storage: storage);
  await auth.tryRestoreSession();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => auth),
      Provider.value(value: apiClient),
      Provider.value(value: storage),
    ],
    child: const ManoVecinaApp(),
  ));
}
