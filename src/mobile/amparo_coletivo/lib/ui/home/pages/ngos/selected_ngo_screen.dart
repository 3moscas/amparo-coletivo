import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:amparo_coletivo/ui/home/pages/ngos/selected_ngo_posts_screen.dart';

class SelectedNGOScreen extends StatelessWidget {
  final Map<String, dynamic> ongData;

  const SelectedNGOScreen({super.key, required this.ongData});

  @override
  Widget build(BuildContext context) {
    final String title = ongData['title'] ?? 'ONG sem nome';
    final String description = ongData['sobre_ong'] ?? 'Sem descrição';
    final String imagePath = ongData['image_url'] ?? 'assets/imagem_padrao.jpg';

    final List<String> imagensCarrossel = [
      ongData['foto_relevante1'] ?? 'assets/imagem1.jpg',
      ongData['foto_relevante2'] ?? 'assets/imagem2.jpg',
      ongData['foto_relevante3'] ?? 'assets/imagem3.jpg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfólio'),
      ),

      // ⚡ NOVO BOTÃO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelectedNGOPostsScreen(ongData: ongData),
            ),
          );
        },
        label: const Text('Ver publicações'),
        icon: const Icon(Icons.feed),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo da ONG
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ClipOval(
                        child: imagePath.startsWith("http")
                            ? Image.network(
                                imagePath,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Carrossel
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
                  enableInfiniteScroll: false,
                ),
                items: imagensCarrossel.map((item) {
                  final bool isNetwork = item.startsWith("http");
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
                        image: DecorationImage(
                          image: isNetwork
                              ? NetworkImage(item)
                              : AssetImage(item) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Descrição
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
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    description.isNotEmpty ? description : "Sobre......",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

/// Página para visualizar a imagem em tela cheia com zoom.
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imageUrl.startsWith("http");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visualizar imagem"),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: PhotoView(
            imageProvider: isNetwork
                ? NetworkImage(imageUrl)
                : AssetImage(imageUrl) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          ),
        ),
      ),
    );
  }
}
