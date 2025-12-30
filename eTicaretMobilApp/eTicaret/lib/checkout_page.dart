import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'models.dart';
import 'providers/cart_provider.dart';
import 'services/order_service.dart'; // << HATA ALINAN KISIM İÇİN GEREKLİ IMPORT
import 'order_success_page.dart';

// Gerekli Enum tanımlamaları
enum AddressMethod { saved, newAddress }
enum PaymentMethod { saved, newCard }

class CheckoutPage extends StatefulWidget {
  final User? user; // User nesnesini opsiyonel (nullable) yaptık
  const CheckoutPage({Key? key, this.user}) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // FORM KEY'LERİ
  final _addressFormKey = GlobalKey<FormState>();
  final _cardFormKey = GlobalKey<FormState>();

  // ADRES KONTROLÖRLERİ
  final _fullNameController = TextEditingController();
  final _addressTitleController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();

  // KART KONTROLÖRLERİ
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // DURUM DEĞİŞKENLERİ
  List<Address> _addresses = [];
  List<CreditCard> _cards = [];
  bool _isLoading = true;
  String? _errorMessage;

  // SEÇİM DEĞİŞKENLERİ
  int? _selectedAddressId;
  int? _selectedCardId;
  AddressMethod _addressMethod = AddressMethod.saved;
  PaymentMethod _paymentMethod = PaymentMethod.saved;
  bool _saveAddress = false;
  bool _saveCard = false;


  @override
  void initState() {
    super.initState();
    // Kullanıcı null (misafir) değilse verileri yükle
    if (widget.user != null) {
      _loadCheckoutData();
    } else {
      // Misafir kullanıcı için başlangıç durumunu ayarla
      setState(() {
        _isLoading = false;
        _addressMethod = AddressMethod.newAddress;
        _paymentMethod = PaymentMethod.newCard;
      });
    }
  }

