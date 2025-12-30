import 'package:flutter/material.dart';
import 'main.dart'; // ApiService, AuthService
import 'models.dart'; // Category modeli
import 'kategori_duzenle_page.dart'; // Birazdan oluşturacağımız sayfa

class KategoriYonetimiPage extends StatefulWidget {
  @override
  _KategoriYonetimiPageState createState() => _KategoriYonetimiPageState();
}

class _KategoriYonetimiPageState extends State<KategoriYonetimiPage> {
  late Future<List<Category>> _kategorilerFuture;

  @override
  void initState() {
    super.initState();
    _kategorilerFuture = _loadKategoriler();
  }

  Future<List<Category>> _loadKategoriler() async {
    String? token = await AuthService.getToken();
    if (token == null) throw Exception("Giriş yapılmamış.");
    return ApiService.getAdminCategories(token);
  }

  void _refreshList() {
    setState(() {
      _kategorilerFuture = _loadKategoriler();
    });
  }

  Future<void> _deleteCategory(int categoryId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Silme Onayı'),
        content: Text('Bu kategoriyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Sil')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        String? token = await AuthService.getToken();
        if (token == null) throw Exception("Giriş yapılmamış.");
        bool success = await ApiService.deleteCategory(token, categoryId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kategori silindi.'), backgroundColor: Colors.green));
          _refreshList();
        } else {
          throw Exception("Kategori silinemedi.");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _navigateToEditPage({Category? kategori}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KategoriDuzenlePage(kategori: kategori)),
    ).then((value) {
      if (value == true) {
        _refreshList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Category>>(
        future: _kategorilerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Hiç kategori bulunmuyor.'));
          }

          final kategoriler = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshList(),
            child: ListView.builder(
              itemCount: kategoriler.length,
              itemBuilder: (context, index) {
                final kategori = kategoriler[index];
                return ListTile(
                  title: Text(kategori.adi),
                  subtitle: Text(kategori.aciklama),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToEditPage(kategori: kategori),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(kategori.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _navigateToEditPage(), // Yeni eklemek için kategori göndermiyoruz
      ),
    );
  }
}