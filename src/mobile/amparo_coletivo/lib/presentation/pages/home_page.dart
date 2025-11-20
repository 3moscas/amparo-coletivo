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
    Navigator.of(context).pop(); // fecha o drawer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout efetuado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amparo Coletivo'),
        backgroundColor: Colors.lightBlue,
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
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OngsPage(ongData: ong),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: SizedBox(
                                      width: 180,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Image.network(
                                              ong['image_url'] ?? '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(Icons.image),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              ong['title'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 20),
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
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: Image.network(
                                    ong['image_url'] ?? '',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.image),
                                  ),
                                  title: Text(ong['title'] ?? ''),
                                  subtitle: Text(ong['category'] ?? ''),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OngsPage(ongData: ong),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
