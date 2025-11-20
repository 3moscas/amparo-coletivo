import 'package:flutter/material.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';
import 'package:amparo_coletivo/presentation/pages/ong_posts_page.dart';

class AboutOngPage extends StatelessWidget {
  final Map<String, dynamic> ongData;

  const AboutOngPage({super.key, required this.ongData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(ongData['title'] ?? 'Sobre a ONG'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/perfil');
          }
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
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
