import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/task.dart';
import '../../data/task_repository.dart';

// tela usada tanto para criar uma nova tarefa quanto para editar uma existente.
// recebe um Task opcional: quando null, abre em modo de criacao
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'medium';
  String _status = 'pending';
  DateTime? _dueDate;
  bool _isLoading = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    // quando esta editando, preenche os campos com os valores existentes
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _priority = task.priority;
      _status = task.status;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // abre o seletor de data e depois o de horario para compor o prazo completo.
  // se o usuario cancelar qualquer um dos dois, o prazo anterior e mantido
  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute)
          : TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final repository = TaskRepository(userId: user.uid);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateTask(
          taskId: widget.task!.id,
          title: title,
          description: description,
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
        );
      } else {
        await repository.addTask(
          title: title,
          description: description,
          priority: _priority,
          dueDate: _dueDate,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a tarefa.')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar tarefa' : 'Nova tarefa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex: Trabalho de Programação',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe um título para a tarefa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Detalhes da tarefa (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Baixa')),
                  DropdownMenuItem(value: 'medium', child: Text('Média')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
              ),
              // o status so aparece em modo de edicao. ao criar uma tarefa,
              // ela comeca sempre como 'pending' (regra definida no repository)
              if (_isEditing) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pendente'),
                    ),
                    DropdownMenuItem(
                      value: 'inProgress',
                      child: Text('Em andamento'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Concluída'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _dueDate == null
                      ? 'Sem prazo definido'
                      : 'Prazo: ${_formatDate(_dueDate!)}',
                ),
                trailing: TextButton(
                  onPressed: _isLoading ? null : _pickDueDate,
                  child: Text(_dueDate == null ? 'Definir' : 'Alterar'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
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
