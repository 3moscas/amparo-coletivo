import 'package:flutter/material.dart';
import 'package:amparo_coletivo/presentation/pages/ong_posts_page.dart';

class AboutOngPage extends StatelessWidget {
  final Map<String, dynamic> ongData;

  const AboutOngPage({super.key, required this.ongData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar com botão de voltar
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(ongData['title'] ?? 'Sobre a ONG'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),

      // Botão flutuante
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OngPostsPage(ongData: ongData),
            ),
          );
        },
        label: const Text('Ver postagens'),
        icon: const Icon(Icons.article),
        backgroundColor: Colors.blue,
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
                      color: Colors.grey.shade300,
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
