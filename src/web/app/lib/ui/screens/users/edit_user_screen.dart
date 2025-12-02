import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/user_service.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController genderCtrl;
  late TextEditingController bioCtrl;

  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController(text: widget.user.firstName);
    lastNameCtrl = TextEditingController(text: widget.user.lastName);
    emailCtrl = TextEditingController(text: widget.user.email);
    genderCtrl = TextEditingController(text: widget.user.gender);
    bioCtrl = TextEditingController(text: widget.user.bio);
    isAdmin = widget.user.isAdmin;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = UserModel(
      id: widget.user.id,
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      gender: genderCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      bio: bioCtrl.text.trim(),
      avatarUrl: widget.user.avatarUrl,
      isAdmin: isAdmin,
    );

    await _userService.updateUser(updated);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Usuário")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: "Nome"),
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              TextFormField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: "Sobrenome"),
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "E-mail"),
              ),
              TextFormField(
                controller: genderCtrl,
                decoration: const InputDecoration(labelText: "Gênero"),
              ),
              TextFormField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: "Biografia"),
                maxLines: 3,
              ),
              SwitchListTile(
                title: const Text("Administrador"),
                value: isAdmin,
                onChanged: (v) => setState(() => isAdmin = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUser,
                child: const Text("Salvar Alterações"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
