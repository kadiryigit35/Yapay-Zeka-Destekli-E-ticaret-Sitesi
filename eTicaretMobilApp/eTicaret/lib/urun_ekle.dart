// lib/urun_ekle.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'models.dart';

class UrunEklePage extends StatefulWidget {
  @override
  _UrunEklePageState createState() => _UrunEklePageState();
}

class _UrunEklePageState extends State<UrunEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _adiController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _stokController = TextEditingController();

  // Kategori ID'si için, normalde bir dropdown'dan seçtirilir.
  // Şimdilik sabit bir değer giriyoruz.
  final int _kategoriId = 1;

  File? _secilenResim;
  bool _isLoading = false;

  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _secilenResim = File(pickedFile.path);
      });
    }
  }

  Future<void> _createProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_secilenResim == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen bir ürün resmi seçin.'),
              backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String? token = await AuthService.getToken();
        if (token == null) throw Exception("Giriş yapılmamış.");

        // 1. Resmi yükle ve dosya adını al
        String? fileName = await ApiService.uploadImage(token, _secilenResim!);
        if (fileName == null) throw Exception("Resim yüklenemedi.");

        // 2. Ürün modelini oluştur
        final newProduct = Product(
          id: 0,
          // Yeni ürün olduğu için ID 0
          adi: _adiController.text,
          aciklama: _aciklamaController.text,
          fiyat: double.tryParse(_fiyatController.text) ?? 0.0,
          stok: int.tryParse(_stokController.text) ?? 0,
          resim: fileName,
          kategoriId: _kategoriId,
          // Kategori ID'si
          saticiId: 0, // API bu alanı kendisi dolduracak
        );

        // 3. Ürünü API'ye gönder
        bool success = await ApiService.createProduct(token, newProduct);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Ürün başarıyla eklendi!'),
                backgroundColor: Colors.green));
            Navigator.pop(context, true); // Listeyi yenilemek için true dön
          } else {
            throw Exception('Ürün eklenemedi.');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Ürün Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text("Ürün Resmi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  // DEĞİŞİKLİK BURADA: BoxFit.contain olarak güncellendi.
                      ? Image.file(_secilenResim!, fit: BoxFit.contain)
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.grey
                            .shade600, size: 50),
                        SizedBox(height: 8),
                        Text(
                          "Resim Seçmek İçin Tıklayın",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            TextFormField(controller: _adiController,
                decoration: InputDecoration(labelText: 'Ürün Adı'),
                validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            SizedBox(height: 16),
            TextFormField(controller: _aciklamaController,
                decoration: InputDecoration(labelText: 'Açıklama'),
                maxLines: 3),
            SizedBox(height: 16),
            TextFormField(controller: _fiyatController,
                decoration: InputDecoration(labelText: 'Fiyat (₺)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            SizedBox(height: 16),
            TextFormField(controller: _stokController,
                decoration: InputDecoration(labelText: 'Stok Adedi'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createProduct,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Ürünü Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}