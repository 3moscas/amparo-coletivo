// lib/presentation/pages/ongs_page.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';
import 'package:amparo_coletivo/presentation/pages/ong_posts_page.dart';

class OngsPage extends StatefulWidget {
  final Map<String, dynamic> ongData;

  const OngsPage({super.key, required this.ongData});

  @override
  State<OngsPage> createState() => _OngsPageState();
}

class _OngsPageState extends State<OngsPage> {
  final supabase = Supabase.instance.client;

  bool isFavorite = false;
  String? favoriteId;
  bool loadingFavorite = true;
  bool toggling = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    setState(() => loadingFavorite = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isFavorite = false;
        favoriteId = null;
        loadingFavorite = false;
      });
      return;
    }

    try {
      final ongId = widget.ongData['id'];
      final response = await supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('ong_id', ongId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          isFavorite = true;
          favoriteId = response['id']?.toString();
        });
      } else {
        setState(() {
          isFavorite = false;
          favoriteId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar favoritos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (toggling) return;
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para favoritar uma ONG.')),
      );
      return;
    }

    setState(() => toggling = true);
    final ongId = widget.ongData['id'];

    try {
      if (isFavorite) {
        if (favoriteId != null) {
          await supabase.from('favorites').delete().eq('id', favoriteId!);
        } else {
          await supabase
              .from('favorites')
              .delete()
              .eq('user_id', user.id)
              .eq('ong_id', ongId);
        }

        setState(() {
          isFavorite = false;
          favoriteId = null;
        });
      } else {
        final inserted = await supabase
            .from('favorites')
            .insert({'user_id': user.id, 'ong_id': ongId})
            .select()
            .maybeSingle();

        if (inserted != null && inserted['id'] != null) {
          setState(() {
            isFavorite = true;
            favoriteId = inserted['id'].toString();
          });
        } else {
          final insertedList = await supabase
              .from('favorites')
              .insert({'user_id': user.id, 'ong_id': ongId}).select();

          if (insertedList.isNotEmpty && insertedList.first['id'] != null) {
            setState(() {
              isFavorite = true;
              favoriteId = insertedList.first['id'].toString();
            });
          } else {
            setState(() => isFavorite = true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar favorito: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ongData = widget.ongData;
    final String title = (ongData['title'] ?? 'ONG sem nome').toString();
    final String description =
        (ongData['sobre_ong'] ?? 'Sem descrição').toString();
    final String imagePath =
        (ongData['image_url'] ?? 'assets/imagem_padrao.jpg').toString();

    final List<String> imagensCarrossel = [
      (ongData['foto_relevante1'] ?? 'assets/imagem1.jpg').toString(),
      (ongData['foto_relevante2'] ?? 'assets/imagem2.jpg').toString(),
      (ongData['foto_relevante3'] ?? 'assets/imagem3.jpg').toString(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E8B57),
        elevation: 0,
        actions: [
          if (loadingFavorite)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              tooltip: isFavorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.white,
                size: 28,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OngPostsPage(
                ongId: ongData['id'].toString(),
              ),
            ),
          );
        }, // <-- CORRIGIDO (não pode ter ; e precisa da vírgula)

        label: const Text('Ver publicações'),
        icon: const Icon(Icons.feed),
        backgroundColor: const Color(0xFF2E8B57),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LOGO / NOME
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipOval(
                      child: imagePath.startsWith("http")
                          ? Image.network(
                              imagePath,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Image.asset(
                                  'assets/imagem_padrao.jpg',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              imagePath,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CARROSSEL
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    "Fotos relevantes:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              CarouselSlider(
                options: CarouselOptions(
                    height: 130.0,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false),
                items: imagensCarrossel.map((item) {
                  final bool isNetwork = item.startsWith("http");
                  final ImageProvider imageProvider = isNetwork
                      ? NetworkImage(item)
                      : AssetImage(item) as ImageProvider;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageView(imageUrl: item),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.blue[100],
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // DESCRIÇÃO
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    "Informações adicionais:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Text(
                  description.isNotEmpty ? description : "Sobre......",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imageUrl.startsWith("http");

    final ImageProvider<Object> provider = isNetwork
        ? NetworkImage(imageUrl)
        : AssetImage(imageUrl) as ImageProvider<Object>;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Visualizar imagem"),
          backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: PhotoView(
            imageProvider: provider,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          ),
        ),
      ),
    );
  }
}
