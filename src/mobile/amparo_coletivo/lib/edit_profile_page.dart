import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _bioController = TextEditingController();

  String? genero; // 'male' ou 'female'
  String? avatarUrl;
  String? avatarPath;
  bool uploading = false;
  bool carregando = true;

  final Map<String, String> generoMap = {
    'male': 'Masculino',
    'female': 'Feminino',
  };

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => carregando = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('usuarios')
          .select('first_name,last_name,gender,bio,avatar_url,avatar_path')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      _firstController.text = res['first_name'] ?? '';
      _lastController.text = res['last_name'] ?? '';
      genero = res['gender']; // deve ser 'male' ou 'female'
      _bioController.text = res['bio'] ?? '';
      avatarUrl = res['avatar_url'];
      avatarPath = res['avatar_path'];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<Uint8List?> _pickImageBytes() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);
      if (!mounted) return null;
      if (result == null || result.files.isEmpty) return null;
      return result.files.single.bytes;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _uploadAvatar() async {
    final bytes = await _pickImageBytes();
    if (bytes == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => uploading = true);

    final folder = "USUARIO_${user.id}";
    final filename = "avatar_${DateTime.now().millisecondsSinceEpoch}.png";
    final newPath = "$folder/$filename";

    try {
      final storage = supabase.storage.from('avatars');

      await storage.uploadBinary(
        newPath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final newUrl = storage.getPublicUrl(newPath);

      if (avatarPath != null && avatarPath!.isNotEmpty) {
        try {
          await storage.remove([avatarPath!]);
        } catch (_) {}
      }

      await supabase.from('usuarios').update(
          {'avatar_url': newUrl, 'avatar_path': newPath}).eq('id', user.id);

      if (!mounted) return;
      setState(() {
        avatarUrl = newUrl;
        avatarPath = newPath;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar atualizado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar avatar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  Future<void> _removerAvatar() async {
    final user = supabase.auth.currentUser;
    if (user == null || avatarPath == null || avatarPath!.isEmpty) return;

    try {
      final storage = supabase.storage.from('avatars');
      await storage.remove([avatarPath!]);

      await supabase
          .from('usuarios')
          .update({'avatar_url': null, 'avatar_path': null}).eq('id', user.id);

      if (!mounted) return;
      setState(() {
        avatarUrl = null;
        avatarPath = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar removido!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover avatar: $e')),
      );
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('usuarios').update({
        'first_name': _firstController.text.trim(),
        'last_name': _lastController.text.trim(),
        'gender': genero,
        'bio': _bioController.text.trim(),
      }).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl!)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'editAvatar',
                              onPressed: uploading ? null : _uploadAvatar,
                              child: uploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.camera_alt),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 4)
                                ],
                              ),
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed:
                                    avatarUrl != null ? _removerAvatar : null,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _firstController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Preencha o nome' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastController,
                      decoration: const InputDecoration(labelText: 'Sobrenome'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Preencha o sobrenome'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: genero,
                      items: generoMap.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => genero = v),
                      decoration: const InputDecoration(labelText: 'Gênero'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Selecione o gênero' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: _salvarPerfil,
                        child: const Text('Salvar alterações')),
                  ],
                ),
              ),
            ),
    );
  }
}
