

import 'dart:convert';


class Satici {
  final int id;
  final String adi;
  final String? resim;
  final String? hakkinda;
  // YENİ EKLENEN ALANLAR
  final double ortalamaPuan;
  final int toplamPuanSayisi;

  Satici({
    required this.id,
    required this.adi,
    this.resim,
    this.hakkinda,
    // YENİ EKLENEN ALANLAR
    this.ortalamaPuan = 0.0,
    this.toplamPuanSayisi = 0,
  });

  factory Satici.fromJson(Map<String, dynamic> json) {
    return Satici(
      id: json['Id'],
      adi: json['Adi'] ?? '',
      resim: json['Resim'],
      hakkinda: json['Hakkinda'],
      // YENİ EKLENEN ALANLAR
      ortalamaPuan: (json['OrtalamaPuan'] ?? 0.0).toDouble(),
      toplamPuanSayisi: json['ToplamPuanSayisi'] ?? 0,
    );
  }
}
class Product {
  final int id;
  final String adi;
  final String aciklama;
  final double fiyat;
  final int stok;
  final String? resim;
  final int kategoriId;
  final int saticiId;
  final Satici? satici;
  final List<Yorum> yorumlar;
  // YENİ EKLENEN ALANLAR
  final double ortalamaPuan;
  final int toplamPuanSayisi;

