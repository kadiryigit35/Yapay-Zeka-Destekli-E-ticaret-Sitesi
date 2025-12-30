using System;
using System.Linq;
using System.Web.Http;
using eTicaretAPI.Entity;
using System.Data.Entity;
using System.Collections.Generic;

namespace eTicaretAPI.Controllers
{
    [RoutePrefix("api/orders")]
    public class OrdersController : ApiController
    {
        private readonly DataContext db = new DataContext();

        [HttpPost]
        [Route("create")]
        public IHttpActionResult CreateOrder(CreateOrderModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // GEREKLİ KONTROLLER
            if (!model.AdresId.HasValue && model.YeniAdres == null)
            {
                return BadRequest("Geçerli bir teslimat adresi belirtilmedi.");
            }
            if (!model.KartId.HasValue && model.YeniKart == null)
            {
                return BadRequest("Geçerli bir ödeme yöntemi belirtilmedi.");
            }

            try
            {
                // ADRES BİLGİLERİNİ BELİRLEME
                string tamAd, adresBasligi, adres, sehir, mahalle, sokak, postaKodu;

                if (model.YeniAdres != null) // EĞER YENİ ADRES GİRİLDİYSE
                {
                    var yeniAdres = model.YeniAdres;
                    tamAd = yeniAdres.TamAd;
                    adresBasligi = yeniAdres.AdresBasligi;
                    adres = yeniAdres.Adres;
                    sehir = yeniAdres.Sehir;
                    mahalle = yeniAdres.Mahalle;
                    sokak = yeniAdres.Sokak;
                    postaKodu = yeniAdres.PostaKodu;

                    // Adres kaydetme: Sadece UserId varsa ve kullanıcı kaydetmek istiyorsa çalışsın.
                    if (yeniAdres.Kaydet && !string.IsNullOrEmpty(model.UserId))
                    {
                        var yeniKayitliAdres = new kayitliAdres
                        {
                            KullaniciId = model.UserId,
                            TamAd = tamAd,
                            AdresBasligi = adresBasligi,
                            Adres = adres,
                            Sehir = sehir,
                            Mahalle = mahalle,
                            Sokak = sokak,
                            PostaKodu = postaKodu,
                            Telefon = yeniAdres.Telefon
                        };
                        db.KayitliAdresler.Add(yeniKayitliAdres);
                    }
                }
                else // EĞER KAYITLI ADRES SEÇİLDİYSE
                {
                    var teslimatAdresi = db.KayitliAdresler.FirstOrDefault(a => a.Id == model.AdresId.Value && a.KullaniciId == model.UserId);
                    if (teslimatAdresi == null)
                    {
                        return BadRequest("Teslimat adresi bulunamadı.");
                    }
                    tamAd = teslimatAdresi.TamAd;
                    adresBasligi = teslimatAdresi.AdresBasligi;
                    adres = teslimatAdresi.Adres;
                    sehir = teslimatAdresi.Sehir;
                    mahalle = teslimatAdresi.Mahalle;
                    sokak = teslimatAdresi.Sokak;
                    postaKodu = teslimatAdresi.PostaKodu;
                }

                // Kart kaydetme: Sadece UserId varsa ve kullanıcı kaydetmek istiyorsa çalışsın.
                if (model.YeniKart != null && model.YeniKart.Kaydet && !string.IsNullOrEmpty(model.UserId))
                {
                    var yeniKayitliKart = new kayitliOdemeYontemi
                    {
                        KullaniciId = model.UserId,
                        KartSahibi = model.YeniKart.KartSahibi,
                        KartNumarasi = model.YeniKart.KartNumarasi,
                        SKT = model.YeniKart.SKT,
                        CVV = model.YeniKart.CVV
                    };
                    db.KayitliOdemeYontemleri.Add(yeniKayitliKart);
                }

                // SİPARİŞİ OLUŞTURMA
                var siparis = new siparis()
                {
                    // UserId null olabilir, bu durumda veritabanında da null olarak kaydedilir.
                    UserId = model.UserId,
                    SiparisNumarasi = "A" + new Random().Next(1000, 9999).ToString(),
                    Toplam = model.ToplamTutar,
                    SiparisTarihi = DateTime.Now,
                    siparisDurum = EnumsiparisDurum.SiparisAlındı,
                    TamAd = tamAd, // Belirlenen adres bilgilerini kullan
                    AdresBasligi = adresBasligi,
                    Adres = adres,
                    Sehir = sehir,
                    Mahalle = mahalle,
                    Sokak = sokak,
                    PostaKodu = postaKodu,
                    GetSiparisYolu = new List<siparisYolu>()
                };

                foreach (var item in model.SiparisKalemleri)
                {
                    siparis.GetSiparisYolu.Add(new siparisYolu()
                    {
                        Adet = item.Adet,
                        Fiyat = item.Fiyat,
                        UrunId = item.UrunId
                    });
                }

                db.siparisler.Add(siparis);
                db.SaveChanges();

                return Ok(new { success = true, message = "Sipariş başarıyla oluşturuldu.", siparisNumarasi = siparis.SiparisNumarasi });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("update-status")]
        public IHttpActionResult UpdateOrderStatus(int orderId, string userId)
        {
            try
            {
                // Siparişi ve kullanıcıyı doğrula
                var siparis = db.siparisler.FirstOrDefault(s => s.Id == orderId && s.UserId == userId);
                if (siparis == null) return BadRequest("Sipariş bulunamadı.");

                string mesaj = "";
                string iadeKodu = "";

                // 1. Durum: Sipariş Alındı -> İPTAL EDİLEBİLİR
                if (siparis.siparisDurum == EnumsiparisDurum.SiparisAlındı)
                {
                    siparis.siparisDurum = EnumsiparisDurum.İptalEdildi;
                    mesaj = "Siparişiniz başarıyla iptal edildi.";
                }
                // 2. Durum: Kargoya Verildi -> DİREKT İADE
                else if (siparis.siparisDurum == EnumsiparisDurum.KargoyaVerildi)
                {
                    siparis.siparisDurum = EnumsiparisDurum.IadeEdildi;
                    mesaj = "Siparişiniz iade sürecine alındı.";
                }
                // 3. Durum: Teslim Edildi -> 21 GÜN KONTROLÜ
                else if (siparis.siparisDurum == EnumsiparisDurum.TeslimEdildi)
                {
                    var gecenGun = (DateTime.Now - siparis.SiparisTarihi).TotalDays;

                    if (gecenGun <= 21)
                    {
                        siparis.siparisDurum = EnumsiparisDurum.IadeEdildi;
                        // Simülasyon Kargo Kodu
                        iadeKodu = "KRG" + new Random().Next(100000, 999999).ToString();
                        mesaj = $"İade talebiniz alındı. Kargo İade Kodunuz: {iadeKodu}. Bu kod ile kargo şubesine gidiniz.";
                    }
                    else
                    {
                        return BadRequest("Teslimat üzerinden 21 gün geçtiği için iade edilemez.");
                    }
                }
                else
                {
                    return BadRequest("Bu sipariş durumu için işlem yapılamaz.");
                }

                db.SaveChanges();
                return Ok(new { success = true, message = mesaj, iadeKodu = iadeKodu, yeniDurum = siparis.siparisDurum.ToString() });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }

    // --- API MODELLERİ ---

    public class NewCardModel
    {
        public string KartSahibi { get; set; }
        public string KartNumarasi { get; set; }
        public string SKT { get; set; }
        public string CVV { get; set; }
        public bool Kaydet { get; set; }
    }

    public class NewAddressModel
    {
        public string TamAd { get; set; }
        public string AdresBasligi { get; set; }
        public string Adres { get; set; }
        public string Sehir { get; set; }
        public string Mahalle { get; set; }
        public string Sokak { get; set; }
        public string PostaKodu { get; set; }
        public string Telefon { get; set; }
        public bool Kaydet { get; set; }
    }

    public class CreateOrderModel
    {
        public string UserId { get; set; } // Bu alan null gelebilir.
        public double ToplamTutar { get; set; }
        public List<OrderItemModel> SiparisKalemleri { get; set; }

        public int? AdresId { get; set; }
        public NewAddressModel YeniAdres { get; set; }

        public int? KartId { get; set; }
        public NewCardModel YeniKart { get; set; }
    }

    public class OrderItemModel
    {
        public int UrunId { get; set; }
        public int Adet { get; set; }
        public double Fiyat { get; set; }
    }
}