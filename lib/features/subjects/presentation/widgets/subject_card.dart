import 'package:flutter/material.dart';

import '../../data/subject.dart';

// paleta fixa de cores que o usuario pode escolher ao criar uma disciplina.
// declarada aqui para servir tanto ao card quanto ao formulario sem duplicar
const List<Color> subjectColorPalette = <Color>[
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
];

// widget que representa uma disciplina dentro da lista
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // cor e salva no firestore como int. quando ausente usa cinza como neutro
    final color = subject.color != null ? Color(subject.color!) : Colors.grey;
    final hasTeacher = (subject.teacher ?? '').trim().isNotEmpty;
    final hasSchedule = (subject.schedule ?? '').trim().isNotEmpty;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            subject.name.isNotEmpty ? subject.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(subject.name),
        subtitle: hasTeacher || hasSchedule
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTeacher) Text('Professor: ${subject.teacher}'),
                  if (hasSchedule) Text('Horário: ${subject.schedule}'),
                ],
              )
            : null,
        isThreeLine: hasTeacher && hasSchedule,
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
