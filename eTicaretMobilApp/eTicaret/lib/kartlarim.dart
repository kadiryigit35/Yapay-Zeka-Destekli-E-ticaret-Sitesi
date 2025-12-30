import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart';
import 'api_config.dart';

class CardsService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<CreditCard>> getUserCards(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user/cards/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<CreditCard>.from(data['cards'].map((x) => CreditCard.fromJson(x)));
      } else {
        throw Exception('Kartlar yüklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<bool> addCard(String userId, CreditCard card) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/user/cards/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(card.toJson()),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateCard(String userId, int cardId, CreditCard card) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/user/cards/$userId/$cardId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(card.toJson()),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteCard(String userId, int cardId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/user/cards/$userId/$cardId'));
    return response.statusCode == 200;
  }
}

class CardsPage extends StatefulWidget {
  final String userId;
  const CardsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CardsPageState createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late Future<List<CreditCard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _cardsFuture = CardsService.getUserCards(widget.userId);
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = CardsService.getUserCards(widget.userId);
    });
  }

  void _showAddEditDialog({CreditCard? card}) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditCardDialog(
        userId: widget.userId,
        card: card,
        onSuccess: _refreshCards,
      ),
    );
  }

  Future<void> _deleteCard(int cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kartı Sil'),
        content: Text('Bu kartı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CardsService.deleteCard(widget.userId, cardId);
        _refreshCards();
      } catch (e) {
        // Hata yönetimi
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıtlı Kartlarım')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<CreditCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Kayıtlı kartınız bulunmuyor.'));
          }
          final cards = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (ctx, index) {
              final card = cards[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.credit_card),
                  title: Text(card.kartSahibi),
                  subtitle: Text('**** **** **** ${card.kartNumarasi.substring(card.kartNumarasi.length - 4)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit), onPressed: () => _showAddEditDialog(card: card)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCard(card.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddEditCardDialog extends StatefulWidget {
  final String userId;
  final CreditCard? card;
  final VoidCallback onSuccess;

  const AddEditCardDialog({Key? key, required this.userId, this.card, required this.onSuccess}) : super(key: key);

  @override
  _AddEditCardDialogState createState() => _AddEditCardDialogState();
}

class _AddEditCardDialogState extends State<AddEditCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kartSahibiController = TextEditingController();
  final _kartNumarasiController = TextEditingController();
  final _sktController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _kartSahibiController.text = widget.card!.kartSahibi;
      _kartNumarasiController.text = widget.card!.kartNumarasi;
      _sktController.text = widget.card!.skt;
      _cvvController.text = widget.card!.cvv;
    }
  }

  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final card = CreditCard(
        id: widget.card?.id ?? 0,
        kartSahibi: _kartSahibiController.text,
        kartNumarasi: _kartNumarasiController.text,
        skt: _sktController.text,
        cvv: _cvvController.text,
      );
      try {
        if (widget.card == null) {
          await CardsService.addCard(widget.userId, card);
        } else {
          await CardsService.updateCard(widget.userId, widget.card!.id, card);
        }
        widget.onSuccess();
        Navigator.of(context).pop();
      } catch (e) {
        // Hata
      }
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.card == null ? 'Yeni Kart Ekle' : 'Kartı Düzenle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _kartSahibiController, decoration: InputDecoration(labelText: 'Kart Sahibi'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              TextFormField(controller: _kartNumarasiController, decoration: InputDecoration(labelText: 'Kart Numarası'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)], validator: (v) => v!.length != 16 ? '16 haneli olmalı' : null),
              TextFormField(controller: _sktController, decoration: InputDecoration(labelText: 'SKT (AA/YY)'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              TextFormField(controller: _cvvController, decoration: InputDecoration(labelText: 'CVV'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)], validator: (v) => v!.length != 3 ? '3 haneli olmalı' : null),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('İptal')),
        ElevatedButton(onPressed: _isLoading ? null : _saveCard, child: Text('Kaydet')),
      ],
    );
  }
}
