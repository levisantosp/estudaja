import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/subject.dart';
import '../../data/subject_repository.dart';
import '../widgets/subject_card.dart';
import 'subject_form_page.dart';

// tela que lista as disciplinas do usuario logado em tempo real
class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final SubjectRepository _repository;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _repository = SubjectRepository(userId: user.uid);
  }

  Future<void> _openForm({Subject? subject}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectFormPage(subject: subject),
      ),
    );
  }

  Future<void> _confirmDelete(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir disciplina'),
        content: Text(
          'Deseja realmente excluir "${subject.name}"?\n\n'
          'As tarefas vinculadas a essa disciplina continuarão existindo, '
          'mas sem associação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteSubject(subject.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir a disciplina.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas disciplinas')),
      body: StreamBuilder<List<Subject>>(
        stream: _repository.watchSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // imprime o erro completo no terminal para facilitar o diagnostico
            debugPrint('Erro ao carregar disciplinas: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ocorreu um erro ao carregar as disciplinas',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final subjects = snapshot.data ?? const <Subject>[];

          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma disciplina cadastrada.\nToque no botão + para criar a primeira.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SubjectCard(
                subject: subject,
                onTap: () => _openForm(subject: subject),
                onDelete: () => _confirmDelete(subject),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nova disciplina',
        child: const Icon(Icons.add),
      ),
    );
  }
}
