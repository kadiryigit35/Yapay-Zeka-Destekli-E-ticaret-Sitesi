// lib/profildüzenle.dart
import 'api_config.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'models.dart';

class ProfileEditService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String adi,
    required String soyadi,
    required String email,
    String? mevcutSifre,
    String? yeniSifre,
    String? profilResmi, // GÜNCELLENDİ: Resim parametresi eklendi
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Adi': adi,
          'Soyadi': soyadi,
          'Email': email,
          'MevcutSifre': mevcutSifre,
          'YeniSifre': yeniSifre,
          'ProfilResmi': profilResmi, // GÜNCELLENDİ: Resim parametresi eklendi
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['Message'] ?? 'Profil güncellenemedi'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }
}

class ProfileEditPage extends StatefulWidget {
  final User user;
  const ProfileEditPage({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _adiController;
  late TextEditingController _soyadiController;
  late TextEditingController _emailController;
  final _mevcutSifreController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();

  // YENİ EKLENDİ: Resim yönetimi için state'ler
  File? _secilenResim;
  String? _mevcutResimAdi;
  bool _isLoading = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _adiController = TextEditingController(text: widget.user.adi);
    _soyadiController = TextEditingController(text: widget.user.soyadi);
    _emailController = TextEditingController(text: widget.user.email);
    _mevcutResimAdi = widget.user.profilResmi; // YENİ EKLENDİ
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
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_showPasswordFields && _yeniSifreController.text != _yeniSifreTekrarController.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yeni şifreler eşleşmiyor'), backgroundColor: Colors.red));
        return;
      }
      setState(() => _isLoading = true);
      String? sonResimAdi = _mevcutResimAdi;

      try {
        String? token = await AuthService.getToken();
        if (token == null) throw Exception("Giriş yapılmamış.");

        if (_secilenResim != null) {
          String? yeniDosyaAdi = await ApiService.uploadImage(token, _secilenResim!);
          if (yeniDosyaAdi != null) {
            sonResimAdi = yeniDosyaAdi;
          } else {
            throw Exception("Resim yüklenirken hata oluştu.");
          }
        }

        final result = await ProfileEditService.updateProfile(
          userId: widget.user.id,
          adi: _adiController.text,
          soyadi: _soyadiController.text,
          email: _emailController.text,
          mevcutSifre: _showPasswordFields ? _mevcutSifreController.text : null,
          yeniSifre: _showPasswordFields ? _yeniSifreController.text : null,
          profilResmi: sonResimAdi, // GÜNCELLENDİ
        );

        if (mounted) {
          if (result['success']) {
            await _updateLocalUserData(newProfilePic: sonResimAdi);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil güncellendi'), backgroundColor: Colors.green));
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocalUserData({String? newProfilePic}) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      userData['adi'] = _adiController.text;
      userData['soyadi'] = _soyadiController.text;
      userData['email'] = _emailController.text;
      if (newProfilePic != null) {
        userData['profilResmi'] = newProfilePic;
      }
      await prefs.setString('user_data', json.encode(userData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // YENİ EKLENDİ: Resim gösterme ve seçme alanı
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _secilenResim != null
                          ? FileImage(_secilenResim!)
                          : (_mevcutResimAdi != null && _mevcutResimAdi!.isNotEmpty && _mevcutResimAdi != 'default.png')
                          ? NetworkImage('${ApiService.baseUrl}/Upload/$_mevcutResimAdi')
                          : null as ImageProvider?,
                      child: (_secilenResim == null && (_mevcutResimAdi == null || _mevcutResimAdi!.isEmpty || _mevcutResimAdi == 'default.png'))
                          ? Icon(Icons.person, size: 60)
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
              TextFormField(controller: _adiController, decoration: InputDecoration(labelText: 'Ad'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              SizedBox(height: 16),
              TextFormField(controller: _soyadiController, decoration: InputDecoration(labelText: 'Soyad'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              SizedBox(height: 24),
              SwitchListTile(
                title: Text('Şifre Değiştir'),
                value: _showPasswordFields,
                onChanged: (value) => setState(() => _showPasswordFields = value),
              ),
              if (_showPasswordFields) ...[
                TextFormField(controller: _mevcutSifreController, decoration: InputDecoration(labelText: 'Mevcut Şifre'), obscureText: true, validator: (v) => _showPasswordFields && v!.isEmpty ? 'Gerekli' : null),
                SizedBox(height: 16),
                TextFormField(controller: _yeniSifreController, decoration: InputDecoration(labelText: 'Yeni Şifre'), obscureText: true, validator: (v) => _showPasswordFields && v!.isEmpty ? 'Gerekli' : null),
                SizedBox(height: 16),
                TextFormField(controller: _yeniSifreTekrarController, decoration: InputDecoration(labelText: 'Yeni Şifre Tekrar'), obscureText: true, validator: (v) => _showPasswordFields && v!.isEmpty ? 'Gerekli' : null),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white,) : Text('Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}