import 'package:flutter/material.dart';
import 'main.dart'; // ApiService, AuthService ve Product için
import 'models.dart'; // Product modeli için
import 'urun_duzenle.dart';
import 'urun_ekle.dart'; // Yeni sayfayı import et

class SaticiUrunYonetimiPage extends StatefulWidget {
  @override
  _SaticiUrunYonetimiPageState createState() => _SaticiUrunYonetimiPageState();
}

class _SaticiUrunYonetimiPageState extends State<SaticiUrunYonetimiPage> {
  late Future<List<Product>> _urunlerFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _urunlerFuture = _loadUrunler();
    });
  }

  Future<List<Product>> _loadUrunler() async {
    String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Giriş yapılmamış. Lütfen tekrar giriş yapın.");
    }
    return ApiService.getSellerProducts(token);
  }

  // YENİ EKLENDİ: Ürün silme işlemini yöneten metot
  Future<void> _deleteProduct(int productId) async {
    // Kullanıcıdan onay almak için bir dialog göster
    final bool? userConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emin misiniz?'),
        content: Text('Bu ürünü kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // "Hayır" cevabı
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // "Evet" cevabı
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Kullanıcı "Sil" butonuna basmadıysa (null veya false ise) işlemi durdur
    if (userConfirmed != true) return;

    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception("Yetkilendirme hatası.");

      // ApiService üzerinden silme isteğini gönder
      bool success = await ApiService.deleteProduct(token, productId);

      if (mounted) { // İşlem sonrası widget hala ekranda mı diye kontrol et
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ürün başarıyla silindi.'), backgroundColor: Colors.green),
          );
          // Liste anında güncellensin diye Future'ı yeniden tetikle
          _refreshProducts();
        } else {
          throw Exception('Ürün silinemedi. API yanıtı başarısız.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ürün Yönetimi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UrunEklePage()),
          );
          if (result == true) {
            _refreshProducts();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Yeni Ürün Ekle',
      ),
      body: FutureBuilder<List<Product>>(
        future: _urunlerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Hata: ${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Henüz ürün eklememişsiniz.'));
          }

          final urunler = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              itemCount: urunler.length,
              itemBuilder: (context, index) {
                final urun = urunler[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: urun.resim != null
                        ? Image.network(
                      '${ApiService.baseUrl}/Upload/${urun.resim}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Icon(Icons.image_not_supported),
                    )
                        : Icon(Icons.image, size: 50),
                    title: Text(urun.adi),
                    subtitle: Text('Fiyat: ₺${urun.fiyat.toStringAsFixed(2)} - Stok: ${urun.stok}'),
                    // DEĞİŞİKLİK: Düzenle ve Sil butonlarını içeren bir Row eklendi
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // Butonların minimum yer kaplamasını sağla
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                          tooltip: 'Düzenle',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UrunDuzenlePage(product: urun)),
                            );
                            if (result == true) {
                              _refreshProducts();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          tooltip: 'Sil',
                          onPressed: () => _deleteProduct(urun.id), // Silme metodunu çağır
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}