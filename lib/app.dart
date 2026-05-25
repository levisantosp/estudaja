import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/tasks/presentation/pages/tasks_page.dart';

// widget raiz do app. configura tema, rotas e decide qual tela abrir primeiro
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EstudaJá',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),

      // ao abrir o app, verifica se o firebase auth ja conhece um user
      // se existir, vai direto para a home
      // se nao existir vai pra pagina de login
      initialRoute: FirebaseAuth.instance.currentUser == null
          ? AppRoutes.login
          : AppRoutes.home,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const RegisterPage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.tasks: (_) => const TasksPage(),
      },
    );
  }
}
