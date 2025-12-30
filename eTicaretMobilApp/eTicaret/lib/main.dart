import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'api_config.dart';
// Yönetim paneli ve diğer sayfaların importları
import 'admin_home_page.dart';
import 'sifre_sifirlama_page.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'satici_profil_page.dart';
import 'kai_chat_page.dart';
import 'theme_provider.dart';
import 'providers/cart_provider.dart';
import 'productspage.dart';
import 'siparislerim.dart';
import 'favorilerim.dart';
import 'adreslerim.dart';
import 'kartlarim.dart';
import 'profildüzenle.dart';
import 'sepetim.dart';
import 'satici_profil_duzenle.dart';
import 'satici_urun_yonetimi.dart';
import 'satici_siparis_yonetimi.dart';
import 'kategori_yonetimi_page.dart';

// Geliştirme ortamında SSL sertifika hatalarını atlamak için
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'eTicaret',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: AuthCheck(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ... AuthCheck, AuthService, ApiService class'ları aynı kalabilir ...

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndRedirect();
  }

  Future<void> _checkLoginAndRedirect() async {
    await Future.delayed(Duration.zero);
    User? user = await AuthService.getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      if (user.roles.contains('admin') || user.roles.contains('satici')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomePage(user: user)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> login({
    required String kullaniciAdi,
    required String sifre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'KullaniciAdi': kullaniciAdi, 'Sifre': sifre}),
      );
      final data = json.decode(response.body);

      // YENİ: BAN KONTROLÜ
      if (response.statusCode == 403) { // 403 Forbidden
        return {'success': false, 'error': data['message'] ?? 'Hesabınız askıya alınmıştır.'};
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(data['user']));
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('is_logged_in', true);
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Giriş hatası'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String adi,
    required String soyadi,
    required String email,
    required String kullaniciAdi,
    required String sifre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Adi': adi,
          'Soyadi': soyadi,
          'Email': email,
          'KullaniciAdi': kullaniciAdi,
          'Sifre': sifre,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Kayıt hatası'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('auth_token');
    await prefs.setBool('is_logged_in', false);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn) {
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
    }
    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/urunler'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('API çağrısı başarısız: ${response.statusCode}');
    }
  }
  static Future<bool> postRating({
    required String token,
    required int productId,
    required int rating,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/urunler/$productId/puanla'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'Deger': rating}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Puan gönderilemedi: $e');
      return false;
    }
  }
