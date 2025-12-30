import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart';
import 'api_config.dart';

class AddressesService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user/addresses/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Address>.from(data['addresses'].map((x) => Address.fromJson(x)));
      } else {
        throw Exception('Adresler yüklenemedi');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<bool> addAddress(String userId, Address address) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/user/addresses/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(address.toJson()),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateAddress(String userId, int addressId, Address address) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/user/addresses/$userId/$addressId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(address.toJson()),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteAddress(String userId, int addressId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/user/addresses/$userId/$addressId'));
    return response.statusCode == 200;
  }
}

class AddressesPage extends StatefulWidget {
  final String userId;
  const AddressesPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AddressesPageState createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  late Future<List<Address>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = AddressesService.getUserAddresses(widget.userId);
  }

  void _refreshAddresses() {
    setState(() {
      _addressesFuture = AddressesService.getUserAddresses(widget.userId);
    });
  }

  void _showAddEditDialog({Address? address}) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditAddressDialog(
        userId: widget.userId,
        address: address,
        onSuccess: _refreshAddresses,
      ),
    );
  }

  Future<void> _deleteAddress(int addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adresi Sil'),
        content: Text('Bu adresi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AddressesService.deleteAddress(widget.userId, addressId);
        _refreshAddresses();
      } catch (e) {
        // Hata yönetimi
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıtlı Adreslerim')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Kayıtlı adresiniz bulunmuyor.'));
          }
          final addresses = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (ctx, index) {
              final address = addresses[index];
              return Card(
                child: ListTile(
                  title: Text(address.adresBasligi),
                  subtitle: Text('${address.adres}, ${address.sehir}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit), onPressed: () => _showAddEditDialog(address: address)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAddress(address.id)),
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

class AddEditAddressDialog extends StatefulWidget {
  final String userId;
  final Address? address;
  final VoidCallback onSuccess;

  const AddEditAddressDialog({Key? key, required this.userId, this.address, required this.onSuccess}) : super(key: key);

  @override
  _AddEditAddressDialogState createState() => _AddEditAddressDialogState();
}

class _AddEditAddressDialogState extends State<AddEditAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tamAdController = TextEditingController();
  final _adresBasligiController = TextEditingController();
  final _adresController = TextEditingController();
  final _sehirController = TextEditingController();
  final _mahalleController = TextEditingController();
  final _sokakController = TextEditingController();
  final _postaKoduController = TextEditingController();
  final _telefonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _tamAdController.text = widget.address!.tamAd;
      _adresBasligiController.text = widget.address!.adresBasligi;
      _adresController.text = widget.address!.adres;
      _sehirController.text = widget.address!.sehir;
      _mahalleController.text = widget.address!.mahalle;
      _sokakController.text = widget.address!.sokak;
      _postaKoduController.text = widget.address!.postaKodu;
      _telefonController.text = widget.address!.telefon;
    }
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final address = Address(
        id: widget.address?.id ?? 0,
        tamAd: _tamAdController.text,
        adresBasligi: _adresBasligiController.text,
        adres: _adresController.text,
        sehir: _sehirController.text,
        mahalle: _mahalleController.text,
        sokak: _sokakController.text,
        postaKodu: _postaKoduController.text,
        telefon: _telefonController.text,
      );
      try {
        if (widget.address == null) {
          await AddressesService.addAddress(widget.userId, address);
        } else {
          await AddressesService.updateAddress(widget.userId, widget.address!.id, address);
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
      title: Text(widget.address == null ? 'Yeni Adres Ekle' : 'Adresi Düzenle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _adresBasligiController, decoration: InputDecoration(labelText: 'Adres Başlığı'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              TextFormField(controller: _tamAdController, decoration: InputDecoration(labelText: 'Tam Ad'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              TextFormField(controller: _adresController, decoration: InputDecoration(labelText: 'Adres'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              TextFormField(controller: _sehirController, decoration: InputDecoration(labelText: 'Şehir'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
              TextFormField(controller: _postaKoduController, decoration: InputDecoration(labelText: 'Posta Kodu')),
              TextFormField(controller: _mahalleController, decoration: InputDecoration(labelText: 'Mahalle')),
              TextFormField(controller: _sokakController, decoration: InputDecoration(labelText: 'Sokak')),
              TextFormField(controller: _telefonController, decoration: InputDecoration(labelText: 'Telefon'), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('İptal')),
        ElevatedButton(onPressed: _isLoading ? null : _saveAddress, child: Text('Kaydet')),
      ],
    );
  }
}
