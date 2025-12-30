using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.Mvc;
using eTicaretSitesi.MvcWebUI.Entity;
using eTicaretSitesi.MvcWebUI.Models;
using Microsoft.AspNet.Identity;
using Newtonsoft.Json;

namespace eTicaretSitesi.MvcWebUI.Controllers
{
    public class SepetController : BaseController
    {
        private DataContext db = new DataContext();
    // GET: Sepet
    public ActionResult Index()
        {
            return View(getSepet());
        }

        [HttpPost]
        public ActionResult SepeteEkle(int Id)
        {
            var urun = db.urunler.FirstOrDefault(i => i.Id == Id);
            if (urun == null)
            {
                return Json(new { success = false, message = "Ürün bulunamadı." });
            }

            if (urun.Stok <= 0)
            {
                return Json(new { success = false, message = "Ürün stokta bulunmamaktadır." });
            }

            getSepet().urunEkleme(urun, 1);
            return Json(new { success = true, message = "Sepetinize eklendi!" });
        }

        public ActionResult SepeteCikar(int Id)
        {
            var urun = db.urunler.FirstOrDefault(i => i.Id == Id);
            if (urun != null)
            {
                getSepet().urunCikarma(urun);
            }
            return RedirectToAction("Index");
        }

        // YENİ EKLENEN METOT: SEPETİ DİNAMİK GÜNCELLEME
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SepetiGuncelle(int Id, string islem)
        {
            var urun = db.urunler.FirstOrDefault(i => i.Id == Id);
            if (urun == null)
            {
                return Json(new { success = false, message = "Ürün bulunamadı." });
            }

            var sepet = getSepet();

            switch (islem)
            {
                case "arttir":
                    // Stok kontrolü yap
                    var sepettekiUrun = sepet.sepetOgeleri.FirstOrDefault(i => i.urun.Id == Id);
                    if (urun.Stok > (sepettekiUrun?.Adet ?? 0))
                    {
                        sepet.urunEkleme(urun, 1);
                    }
                    else
                    {
                        return Json(new { success = false, message = "Stok yetersiz." });
                    }
                    break;
                case "azalt":
                    sepet.urunAdetAzalt(urun);
                    break;
                case "sil":
                    sepet.urunCikarma(urun);
                    break;
                default:
                    return Json(new { success = false, message = "Geçersiz işlem." });
            }

            var sepetOgesi = sepet.sepetOgeleri.FirstOrDefault(i => i.urun.Id == Id);

            return Json(new
            {
                success = true,
                adet = sepetOgesi?.Adet ?? 0,
                urunToplam = (sepetOgesi != null ? (sepetOgesi.Adet * sepetOgesi.urun.Fiyat) : 0).ToString("c"),
                sepetToplam = sepet.sepetTutari().ToString("c"),
                sepetOgeSayisi = sepet.sepetOgeleri.Count,
                sepetToplamAdet = sepet.sepetOgeleri.Sum(x => x.Adet)
            });
        }


        public sepet getSepet()
        {
            var sessionKey = "sepet_" + (User.Identity.Name ?? Session.SessionID);
            var Sepet = (sepet)Session[sessionKey];
            if (Sepet == null)
            {
                Sepet = new sepet();
                Session[sessionKey] = Sepet;
            }
            return Sepet;
        }

        public PartialViewResult ozet()
        {
            return PartialView(getSepet());
        }

