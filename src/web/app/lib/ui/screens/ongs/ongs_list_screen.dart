import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/ong_model.dart';
import '../../../core/services/ong_service.dart';
import 'ong_details_screen.dart';
import 'manage_ong_screen.dart';

class OngsListScreen extends StatefulWidget {
  const OngsListScreen({super.key});

  @override
  State<OngsListScreen> createState() => _OngsListScreenState();
}

class _OngsListScreenState extends State<OngsListScreen> {
  final OngService _ongService = OngService();
  late Future<List<Ong>> _ongsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOngs();
  }

  void _loadOngs() {
    setState(() {
      _ongsFuture = _ongService.getOngs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONGs Cadastradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOngs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ONG...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Ong>>(
              future: _ongsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Erro ao carregar as ONGs'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _loadOngs,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma ONG cadastrada'),
                  );
                }

                final ongs = _searchQuery.isEmpty
                    ? snapshot.data!
                    : snapshot.data!
                        .where((ong) =>
                            ong.title.toLowerCase().contains(_searchQuery) ||
                            ong.description
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            ong.category.toLowerCase().contains(_searchQuery))
                        .toList();

                if (ongs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma ONG encontrada'),
                  );
                }

                return ListView.builder(
                  itemCount: ongs.length,
                  itemBuilder: (context, index) {
                    final ong = ongs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: ong.imageUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage:
                                    CachedNetworkImageProvider(ong.imageUrl),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.people),
                              ),
                        title: Text(ong.title),
                        subtitle: Text(
                          ong.description.length > 50
                              ? '${ong.description.substring(0, 50)}...'
                              : ong.description,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OngDetailsScreen(ong: ong),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageOngScreen(),
            ),
          );

          if (result == true) {
            _loadOngs();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
