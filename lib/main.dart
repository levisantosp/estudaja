import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

// ponto de entrada do app. precisa ser async porque inicializa o firebase antes de tudo
Future<void> main() async {
  // garante que o flutter está pronto para chamar código nativo antes de qualquer coisa
  WidgetsFlutterBinding.ensureInitialized();

  // inicializa o firebase usando as configurações geradas pelo flutterfire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}