  Product({
    required this.id,
    required this.adi,
    required this.aciklama,
    required this.fiyat,
    required this.stok,
    this.resim,
    required this.kategoriId,
    required this.saticiId,
    this.satici,
    this.yorumlar = const [],
    // YENİ EKLENEN ALANLAR
    this.ortalamaPuan = 0.0,
    this.toplamPuanSayisi = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var yorumlarListFromJson = json['Yorumlar'] as List?;
    List<Yorum> parsedYorumlar = yorumlarListFromJson != null
        ? yorumlarListFromJson.map((i) => Yorum.fromJson(i)).toList()
        : [];

    return Product(
      id: json['Id'],
      adi: json['Adi'] ?? '',
      aciklama: json['Aciklama'] ?? '',
      fiyat: (json['Fiyat'] ?? 0).toDouble(),
      stok: json['Stok'] ?? 0,
      resim: json['Resim'],
      kategoriId: json['kategoriId'] ?? 0,
      saticiId: json['saticiId'] ?? 0,
      satici: json['Satici'] != null ? Satici.fromJson(json['Satici']) : null,
      yorumlar: parsedYorumlar,
      // YENİ EKLENEN ALANLAR
      ortalamaPuan: (json['OrtalamaPuan'] ?? 0.0).toDouble(),
      toplamPuanSayisi: json['ToplamPuanSayisi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Adi': adi,
      'Aciklama': aciklama,
      'Fiyat': fiyat,
      'Stok': stok,
      'Resim': resim,
      'kategoriId': kategoriId,
      'saticiId': saticiId,
    };
  }
}



class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class User {
  final String id;
  final String adi;
  final String soyadi;
  final String email;
  final String kullaniciAdi;
  final String profilResmi;
  final List<String> roles;

  User({
    required this.id,
    required this.adi,
    required this.soyadi,
    required this.email,
    required this.kullaniciAdi,
    required this.profilResmi,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      email: json['email'] ?? '',
      kullaniciAdi: json['kullaniciAdi'] ?? '',
      profilResmi: json['profilResmi'] ?? 'default.png',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adi': adi,
      'soyadi': soyadi,
      'email': email,
      'kullaniciAdi': kullaniciAdi,
      'profilResmi': profilResmi,
      'roles': roles,
    };
  }
}

class Category {
  final int id;
  final String adi;
  final String aciklama;

  Category({
    required this.id,
    required this.adi,
    required this.aciklama
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['Id'],
      adi: json['Adi'] ?? '',
      aciklama: json['Aciklama'] ?? '',
    );
  }
}


class Order {
  final int id;
  final String siparisNumarasi;
  final DateTime siparisTarihi;
  final String siparisDurum;
  final double toplam;
  final List<OrderItem> siparisKalemleri;
  final Address? teslimatAdresi;

  Order({
    required this.id,
    required this.siparisNumarasi,
    required this.siparisTarihi,
    required this.siparisDurum,
    required this.toplam,
    this.siparisKalemleri = const [],
    this.teslimatAdresi,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['Id'],
      siparisNumarasi: json['SiparisNumarasi'] ?? '',
      siparisTarihi: DateTime.parse(json['SiparisTarihi']),
      siparisDurum: json['siparisDurum'] ?? '',
      toplam: (json['Toplam'] ?? 0).toDouble(),
      siparisKalemleri: json['SiparisKalemleri'] != null
          ? List<OrderItem>.from(json['SiparisKalemleri'].map((x) => OrderItem.fromJson(x)))
          : [],
      teslimatAdresi: json['TeslimatAdresi'] != null
          ? Address.fromJson(json['TeslimatAdresi'])
          : null,
    );
  }
}

class OrderItem {
  final int urunId;
  final String urunAdi;
  final int adet;
  final double fiyat;
  final String? urunResim;

  OrderItem({
    required this.urunId,
    required this.urunAdi,
    required this.adet,
    required this.fiyat,
    this.urunResim,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      urunId: json['UrunId'],
      urunAdi: json['UrunAdi'] ?? '',
      adet: json['Adet'],
      fiyat: (json['Fiyat'] ?? 0).toDouble(),
      urunResim: json['UrunResim'],
    );
  }
}

class Address {
  final int id;
  final String tamAd;
  final String adresBasligi;
  final String adres;
  final String sehir;
  final String mahalle;
  final String sokak;
  final String postaKodu;
  final String telefon;

  Address({
    required this.id,
    required this.tamAd,
    required this.adresBasligi,
    required this.adres,
    required this.sehir,
    required this.mahalle,
    required this.sokak,
    required this.postaKodu,
    required this.telefon,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['Id'],
      tamAd: json['TamAd'] ?? '',
      adresBasligi: json['AdresBasligi'] ?? '',
      adres: json['Adres'] ?? '',
      sehir: json['Sehir'] ?? '',
      mahalle: json['Mahalle'] ?? '',
      sokak: json['Sokak'] ?? '',
      postaKodu: json['PostaKodu'] ?? '',
      telefon: json['Telefon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TamAd': tamAd,
      'AdresBasligi': adresBasligi,
      'Adres': adres,
      'Sehir': sehir,
      'Mahalle': mahalle,
      'Sokak': sokak,
      'PostaKodu': postaKodu,
      'Telefon': telefon,
    };
  }
}

class CreditCard {
  final int id;
  final String kartSahibi;
  final String kartNumarasi;
  final String skt;
  final String cvv;

  CreditCard({
    required this.id,
    required this.kartSahibi,
    required this.kartNumarasi,
    required this.skt,
    required this.cvv,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['Id'],
      kartSahibi: json['KartSahibi'] ?? '',
      kartNumarasi: json['KartNumarasi'] ?? '',
      skt: json['SKT'] ?? '',
      cvv: json['CVV'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'KartSahibi': kartSahibi,
      'KartNumarasi': kartNumarasi,
      'SKT': skt,
      'CVV': cvv,
    };
  }
}

class Yorum {
  final int id;
  final String kullaniciAdi;
  final String icerik;
  final DateTime tarih;

  Yorum({
    required this.id,
    required this.kullaniciAdi,
    required this.icerik,
    required this.tarih,
  });

  factory Yorum.fromJson(Map<String, dynamic> json) {
    return Yorum(
      id: json['Id'],
      kullaniciAdi: json['KullaniciAdi'] ?? 'Anonim',
      icerik: json['Icerik'] ?? '',
      tarih: DateTime.parse(json['Tarih']),
    );
  }
}
class ChatMessage {
  final String text;
  final bool isUser;
  final List<KaiProduct> products;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.products = const [],
  });
}

class KaiProduct {
  final int id;
  final String adi;
  final String fiyat;
  final String? resim;

  KaiProduct({
    required this.id,
    required this.adi,
    required this.fiyat,
    this.resim,
  });

  factory KaiProduct.fromJson(Map<String, dynamic> json) {
    return KaiProduct(
      id: json['Id'],
      adi: json['Adi'] ?? '',
      fiyat: json['Fiyat'] ?? '0.00',
      resim: json['Resim'],
    );
  }
}