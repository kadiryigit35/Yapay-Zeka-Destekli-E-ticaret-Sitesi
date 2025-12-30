import 'package:flutter/material.dart';
import 'main.dart'; // ApiService, AuthService
import 'models.dart'; // Category modeli

class KategoriDuzenlePage extends StatefulWidget {
  final Category? kategori; // Null olabilir, null ise yeni kategori oluşturulur

  KategoriDuzenlePage({this.kategori});

  @override
  _KategoriDuzenlePageState createState() => _KategoriDuzenlePageState();
}

class _KategoriDuzenlePageState extends State<KategoriDuzenlePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _adiController;
  late TextEditingController _aciklamaController;
  bool _isLoading = false;
  bool get _isEditing => widget.kategori != null;

  @override
  void initState() {
    super.initState();
    _adiController = TextEditingController(text: widget.kategori?.adi ?? '');
    _aciklamaController = TextEditingController(text: widget.kategori?.aciklama ?? '');
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String? token = await AuthService.getToken();
        if (token == null) throw Exception("Giriş yapılmamış.");

        if (_isEditing) {
          // Güncelleme
          final updatedCategory = Category(
            id: widget.kategori!.id,
            adi: _adiController.text,
            aciklama: _aciklamaController.text,
          );
          await ApiService.updateCategory(token, updatedCategory);
        } else {
          // Yeni oluşturma
          await ApiService.createCategory(token, _adiController.text, _aciklamaController.text);
        }

        if (mounted) {
          Navigator.pop(context, true); // Geri dönerken listeyi yenilemek için true gönder
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _adiController,
              decoration: InputDecoration(labelText: 'Kategori Adı'),
              validator: (v) => v!.isEmpty ? 'Kategori adı boş olamaz' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _aciklamaController,
              decoration: InputDecoration(labelText: 'Açıklama'),
              validator: (v) => v!.isEmpty ? 'Açıklama boş olamaz' : null,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCategory,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}