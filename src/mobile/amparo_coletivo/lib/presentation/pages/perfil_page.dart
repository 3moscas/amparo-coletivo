import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final supabase = Supabase.instance.client;

  String? nomeCompleto;
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

  // ============================================================
  // CARREGAR DADOS DO USUÁRIO
  // ============================================================
  Future<void> _carregarDadosUsuario() async {
    setState(() => carregando = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
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
        nomeCompleto = fullName.isNotEmpty ? fullName : "Usuário sem nome";
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

  // ============================================================
  // SELECIONAR IMAGEM (WEB + MOBILE) - usa FilePicker com bytes
  // ============================================================
  Future<Uint8List?> _pickImageBytes() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // importante para web/mobile (bytes)
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      // prefer bytes (works on web and mobile when withData:true)
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return file.bytes;
      }
      // fallback: if bytes null but path exists and not web, try read (but we avoid dart:io import)
      // As we've requested withData:true, normally bytes should be present.
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

  // ============================================================
  // UPLOAD DO AVATAR (usa uploadBinary - compatível web/mobile)
  // ============================================================
  Future<void> _uploadAvatar() async {
    final bytes = await _pickImageBytes();
    if (bytes == null) {
      // usuário cancelou ou bytes não disponível
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
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
      final storage =
          supabase.storage.from('avatars'); // nome do bucket: 'avatars'
      await storage.uploadBinary(newPath, bytes,
          fileOptions: const FileOptions(upsert: true));

      final newUrl = storage.getPublicUrl(newPath);

      // remove antigo (se existir)
      if (avatarPath != null && avatarPath!.isNotEmpty) {
        try {
          await storage.remove([avatarPath!]);
        } catch (_) {
          // ignora falha de remoção
        }
      }

      // Atualiza DB
      await supabase.from('usuarios').update({
        'avatar_url': newUrl,
        'avatar_path': newPath,
      }).eq('id', user.id);

      // Recarrega dados
      await _carregarDadosUsuario();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar atualizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagem: $e')),
      );
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  // ============================================================
  // REMOVER AVATAR (opcional)
  // ============================================================
  Future<void> _removerAvatar() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (avatarPath == null || avatarPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma foto para remover.')),
      );
      return;
    }

    final storage = supabase.storage.from('avatars');

    try {
      await storage.remove([avatarPath!]);
    } catch (_) {}

    await supabase.from('usuarios').update({
      'avatar_url': null,
      'avatar_path': null,
    }).eq('id', user.id);

    await _carregarDadosUsuario();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar removido.')),
    );
  }

  // ============================================================
  // EDITAR BIO (Material 3 - sem contador duplicado)
  // ============================================================
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
                      counterText:
                          '', // remoção do contador automático visual duplicado
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[100],
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
      setState(() => bio = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descrição atualizada!')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar bio: $e')));
    }
  }

  // ============================================================
  // FAVORITOS - carregar e remover
  // ============================================================
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

      if (res == null) {
        setState(() => carregandoFavoritos = false);
        return;
      }

      // res is a List<dynamic> of records with nested 'ongs'
      List<Map<String, dynamic>> list = [];
      for (var r in res) {
        if (r is Map && r.containsKey('ongs') && r['ongs'] != null) {
          final ong = Map<String, dynamic>.from(r['ongs']);
          list.add(ong);
        }
      }

      setState(() {
        favoritos = list;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar favoritos: $e')));
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removido dos favoritos')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('Faça login para acessar seu perfil.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
      ),
      drawer: CustomDrawer(onLogout: _handleLogout),
      body: carregando
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
                    // Avatar + camera button
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              avatarUrl != null && avatarUrl!.isNotEmpty
                                  ? NetworkImage(avatarUrl!)
                                  : null,
                          child: (avatarUrl == null || avatarUrl!.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // remove button (small)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 4)
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                onPressed:
                                    avatarUrl == null || avatarUrl!.isEmpty
                                        ? null
                                        : _removerAvatar,
                                tooltip: 'Remover foto',
                              ),
                            ),
                            FloatingActionButton.small(
                              heroTag: 'changeAvatar',
                              onPressed: uploadingAvatar ? null : _uploadAvatar,
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

                    // Nome
                    Text(
                      nomeCompleto ?? 'Usuário',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    // Email
                    Text(
                      email ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Gênero
                    if (genero != null && genero!.isNotEmpty)
                      Text(
                        'Gênero: $genero',
                        style: const TextStyle(color: Colors.grey),
                      ),

                    const SizedBox(height: 20),

                    // Bio card
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
                                    fontWeight: FontWeight.bold, fontSize: 16)),
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

                    // Favoritos (ONGs)
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
                      Column(
                        children: const [
                          SizedBox(height: 16),
                          Text('Você ainda não favoritou nenhuma ONG.'),
                        ],
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: favoritos.length,
                          itemBuilder: (context, index) {
                            final ong = favoritos[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/about_ong',
                                    arguments: ong);
                              },
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 4)
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: (ong['image_url'] != null &&
                                              ong['image_url']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? Image.network(ong['image_url'],
                                              height: 90,
                                              width: 140,
                                              fit: BoxFit.cover)
                                          : Container(
                                              height: 90,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                  Icons.image_not_supported)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(ong['title'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.open_in_new,
                                                    size: 18),
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                      context, '/about_ong',
                                                      arguments: ong);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _removerFavorito(ong['id']),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
