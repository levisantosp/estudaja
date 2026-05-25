import 'package:cloud_firestore/cloud_firestore.dart';

import 'subject.dart';

// repositorio responsavel por toda comunicacao com o firestore para disciplinas.
// as telas nao acessam o banco diretamente, so chamam os metodos dessa classe.
class SubjectRepository {
  SubjectRepository({FirebaseFirestore? firestore, required this.userId})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // uid do usuario logado. usado para filtrar so as disciplinas dele
  final String userId;

  // disciplinas ficam em colecao raiz. o campo userId dentro de cada documento
  // e o que garante o isolamento por usuario (reforçado pelas security rules)
  CollectionReference<Map<String, dynamic>> get _subjectsCollection =>
      _firestore.collection('subjects');

  // stream em tempo real ordenado por nome
  Stream<List<Subject>> watchSubjects() {
    return _subjectsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Subject.fromDocument).toList());
  }

  // create: adiciona uma nova disciplina ao firestore
  Future<void> addSubject({
    required String name,
    String? teacher,
    String? schedule,
    int? color,
  }) {
    return _subjectsCollection.add({
      'name': name,
      'userId': userId,
      'teacher': ?teacher,
      'schedule': ?schedule,
      'color': ?color,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // update: altera os campos editaveis de uma disciplina existente.
  // teacher, schedule e color sao "clearable": passar null remove o campo no firestore
  Future<void> updateSubject({
    required String subjectId,
    required String name,
    required String? teacher,
    required String? schedule,
    required int? color,
  }) {
    return _subjectsCollection.doc(subjectId).update({
      'name': name,
      'teacher': teacher ?? FieldValue.delete(),
      'schedule': schedule ?? FieldValue.delete(),
      'color': color ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // delete: remove o documento da disciplina pelo id
  Future<void> deleteSubject(String subjectId) {
    return _subjectsCollection.doc(subjectId).delete();
  }
}
