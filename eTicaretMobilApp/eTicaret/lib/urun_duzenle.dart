// lib/urun_duzenle.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'models.dart';

class UrunDuzenlePage extends StatefulWidget {
  final Product product;
  UrunDuzenlePage({required this.product});

  @override
  _UrunDuzenlePageState createState() => _UrunDuzenlePageState();
}

class _UrunDuzenlePageState extends State<UrunDuzenlePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _adiController;
  late TextEditingController _aciklamaController;
  late TextEditingController _fiyatController;
  late TextEditingController _stokController;

  File? _secilenResim;
  String? _mevcutResimAdi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _adiController = TextEditingController(text: widget.product.adi);
    _aciklamaController = TextEditingController(text: widget.product.aciklama);
    _fiyatController = TextEditingController(text: widget.product.fiyat.toString());
    _stokController = TextEditingController(text: widget.product.stok.toString());
    _mevcutResimAdi = widget.product.resim;
  }

  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _secilenResim = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? sonResimAdi = _mevcutResimAdi;

      try {
        String? token = await AuthService.getToken();
        if (token == null) {
          throw Exception("Giriş yapılmamış. Lütfen tekrar giriş yapın.");
        }

        if (_secilenResim != null) {
          String? yeniDosyaAdi = await ApiService.uploadImage(token, _secilenResim!);
          if (yeniDosyaAdi != null) {
            sonResimAdi = yeniDosyaAdi;
          } else {
            throw Exception("Resim yüklenirken hata oluştu.");
          }
        }

        final updatedProduct = Product(
          id: widget.product.id,
          adi: _adiController.text,
          aciklama: _aciklamaController.text,
          fiyat: double.tryParse(_fiyatController.text) ?? 0.0,
          stok: int.tryParse(_stokController.text) ?? 0,
          resim: sonResimAdi,
          kategoriId: widget.product.kategoriId,
          saticiId: widget.product.saticiId,
        );

        bool success = await ApiService.updateProduct(token, updatedProduct);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ürün güncellendi!'), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          } else {
            throw Exception('Ürün güncellenemedi.');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ürünü Düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text("Ürün Resmi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _resimSec,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _secilenResim != null
                  // DEĞİŞİKLİK 1: BoxFit.contain olarak güncellendi.
                      ? Image.file(_secilenResim!, fit: BoxFit.contain)
                      : (_mevcutResimAdi != null && _mevcutResimAdi!.isNotEmpty)
                      ? Image.network(
                    '${ApiService.baseUrl}/Upload/$_mevcutResimAdi',
                    // DEĞİŞİKLİK 2: BoxFit.contain olarak güncellendi.
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) => progress == null ? child : Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: Colors.grey.shade600, size: 50)),
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600, size: 50),
                        SizedBox(height: 8),
                        Text(
                          "Resmi Değiştirmek İçin Tıklayın",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            TextFormField(controller: _adiController, decoration: InputDecoration(labelText: 'Ürün Adı'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            SizedBox(height: 16),
            TextFormField(controller: _aciklamaController, decoration: InputDecoration(labelText: 'Açıklama'), maxLines: 3),
            SizedBox(height: 16),
            TextFormField(controller: _fiyatController, decoration: InputDecoration(labelText: 'Fiyat (₺)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            SizedBox(height: 16),
            TextFormField(controller: _stokController, decoration: InputDecoration(labelText: 'Stok Adedi'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}