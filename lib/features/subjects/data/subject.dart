import 'package:cloud_firestore/cloud_firestore.dart';

// modelo que representa uma disciplina do usuario.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.userId,
    this.teacher,
    this.schedule,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String userId;
  final String? teacher;
  final String? schedule;
  // cor salva como int (Color.value) para serializar no firestore
  final int? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // converte um documento do firestore em um objeto Subject.
  factory Subject.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};

    return Subject(
      id: document.id,
      name: data['name'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      teacher: data['teacher'] as String?,
      schedule: data['schedule'] as String?,
      color: data['color'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // converte o objeto para um mapa pronto para salvar no firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'teacher': ?teacher,
      'schedule': ?schedule,
      'color': ?color,
    };
  }

  Subject copyWith({
    String? name,
    String? teacher,
    String? schedule,
    int? color,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      userId: userId,
      teacher: teacher ?? this.teacher,
      schedule: schedule ?? this.schedule,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
