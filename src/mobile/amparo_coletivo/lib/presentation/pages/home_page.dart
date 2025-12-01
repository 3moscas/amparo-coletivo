import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';
import 'package:amparo_coletivo/presentation/info_ongs/ongs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _ongs = [];
  List<dynamic> _ongsDestaque = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarOngs();
  }

  Future<void> _carregarOngs() async {
    try {
      final data = await supabase
          .from('ongs')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _ongs = data;
        _ongsDestaque = data.where((o) => o['highlighted'] == true).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );

      setState(() => _loading = false);
    }
  }

  void _handleLogout() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout efetuado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amparo Coletivo'),
        backgroundColor: const Color(0xFF2E8B57),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: CustomDrawer(onLogout: _handleLogout),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarOngs,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === DESTAQUES =================================
                    const Text(
                      'ONGs em destaque',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    _ongsDestaque.isEmpty
                        ? const Text('Nenhuma ONG em destaque no momento.')
                        : SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _ongsDestaque.length,
                              itemBuilder: (context, i) {
                                final ong = _ongsDestaque[i];

                                return ZoomCard(
                                  width: 180,
                                  child: _buildDestaqueCard(ong),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OngsPage(ongData: ong),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                    const SizedBox(height: 20),

                    // === TODAS AS ONGS =================================
                    const Text(
                      'Todas as ONGs',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    _ongs.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Nenhuma ONG cadastrada ainda.'),
                            ),
                          )
                        : Column(
                            children: _ongs.map((ong) {
                              return ZoomCard(
                                child: _buildListaCard(ong),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OngsPage(ongData: ong),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  // ===================== WIDGETS DAS ONGS ===========================

  Widget _buildDestaqueCard(dynamic ong) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              ong['image_url'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.image),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Text(
              ong['title'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 6,
                  )
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCard(dynamic ong) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Flexible(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Image.network(
                    ong['image_url'] ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ong['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ong['category'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ===================== WIDGET ZOOM ANIMADO ===========================
// ====================================================================

class ZoomCard extends StatefulWidget {
  final Widget child;
  final void Function()? onTap;
  final double width;

  const ZoomCard({
    super.key,
    required this.child,
    this.onTap,
    this.width = double.infinity,
  });

  @override
  State<ZoomCard> createState() => _ZoomCardState();
}

class _ZoomCardState extends State<ZoomCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Future.delayed(const Duration(milliseconds: 80), () {
          if (widget.onTap != null) widget.onTap!();
        });
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween(begin: 1, end: _pressed ? 0.95 : 1),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: scale,
            child: SizedBox(width: widget.width, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
