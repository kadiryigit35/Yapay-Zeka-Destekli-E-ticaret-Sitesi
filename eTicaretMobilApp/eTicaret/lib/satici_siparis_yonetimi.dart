import 'package:flutter/material.dart';
import 'main.dart'; // ApiService için
import 'models.dart'; // Order modeli için

class SaticiSiparisYonetimiPage extends StatefulWidget {
  @override
  _SaticiSiparisYonetimiPageState createState() =>
      _SaticiSiparisYonetimiPageState();
}

class _SaticiSiparisYonetimiPageState extends State<SaticiSiparisYonetimiPage> {
  late Future<List<Order>> _siparislerFuture;

  // DÜZELTME: Bu liste artık C# EnumsiparisDurum.cs dosyası ile birebir aynı
  final List<String> siparisDurumlari = [
    'SiparisAlındı',
    'KargoyaVerildi',
    'TeslimEdildi',
    'İptalEdildi',
    'IadeEdildi'

  ];

  @override
  void initState() {
    super.initState();
    _siparislerFuture = _loadSiparisler();
  }

  Future<List<Order>> _loadSiparisler() async {
    String? token = await AuthService.getToken();
    if (token == null) throw Exception("Giriş yapılmamış.");

    final List<dynamic> data = await ApiService.getSellerOrders(token);
    return data.map((json) => Order.fromJson(json)).toList();
  }

  Future<void> _updateStatus(int siparisId, String yeniDurum) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception("Giriş yapılmamış.");

      bool success = await ApiService.updateOrderStatus(token, siparisId, yeniDurum);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Durum güncellendi!'), backgroundColor: Colors.green));
        setState(() {
          _siparislerFuture = _loadSiparisler(); // Listeyi yenile
        });
      } else {
        throw Exception("Durum güncellenemedi.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sipariş Yönetimi')),
      body: FutureBuilder<List<Order>>(
        future: _siparislerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Henüz siparişiniz bulunmuyor.'));
          }

          final siparisler = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _siparislerFuture = _loadSiparisler();
              });
            },
            child: ListView.builder(
              itemCount: siparisler.length,
              itemBuilder: (context, index) {
                final order = siparisler[index];
                final urunlerListesi = order.siparisKalemleri
                    .map((item) => "${item.adet}x ${item.urunAdi}")
                    .join('\n');

                return Card(
                  margin: EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sipariş No: ${order.siparisNumarasi}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Tarih: ${order.siparisTarihi.toLocal().toString().substring(0, 16)}'),
                        if (order.teslimatAdresi != null) ...[
                          Divider(),
                          Text('Teslimat: ${order.teslimatAdresi!.tamAd}', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(order.teslimatAdresi!.adres),
                          Text('${order.teslimatAdresi!.sehir} - ${order.teslimatAdresi!.telefon}'),
                        ],
                        Divider(),
                        Text('Ürünler:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(urunlerListesi),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Toplam: ₺${order.toplam.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Durum: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<String>(
                              value: order.siparisDurum,
                              items: siparisDurumlari.map((String durum) {
                                return DropdownMenuItem<String>(
                                  value: durum,
                                  child: Text(durum),
                                );
                              }).toList(),
                              onChanged: (String? yeniDeger) {
                                if (yeniDeger != null) {
                                  _updateStatus(order.id, yeniDeger);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}