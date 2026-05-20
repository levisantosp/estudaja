import 'package:cloud_firestore/cloud_firestore.dart';

import 'task.dart';

// repositório responsável por toda comunicação com o firestore para tarefas.
// as telas não acessam o banco diretamente, só chamam os métodos dessa classe.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore, required this.userId})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // uid do usuário logado. usado para acessar só as tarefas dele
  final String userId;

  // atalho para a subcoleção de tarefas do usuário: users/{uid}/tasks
  // cada usuário tem sua própria subcoleção separada no firestore
  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // retorna um stream que escuta o firestore em tempo real.
  // sempre que uma tarefa mudar no banco, o flutter reconstrói a tela automaticamente
  Stream<List<Task>> watchTasks() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Task.fromDocument).toList());
  }

  // create: cria um novo documento de tarefa na subcoleção do usuário
  Future<void> addTask({
    required String title,
    required String description,
    String priority = 'medium',
    String? subjectId,
    DateTime? dueDate,
  }) {
    return _tasksCollection.add({
      'title': title,
      'description': description,
      'isDone': false,
      'status': 'pending',
      'priority': priority,
      'userId': userId,
      'subjectId': ?subjectId,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // update: altera os campos editaveis de uma tarefa existente
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    String? priority,
    String? status,
    String? subjectId,
    DateTime? dueDate,
  }) {
    return _tasksCollection.doc(taskId).update({
      'title': title,
      'description': description,
      'priority': ?priority,
      'status': ?status,
      'subjectId': ?subjectId,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // update: muda apenas o campo isDone, chamado quando o usuário marca o checkbox
  Future<void> toggleTaskDone({required String taskId, required bool isDone}) {
    return _tasksCollection.doc(taskId).update({
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // delete: remove o documento da tarefa pelo id
  Future<void> deleteTask(String taskId) {
    return _tasksCollection.doc(taskId).delete();
  }
}
