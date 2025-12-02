import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'manage_ong_screen.dart';
import '../../../core/models/ong_model.dart';

class OngDetailsScreen extends StatelessWidget {
  final Ong ong;

  const OngDetailsScreen({super.key, required this.ong});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(ong.title),
              background: ong.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ong.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : Container(
                      color: Theme.of(context).primaryColor,
                      child: const Icon(Icons.people, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ong.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (ong.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(ong.description),
                    ),
                  if (ong.category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Categoria: ${ong.category}'),
                    ),
                  if (ong.sobreOng.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Sobre a ONG: ${ong.sobreOng}'),
                    ),
                  const Divider(),
                  // Aqui você poderia adicionar outras fotos relevantes
                  if (ong.fotoRelevante1.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Image.network(ong.fotoRelevante1),
                    ),
                  if (ong.fotoRelevante2.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Image.network(ong.fotoRelevante2),
                    ),
                  if (ong.fotoRelevante3.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Image.network(ong.fotoRelevante3),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageOngScreen(ong: ong),
            ),
          );

          if (result == true) {
            Navigator.pop(context, true);
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
