import 'package:flutter/material.dart';
import '../../../../core/services/user_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController genderCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();

  bool isAdmin = false;
  bool _isLoading = false;

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userService.createUser(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        gender: genderCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
        isAdmin: isAdmin,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar usuário: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Usuário")),
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
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: "Senha"),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Obrigatório";
                  if (v.length < 6) return "Mínimo 6 caracteres";
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: genderCtrl.text.isEmpty ? null : genderCtrl.text,
                decoration: const InputDecoration(labelText: "Gênero"),
                items: const [
                  DropdownMenuItem(value: "male", child: Text("Masculino")),
                  DropdownMenuItem(value: "female", child: Text("Feminino")),
                ],
                onChanged: (value) {
                  setState(() {
                    genderCtrl.text = value!;
                  });
                },
                validator: (value) =>
                    value == null ? "Selecione um gênero" : null,
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
                onPressed: _isLoading ? null : _saveUser,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