        public ActionResult teslimat()
        {
            var model = new TeslimatOdemeViewModel
            {
                Teslimat = new teslimatBilgileri(),
                Odeme = new odemeBilgileri(),
                KayitliAdresler = new List<kayitliAdres>(),
                KayitliOdemeYontemleri = new List<kayitliOdemeYontemi>()
            };

            if (User.Identity.IsAuthenticated)
            {
                var userId = User.Identity.GetUserId();
                model.KayitliAdresler = db.KayitliAdresler.Where(a => a.KullaniciId == userId).ToList();
                model.KayitliOdemeYontemleri = db.KayitliOdemeYontemleri.Where(k => k.KullaniciId == userId).ToList();
            }

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult teslimat(TeslimatOdemeViewModel model)
        {
            var sepet = getSepet();

            if (sepet.sepetOgeleri.Count == 0)
            {
                ModelState.AddModelError("bosSepet", "Sepetinizde Ürün Bulunmamaktadır");
            }

            string userId = User.Identity.IsAuthenticated ? User.Identity.GetUserId() : null;

            if (model.SecilenAdresId.HasValue && User.Identity.IsAuthenticated)
            {
                var selectedAdres = db.KayitliAdresler.FirstOrDefault(a => a.Id == model.SecilenAdresId && a.KullaniciId == userId);
                if (selectedAdres != null)
                {
                    model.Teslimat = new teslimatBilgileri
                    {
                        TamAd = selectedAdres.TamAd,
                        AdresBasligi = selectedAdres.AdresBasligi,
                        Adres = selectedAdres.Adres,
                        Sehir = selectedAdres.Sehir,
                        Mahalle = selectedAdres.Mahalle,
                        Sokak = selectedAdres.Sokak,
                        PostaKodu = selectedAdres.PostaKodu,
                        Telefon = selectedAdres.Telefon
                    };
                }
            }

            if (model.SecilenOdemeId.HasValue && User.Identity.IsAuthenticated)
            {
                var selectedOdeme = db.KayitliOdemeYontemleri.FirstOrDefault(o => o.Id == model.SecilenOdemeId && o.KullaniciId == userId);
                if (selectedOdeme != null)
                {
                    model.Odeme = new odemeBilgileri
                    {
                        KartSahibi = selectedOdeme.KartSahibi,
                        KartNumarasi = selectedOdeme.KartNumarasi,
                        SonKullanma = selectedOdeme.SKT,
                        Cvc = selectedOdeme.CVV
                    };
                }
            }

            if (ModelState.IsValid)
            {
                if (User.Identity.IsAuthenticated)
                {
                    if (model.AdresiKaydet && !model.SecilenAdresId.HasValue)
                    {
                        var yeniAdres = new kayitliAdres
                        {
                            KullaniciId = userId,
                            AdresBasligi = model.Teslimat.AdresBasligi,
                            Adres = model.Teslimat.Adres,
                            Sehir = model.Teslimat.Sehir,
                            Mahalle = model.Teslimat.Mahalle,
                            Sokak = model.Teslimat.Sokak,
                            PostaKodu = model.Teslimat.PostaKodu,
                            Telefon = model.Teslimat.Telefon,
                            TamAd = model.Teslimat.TamAd
                        };
                        db.KayitliAdresler.Add(yeniAdres);
                        db.SaveChanges();
                    }

                    if (model.OdemeyiKaydet && !model.SecilenOdemeId.HasValue)
                    {
                        var yeniOdeme = new kayitliOdemeYontemi
                        {
                            KullaniciId = userId,
                            KartSahibi = model.Odeme.KartSahibi,
                            KartNumarasi = model.Odeme.KartNumarasi,
                            SKT = model.Odeme.SonKullanma,
                            CVV = model.Odeme.Cvc
                        };
                        db.KayitliOdemeYontemleri.Add(yeniOdeme);
                        db.SaveChanges();
                    }
                }

                siparisKaydet(sepet, model.Teslimat);

                sepet.sepetiTemizle();
                return View("tamamlandi");
            }

            if (User.Identity.IsAuthenticated)
            {
                model.KayitliAdresler = db.KayitliAdresler.Where(a => a.KullaniciId == userId).ToList();
                model.KayitliOdemeYontemleri = db.KayitliOdemeYontemleri.Where(k => k.KullaniciId == userId).ToList();
            }

            return View(model);
        }

        private void siparisKaydet(sepet Sepet, teslimatBilgileri entity)
        {
            var Siparis = new siparis();

            if (User.Identity.IsAuthenticated)
            {
                Siparis.UserId = User.Identity.GetUserId();
            }
            else
            {
                Siparis.GuestId = Guid.NewGuid().ToString();
                Siparis.Eposta = entity.Eposta;
            }

            Siparis.SiparisNumarasi = "A" + (new Random()).Next(1000, 9999).ToString();
            Siparis.Toplam = Sepet.sepetTutari();
            Siparis.SiparisTarihi = DateTime.Now;
            Siparis.siparisDurum = EnumsiparisDurum.SiparisAlındı;
            Siparis.TamAd = entity.TamAd;
            Siparis.AdresBasligi = entity.AdresBasligi;
            Siparis.Adres = entity.Adres;
            Siparis.Sehir = entity.Sehir;
            Siparis.Mahalle = entity.Mahalle;
            Siparis.Sokak = entity.Sokak;
            Siparis.PostaKodu = entity.PostaKodu;
            Siparis.GetSiparisYolu = new List<siparisYolu>();

            foreach (var pr in Sepet.sepetOgeleri)
            {
                var SiparisYolu = new siparisYolu();
                SiparisYolu.Adet = pr.Adet;
                SiparisYolu.Fiyat = pr.Adet * pr.urun.Fiyat;
                SiparisYolu.UrunId = pr.urun.Id;
                Siparis.GetSiparisYolu.Add(SiparisYolu);
            }

            db.siparisler.Add(Siparis);
            db.SaveChanges();
            Task.Run(() => CallCsvKaydetApi(Siparis));
        }


        // YENİ EKLENEN METOT
        private async Task CallCsvKaydetApi(siparis siparis)
        {
            var data = new
            {
                UserId = siparis.UserId ?? siparis.GuestId,
                Urunler = siparis.GetSiparisYolu.Select(u => new { UrunId = u.UrunId, Adet = u.Adet }).ToList()
            };

            using (var client = new HttpClient())
            {
                // NOT: API adresinizi buraya yazın.
                client.BaseAddress = new Uri("https://localhost:44366/");

                var json = JsonConvert.SerializeObject(data);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                try
                {
                    await client.PostAsync("api/siparis/csv-kaydet", content);
                }
                catch (Exception ex)
                {
                    // Hata loglama mekanizması eklenebilir.
                    System.Diagnostics.Debug.WriteLine("CSV API'ye yazma hatası: " + ex.Message);
                }
            }
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SiparisDurumGuncelle(int id)
        {
            var userId = User.Identity.GetUserId();
            var siparis = db.siparisler.FirstOrDefault(s => s.Id == id && s.UserId == userId);

            if (siparis != null)
            {
                if (siparis.siparisDurum == EnumsiparisDurum.SiparisAlındı)
                {
                    siparis.siparisDurum = EnumsiparisDurum.İptalEdildi;
                    TempData["Mesaj"] = "Siparişiniz iptal edildi.";
                }
                else if (siparis.siparisDurum == EnumsiparisDurum.KargoyaVerildi)
                {
                    siparis.siparisDurum = EnumsiparisDurum.IadeEdildi;
                    TempData["Mesaj"] = "Sipariş iade edildi.";
                }
                else if (siparis.siparisDurum == EnumsiparisDurum.TeslimEdildi)
                {
                    var gecenGun = (DateTime.Now - siparis.SiparisTarihi).TotalDays;
                    if (gecenGun <= 21)
                    {
                        siparis.siparisDurum = EnumsiparisDurum.IadeEdildi;
                        string kod = "WEB-" + new Random().Next(1000, 9999);
                        TempData["Mesaj"] = "İade talebi alındı. Kodunuz: " + kod;
                    }
                    else
                    {
                        TempData["Hata"] = "21 günlük iade süresi dolmuş.";
                    }
                }

                db.SaveChanges();
            }

            // Kullanıcıyı siparişlerim sayfasına geri gönder
            return RedirectToAction("siparislerim", "hesap"); // Action adınız farklıysa değiştirin (örn: Siparislerim)
        }
    }
}