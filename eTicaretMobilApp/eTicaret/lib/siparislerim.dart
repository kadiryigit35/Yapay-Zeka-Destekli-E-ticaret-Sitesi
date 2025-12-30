import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // Artık burada direkt http kullanmıyoruz, servis kullanıyoruz
// import 'dart:convert';
import 'services/order_service.dart'; // Doğru servisi import et
import 'models.dart'; // Ana model dosyasını import et (Order modeli için)

// --- DİKKAT: BURADAKİ "class Order { ... }" KISMINI SİLDİK ---
// --- DİKKAT: BURADAKİ "class OrdersService { ... }" KISMINI SİLDİK ---

class OrdersPage extends StatefulWidget {
  final String userId;

  const OrdersPage({Key? key, required this.userId}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      // Düzeltme: OrdersService (Çoğul) yerine OrderService (Tekil) kullanıyoruz
      final loadedOrders = await OrderService.getUserOrders(widget.userId);
      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Siparişler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) { // "SiparisAlındı" gibi gelebilir, case-insensitive bakalım veya direkt string eşleşmesi
      case 'tamamlandı':
      case 'teslimedildi': // Enum string karşılığı
        return Colors.green;
      case 'kargoda':
      case 'kargoyaverildi':
        return Colors.blue;
      case 'hazırlanıyor':
      case 'siparisalındı':
        return Colors.orange;
      case 'iptal edildi':
      case 'i̇ptaledildi': // Türkçe karakter sorunu olmaması için
      case 'iptaledildi':
        return Colors.red;
      case 'iadeedildi':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    // Yukarıdaki mantığın aynısı
    String s = status.toLowerCase();
    if (s.contains('teslim')) return Icons.check_circle;
    if (s.contains('kargo')) return Icons.local_shipping;
    if (s.contains('siparis') || s.contains('hazır')) return Icons.hourglass_empty;
    if (s.contains('iptal')) return Icons.cancel;
    if (s.contains('iade')) return Icons.assignment_return;
    return Icons.info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Siparişlerim'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz siparişiniz bulunmuyor',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Alışverişe Başla'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadOrders,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sipariş #${order.siparisNumarasi}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.siparisDurum)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(order.siparisDurum),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(order.siparisDurum),
                                size: 16,
                                color: _getStatusColor(order.siparisDurum),
                              ),
                              SizedBox(width: 4),
                              Text(
                                order.siparisDurum,
                                style: TextStyle(
                                  color: _getStatusColor(order.siparisDurum),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          '${order.siparisTarihi.day}/${order.siparisTarihi.month}/${order.siparisTarihi.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₺${order.toplam.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // --- İPTAL / İADE BUTONU ---
                    if (order.siparisDurum == 'SiparisAlındı' ||
                        order.siparisDurum == 'KargoyaVerildi' ||
                        order.siparisDurum == 'TeslimEdildi')
                      ElevatedButton(
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('İşlem Onayı'),
                              content: Text(order.siparisDurum == 'SiparisAlındı'
                                  ? 'Siparişi iptal etmek istiyor musunuz?'
                                  : 'Ürünü iade etmek istiyor musunuz?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hayır')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Evet')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // BURADA: OrderService (Tekil) kullanıyoruz.
                            var result = await OrderService.cancelOrReturnOrder(order.id, widget.userId);

                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(result['message']),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 5),
                              ));

                              if (result['iadeKodu'] != null && result['iadeKodu'].toString().isNotEmpty) {
                                showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text("İade Kodu Oluşturuldu"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(result['message']),
                                          SizedBox(height: 10),
                                          Text(result['iadeKodu'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                        ],
                                      ),
                                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Tamam"))],
                                    )
                                );
                              }

                              loadOrders();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(result['message']),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: order.siparisDurum == 'SiparisAlındı' ? Colors.red : Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(order.siparisDurum == 'SiparisAlındı' ? 'Siparişi İptal Et' : 'İade Et'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}