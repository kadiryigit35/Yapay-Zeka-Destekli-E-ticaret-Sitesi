// yonetim_page.dart

import 'package:flutter/material.dart';
import 'main.dart'; // ApiService ve AuthService için

class YonetimPage extends StatefulWidget {
  const YonetimPage({Key? key}) : super(key: key);

  @override
  _YonetimPageState createState() => _YonetimPageState();
}

class _YonetimPageState extends State<YonetimPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _kullaniciListesiKey = GlobalKey<_KullaniciListesiWidgetState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
          Tab(icon: Icon(Icons.flag), text: 'Şikayetler'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          KullaniciListesiWidget(key: _kullaniciListesiKey),
          SikayetListesiWidget(
            tabController: _tabController,
            onUserBanned: () {
              _kullaniciListesiKey.currentState?.refreshUsers();
            },
          ),
        ],
      ),
    );
  }
}

// --- Kullanıcıları Listeleyen Widget ---
class KullaniciListesiWidget extends StatefulWidget {
  const KullaniciListesiWidget({Key? key}) : super(key: key);

  @override
  _KullaniciListesiWidgetState createState() => _KullaniciListesiWidgetState();
}

class _KullaniciListesiWidgetState extends State<KullaniciListesiWidget> {
  late Future<List<dynamic>> _kullanicilarFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final token = await AuthService.getToken();
    if (token != null && mounted) {
      setState(() {
        _kullanicilarFuture = ApiService.getAdminUsers(token);
      });
    }
  }

  void refreshUsers() {
    _loadUsers();
  }

  Future<void> _unbanUser(String userId, String username) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yasağı Kaldır'),
        content: Text('$username kullanıcısının yasağını kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(child: Text('İptal'), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: Text('Onayla'), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final token = await AuthService.getToken();
      if (token == null) return;
      bool success = await ApiService.unbanUser(token, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Yasak başarıyla kaldırıldı.' : 'İşlem başarısız oldu.')),
      );
      if (success) _loadUsers();
    }
  }

  // GÜNCELLENDİ: Ban diyalogundan "Tüm yorumları sil" kaldırıldı
  Future<void> _showBanDialog(Map<String, dynamic> user, {Function? onBanned}) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final _reasonController = TextEditingController();
    final _durationController = TextEditingController();
    // Yorum silme checkbox'ı kaldırıldığı için state değişkeni de kaldırıldı.

    bool? banConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${user['KullaniciAdi']} kullanıcısını yasakla'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _reasonController, decoration: InputDecoration(labelText: 'Yasaklama Nedeni*')),
              SizedBox(height: 8),
              TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Süre (Gün)', hintText: 'Kalıcı için boş bırakın')),
              // "Tüm yorumları sil" checkbox'ı buradan kaldırıldı.
            ],
          ),
        ),
        actions: [
          TextButton(child: Text('İptal'), onPressed: () => Navigator.of(ctx).pop(false)),
          ElevatedButton(
            child: Text('Yasakla'),
            onPressed: () async {
              if (_reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('Neden belirtmelisiniz!'), backgroundColor: Colors.red));
                return;
              }
              bool success = await ApiService.banUser(
                token: token,
                userId: user['Id'],
                days: _durationController.text.isNotEmpty ? int.tryParse(_durationController.text) : null,
                reason: _reasonController.text,
                // Yorum silme parametreleri gönderilmiyor
              );
              ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text(success ? 'Kullanıcı yasaklandı.' : 'İşlem başarısız.')));
              Navigator.of(ctx).pop(success);
            },
          ),
        ],
      ),
    );

    if (banConfirmed ?? false) {
      _loadUsers();
      onBanned?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _kullanicilarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Kullanıcılar yüklenemedi: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Yönetilecek kullanıcı bulunamadı.'));

        final kullanicilar = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _loadUsers,
          child: ListView.builder(
            itemCount: kullanicilar.length,
            itemBuilder: (context, index) {
              final user = kullanicilar[index];
              final isBanned = user['BanliMi'] ?? false;
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text(user['KullaniciAdi'] ?? 'İsimsiz'),
                subtitle: Text(user['Email'] ?? 'E-posta yok'),
                trailing: ElevatedButton(
                  child: Text(isBanned ? 'Yasağı Kaldır' : 'Yasakla'),
                  style: ElevatedButton.styleFrom(backgroundColor: isBanned ? Colors.green : Colors.red),
                  onPressed: () => isBanned ? _unbanUser(user['Id'], user['KullaniciAdi']) : _showBanDialog(user),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- Şikayetleri Listeleyen Widget ---
class SikayetListesiWidget extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onUserBanned;
  const SikayetListesiWidget({Key? key, required this.tabController, required this.onUserBanned}) : super(key: key);

  @override
  _SikayetListesiWidgetState createState() => _SikayetListesiWidgetState();
}

class _SikayetListesiWidgetState extends State<SikayetListesiWidget> {
  late Future<List<dynamic>> _sikayetlerFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final token = await AuthService.getToken();
    if (token != null && mounted) {
      setState(() {
        _sikayetlerFuture = ApiService.getReportedComments(token);
      });
    }
  }

  Future<void> _ignoreReport(int reportId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    bool success = await ApiService.ignoreReport(token, reportId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Şikayet yoksayıldı.' : 'İşlem başarısız oldu.')),
    );
    if (success) _loadReports();
  }

  // GÜNCELLENDİ: Ban diyalogu artık "Şikayet edilen yorumu sil" seçeneği sunuyor.
  Future<void> _showBanDialogFromReport(Map<String, dynamic> report) async {
    final user = {"Id": report['YorumuYapanKullaniciId'], "KullaniciAdi": report['YorumuYapanKullanici']};
    final token = await AuthService.getToken();
    if (token == null || user['Id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kullanıcı ID bulunamadı!')));
      return;
    }

    final _reasonController = TextEditingController();
    final _durationController = TextEditingController();
    bool _deleteReportedComment = false; // State değişkeni güncellendi

    bool? banConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${user['KullaniciAdi']} kullanıcısını yasakla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: _reasonController, decoration: InputDecoration(labelText: 'Yasaklama Nedeni*')),
                SizedBox(height: 8),
                TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Süre (Gün)', hintText: 'Kalıcı için boş bırakın')),
                CheckboxListTile(
                  title: Text('Şikayet edilen yorumu sil'), // Checkbox metni güncellendi
                  value: _deleteReportedComment,
                  onChanged: (val) => setDialogState(() => _deleteReportedComment = val!),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: Text('İptal'), onPressed: () => Navigator.of(ctx).pop(false)),
            ElevatedButton(
              child: Text('Yasakla'),
              onPressed: () async {
                if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('Neden belirtmelisiniz!'), backgroundColor: Colors.red));
                  return;
                }
                bool success = await ApiService.banUser(
                  token: token,
                  userId: user['Id'],
                  days: _durationController.text.isNotEmpty ? int.tryParse(_durationController.text) : null,
                  reason: _reasonController.text,
                  deleteCommentId: _deleteReportedComment ? report['YorumId'] : null, // deleteCommentId gönderiliyor
                );
                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text(success ? 'Kullanıcı yasaklandı.' : 'İşlem başarısız.')));
                Navigator.of(ctx).pop(success);
              },
            ),
          ],
        ),
      ),
    );

    if (banConfirmed ?? false) {
      _loadReports();
      widget.onUserBanned();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _sikayetlerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Şikayetler yüklenemedi: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Şikayet bulunamadı.'));

        final sikayetler = snapshot.data!.where((r) => r['IslemYapildiMi'] == false).toList();
        if (sikayetler.isEmpty) return Center(child: Text('Bekleyen şikayet bulunamadı.'));

        return RefreshIndicator(
          onRefresh: _loadReports,
          child: ListView.builder(
            itemCount: sikayetler.length,
            itemBuilder: (context, index) {
              final report = sikayetler[index];
              return Card(
                child: ListTile(
                  title: Text('"${report['YorumIcerik']}"'),
                  subtitle: Text('Yapan: ${report['YorumuYapanKullanici']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'ignore') {
                        _ignoreReport(report['SikayetId']);
                      } else if (value == 'inspect') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => KullaniciYorumlariSayfasi(kullaniciAdi: report['YorumuYapanKullanici'])));
                      } else if (value == 'ban') {
                        _showBanDialogFromReport(report);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(value: 'inspect', child: Text('Yorumları Gör')),
                      const PopupMenuItem<String>(value: 'ignore', child: Text('Yoksay')),
                      const PopupMenuItem<String>(value: 'ban', child: Text('Kullanıcıyı Yasakla', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ... KullaniciYorumlariSayfasi widget'ı aynı kalabilir ...
class KullaniciYorumlariSayfasi extends StatelessWidget {
  final String kullaniciAdi;
  const KullaniciYorumlariSayfasi({Key? key, required this.kullaniciAdi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$kullaniciAdi Yorumları')),
      body: FutureBuilder<List<dynamic>>(
        future: () async {
          final token = await AuthService.getToken();
          if (token == null) throw Exception('Yetkilendirme token bulunamadı.');
          return ApiService.getUserComments(token, kullaniciAdi);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Bu kullanıcının yorumu bulunamadı.'));

          final yorumlar = snapshot.data!;
          return ListView.builder(
            itemCount: yorumlar.length,
            itemBuilder: (context, index) {
              final yorum = yorumlar[index];
              return ListTile(
                title: Text(yorum['Icerik']),
                subtitle: Text(DateTime.parse(yorum['Tarih']).toLocal().toString().substring(0, 16)),
              );
            },
          );
        },
      ),
    );
  }
}