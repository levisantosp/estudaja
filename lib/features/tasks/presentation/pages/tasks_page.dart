import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../subjects/data/subject.dart';
import '../../../subjects/data/subject_repository.dart';
import '../../data/task.dart';
import '../../data/task_repository.dart';
import '../widgets/task_card.dart';
import 'task_form_page.dart';

// tela que lista as tarefas do usuario logado em tempo real
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TaskRepository _repository;
  late final SubjectRepository _subjectRepository;

  @override
  void initState() {
    super.initState();
    // resolve o uid uma unica vez para nao recriar o repositorio em cada rebuild
    final user = FirebaseAuth.instance.currentUser!;
    _repository = TaskRepository(userId: user.uid);
    _subjectRepository = SubjectRepository(userId: user.uid);
  }

  // abre o formulario de tarefa. quando task e null, abre em modo criacao
  Future<void> _openForm({Task? task}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskFormPage(task: task),
      ),
    );
  }

  // pede confirmacao antes de remover uma tarefa para evitar exclusao acidental
  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
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
      await _repository.deleteTask(task.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a tarefa.')),
      );
    }
  }

  Future<void> _toggleDone(Task task, bool isDone) async {
    try {
      await _repository.toggleTaskDone(taskId: task.id, isDone: isDone);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar a tarefa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas tarefas')),
      // o stream de disciplinas fica por fora porque o card precisa do nome
      // e da cor de cada uma. se falhar (ex: indice composto faltando),
      // o mapa fica vazio e os cards apenas nao exibem o chip de disciplina
      body: StreamBuilder<List<Subject>>(
        stream: _subjectRepository.watchSubjects(),
        builder: (context, subjectsSnapshot) {
          // se as disciplinas falharem, registra mas nao quebra a tela de tarefas.
          // os cards apenas deixam de mostrar o chip de disciplina
          if (subjectsSnapshot.hasError) {
            debugPrint(
              'Erro ao carregar disciplinas na tela de tarefas: '
              '${subjectsSnapshot.error}',
            );
          }
          final subjects = subjectsSnapshot.data ?? const <Subject>[];
          final subjectsById = {for (final s in subjects) s.id: s};

          return StreamBuilder<List<Task>>(
            stream: _repository.watchTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Erro ao carregar as tarefas.'),
                );
              }

              final tasks = snapshot.data ?? const <Task>[];

              if (tasks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma tarefa cadastrada.\nToque no botão + para criar a primeira.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final subject = task.subjectId != null
                      ? subjectsById[task.subjectId]
                      : null;
                  return TaskCard(
                    task: task,
                    subject: subject,
                    onToggleDone: (isDone) => _toggleDone(task, isDone),
                    onTap: () => _openForm(task: task),
                    onDelete: () => _confirmDelete(task),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nova tarefa',
        child: const Icon(Icons.add),
      ),
    );
  }
}
