import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';
import 'package:amparo_coletivo/edit_profile_page.dart';
import 'package:amparo_coletivo/presentation/info_ongs/ongs_page.dart';

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
  String? email;

  bool carregando = true;
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
      setState(() => carregando = false);
      return;
    }

    try {
      final res = await supabase
          .from('usuarios')
          .select('first_name,last_name,gender,bio,avatar_url,email')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      final first = res['first_name'] ?? '';
      final last = res['last_name'] ?? '';
      final fullName = "$first $last".trim();

      setState(() {
        nomeCompleto = fullName.isNotEmpty ? fullName : "Usuário sem nome";
        genero = res['gender'];
        bio = res['bio'];
        avatarUrl = res['avatar_url'];
        email = res['email'] ?? user.email;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar usuário: $e')));
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> _carregarFavoritos() async {
    if (!mounted) return;
    setState(() => carregandoFavoritos = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => carregandoFavoritos = false);
      }
      return;
    }

    try {
      final res = await supabase
          .from('favorites')
          .select('ongs (*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> list = [];
      for (var r in res) {
        if (r['ongs'] != null) {
          list.add(Map<String, dynamic>.from(r['ongs']));
        }
      }

      if (!mounted) return;
      setState(() => favoritos = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar favoritos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => carregandoFavoritos = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer()),
        ),
      ),
      drawer: CustomDrawer(onLogout: user != null ? _handleLogout : null),
      body: user == null
          ? _buildNotLogged()
          : carregando
              ? const Center(child: CircularProgressIndicator())
              : _buildPerfil(),
    );
  }

  Widget _buildNotLogged() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Faça login para acessar seu perfil.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login),
            label: const Text('Ir para Login'),
          )
        ],
      ),
    );
  }

  Widget _buildPerfil() {
    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(nomeCompleto ?? 'Usuário',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ---------- EMAIL ----------
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Email:",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey)),
                  Text(email ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- GÊNERO ----------
            if (genero != null && genero!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gênero:",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey)),
                    Text(
                      genero == 'male'
                          ? 'Masculino'
                          : genero == 'female'
                              ? 'Feminino'
                              : genero!,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ---------- BIO ----------
            if (bio != null && bio!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bio:",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(bio!, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ).then((_) => _carregarDadosUsuario());
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
            ),

            const SizedBox(height: 24),

            _buildFavoritosTitle(),
            const SizedBox(height: 12),

            _buildFavoritosList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritosTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text('ONGs favoritas',
          style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildFavoritosList() {
    if (carregandoFavoritos) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (favoritos.isEmpty) {
      return const Text(
        'Você ainda não favoritou nenhuma ONG.',
        textAlign: TextAlign.center,
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: favoritos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ong = favoritos[index];

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OngsPage(ongData: ong),
                ),
              );
            },
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 11,
                      child: Image.network(
                        ong['image_url'] ?? '',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Text(
                      ong['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
