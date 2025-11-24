import 'package:flutter/material.dart';
import 'package:amparo_coletivo/ui/home/pages/ngos/selected_ngo_posts_screen.dart';

class AboutUsScreen extends StatelessWidget {
  final Map<String, dynamic> ongData;

  const AboutUsScreen({super.key, required this.ongData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // AppBar com botão de voltar
      appBar: AppBar(
        title: Text(ongData['title'] ?? 'Sobre a ONG'),
      ),

      // Botão flutuante
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelectedNGOPostsScreen(ongData: ongData),
            ),
          );
        },
        label: const Text('Ver postagens'),
        icon: const Icon(Icons.article),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Imagem da ONG
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ongData['image_url'] != null &&
                      ongData['image_url'].toString().isNotEmpty
                  ? Image.network(
                      ongData['image_url'],
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      height: 200,
                      width: MediaQuery.of(context).size.width * 0.9,
                      alignment: Alignment.center,
                      child: const Text("Sem imagem disponível"),
                    ),
            ),
            const SizedBox(height: 20),

            // Título e descrição
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    ongData['title'] ?? 'ONG',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ongData['description'] ??
                        'Essa ONG ainda não possui uma descrição.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