  Future<void> _loadCheckoutData() async {
    // Giriş yapmış kullanıcı yoksa fonksiyondan çık
    if (widget.user == null) return;
    try {
      final loadedAddresses = await AddressesService.getUserAddresses(widget.user!.id);
      final loadedCards = await CardsService.getUserCards(widget.user!.id);
      if (!mounted) return;
      setState(() {
        _addresses = loadedAddresses;
        _cards = loadedCards;

        if (_addresses.isNotEmpty) {
          _selectedAddressId = _addresses.first.id;
          _addressMethod = AddressMethod.saved;
        } else {
          _addressMethod = AddressMethod.newAddress;
        }

        if (_cards.isNotEmpty) {
          _selectedCardId = _cards.first.id;
          _paymentMethod = PaymentMethod.saved;
        } else {
          _paymentMethod = PaymentMethod.newCard;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    // Adres ve Kart kontrolleri
    if (_addressMethod == AddressMethod.saved && _selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen bir teslimat adresi seçin.'), backgroundColor: Colors.red));
      return;
    }
    if (_addressMethod == AddressMethod.newAddress && !_addressFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen adres bilgilerini eksiksiz girin.'), backgroundColor: Colors.red));
      return;
    }
    if (_paymentMethod == PaymentMethod.saved && _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen kayıtlı bir kart seçin.'), backgroundColor: Colors.red));
      return;
    }
    if (_paymentMethod == PaymentMethod.newCard && !_cardFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen kart bilgilerini eksiksiz girin.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);

    Address? newAddress;
    if (_addressMethod == AddressMethod.newAddress) {
      newAddress = Address(
          id: 0,
          tamAd: _fullNameController.text,
          adresBasligi: _addressTitleController.text,
          adres: _addressLineController.text,
          sehir: _cityController.text,
          mahalle: _districtController.text,
          sokak: "",
          postaKodu: "",
          telefon: _phoneController.text
      );
    }
    CreditCard? newCard;
    if (_paymentMethod == PaymentMethod.newCard) {
      newCard = CreditCard(
          id: 0,
          kartSahibi: _cardHolderController.text,
          kartNumarasi: _cardNumberController.text,
          skt: _expiryDateController.text,
          cvv: _cvvController.text
      );
    }

    final result = await OrderService.createOrder(
      userId: widget.user?.id, // userId'yi opsiyonel olarak gönder
      cart: cart,
      addressId: _addressMethod == AddressMethod.saved ? _selectedAddressId : null,
      newAddress: newAddress,
      saveAddress: widget.user != null && _saveAddress, // Misafir ise kaydetme
      cardId: _paymentMethod == PaymentMethod.saved ? _selectedCardId : null,
      newCard: newCard,
      saveCard: widget.user != null && _saveCard, // Misafir ise kaydetme
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      // CSV loglama sadece giriş yapmış kullanıcılar için çalışsın
      if (widget.user != null) {
        try {
          final productsForCsv = cart.items.values.map((item) => {
            'UrunId': item.product.id,
            'Adet': item.quantity,
          }).toList();
          ApiService.logOrderToCsv(userId: widget.user!.id, products: productsForCsv);
        } catch (e) {
          print("CSV'ye yazma hatası: $e");
        }
      }

      cart.clearCart();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => OrderSuccessPage(orderData: result['data'])),
            (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Siparişi Tamamla')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TESLİMAT ADRESİ BÖLÜMÜ
            _buildSectionTitle('Teslimat Adresi'),
            // Sadece giriş yapmış ve adresi olan kullanıcılar için sekmeleri göster
            if (widget.user != null && _addresses.isNotEmpty)
              SegmentedButton<AddressMethod>(
                segments: const [
                  ButtonSegment(value: AddressMethod.saved, label: Text('Kayıtlı Adresler')),
                  ButtonSegment(value: AddressMethod.newAddress, label: Text('Yeni Adres')),
                ],
                selected: {_addressMethod},
                onSelectionChanged: (s) => setState(() => _addressMethod = s.first),
              ),
            SizedBox(height: 16),
            if (_addressMethod == AddressMethod.saved)
              _buildSavedAddressSection()
            else
              _buildNewAddressForm(),
            SizedBox(height: 24),

            // ÖDEME YÖNTEMİ BÖLÜMÜ
            _buildSectionTitle('Ödeme Yöntemi'),
            // Sadece giriş yapmış ve kartı olan kullanıcılar için sekmeleri göster
            if (widget.user != null && _cards.isNotEmpty)
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(value: PaymentMethod.saved, label: Text('Kayıtlı Kartlarım')),
                  ButtonSegment(value: PaymentMethod.newCard, label: Text('Yeni Kart')),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
              ),
            SizedBox(height: 16),
            if (_paymentMethod == PaymentMethod.saved)
              _buildSavedCardsSection()
            else
              _buildNewCardForm(),
            SizedBox(height: 24),

            // SİPARİŞ ÖZETİ BÖLÜMÜ
            _buildSectionTitle('Sipariş Özeti'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...cart.items.values.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.quantity}x ${item.product.adi}', overflow: TextOverflow.ellipsis)),
                          Text('₺${(item.product.fiyat * item.quantity).toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                    Divider(height: 20, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Toplam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₺${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: _isLoading ? SizedBox.shrink() : Icon(Icons.shield_outlined),
          onPressed: _isLoading ? null : _placeOrder,
          label: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Ödemeyi Tamamla'),
          style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(fontSize: 16)
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METOTLARI ---

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _buildSavedAddressSection() {
    if (_addresses.isEmpty) return Text('Kayıtlı adresiniz bulunmuyor.');
    return Column(
      children: _addresses.map((addr) => Card(
        child: RadioListTile<int>(
          title: Text(addr.adresBasligi),
          subtitle: Text('${addr.adres}, ${addr.sehir}'),
          value: addr.id,
          groupValue: _selectedAddressId,
          onChanged: (v) => setState(() => _selectedAddressId = v),
        ),
      )).toList(),
    );
  }

  Widget _buildNewAddressForm() {
    return Form(
      key: _addressFormKey,
      child: Column(
        children: [
          TextFormField(controller: _fullNameController, decoration: InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          SizedBox(height: 12),
          TextFormField(controller: _addressTitleController, decoration: InputDecoration(labelText: 'Adres Başlığı (Ev, İş vb.)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          SizedBox(height: 12),
          TextFormField(controller: _addressLineController, decoration: InputDecoration(labelText: 'Adres Satırı', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _cityController, decoration: InputDecoration(labelText: 'Şehir', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null)),
            SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _districtController, decoration: InputDecoration(labelText: 'İlçe/Mahalle', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null)),
          ]),
          SizedBox(height: 12),
          TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: 'Telefon', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          // Sadece giriş yapmış kullanıcılar için kaydetme seçeneğini göster
          if (widget.user != null)
            CheckboxListTile(
              title: Text("Adresimi sonraki alışverişler için kaydet"),
              value: _saveAddress,
              onChanged: (val) => setState(() => _saveAddress = val!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildSavedCardsSection() {
    if (_cards.isEmpty) return Text('Kayıtlı kartınız bulunmuyor.');
    return Column(
      children: _cards.map((card) => Card(
        child: RadioListTile<int>(
          title: Text(card.kartSahibi),
          subtitle: Text('**** **** **** ${card.kartNumarasi.substring(card.kartNumarasi.length - 4)}'),
          value: card.id,
          groupValue: _selectedCardId,
          onChanged: (v) => setState(() => _selectedCardId = v),
        ),
      )).toList(),
    );
  }

  Widget _buildNewCardForm() {
    return Form(
      key: _cardFormKey,
      child: Column(
        children: [
          TextFormField(controller: _cardHolderController, decoration: InputDecoration(labelText: 'Kart Üzerindeki İsim', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          SizedBox(height: 12),
          TextFormField(controller: _cardNumberController, decoration: InputDecoration(labelText: 'Kart Numarası', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _expiryDateController, decoration: InputDecoration(labelText: 'SKT (AA/YY)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Zorunlu' : null)),
            SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _cvvController, decoration: InputDecoration(labelText: 'CVV', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Zorunlu' : null)),
          ]),
          // Sadece giriş yapmış kullanıcılar için kaydetme seçeneğini göster
          if (widget.user != null)
            CheckboxListTile(
              title: Text("Kartımı sonraki alışverişler için kaydet"),
              value: _saveCard,
              onChanged: (val) => setState(() => _saveCard = val!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}