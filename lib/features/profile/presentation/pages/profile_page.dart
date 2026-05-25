import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';

// tela de perfil do usuario. permite editar o nome salvo no firestore e
// concentra a acao de logout, que antes ficava no AppBar do HomePage
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoadingInitial = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // carrega o nome atual do firestore para preencher o campo do form
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) {
        return;
      }
      setState(() {
        _nameController.text = doc.data()?['name'] as String? ?? '';
        _isLoadingInitial = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar perfil: $error');
      debugPrint(stackTrace.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // set com merge cria o documento caso ainda nao exista (registros antigos
      // podem nao ter o doc em users/) e atualiza o campo nome em qualquer caso
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'name': _nameController.text.trim()},
        SetOptions(merge: true),
      );
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar perfil: $error');
      debugPrint(stackTrace.toString());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o perfil.')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado.')),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    // limpa toda a pilha de navegacao para evitar voltar para telas autenticadas
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  // exclui a conta do usuario removendo todos os dados antes de apagar o
  // registro do firebase auth. usa batch para garantir atomicidade no firestore
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta?\n\n'
          'Todas as suas tarefas e disciplinas serão removidas. '
          'Esta ação é irreversível.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // tarefas estao em subcolecao users/{uid}/tasks
      final tasksSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();
      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // disciplinas ficam em colecao raiz, filtradas pelo campo userId
      final subjectsSnapshot = await firestore
          .collection('subjects')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in subjectsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(firestore.collection('users').doc(user.uid));

      await batch.commit();

      // por fim, apaga o registro de autenticacao. essa chamada faz o logout
      await user.delete();
    } catch (error, stackTrace) {
      debugPrint('Erro ao excluir conta: $error');
      debugPrint(stackTrace.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });

      // firebase exige sessao recente para exclusao por motivo de seguranca.
      // nesse caso o usuario precisa relogar antes de tentar de novo
      final isRecentLoginRequired = error is FirebaseAuthException &&
          error.code == 'requires-recent-login';
      final message = isRecentLoginRequired
          ? 'Por segurança, faça logout e login novamente antes de excluir a conta.'
          : 'Não foi possível excluir a conta.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Como você quer ser chamado',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Informe um nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Salvar'),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _deleteAccount,
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Excluir conta',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