// main.dart -> ApiService Sınıfı

  // main.dart -> ApiService Sınıfı

  // YENİ
  static Future<List<dynamic>> getUserComments(String token, String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/kullanici-yorumlari/$username'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Yorumlar yüklenemedi');
  }

  // YENİ
  static Future<bool> ignoreReport(String token, int reportId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/sikayet-yoksay/$reportId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
  static Future<bool> rateSeller({
    required String token,
    required int saticiId,
    required int rating,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/saticilar/$saticiId/puanla'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'Deger': rating}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Satıcı puanlanamadı: $e');
      return false;
    }
  }
  static Future<List<dynamic>> getAdminUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/kullanicilar'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Kullanıcılar yüklenemedi: ${response.statusCode}');
  }

  static Future<List<dynamic>> getReportedComments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/sikayetler'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Şikayetler yüklenemedi: ${response.statusCode}');
  }
  static Future<bool> banUser({
    required String token,
    required String userId,
    required String reason,
    int? days,
    bool deleteComments = false, // Bu genel listeden banlama için kalabilir.
    int? deleteCommentId, // Bu şikayetten banlama için eklendi.
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/banla'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'KullaniciId': userId,
        'SureGun': days,
        'Sebep': reason,
        'YorumlariSil': deleteComments,
        'SilinecekYorumId': deleteCommentId, // Yeni parametre
      }),
    );
    return response.statusCode == 200;
  }


  static Future<bool> unbanUser(String token, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/ban-kaldir/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> reportComment({
    required String token,
    required int yorumId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/yorumlar/$yorumId/sikayet-et'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Yorum şikayet edilemedi: $e');
      return false;
    }
  }

  static Future<String?> uploadImage(String token, File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/dosya/yukle'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return json.decode(responseBody)['fileName'];
    } else {
      return null;
    }
  }

  static Future<bool> createProduct(String token, Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/satici/urunler'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(product.toJson()),
    );
    return response.statusCode == 200;
  }
  static Future<List<Product>> getPopularProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/urunler/populer'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Popüler ürünler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<bool> logOrderToCsv({
    required String userId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/siparis/csv-kaydet'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'UserId': userId,
          'Urunler': products,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('CSV loglama hatası: $e');
      return false;
    }
  }

  static Future<List<Product>> getRecommendedProducts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/urunler/onerilen/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Önerilen ürünler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<Map<String, dynamic>> sifreSifirlamaKodGonder(String email) async {
    try {
      final url = Uri.parse('$baseUrl/api/hesap/sifre-sifirlama/kod-gonder');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Email': email}),
      ).timeout(const Duration(seconds: 15));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      print('!!! HATA YAKALANDI: $e');
      return {'statusCode': 500, 'body': {'Message': 'İstek gönderilirken bir hata oluştu: $e'}};
    }
  }

  static Future<Map<String, dynamic>> sifreSifirlamaKodDogrula(String email, String kod) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/hesap/sifre-sifirlama/kod-dogrula'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'Email': email, 'GirilenKod': kod}),
    );
    return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
  }

  static Future<Map<String, dynamic>> sifreSifirlamaYeniSifre(String email, String kod, String yeniSifre) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/hesap/sifre-sifirlama/yeni-sifre'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'Email': email, 'GirilenKod': kod, 'YeniSifre': yeniSifre}),
    );
    return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
  }

  static Future<Product> getProductDetails(int productId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/urunler/$productId'));
      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Ürün detayı yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<bool> postComment({
    required int productId,
    required String kullaniciAdi,
    required String icerik,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/urunler/$productId/yorumlar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'KullaniciAdi': kullaniciAdi,
          'Icerik': icerik,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Yorum gönderilemedi: $e');
    }
  }

  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/kategoriler'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Kategoriler yüklenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<List<Satici>> getSellers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/saticilar'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Satici.fromJson(json)).toList();
      } else {
        throw Exception('Satıcılar yüklenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<List<Satici>> getSellersByCategoryId(int kategoriId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/kategoriler/$kategoriId/saticilar'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Satici.fromJson(json)).toList();
      } else {
        throw Exception('Kategoriye ait satıcılar yüklenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<List<Product>> getFilteredProducts({
    List<int>? kategoriIds,
    double? minFiyat,
    double? maxFiyat,
    List<int>? saticiIds,
    String? searchQuery,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (kategoriIds != null && kategoriIds.isNotEmpty) {
        queryParams['kategoriIds'] = kategoriIds.join(',');
      }
      if (saticiIds != null && saticiIds.isNotEmpty) {
        queryParams['saticiIds'] = saticiIds.join(',');
      }
      if (minFiyat != null) queryParams['minFiyat'] = minFiyat.toString();
      if (maxFiyat != null) queryParams['maxFiyat'] = maxFiyat.toString();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['searchQuery'] = searchQuery;
      }

      final uri = Uri.parse('$baseUrl/api/urunler')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception(
            'Filtrelenmiş ürünler yüklenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<Map<String, dynamic>> getSellerProfileWithProducts(int sellerId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/saticilar/$sellerId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Satıcı profili yüklenemedi: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getSellerProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/satici/profil'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Satıcı profili yüklenemedi: ${response.statusCode}');
  }

  static Future<bool> updateSellerProfile(String token, String adi, String hakkinda, {String? resim}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/satici/profil'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'Adi': adi,
        'Hakkinda': hakkinda,
        'Resim': resim,
      }),
    );
    return response.statusCode == 200;
  }
  static Future<List<Product>> getSellerProducts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/satici/urunler'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Satıcı ürünleri yüklenemedi: ${response.statusCode}');
  }

  static Future<bool> updateProduct(String token, Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/satici/urunler/${product.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(product.toJson()),
    );
    return response.statusCode == 200;
  }
  // YENİ EKLENDİ: Ürün silme fonksiyonu
  static Future<bool> deleteProduct(String token, int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/satici/urunler/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
  static Future<List<dynamic>> getSellerOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/satici/siparisler'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Siparişler yüklenemedi: ${response.statusCode}');
  }

  static Future<bool> updateOrderStatus(String token, int orderId, String newStatus) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/satici/siparisler/$orderId/durum'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'YeniDurum': newStatus}),
    );
    return response.statusCode == 200;
  }

  static Future<List<Category>> getAdminCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/kategoriler'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    }
    throw Exception('Kategoriler yüklenemedi: ${response.statusCode}');
  }

  static Future<Category> createCategory(String token, String adi, String aciklama) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/kategoriler'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'Adi': adi, 'Aciklama': aciklama}),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    }
    throw Exception('Kategori oluşturulamadı: ${response.statusCode}');
  }

  static Future<bool> updateCategory(String token, Category kategori) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/kategoriler/${kategori.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'Id': kategori.id, 'Adi': kategori.adi, 'Aciklama': kategori.aciklama}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteCategory(String token, int kategoriId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/kategoriler/$kategoriId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> sendMessageToKai(String message, List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kai/getreply'),
      headers: {'Content-Type': 'application/json'},
      // Vücut (body) güncellendi: 'message' ve 'history' gönderiliyor
      body: json.encode({
        'message': message,
        'history': history,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Kai ile iletişim kurulamadı: ${response.statusCode}');
  }
}

// --- ALIŞVERİŞ ANA SAYFASI (MÜŞTERİ ARAYÜZÜ) ---
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  User? currentUser;

  List<Product> allProducts = [];
  List<Product> recommendedProducts = [];
  List<Product> popularProducts = [];
  List<Satici> saticilar = [];

  bool isLoading = true;
  bool isRecommendationsLoading = true;
  bool arePopularsLoading = true;
  bool areSellersLoading = true;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    final userFuture = AuthService.getCurrentUser();
    final productsFuture = ApiService.getProducts();
    final popularsFuture = ApiService.getPopularProducts();
    final sellersFuture = ApiService.getSellers();

    final user = await userFuture;
    if (mounted) {
      setState(() {
        currentUser = user;
      });
      if (user != null) {
        final recommendations = await ApiService.getRecommendedProducts(user.id);
        if (mounted) setState(() => recommendedProducts = recommendations);
      }
    }
    if (mounted) setState(() => isRecommendationsLoading = false);

    final results = await Future.wait([productsFuture, popularsFuture, sellersFuture]);
    if (mounted) {
      setState(() {
        allProducts = results[0] as List<Product>;
        popularProducts = results[1] as List<Product>;
        saticilar = results[2] as List<Satici>;

        arePopularsLoading = false;
        areSellersLoading = false;
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => KaiChatPage()));
      return;
    }
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage()))
            .then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()))
            .then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        if (currentUser == null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()))
              .then((_) {
            fetchAllData();
            setState(() => _selectedIndex = 0);
          });
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(user: currentUser!)))
              .then((_) {
            fetchAllData();
            setState(() => _selectedIndex = 0);
          });
        }
        break;
    }
  }

  Widget _buildJumbotron() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SÜPER İNDİRİM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Şahane fiyatlar, sınırlı stok ürünler için hemen alışverişe başla!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage()));
                  },
                  child: Text('Tüm Ürünleri Gör'),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Image.network(
              '${ApiService.baseUrl}/Upload/kasa-monitor-orta.png',
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.computer, color: Colors.white, size: 80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSlider(String title, List<Product> productList, bool isLoading) {
    if (isLoading && productList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (productList.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: productList.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: EdgeInsets.only(right: 10),
                child: ProductCard(product: productList[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsSlider() {
    if (areSellersLoading && saticilar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (saticilar.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text("Markalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: saticilar.length,
            itemBuilder: (context, index) {
              return BrandCard(satici: saticilar[index]);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('eTicaret', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchAllData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildJumbotron()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Ürün ara...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  // onSubmitted özelliğini aşağıdaki gibi güncelleyin
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      // Ana sayfadaki arama çubuğunu temizle
                      searchController.clear();
                      // Kullanıcıyı ProductsPage'e yönlendir ve arama sorgusunu ilet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductsPage(initialSearchQuery: query),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildProductSlider("Popüler Ürünler", popularProducts, arePopularsLoading)),
            if (currentUser != null)
              SliverToBoxAdapter(child: _buildProductSlider("Senin İçin Önerdiklerimiz", recommendedProducts, isRecommendationsLoading)),
            SliverToBoxAdapter(child: _buildProductSlider("Diğer Ürünlerimiz", allProducts, isLoading)),
            SliverToBoxAdapter(child: _buildBrandsSlider()),
            SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Ürünler'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Sepet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Kai'),
        ],
      ),
    );
  }
}

// DÜZELTME: ProductCard widget'ı artık temadan renk alıyor
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({Key? key, required this.product}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: product.resim != null
                    ? Image.network(
                  '${ApiService.baseUrl}/Upload/${product.resim}',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                )
                    : Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.adi,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Text(
                      '₺${product.fiyat.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandCard extends StatelessWidget {
  final Satici satici;
  const BrandCard({Key? key, required this.satici}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = satici.resim != null && satici.resim!.isNotEmpty && satici.resim != 'default.png'
        ? '${ApiService.baseUrl}/Upload/${satici.resim}'
        : '${ApiService.baseUrl}/Upload/default.png';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SaticiProfilPage(saticiId: satici.id)),
        );
      },
      child: Container(
        width: 110,
        margin: EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                  )
                ],
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.storefront, size: 40, color: Colors.grey),
              ),
            ),
            SizedBox(height: 8),
            Text(
              satici.adi,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _kullaniciAdiController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await AuthService.login(
        kullaniciAdi: _kullaniciAdiController.text,
        sifre: _sifreController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        final User user = result['user'];
        if (user.roles.contains('admin') || user.roles.contains('satici')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => AdminHomePage(user: user)),
                (Route<dynamic> route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giriş Yap')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _kullaniciAdiController,
                decoration: InputDecoration(labelText: 'Kullanıcı Adı', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Kullanıcı adı gerekli' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sifreController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Şifre gerekli' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Giriş Yap'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage())),
                child: Text('Hesabınız yok mu? Kayıt olun'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SifreSifirlamaPage())),
                child: Text('Şifremi Unuttum'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _adiController = TextEditingController();
  final _soyadiController = TextEditingController();
  final _emailController = TextEditingController();
  final _kullaniciAdiController = TextEditingController();
  final _sifreController = TextEditingController();
  final _sifreTekrarController = TextEditingController();
  bool _isLoading = false;
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_sifreController.text != _sifreTekrarController.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Şifreler eşleşmiyor'), backgroundColor: Colors.red));
        return;
      }
      setState(() => _isLoading = true);
      final result = await AuthService.register(
        adi: _adiController.text,
        soyadi: _soyadiController.text,
        email: _emailController.text,
        kullaniciAdi: _kullaniciAdiController.text,
        sifre: _sifreController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _adiController,
                decoration: InputDecoration(labelText: 'Ad', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Ad gerekli' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _soyadiController,
                decoration: InputDecoration(labelText: 'Soyad', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Soyad gerekli' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Email gerekli' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _kullaniciAdiController,
                decoration: InputDecoration(labelText: 'Kullanıcı Adı', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Kullanıcı adı gerekli' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sifreController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Şifre gerekli' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sifreTekrarController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Şifre Tekrar', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Şifre tekrarı gerekli' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// DÜZELTME: ProfilePage widget'ı artık temadan renk alıyor
class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({Key? key, required this.user}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _currentUser;
  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthCheck()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _refreshUser() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final imageProvider = _currentUser.profilResmi != 'default.png'
        ? NetworkImage('${ApiService.baseUrl}/Upload/${_currentUser.profilResmi}')
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: imageProvider,
              onBackgroundImageError: imageProvider != null ? (_, __) {} : null,
              child: imageProvider == null ? Icon(Icons.person, size: 50) : null,
            ),
            SizedBox(height: 15),
            Text('${_currentUser.adi} ${_currentUser.soyadi}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('@${_currentUser.kullaniciAdi}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 30),
            _buildMenuOption(
              icon: Icons.shopping_bag,
              title: 'Siparişlerim',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OrdersPage(userId: _currentUser.id))),
            ),
            _buildMenuOption(
              icon: Icons.favorite,
              title: 'Favorilerim',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          FavoritesPage(username: _currentUser.kullaniciAdi))),
            ),
            _buildMenuOption(
              icon: Icons.location_on,
              title: 'Adreslerim',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddressesPage(userId: _currentUser.id))),
            ),
            _buildMenuOption(
              icon: Icons.credit_card,
              title: 'Kartlarım',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CardsPage(userId: _currentUser.id))),
            ),
            _buildMenuOption(
              icon: Icons.settings,
              title: 'Profili Düzenle',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProfileEditPage(user: _currentUser))).then((_) => _refreshUser()),
            ),
            if (_currentUser.roles.contains('satici')) ...[
              SizedBox(height: 20),
              Text('Satıcı İşlemleri',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
              SizedBox(height: 10),
              _buildMenuOption(
                icon: Icons.store_mall_directory,
                title: 'Satıcı Profilim',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SaticiProfilDuzenlePage())),
              ),
              _buildMenuOption(
                icon: Icons.store,
                title: 'Ürün Yönetimi',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SaticiUrunYonetimiPage())),
              ),
              _buildMenuOption(
                icon: Icons.assignment,
                title: 'Sipariş Yönetimi',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SaticiSiparisYonetimiPage())),
              ),
            ],
            if (_currentUser.roles.contains('admin')) ...[
              SizedBox(height: 20),
              Text('Admin İşlemleri',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              SizedBox(height: 10),
              _buildMenuOption(
                icon: Icons.category,
                title: 'Kategori Yönetimi',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => KategoriYonetimiPage())),
              ),
              _buildMenuOption(
                icon: Icons.people,
                title: 'Kullanıcı Yönetimi',
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
// main.dart dosyasının sonuna bu iki yeni sınıfı ekleyin

class AddressesService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user/addresses/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> addressList = data['addresses'];
          return addressList.map((json) => Address.fromJson(json)).toList();
        } else {
          throw Exception('Adresler sunucudan alınamadı.');
        }
      } else {
        throw Exception('Adresler yüklenemedi. Hata kodu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Adresler yüklenirken bir bağlantı hatası oluştu: $e');
    }
  }

// Yeni adres ekleme, güncelleme, silme fonksiyonları da buraya eklenebilir.
}

class CardsService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<CreditCard>> getUserCards(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user/cards/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> cardList = data['cards'];
          return cardList.map((json) => CreditCard.fromJson(json)).toList();
        } else {
          throw Exception('Kartlar sunucudan alınamadı.');
        }
      } else {
        throw Exception('Kartlar yüklenemedi. Hata kodu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kartlar yüklenirken bir bağlantı hatası oluştu: $e');
    }
  }
// Yeni kart ekleme, güncelleme, silme fonksiyonları da buraya eklenebilir.
}