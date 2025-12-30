  import 'package:flutter/material.dart';
  import 'main.dart'; // ApiService için

  enum SifirlamaAdimi { emailGir, kodGir, sifreGir }

  class SifreSifirlamaPage extends StatefulWidget {
    @override
    _SifreSifirlamaPageState createState() => _SifreSifirlamaPageState();
  }

  class _SifreSifirlamaPageState extends State<SifreSifirlamaPage> {
    SifirlamaAdimi _currentStep = SifirlamaAdimi.emailGir;
    bool _isLoading = false;

    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _kodController = TextEditingController();
    final _yeniSifreController = TextEditingController();
    final _yeniSifreTekrarController = TextEditingController();

    void _showError(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    Future<void> _kodGonder() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      setState(() => _isLoading = true);

      try {
        final result = await ApiService.sifreSifirlamaKodGonder(_emailController.text.trim());
        if (mounted) {
          if (result['statusCode'] == 200) {
            final responseBody = result['body'];
            if (responseBody['success'] == true) {
              setState(() => _currentStep = SifirlamaAdimi.kodGir);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(responseBody['Message'] ?? 'Doğrulama kodu gönderildi!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              _showError(responseBody['Message'] ?? 'Bilinmeyen bir hata oluştu.');
            }
          } else {
            final errorMessage = result['body']['Message'] ?? 'HTTP ${result['statusCode']} hatası';
            _showError(errorMessage);
          }
        }
      } catch (e) {
        _showError('Beklenmeyen bir hata oluştu: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    Future<void> _kodDogrula() async {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _isLoading = true);

      try {
        final result = await ApiService.sifreSifirlamaKodDogrula(
            _emailController.text.trim(), _kodController.text.trim());

        if (mounted) {
          if (result['statusCode'] == 200) {
            final responseBody = result['body'];
            if (responseBody['success'] == true) {
              setState(() => _currentStep = SifirlamaAdimi.sifreGir);
            } else {
              _showError(responseBody['Message'] ?? 'Kod doğrulanamadı.');
            }
          } else {
            final errorMessage = result['body']['Message'] ??
                result['body']['message'] ??
                'Kod doğrulanamadı.';
            _showError(errorMessage);
          }
        }
      } catch (e) {
        _showError('Beklenmeyen bir hata oluştu: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    Future<void> _yeniSifreKaydet() async {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _isLoading = true);

      try {
        final result = await ApiService.sifreSifirlamaYeniSifre(
            _emailController.text.trim(),
            _kodController.text.trim(),
            _yeniSifreController.text);

        if (mounted) {
          if (result['statusCode'] == 200) {
            final responseBody = result['body'];
            if (responseBody['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(responseBody['Message'] ?? 'Şifreniz güncellendi!'),
                    backgroundColor: Colors.green),
              );
              Navigator.of(context).pop();
            } else {
              _showError(responseBody['Message'] ?? 'Şifre güncellenemedi.');
            }
          } else {
            final errorMessage = result['body']['Message'] ??
                result['body']['message'] ??
                'Şifre güncellenemedi.';
            _showError(errorMessage);
          }
        }
      } catch (e) {
        _showError('Beklenmeyen bir hata oluştu: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('Şifremi Unuttum')),
        body: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep.index,
            onStepTapped: (step) {
              // Adımlara tıklayarak geçişi engelle
            },
            controlsBuilder: (context, details) {
              if (_isLoading) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Container(
                margin: EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep == SifirlamaAdimi.emailGir) _kodGonder();
                    if (_currentStep == SifirlamaAdimi.kodGir) _kodDogrula();
                    if (_currentStep == SifirlamaAdimi.sifreGir) _yeniSifreKaydet();
                  },
                  child: Text(_getButtonText()),
                ),
              );
            },
            steps: [
              _buildEmailStep(),
              _buildKodStep(),
              _buildSifreStep(),
            ],
          ),
        ),
      );
    }

    String _getButtonText() {
      switch (_currentStep) {
        case SifirlamaAdimi.emailGir:
          return 'Kod Gönder';
        case SifirlamaAdimi.kodGir:
          return 'Kodu Doğrula';
        case SifirlamaAdimi.sifreGir:
          return 'Şifreyi Güncelle';
      }
    }

    Step _buildEmailStep() {
      return Step(
        title: Text('E-posta Adresi'),
        isActive: _currentStep.index >= 0,
        state: _currentStep.index > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            Text(
                'Sistemde kayıtlı e-posta adresinizi girin. Size bir doğrulama kodu göndereceğiz.'),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'E-posta'),
              // ===== DÜZELTME 1 BURADA =====
              validator: (value) {
                if (_currentStep == SifirlamaAdimi.emailGir) {
                  if (value == null || !value.contains('@')) {
                    return 'Lütfen geçerli bir e-posta adresi girin.';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      );
    }

    Step _buildKodStep() {
      return Step(
        title: Text('Doğrulama Kodu'),
        isActive: _currentStep.index >= 1,
        state: _currentStep.index > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            Text('E-posta adresinize gönderilen 6 haneli kodu girin.'),
            SizedBox(height: 16),
            TextFormField(
              controller: _kodController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Doğrulama Kodu'),
              // ===== DÜZELTME 2 BURADA =====
              validator: (value) {
                if (_currentStep == SifirlamaAdimi.kodGir) {
                  if (value == null || value.length < 6) {
                    return 'Lütfen 6 haneli kodu girin.';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      );
    }

    Step _buildSifreStep() {
      return Step(
        title: Text('Yeni Şifre'),
        isActive: _currentStep.index >= 2,
        content: Column(
          children: [
            Text('Lütfen yeni şifrenizi belirleyin.'),
            SizedBox(height: 16),
            TextFormField(
              controller: _yeniSifreController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Yeni Şifre'),
              // ===== DÜZELTME 3 BURADA =====
              validator: (value) {
                if (_currentStep == SifirlamaAdimi.sifreGir) {
                  if (value == null || value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır.';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _yeniSifreTekrarController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
              // ===== DÜZELTME 4 BURADA =====
              validator: (value) {
                if (_currentStep == SifirlamaAdimi.sifreGir) {
                  if (value != _yeniSifreController.text) {
                    return 'Şifreler uyuşmuyor.';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      );
    }
  }