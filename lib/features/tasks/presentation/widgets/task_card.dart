import 'package:flutter/material.dart';

import '../../../subjects/data/subject.dart';
import '../../data/task.dart';

// widget que representa um item da lista de tarefas.
// mostra titulo, descricao, prioridade e prazo. permite marcar como concluida.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onTap,
    required this.onDelete,
    this.subject,
  });

  final Task task;
  // disciplina vinculada a tarefa, quando existir. resolvida na page pai
  // a partir do subjectId, ja que o card nao acessa o firestore diretamente
  final Subject? subject;
  // callback chamado quando o usuario marca ou desmarca o checkbox
  final ValueChanged<bool> onToggleDone;
  // callback para abrir a tela de edicao da tarefa
  final VoidCallback onTap;
  // callback para excluir a tarefa
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasDescription = task.description.trim().isNotEmpty;
    final hasDueDate = task.dueDate != null;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (value) => onToggleDone(value ?? false),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDescription) ...[
              const SizedBox(height: 4),
              Text(task.description),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PriorityChip(priority: task.priority),
                if (subject != null) _SubjectChip(subject: subject!),
                if (hasDueDate)
                  Text(
                    'Prazo: ${_formatDate(task.dueDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Excluir',
          onPressed: onDelete,
        ),
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

// pequeno chip colorido que indica a prioridade da tarefa
class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (priority) {
      case 'high':
        color = Colors.red;
        label = 'Alta';
      case 'low':
        color = Colors.green;
        label = 'Baixa';
      case 'medium':
      default:
        color = Colors.orange;
        label = 'Média';
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// chip que mostra o nome da disciplina com um circulo da cor escolhida.
// reaproveita o componente Chip padrao para manter o estilo simples
class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final color = subject.color != null ? Color(subject.color!) : Colors.grey;

    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(subject.name),
      visualDensity: VisualDensity.compact,
    );
  }
}
