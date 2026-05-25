import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';

// tela principal exibida apos o login
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // busca o nome do usuario salvo no firestore
  Future<String?> _loadUserName(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] as String?;
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EstudaJá'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _loadUserName(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // usa o nome do firestore, ou o email como fallback
          final name = snapshot.data ?? user.email ?? '';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Olá, $name!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.tasks),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Minhas tarefas'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.subjects),
                    icon: const Icon(Icons.school),
                    label: const Text('Minhas disciplinas'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
