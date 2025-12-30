import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}

// GÜNCELLENMİŞ VE TAMAMLANMIŞ TEMA TANIMLARI
class AppThemes {
  // Açık Tema Tanımı (Mavi-Beyaz Paleti)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Hafif kirli beyaz
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    cardColor: Colors.white,
    // Profil sayfası ikonlarının rengini belirler
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.blue,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue, // Seçili eleman Mavi
      unselectedItemColor: Colors.grey[600], // Seçili olmayanlar Koyu Gri
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      background: Color(0xFFF5F5F5),
      // Fiyat gibi önemli metinler için
      tertiary: Colors.red,
    ),
  );

  // Koyu Tema Tanımı (Mavi-Koyu Gri Paleti)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212), // Materyal Tasarım Koyu Gri
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    cardColor: const Color(0xFF1E1E1E),
    // Profil sayfası ikonlarının koyu temada görünür olmasını sağlar
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70, // İkonlar açık gri
    ),
    // Navigasyon barı arka planı ve seçili eleman rengi ayrıldı
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E), // Arka plan Koyu Gri
      selectedItemColor: Colors.blue,           // Seçili eleman Mavi
      unselectedItemColor: Colors.grey[400],    // Seçili olmayanlar görünür Gri
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      // Fiyat gibi önemli metinler için
      tertiary: Colors.lightBlueAccent,
    ),
  );
}
