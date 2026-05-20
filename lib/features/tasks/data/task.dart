import 'package:cloud_firestore/cloud_firestore.dart';

// modelo que representa uma tarefa do usuario.
// a ideia e ter um objeto dart limpo que a tela possa usar sem saber nada do firestore.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.status,
    required this.priority,
    required this.userId,
    this.subjectId,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final bool isDone;
  // status: 'pending' | 'inProgress' | 'completed'
  final String status;
  // priority: 'low' | 'medium' | 'high'
  final String priority;
  final String userId;
  // referencia opcional para a disciplina associada
  final String? subjectId;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // converte um documento do firestore em um objeto Task.
  factory Task.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};

    return Task(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isDone: data['isDone'] as bool? ?? false,
      status: data['status'] as String? ?? 'pending',
      priority: data['priority'] as String? ?? 'medium',
      userId: data['userId'] as String? ?? '',
      subjectId: data['subjectId'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // converte o objeto para um mapa pronto para salvar no firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isDone': isDone,
      'status': status,
      'priority': priority,
      'userId': userId,
      'subjectId': ?subjectId,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
    };
  }

  Task copyWith({
    String? title,
    String? description,
    bool? isDone,
    String? status,
    String? priority,
    String? subjectId,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      userId: userId,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
