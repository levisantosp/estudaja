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

  // filtros ativos. null significa "todas/todos", ou seja, sem filtro daquele campo
  String? _filterSubjectId;
  String? _filterPriority;
  String? _filterStatus;

  bool get _hasActiveFilters =>
      _filterSubjectId != null ||
      _filterPriority != null ||
      _filterStatus != null;

  @override
  void initState() {
    super.initState();
    // resolve o uid uma unica vez para nao recriar o repositorio em cada rebuild
    final user = FirebaseAuth.instance.currentUser!;
    _repository = TaskRepository(userId: user.uid);
    _subjectRepository = SubjectRepository(userId: user.uid);
  }

  void _clearFilters() {
    setState(() {
      _filterSubjectId = null;
      _filterPriority = null;
      _filterStatus = null;
    });
  }

  // aplica os filtros ativos sobre a lista vinda do firestore.
  // mantemos a filtragem em memoria para evitar criar indices compostos extras
  List<Task> _applyFilters(List<Task> tasks) {
    if (!_hasActiveFilters) {
      return tasks;
    }
    return tasks.where((task) {
      if (_filterSubjectId != null && task.subjectId != _filterSubjectId) {
        return false;
      }
      if (_filterPriority != null && task.priority != _filterPriority) {
        return false;
      }
      if (_filterStatus != null && task.status != _filterStatus) {
        return false;
      }
      return true;
    }).toList();
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

  // monta a linha de filtros no topo da tela. recebe a lista de disciplinas
  // ja carregada pelo StreamBuilder externo para popular o dropdown de disciplina
  Widget _buildFilters(List<Subject> subjects) {
    // tarefa pode estar filtrada por uma disciplina que foi excluida depois.
    // mantemos a opcao no dropdown para nao quebrar e para o usuario poder limpar
    final filterOrphan = _filterSubjectId != null &&
        !subjects.any((s) => s.id == _filterSubjectId);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Disciplina',
                  value: _filterSubjectId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final s in subjects)
                      DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    if (filterOrphan)
                      DropdownMenuItem<String?>(
                        value: _filterSubjectId,
                        child: const Text('Disciplina removida'),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _filterSubjectId = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: 'Prioridade',
                  value: _filterPriority,
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'high',
                      child: Text('Alta'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'medium',
                      child: Text('Média'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'low',
                      child: Text('Baixa'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _filterPriority = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: 'Status',
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'pending',
                      child: Text('Pendente'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'inProgress',
                      child: Text('Em andamento'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'completed',
                      child: Text('Concluída'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _filterStatus = value),
                ),
              ),
            ],
          ),
          if (_hasActiveFilters)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpar filtros'),
              ),
            ),
        ],
      ),
    );
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

          return Column(
            children: [
              _buildFilters(subjects),
              Expanded(
                child: StreamBuilder<List<Task>>(
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

                    final filtered = _applyFilters(tasks);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma tarefa encontrada com os filtros aplicados.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
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
                ),
              ),
            ],
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

// dropdown compacto com label usado na barra de filtros. encapsula o padrao
// "InputDecorator + DropdownButton" para nao repetir o boilerplate tres vezes
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
