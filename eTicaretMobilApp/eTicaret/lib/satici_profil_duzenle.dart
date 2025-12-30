// lib/satici_profil_duzenle.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart'; // ApiService ve AuthService için

class SaticiProfilDuzenlePage extends StatefulWidget {
  @override
  _SaticiProfilDuzenlePageState createState() => _SaticiProfilDuzenlePageState();
}

class _SaticiProfilDuzenlePageState extends State<SaticiProfilDuzenlePage> {
  final _formKey = GlobalKey<FormState>();
  final _adiController = TextEditingController();
  final _hakkindaController = TextEditingController();

  // YENİ EKLENDİ: Resim yönetimi için state'ler
  File? _secilenResim;
  String? _mevcutResimAdi;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Giriş yapılmamış. Lütfen tekrar giriş yapın.");
      }

      var profileData = await ApiService.getSellerProfile(token);
      if (mounted) {
        setState(() {
          _adiController.text = profileData['Adi'];
          _hakkindaController.text = profileData['Hakkinda'] ?? '';
          _mevcutResimAdi = profileData['Resim']; // YENİ EKLENDİ
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // YENİ EKLENDİ: Galeriden resim seçme metodu
  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _secilenResim = File(pickedFile.path);
      });
    }
  }

  // GÜNCELLENDİ: Kaydetme metodu resim yüklemeyi de içeriyor
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? sonResimAdi = _mevcutResimAdi;

      try {
        String? token = await AuthService.getToken();
        if (token == null) {
          throw Exception("Giriş yapılmamış. Lütfen tekrar giriş yapın.");
        }

        // Eğer yeni bir resim seçildiyse, önce onu yükle
        if (_secilenResim != null) {
          String? yeniDosyaAdi = await ApiService.uploadImage(token, _secilenResim!);
          if (yeniDosyaAdi != null) {
            sonResimAdi = yeniDosyaAdi;
          } else {
            throw Exception("Resim yüklenirken hata oluştu.");
          }
        }

        bool success = await ApiService.updateSellerProfile(
          token,
          _adiController.text,
          _hakkindaController.text,
          resim: sonResimAdi,
        );
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green),
            );

            // Hatalı olan Navigator.pop satırını silin ve aşağıdaki kodu ekleyin
            setState(() {
              _secilenResim = null; // Seçilen yerel resmi temizle
            });
            await _loadProfile(); // Sunucudan güncel bilgileri tekrar yükle

          } else {
            throw Exception('Profil güncellenemedi.');
          }
        }
      }
      catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Satıcı Profilini Düzenle')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Hata: $_errorMessage', textAlign: TextAlign.center),
      ))
          : Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // YENİ EKLENDİ: Resim gösterme ve seçme alanı
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _secilenResim != null
                        ? FileImage(_secilenResim!)
                        : (_mevcutResimAdi != null && _mevcutResimAdi!.isNotEmpty)
                        ? NetworkImage('${ApiService.baseUrl}/Upload/$_mevcutResimAdi')
                        : null, // BURASI
                    child: (_secilenResim == null && (_mevcutResimAdi == null || _mevcutResimAdi!.isEmpty))
                        ? Icon(Icons.store, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _resimSec,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _adiController,
              decoration: InputDecoration(labelText: 'Mağaza Adı', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Mağaza adı boş olamaz' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _hakkindaController,
              decoration: InputDecoration(labelText: 'Hakkında', border: OutlineInputBorder()),
              maxLines: 5,
              minLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Kaydet'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}