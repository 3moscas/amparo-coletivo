import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  String? nomeCompleto;
  String? firstName;
  String? lastName;
  String? genero;
  String? bio;
  String? avatarUrl;
  String? avatarPath;
  String? email;

  bool carregando = true;
  bool uploadingAvatar = false;
  bool carregandoFavoritos = false;

  List<Map<String, dynamic>> favoritos = [];

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    await _carregarDadosUsuario();
    await _carregarFavoritos();
  }

  Future<void> _carregarDadosUsuario() async {
    setState(() => carregando = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => carregando = false);
      return;
    }

    try {
      final response = await supabase
          .from('usuarios')
          .select(
              'first_name, last_name, gender, bio, avatar_url, avatar_path, email')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      final first = (response['first_name'] ?? '').toString();
      final last = (response['last_name'] ?? '').toString();
      final fullName = "$first $last".trim();

      setState(() {
        firstName = first;
        lastName = last;
        nomeCompleto = fullName.isNotEmpty ? fullName : 'Usuário sem nome';
        genero = response['gender'];
        bio = response['bio'];
        avatarUrl = response['avatar_url'];
        avatarPath = response['avatar_path'];
        email = response['email'] ?? user.email;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuário: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<Uint8List?> _pickImageBytes() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (!mounted) return null;
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.single;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return file.bytes;
      }
      return null;
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
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para alterar a foto.')),
      );
      return;
    }

    final folder = "USUARIO_${user.id}";
    final filename = "avatar_${DateTime.now().millisecondsSinceEpoch}.png";
    final newPath = "$folder/$filename";
    setState(() => uploadingAvatar = true);

    try {
      final storage = supabase.storage.from('avatars');
      await storage.uploadBinary(newPath, bytes,
          fileOptions: const FileOptions(upsert: true));
      if (!mounted) return;

      final newUrl = storage.getPublicUrl(newPath);

      if (avatarPath != null && avatarPath!.isNotEmpty) {
        try {
          await storage.remove([avatarPath!]);
          if (!mounted) return;
        } catch (_) {}
      }

      await supabase.from('usuarios').update(
          {'avatar_url': newUrl, 'avatar_path': newPath}).eq('id', user.id);
      if (!mounted) return;

      await _carregarDadosUsuario();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar atualizado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagem: $e')),
      );
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> _editarBio() async {
    final controller = TextEditingController(text: bio ?? '');
    int charCount = controller.text.length;
    const int maxChars = 150;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(builder: (context, setState) {
              final colorScheme = Theme.of(context).colorScheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Editar descrição',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLength: maxChars,
                    maxLines: 4,
                    onChanged: (v) => setState(() => charCount = v.length),
                    decoration: InputDecoration(
                      hintText: 'Fale um pouco sobre você...',
                      counterText: '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('$charCount/$maxChars',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('Salvar'),
                    )
                  ])
                ],
              );
            }),
          ),
        );
      },
    );

    if (result == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('usuarios').update({'bio': result}).eq('id', user.id);
      if (!mounted) return;

      setState(() => bio = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descrição atualizada!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar bio')),
      );
    }
  }

  Future<void> _editarPerfil() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final firstController = TextEditingController(text: firstName ?? '');
    final lastController = TextEditingController(text: lastName ?? '');
    String? localGenero = genero;

    final result = await showDialog<_ProfileEditResult>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Editar perfil',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: firstController,
                    decoration: InputDecoration(
                      labelText: 'Primeiro nome',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastController,
                    decoration: InputDecoration(
                      labelText: 'Sobrenome',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: localGenero,
                    decoration: InputDecoration(
                      labelText: 'Gênero',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Masculino')),
                      DropdownMenuItem(
                          value: 'female', child: Text('Feminino')),
                      DropdownMenuItem(
                          value: 'nonbinary', child: Text('Não binário')),
                      DropdownMenuItem(value: 'other', child: Text('Outro')),
                      DropdownMenuItem(
                          value: null, child: Text('Prefiro não informar')),
                    ],
                    onChanged: (value) => setState(() => localGenero = value),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _ProfileEditResult(
                              firstName: firstController.text.trim(),
                              lastName: lastController.text.trim(),
                              gender: localGenero,
                            ),
                          );
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await supabase.from('usuarios').update({
        'first_name': result.firstName,
        'last_name': result.lastName,
        'gender': result.gender,
      }).eq('id', user.id);

      if (!mounted) return;

      final fullName = '${result.firstName} ${result.lastName}'.trim();
      setState(() {
        firstName = result.firstName;
        lastName = result.lastName;
        genero = result.gender;
        nomeCompleto = fullName.isNotEmpty ? fullName : 'Usuário sem nome';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    }
  }

  Future<void> _carregarFavoritos() async {
    setState(() => carregandoFavoritos = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => carregandoFavoritos = false);
      return;
    }

    try {
      final res = await supabase
          .from('favorites')
          .select('ongs (id, title, image_url)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;

      setState(() => carregandoFavoritos = false);

      if (res.isEmpty) {
        setState(() => favoritos = []);
        return;
      }

      final list = <Map<String, dynamic>>[];
      for (final r in res) {
        if (r.containsKey('ongs') && r['ongs'] != null) {
          list.add(Map<String, dynamic>.from(r['ongs']));
        }
      }

      setState(() => favoritos = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar favoritos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => carregandoFavoritos = false);
    }
  }

  Future<void> _removerFavorito(String ongId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('ong_id', ongId);
      await _carregarFavoritos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removido dos favoritos')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      context.go(AppRoutes.signin);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return user == null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline,
                    size: 80, color: colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Faça login para acessar seu perfil.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final loggedIn = await context.push<bool>(AppRoutes.signin);
                    if (loggedIn == true) {
                      await _carregarTudo();
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Ir para Login'),
                )
              ],
            ),
          )
        : carregando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _carregarTudo,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar + botões
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            backgroundImage:
                                avatarUrl != null && avatarUrl!.isNotEmpty
                                    ? NetworkImage(avatarUrl!)
                                    : null,
                            child: (avatarUrl == null || avatarUrl!.isEmpty)
                                ? Icon(Icons.person,
                                    size: 60,
                                    color: colorScheme.onSurfaceVariant)
                                : null,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow
                                          .withValues(alpha: 0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              FloatingActionButton.small(
                                heroTag: 'changeAvatar',
                                onPressed:
                                    uploadingAvatar ? null : _uploadAvatar,
                                child: uploadingAvatar
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.camera_alt),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text(
                        nomeCompleto ?? 'Usuário',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(email ?? '',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                      if (genero != null && genero!.isNotEmpty)
                        Text('Gênero: $genero',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _editarPerfil,
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text('Editar perfil'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sair'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bio
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sobre você',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(bio != null && bio!.isNotEmpty
                                  ? bio!
                                  : 'Nenhuma descrição adicionada.'),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonalIcon(
                                  onPressed: _editarBio,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Favoritos
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('ONGs favoritas',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 12),

                      if (carregandoFavoritos)
                        const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()))
                      else if (favoritos.isEmpty)
                        const Column(
                          children: [
                            SizedBox(height: 16),
                            Text('Você ainda não favoritou nenhuma ONG.'),
                          ],
                        )
                      else
                        _FavoritesGrid(
                          favoritos: favoritos,
                          onOpen: (ong) =>
                              context.push(AppRoutes.about, extra: ong),
                          onRemove: (id) => _removerFavorito(id),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
  }
}

class _ProfileEditResult {
  final String firstName;
  final String lastName;
  final String? gender;

  const _ProfileEditResult({
    required this.firstName,
    required this.lastName,
    required this.gender,
  });
}

class _FavoritesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> favoritos;
  final void Function(Map<String, dynamic> ong) onOpen;
  final void Function(dynamic id) onRemove;

  const _FavoritesGrid({
    required this.favoritos,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 6
            : width >= 800
                ? 5
                : width >= 600
                    ? 4
                    : width >= 400
                        ? 3
                        : 2;
        const aspectRatio = 3 / 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: favoritos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final ong = favoritos[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onOpen(ong),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: (ong['image_url'] != null &&
                              ong['image_url'].toString().isNotEmpty)
                          ? Image.network(ong['image_url'], fit: BoxFit.cover)
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ong['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18, color: colorScheme.error),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () => onRemove(ong['id']),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
