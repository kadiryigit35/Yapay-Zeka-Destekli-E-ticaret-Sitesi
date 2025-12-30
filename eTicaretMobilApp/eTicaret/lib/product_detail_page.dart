// lib/product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'satici_profil_page.dart';
import 'models.dart';
import 'providers/cart_provider.dart';
import 'main.dart';
import 'favorilerim.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();

  Product? _detailedProduct;
  bool _isFavorite = false;
  bool _isLoading = true;
  User? _currentUser;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await AuthService.getCurrentUser();
      final productDetails = await ApiService.getProductDetails(widget.product.id);

      bool isFav = false;
      if (_currentUser != null) {
        final userFavorites = await FavoritesService.getUserFavorites(_currentUser!.kullaniciAdi);
        isFav = userFavorites.any((p) => p.id == widget.product.id);
      }

      if (mounted) {
        setState(() {
          _detailedProduct = productDetails;
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veriler yüklenemedi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitRating(int rating) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puan vermek için giriş yapmalısınız.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) return;

    final success = await ApiService.postRating(token: token, productId: widget.product.id, rating: rating);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Puanınız ($rating) kaydedildi."), backgroundColor: Colors.green),
      );
      _loadPageData(); // Puan ortalamasını yenilemek için verileri tekrar çek
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Puan kaydedilirken bir hata oluştu."), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorilere eklemek için giriş yapmalısınız.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final originalFavoriteStatus = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      bool success;
      if (_isFavorite) {
        success = await FavoritesService.addToFavorites(_currentUser!.kullaniciAdi, widget.product.id);
      } else {
        success = await FavoritesService.removeFromFavorites(_currentUser!.kullaniciAdi, widget.product.id);
      }

      if (!success && mounted) {
        throw Exception("API işlemi başarısız oldu.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = originalFavoriteStatus; // Hata durumunda geri al
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;

    final success = await ApiService.postComment(
        productId: widget.product.id,
        kullaniciAdi: _currentUser!.kullaniciAdi,
        icerik: _commentController.text);

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Klavyeyi kapat
      _loadPageData(); // Yorum listesini yenile
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yorumunuz eklendi."), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yorum eklenirken hata oluştu."), backgroundColor: Colors.red));
    }
  }

  // YENİ EKLENDİ: Yorum şikayet etme metodu
  Future<void> _reportComment(int yorumId) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumu şikayet etmek için giriş yapmalısınız.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) return;

    final success = await ApiService.reportComment(token: token, yorumId: yorumId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şikayetiniz yöneticiye iletildi."), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şikayet gönderilirken bir hata oluştu."), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final product = _detailedProduct ?? widget.product;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.adi),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 250,
                      child: Image.network(
                        '${ApiService.baseUrl}/Upload/${product.resim}',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(product.adi, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _buildRatingSummary(product),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(product.stok > 0 ? "Stokta Var" : "Tükendi"),
                        backgroundColor: product.stok > 0 ? Colors.green.shade100 : Colors.red.shade100,
                        labelStyle: TextStyle(color: product.stok > 0 ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        '₺${widget.product.fiyat.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary, // Temadan gelen vurgu rengini kullanır
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      if (widget.product.saticiId != 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaticiProfilPage(saticiId: widget.product.saticiId),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Text(
                            'Satıcı: ${product.satici?.adi ?? 'Bilinmiyor'}',
                            style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  if (_currentUser != null) _buildRatingInput(),
                  Container(
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: "Açıklama"),
                        Tab(text: "Yorumlar (${product.yorumlar.length})"),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(product.aciklama),
                        ),
                        _buildCommentsTab(product.yorumlar),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(product),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(Product product) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= product.ortalamaPuan ? Icons.star :
            i - 0.5 <= product.ortalamaPuan ? Icons.star_half : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        SizedBox(width: 8),
        Text(
          '${product.ortalamaPuan.toStringAsFixed(1)} (${product.toplamPuanSayisi} Değerlendirme)',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildRatingInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Puan Ver:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() => _userRating = ratingValue);
                  _submitRating(ratingValue);
                },
                icon: Icon(
                  _userRating >= ratingValue ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(List<Yorum> yorumlar) {
    return Column(
      children: [
        Expanded(
          child: yorumlar.isEmpty
              ? Center(child: Text("Henüz yorum yapılmamış."))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: yorumlar.length,
            itemBuilder: (context, index) {
              final yorum = yorumlar[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(yorum.kullaniciAdi, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(yorum.icerik),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('dd.MM.yy').format(yorum.tarih), style: TextStyle(fontSize: 12, color: Colors.grey)),
                      if (_currentUser != null)
                        IconButton(
                          icon: Icon(Icons.flag_outlined, color: Colors.grey[600], size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  title: Text('Yorumu Şikayet Et'),
                                  content: Text('Bu yorumu şikayet etmek istediğinizden emin misiniz?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('İptal'),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                    TextButton(
                                      child: Text('Evet, Şikayet Et', style: TextStyle(color: Colors.red)),
                                      onPressed: () {
                                        _reportComment(yorum.id);
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_currentUser != null) ...[
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                        hintText: "Yorumunuzu yazın...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _submitComment,
                ),
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1), offset: Offset(0, -5))]),
      child: SafeArea(
        child: ElevatedButton.icon(
          icon: Icon(Icons.add_shopping_cart),
          label: Text(product.stok > 0 ? 'Sepete Ekle' : 'Stokta Yok'),
          onPressed: product.stok > 0
              ? () {
            Provider.of<CartProvider>(context, listen: false).addToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.adi} sepete eklendi!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
              : null,
          style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 50)),
        ),
      ),
    );
  }
}