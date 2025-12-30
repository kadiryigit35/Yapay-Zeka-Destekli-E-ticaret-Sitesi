import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'satici_urun_yonetimi.dart';
import 'satici_siparis_yonetimi.dart';
import 'satici_profil_duzenle.dart';
import 'kategori_yonetimi_page.dart';
import 'main.dart';
import 'theme_provider.dart';
import 'yonetim_page.dart'; // Yeni oluşturduğumuz sayfayı import ediyoruz

class AdminHomePage extends StatefulWidget {
  final User user;
  const AdminHomePage({Key? key, required this.user}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  final List<BottomNavigationBarItem> _navItems = [];
  final List<String> _pageTitles = [];

  @override
  void initState() {
    super.initState();
    _buildNavigationBasedOnRole();
  }

  void _buildNavigationBasedOnRole() {
    _pages.clear();
    _navItems.clear();
    _pageTitles.clear();

    // Admin rolüne özel menü ve sayfalar
    if (widget.user.roles.contains('admin')) {
      _pageTitles.addAll(['Kategori Yönetimi', 'Genel Yönetim']);

      _pages.add(KategoriYonetimiPage());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategoriler'));

      // Kullanıcı ve Şikayet sayfalarını içeren yeni birleşik sayfa
      _pages.add(const YonetimPage());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Yönetim'));
    }
    // Satıcı rolüne özel menü ve sayfalar
    else if (widget.user.roles.contains('satici')) {
      _pageTitles.addAll(['Ürün Yönetimi', 'Sipariş Yönetimi', 'Satıcı Profili']);

      _pages.add(SaticiUrunYonetimiPage());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Ürünler'));

      _pages.add(SaticiSiparisYonetimiPage());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Siparişler'));

      _pages.add(SaticiProfilDuzenlePage());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetki Hatası')),
        body: const Center(
          child: Text('Bu panele erişim yetkiniz bulunmamaktadır.'),
        ),
      );
    }

    return Scaffold(
      // AppBar'ı gizleyen koşulu kaldırıyoruz.
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Temayı Değiştir',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}