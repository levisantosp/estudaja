import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../subjects/data/subject.dart';
import '../../../subjects/data/subject_repository.dart';
import '../../../tasks/data/task.dart';
import '../../../tasks/data/task_repository.dart';
import '../../../tasks/presentation/pages/task_form_page.dart';

// tela principal exibida apos o login. mostra saudacao e painel resumido
// com contagens, tarefas atrasadas e proximos prazos
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TaskRepository _taskRepository;
  late final SubjectRepository _subjectRepository;
  String? _userName;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _taskRepository = TaskRepository(userId: user.uid);
    _subjectRepository = SubjectRepository(userId: user.uid);
    _loadUserName(user.uid);
  }

  // busca o nome do usuario salvo no firestore. atualiza o estado quando chega
  Future<void> _loadUserName(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) {
      return;
    }
    setState(() {
      _userName = doc.data()?['name'] as String?;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  // abre o formulario de edicao para a tarefa tocada nas listas de prazo
  Future<void> _openTask(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskFormPage(task: task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    // usa o nome do firestore, ou o email como fallback ate o nome carregar
    final displayName = _userName ?? user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('EstudaJá'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.tasks),
            icon: const Icon(Icons.checklist),
            tooltip: 'Tarefas',
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.subjects),
            icon: const Icon(Icons.school),
            tooltip: 'Disciplinas',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: StreamBuilder<List<Subject>>(
        stream: _subjectRepository.watchSubjects(),
        builder: (context, subjectsSnapshot) {
          if (subjectsSnapshot.hasError) {
            debugPrint(
              'Erro ao carregar disciplinas no painel: '
              '${subjectsSnapshot.error}',
            );
          }
          final subjects = subjectsSnapshot.data ?? const <Subject>[];
          final subjectsById = {for (final s in subjects) s.id: s};

          return StreamBuilder<List<Task>>(
            stream: _taskRepository.watchTasks(),
            builder: (context, tasksSnapshot) {
              if (tasksSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (tasksSnapshot.hasError) {
                return const Center(
                  child: Text('Erro ao carregar as tarefas.'),
                );
              }

              final tasks = tasksSnapshot.data ?? const <Task>[];

              final pendingCount =
                  tasks.where((t) => t.status == 'pending').length;
              final inProgressCount =
                  tasks.where((t) => t.status == 'inProgress').length;
              final completedCount =
                  tasks.where((t) => t.status == 'completed').length;

              // tarefas com prazo no passado e ainda nao concluidas
              final now = DateTime.now();
              final sevenDaysAhead = now.add(const Duration(days: 7));

              final overdue = tasks
                  .where((t) =>
                      t.dueDate != null &&
                      t.dueDate!.isBefore(now) &&
                      t.status != 'completed')
                  .toList()
                ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

              // tarefas com prazo nos proximos 7 dias e ainda nao concluidas
              final upcoming = tasks
                  .where((t) =>
                      t.dueDate != null &&
                      !t.dueDate!.isBefore(now) &&
                      t.dueDate!.isBefore(sevenDaysAhead) &&
                      t.status != 'completed')
                  .toList()
                ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Olá, $displayName!',
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Resumo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2,
                      children: [
                        _SummaryCard(
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          label: 'Pendentes',
                          value: '$pendingCount',
                        ),
                        _SummaryCard(
                          icon: Icons.timelapse,
                          color: Colors.blue,
                          label: 'Em andamento',
                          value: '$inProgressCount',
                        ),
                        _SummaryCard(
                          icon: Icons.check_circle,
                          color: Colors.green,
                          label: 'Concluídas',
                          value: '$completedCount',
                        ),
                        _SummaryCard(
                          icon: Icons.school,
                          color: Colors.purple,
                          label: 'Disciplinas',
                          value: '${subjects.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (overdue.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Atrasadas (${overdue.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final task in overdue)
                        _TaskSummaryTile(
                          task: task,
                          subject: task.subjectId != null
                              ? subjectsById[task.subjectId]
                              : null,
                          onTap: () => _openTask(task),
                        ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Próximos 7 dias',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (upcoming.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Nenhuma tarefa com prazo próximo.'),
                      )
                    else
                      for (final task in upcoming)
                        _TaskSummaryTile(
                          task: task,
                          subject: task.subjectId != null
                              ? subjectsById[task.subjectId]
                              : null,
                          onTap: () => _openTask(task),
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// card de resumo no topo do painel. mostra um numero grande com icone e label
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// linha compacta usada nas secoes de atrasadas e proximas. mostra titulo,
// prazo formatado e o nome da disciplina vinculada quando existir
class _TaskSummaryTile extends StatelessWidget {
  const _TaskSummaryTile({
    required this.task,
    required this.onTap,
    this.subject,
  });

  final Task task;
  final Subject? subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subjectColor =
        subject?.color != null ? Color(subject!.color!) : null;

    return Card(
      child: ListTile(
        leading: subjectColor != null
            ? CircleAvatar(backgroundColor: subjectColor, radius: 12)
            : const Icon(Icons.assignment_outlined),
        title: Text(task.title),
        subtitle: Text(
          task.dueDate != null
              ? 'Prazo: ${_formatDate(task.dueDate!)}'
              : 'Sem prazo',
        ),
        trailing: subject != null
            ? Text(subject!.name, style: const TextStyle(fontSize: 12))
            : null,
        onTap: onTap,
      ),
    );
  }
}

// formata uma data como dd/mm/yyyy HH:mm sem depender do pacote intl
String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}
