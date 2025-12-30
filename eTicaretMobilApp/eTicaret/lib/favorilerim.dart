// favorites_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class FavoriteProduct {
  final int id;
  final String adi;
  final String aciklama;
  final double fiyat;
  final int stok;
  final String? resim;
  final int kategoriId;
  final int saticiId;
  final FavoriteSatici? satici;

  FavoriteProduct({
    required this.id,
    required this.adi,
    required this.aciklama,
    required this.fiyat,
    required this.stok,
    this.resim,
    required this.kategoriId,
    required this.saticiId,
    this.satici,
  });

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    return FavoriteProduct(
      id: json['Id'],
      adi: json['Adi'] ?? '',
      aciklama: json['Aciklama'] ?? '',
      fiyat: (json['Fiyat'] ?? 0).toDouble(),
      stok: json['Stok'] ?? 0,
      resim: json['Resim'],
      kategoriId: json['kategoriId'] ?? 0,
      saticiId: json['saticiId'] ?? 0,
      satici: json['Satici'] != null ? FavoriteSatici.fromJson(json['Satici']) : null,
    );
  }
}

class FavoriteSatici {
  final int id;
  final String adi;

  FavoriteSatici({required this.id, required this.adi});

  factory FavoriteSatici.fromJson(Map<String, dynamic> json) {
    return FavoriteSatici(
      id: json['Id'],
      adi: json['Adi'] ?? '',
    );
  }
}

class FavoritesService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<FavoriteProduct>> getUserFavorites(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/favorites/$username'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> favoritesData = data['favorites'];
        return favoritesData.map((json) => FavoriteProduct.fromJson(json)).toList();
      } else {
        throw Exception('Favoriler yüklenirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
  // YENİ METOT: Favorilere ürün eklemek için
  static Future<bool> addToFavorites(String username, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/favorites/$username'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ProductId': productId}), // API'nizin beklediği model
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Ürün favorilere eklenirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
  static Future<bool> removeFromFavorites(String username, int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/user/favorites/$username/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Favorilerden kaldırılırken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
}

class FavoritesPage extends StatefulWidget {
  final String username;

  const FavoritesPage({Key? key, required this.username}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteProduct> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final loadedFavorites = await FavoritesService.getUserFavorites(widget.username);
      setState(() {
        favorites = loadedFavorites;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favoriler yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeFromFavorites(int productId) async {
    try {
      final success = await FavoritesService.removeFromFavorites(widget.username, productId);
      if (success) {
        setState(() {
          favorites.removeWhere((product) => product.id == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün favorilerden kaldırıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorilerim'),

      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favorites.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz favori ürününüz yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Ürünleri Keşfet'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadFavorites,
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final product = favorites[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün Resmi
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12)),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: product.resim != null
                                ? Image.network(
                              'https://localhost:44366/Upload/${product.resim}',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 40),
                                );
                              },
                            )
                                : Center(
                              child: Icon(Icons.image,
                                  color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                        // Favorilerden kaldır butonu
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Favorilerden Kaldır'),
                                    content: Text(
                                        '${product.adi} ürününü favorilerden kaldırmak istediğinizden emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          removeFromFavorites(product.id);
                                        },
                                        child: Text('Kaldır',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ürün Bilgileri
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.adi,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          if (product.satici != null) ...[
                            Text(
                              product.satici!.adi,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                          Expanded(
                            child: Text(
                              product.aciklama,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₺${product.fiyat.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: product.stok > 0
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.stok > 0
                                      ? 'Stokta'
                                      : 'Tükendi',
                                  style: TextStyle(
                                    color: product.stok > 0
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}