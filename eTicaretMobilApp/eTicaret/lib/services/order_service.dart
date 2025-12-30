import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cart_provider.dart';
import '../models.dart';
import '../api_config.dart';

class OrderService {
  static String get baseUrl => ApiConfig.baseUrl;

  // --- SİPARİŞ OLUŞTURMA ---
  static Future<Map<String, dynamic>> createOrder({
    String? userId,
    required CartProvider cart,
    int? addressId,
    Address? newAddress,
    bool saveAddress = false,
    int? cardId,
    CreditCard? newCard,
    bool saveCard = false,
  }) async {
    // ... (Buradaki kodların aynı kalacak) ...
    // Hata yapmamak için createOrder içeriğini tekrar yazmıyorum,
    // senin attığın dosyadaki createOrder içeriği buraya gelecek.

    // Sadece kısa özet:
    if (cardId == null && newCard == null) {
      return {'success': false, 'error': 'Ödeme yöntemi seçilmedi.'};
    }
    // ... createOrder devamı ...

    // Buraya temsili olarak senin kodundaki createOrder bitişini koyuyorum:
    try {
      final orderItems = cart.items.values.map((item) => {
        'UrunId': item.product.id,
        'Adet': item.quantity,
        'Fiyat': item.product.fiyat,
      }).toList();

      final Map<String, dynamic> requestBody = {
        if (userId != null) 'UserId': userId,
        'ToplamTutar': cart.totalAmount,
        'SiparisKalemleri': orderItems,
      };

      if (newAddress != null) {
        requestBody['YeniAdres'] = {
          ...newAddress.toJson(),
          'Kaydet': saveAddress,
        };
      } else {
        requestBody['AdresId'] = addressId;
      }

      if (newCard != null) {
        requestBody['YeniKart'] = {
          'KartSahibi': newCard.kartSahibi,
          'KartNumarasi': newCard.kartNumarasi,
          'SKT': newCard.skt,
          'CVV': newCard.cvv,
          'Kaydet': saveCard,
        };
      } else {
        requestBody['KartId'] = cardId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Sipariş oluşturulurken bir hata oluştu.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }

  // --- SİPARİŞ DETAYI ---
  static Future<Order> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/orders/$orderId'));
      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      } else {
        throw Exception('Sipariş detayları yüklenemedi.');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // --- İPTAL / İADE ---
  static Future<Map<String, dynamic>> cancelOrReturnOrder(int orderId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/update-status?orderId=$orderId&userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'iadeKodu': data['iadeKodu']
        };
      } else {
        return {
          'success': false,
          'message': data['Message'] ?? 'İşlem başarısız.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // --- YENİ EKLENEN: KULLANICI SİPARİŞLERİNİ GETİR ---
  // (Bunu siparislerim.dart dosyasından buraya taşıdık)
  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/orders/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> ordersData = data['orders'];
        return ordersData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Siparişler yüklenirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
}