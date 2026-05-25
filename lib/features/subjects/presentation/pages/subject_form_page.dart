import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/subject.dart';
import '../../data/subject_repository.dart';
import '../widgets/subject_card.dart';

// tela usada tanto para criar uma nova disciplina quanto para editar uma existente
class SubjectFormPage extends StatefulWidget {
  const SubjectFormPage({super.key, this.subject});

  final Subject? subject;

  @override
  State<SubjectFormPage> createState() => _SubjectFormPageState();
}

class _SubjectFormPageState extends State<SubjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _scheduleController = TextEditingController();

  // valor int da cor escolhida. null = sem cor definida
  int? _color;
  bool _isLoading = false;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;
    if (subject != null) {
      _nameController.text = subject.name;
      _teacherController.text = subject.teacher ?? '';
      _scheduleController.text = subject.schedule ?? '';
      _color = subject.color;
    } else {
      // ao criar uma disciplina nova, ja seleciona a primeira cor da paleta
      // para evitar a sensacao de "nada esta escolhido" na interface
      _color = subjectColorPalette.first.toARGB32();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _scheduleController.dispose();
    super.dispose();
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

    final repository = SubjectRepository(userId: user.uid);
    final name = _nameController.text.trim();
    final teacher = _teacherController.text.trim();
    final schedule = _scheduleController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateSubject(
          subjectId: widget.subject!.id,
          name: name,
          teacher: teacher.isEmpty ? null : teacher,
          schedule: schedule.isEmpty ? null : schedule,
          color: _color,
        );
      } else {
        await repository.addSubject(
          name: name,
          teacher: teacher.isEmpty ? null : teacher,
          schedule: schedule.isEmpty ? null : schedule,
          color: _color,
        );
      }
    } catch (error, stackTrace) {
      // imprime o erro completo no terminal para facilitar o diagnostico
      debugPrint('Erro ao salvar disciplina: $error');
      debugPrint(stackTrace.toString());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar a disciplina: $error'),
        ),
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
        title: Text(_isEditing ? 'Editar disciplina' : 'Nova disciplina'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: Cálculo I',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe um nome para a disciplina.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Professor (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Horário (opcional)',
                  hintText: 'Ex: Seg/Qua 19h-21h',
                ),
              ),
              const SizedBox(height: 24),
              Text('Cor', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in subjectColorPalette)
                    _ColorOption(
                      color: color,
                      isSelected: _color == color.toARGB32(),
                      onTap: _isLoading
                          ? null
                          : () => setState(
                                () => _color = color.toARGB32(),
                              ),
                    ),
                ],
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

// circulo colorido que serve de opcao para o usuario escolher a cor da disciplina
class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
