// lib/satici_profil_page.dart

import 'package:flutter/material.dart';
import 'models.dart';
import 'main.dart'; // ApiService ve AuthService için
import 'product_detail_page.dart'; // ProductDetailPage'e gitmek için
import 'providers/cart_provider.dart'; // ProductCard'dan dolayı gerekebilir
import 'package:provider/provider.dart';


class SaticiProfilPage extends StatefulWidget {
  final int saticiId;

  const SaticiProfilPage({Key? key, required this.saticiId}) : super(key: key);

  @override
  _SaticiProfilPageState createState() => _SaticiProfilPageState();
}

class _SaticiProfilPageState extends State<SaticiProfilPage> {
  Satici? _satici;
  List<Product> _urunler = [];
  bool _isLoading = true;
  User? _currentUser;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getCurrentUser();
      final profileData = await ApiService.getSellerProfileWithProducts(widget.saticiId);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _satici = Satici.fromJson(profileData);
          _urunler = (profileData['Urunler'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Satıcı profili yüklenemedi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitSellerRating(int rating) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puan vermek için giriş yapmalısınız.'), backgroundColor: Colors.orange),
      );
      return;
    }
    final token = await AuthService.getToken();
    if (token == null) return;

    final success = await ApiService.rateSeller(token: token, saticiId: widget.saticiId, rating: rating);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Puanınız ($rating) kaydedildi."), backgroundColor: Colors.green),
      );
      _loadProfileData(); // Verileri yenile
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Puan kaydedilirken bir hata oluştu."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Yükleniyor...' : _satici?.adi ?? 'Satıcı Profili'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _satici == null
          ? Center(child: Text("Satıcı bulunamadı."))
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Satıcının Ürünleri (${_urunler.length})",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_satici == null) return SizedBox.shrink();
    final satici = _satici!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage('${ApiService.baseUrl}/Upload/${satici.resim ?? 'default.png'}'),
                    onBackgroundImageError: (_, __) {},
                    child: satici.resim == null ? Icon(Icons.store, size: 40) : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(satici.adi, style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(height: 8),
                        _buildRatingSummary(satici),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(satici.hakkinda ?? 'Satıcı hakkında bilgi bulunmuyor.', style: Theme.of(context).textTheme.bodyMedium),
              if (_currentUser != null) _buildRatingInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummary(Satici satici) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= satici.ortalamaPuan ? Icons.star :
            i - 0.5 <= satici.ortalamaPuan ? Icons.star_half : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        SizedBox(width: 8),
        Text(
          '${satici.ortalamaPuan.toStringAsFixed(1)} (${satici.toplamPuanSayisi} Değerlendirme)',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildRatingInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bu Satıcıya Puan Ver:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() => _userRating = ratingValue);
                  _submitSellerRating(ratingValue);
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

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = _urunler[index];
            // ProductCard'ı kullanmak yerine direkt burada oluşturuyoruz.
            // main.dart'taki ProductCard'ı da kullanabilirsiniz.
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)),
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        '${ApiService.baseUrl}/Upload/${product.resim}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (c, e, s) => Icon(Icons.image_not_supported),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(product.adi, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
                      child: Text('₺${product.fiyat.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _urunler.length,
        ),
      ),
    );
  }
}