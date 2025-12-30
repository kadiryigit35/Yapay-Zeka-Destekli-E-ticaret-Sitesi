using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Mail;
using System.Net;
using System.Web;
using System.Web.Mvc;
using System.Web.UI;
using System.Web.WebSockets;
using eTicaretSitesi.MvcWebUI.Entity;
using eTicaretSitesi.MvcWebUI.Identity;
using eTicaretSitesi.MvcWebUI.Models;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using Microsoft.Owin.Security;
using Microsoft.AspNet.Identity.Owin;
using Microsoft.Owin.Security.DataProtection;
using System.Threading.Tasks;
using eTicaretSitesi.MvcWebUI.Helpers;

namespace eTicaretSitesi.MvcWebUI.Controllers
{
    public class hesapController : BaseController
    {
        private DataContext db = new DataContext();
        private UserManager<kullanici> UserManager;
        private RoleManager<yetki> RoleManager;

        public hesapController()
        {
            var userStore = new UserStore<kullanici>(new IdentityDataContext());
            UserManager = new UserManager<kullanici>(userStore);
            var roleStore = new RoleStore<yetki>(new IdentityDataContext());
            RoleManager = new RoleManager<yetki>(roleStore);

            var provider = new DpapiDataProtectionProvider("eTicaretSitesiApp");
            UserManager.UserTokenProvider = new DataProtectorTokenProvider<kullanici>(provider.Create("ASP.NET Identity"));
        }

        private void SetIsAdmin()
        {
            if (User.Identity.IsAuthenticated)
            {
                var userId = User.Identity.GetUserId();
                ViewBag.IsAdmin = UserManager.IsInRole(userId, "admin");
                var user = UserManager.FindById(userId);
                ViewBag.UserName = user?.UserName;
                ViewBag.ProfilResmi = user?.ProfilResmi ?? "default.jpg";
            }
            else
            {
                ViewBag.IsAdmin = false;
                ViewBag.UserName = null;
                ViewBag.ProfilResmi = "default.jpg";
            }
        }

        public ActionResult ProfilDuzenle()
        {
            SetIsAdmin();
            var userId = User.Identity.GetUserId();
            var user = UserManager.FindById(userId);
            return View(user);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ProfilDuzenle(kullanici model, HttpPostedFileBase ProfilResmi)
        {
            if (ModelState.IsValid)
            {
                var user = await UserManager.FindByIdAsync(model.Id);
                if (user == null) return HttpNotFound();

                user.Adi = model.Adi;
                user.Soyadi = model.Soyadi;

                if (ProfilResmi != null && ProfilResmi.ContentLength > 0)
                {
                    string newFileName = await ApiUploader.UploadImageAsync(ProfilResmi);
                    if (!string.IsNullOrEmpty(newFileName))
                    {
                        user.ProfilResmi = newFileName;
                    }
                    else
                    {
                        ModelState.AddModelError("", "Profil resmi yüklenemedi.");
                    }
                }

                var result = await UserManager.UpdateAsync(user);
                if (result.Succeeded)
                {
                    TempData["ProfilMesaj"] = "Profil bilgileriniz başarıyla güncellendi.";
                    return RedirectToAction("ProfilDuzenle");
                }

                foreach (var error in result.Errors)
                {
                    ModelState.AddModelError("", error);
                }
            }

            SetIsAdmin();
            // ModelState geçerli değilse veya güncelleme başarısızsa, formu hatalarla birlikte geri döndür
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> SifreGuncelle(string Id, string MevcutSifre, string YeniSifre, string YeniSifreTekrar)
        {
            var user = await UserManager.FindByIdAsync(Id);
            if (user == null)
            {
                return HttpNotFound();
            }

            if (string.IsNullOrEmpty(MevcutSifre) || string.IsNullOrEmpty(YeniSifre) || string.IsNullOrEmpty(YeniSifreTekrar))
            {
                TempData["SifreHata"] = "Tüm şifre alanları doldurulmalıdır.";
                return RedirectToAction("ProfilDuzenle");
            }

            if (YeniSifre != YeniSifreTekrar)
            {
                TempData["SifreHata"] = "Yeni şifreler uyuşmuyor.";
                return RedirectToAction("ProfilDuzenle");
            }

            var result = await UserManager.ChangePasswordAsync(user.Id, MevcutSifre, YeniSifre);

            if (result.Succeeded)
            {
                TempData["SifreMesaj"] = "Şifreniz başarıyla güncellendi.";
            }
            else
            {
                string errors = string.Join(" ", result.Errors);
                TempData["SifreHata"] = "Şifre güncellenemedi: " + errors;
            }

            return RedirectToAction("ProfilDuzenle");
        }


        [Authorize(Roles = "Satici")]
        public ActionResult SaticiProfilDuzenle()
        {
            var kullaniciAdi = User.Identity.Name;
            var satici = db.saticilar.FirstOrDefault(s => s.Adi == kullaniciAdi);

            if (satici == null)
                return HttpNotFound("Satıcı profili bulunamadı.");

            return View(satici);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Satici")]
        public async Task<ActionResult> SaticiProfilDuzenle(satici model, HttpPostedFileBase Resim)
        {
            var satici = db.saticilar.FirstOrDefault(s => s.Id == model.Id);
            if (satici == null)
                return HttpNotFound();

            satici.Adi = model.Adi;
            satici.Hakkinda = model.Hakkinda;

            // SATICI RESMİ GÜNCELLEME (API ÜZERİNDEN)
            if (Resim != null && Resim.ContentLength > 0)
            {
                string newFileName = await ApiUploader.UploadImageAsync(Resim);
                if (!string.IsNullOrEmpty(newFileName))
                {
                    satici.Resim = newFileName;
                }
                else
                {
                    ModelState.AddModelError("", "Satıcı resmi API'ye yüklenemedi. Lütfen tekrar deneyin.");
                }
            }

            if (ModelState.IsValid)
            {
                db.SaveChanges();
                TempData["Mesaj"] = "Satıcı profili güncellendi.";
                return RedirectToAction("SaticiProfilDuzenle");
            }

            return View(model);
        }

        // --- Diğer metotlarınız burada değişikliğe uğramadan devam ediyor ---
        // kayitOl, girisYap, cikisYap, siparislerim vb. metotlar...
        #region Diğer Metotlar
        public ActionResult kayitOl()
        {
            SetIsAdmin();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult kayitOl(kayitOl model)
        {
            if (ModelState.IsValid)
            {
                kullanici user = new kullanici();
                user.Adi = model.Adi;
                user.Soyadi = model.Soyadi;
                user.Email = model.Email;
                user.UserName = model.KullaniciAdi;
                var result = UserManager.Create(user, model.Sifre);
                if (result.Succeeded)
                {
                    if (RoleManager.RoleExists("Kullanici"))
                    {
                        UserManager.AddToRole(user.Id, "Kullanici");
                    }
                    return RedirectToAction("girisYap", "hesap");
                }
                else
                {
                    ModelState.AddModelError("kullaniciKayitHata", "Kullanıcı Oluşturma Hatası.");
                }
            }
            SetIsAdmin();
            return View(model);
        }

        public ActionResult girisYap()
        {
            SetIsAdmin();
            return View();
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult girisYap(girisYap model, string ReturnUrl)
        {
            if (!ModelState.IsValid)
            {
                SetIsAdmin(); // Bu sizin projenizde olan bir metot, olduğu gibi bırakıldı.
                return View(model);
            }

            var user = UserManager.Find(model.KullaniciAdi, model.Sifre);

            if (user == null)
            {
                ModelState.AddModelError("", "Kullanıcı adı veya şifre yanlış.");
                SetIsAdmin();
                return View(model);
            }

            // --- BAN KONTROLÜ BAŞLANGICI ---
            if (user.BanliMi)
            {
                // Süresi dolmuş ban'ı kontrol et ve gerekirse kaldır
                if (user.BanBitisTarihi.HasValue && user.BanBitisTarihi.Value <= System.DateTime.Now)
                {
                    user.BanliMi = false;
                    user.BanBitisTarihi = null;
                    user.BanSebebi = null;
                    UserManager.Update(user);
                    // Kullanıcı artık banlı değil, giriş işlemine devam edilebilir.
                }
                else
                {
                    string banMesaji = "Hesabınız askıya alınmıştır.";
                    if (user.BanBitisTarihi.HasValue)
                    {
                        banMesaji += $" Yasağınız {user.BanBitisTarihi.Value:dd.MM.yyyy HH:mm} tarihinde sona erecektir.";
                    }
                    else
                    {
                        banMesaji += " Yasağınız kalıcıdır.";
                    }
                    ModelState.AddModelError("", banMesaji);
                    SetIsAdmin();
                    return View(model); // Giriş yapmasını engelle ve hata mesajıyla sayfayı geri döndür
                }
            }
            // --- BAN KONTROLÜ SONU ---

            var authManager = HttpContext.GetOwinContext().Authentication;
            var identity = UserManager.CreateIdentity(user, "ApplicationCookie");

            var authProperties = new AuthenticationProperties
            {
                IsPersistent = model.BeniHatirla
            };

            authManager.SignOut();
            authManager.SignIn(authProperties, identity);

            // Rol bazlı yönlendirme
            if (UserManager.IsInRole(user.Id, "admin"))
            {
                return RedirectToAction("Index", "kategori");
            }
            if (UserManager.IsInRole(user.Id, "satici"))
            {
                return RedirectToAction("Index", "urun");
            }

            if (!string.IsNullOrEmpty(ReturnUrl) && Url.IsLocalUrl(ReturnUrl))
            {
                return Redirect(ReturnUrl);
            }

            return RedirectToAction("Index", "Home");
        }


        public ActionResult cikisYap()
        {
            var yetkilendirmeYöneticisi = HttpContext.GetOwinContext().Authentication;
            yetkilendirmeYöneticisi.SignOut();
            return RedirectToAction("Index", "Home");
        }

        public ActionResult siparislerim()
        {
            SetIsAdmin();
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("girisYap", "hesap");
            }

            var userId = User.Identity.GetUserId();
            var Siparisler = db.siparisler
                .Where(i => i.UserId == userId)
                .Select(i => new kullaniciSiparis
                {
                    Id = i.Id,
                    SiparisNumarasi = i.SiparisNumarasi,
                    SiparisTarihi = i.SiparisTarihi,
                    siparisDurum = i.siparisDurum,
                    Toplam = i.Toplam
                })
                .OrderByDescending(i => i.SiparisTarihi)
                .ToList();
            return View(Siparisler);
        }

        public ActionResult Favorilerim()
        {
            SetIsAdmin();
            var kullaniciAdi = User.Identity.Name;

            var favoriler = db.Favoriler
                .Where(f => f.KullaniciAdi == kullaniciAdi)
                .Select(f => f.Urun)
                .ToList();

            return View(favoriler);
        }

        [HttpPost]
        [Authorize]
        public ActionResult FavoridenKaldir(int urunId)
        {
            var kullaniciAdi = User.Identity.Name;

            var favori = db.Favoriler.FirstOrDefault(f => f.KullaniciAdi == kullaniciAdi && f.UrunId == urunId);
            if (favori != null)
            {
                db.Favoriler.Remove(favori);
                db.SaveChanges();
            }

            return RedirectToAction("Favorilerim");
        }

        public ActionResult Detay(int id)
        {
            var urun = db.urunler.Include("Yorumlar").Include("Satici").FirstOrDefault(u => u.Id == id);
            if (urun == null) return HttpNotFound();

            var userId = User.Identity.GetUserId();
            bool favorideMi = db.Favoriler.Any(f => f.KullaniciAdi == userId && f.UrunId == id);
            ViewBag.FavorideMi = favorideMi;

            return View(urun);
        }
        public ActionResult KayitliAdreslerim()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            var adresler = db.KayitliAdresler.Where(a => a.KullaniciId == userId).ToList();

            return View(adresler);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult EditAdres(kayitliAdres model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            var adres = db.KayitliAdresler.FirstOrDefault(a => a.Id == model.Id && a.KullaniciId == userId);

            if (adres == null)
            {
                return HttpNotFound();
            }

            if (ModelState.IsValid)
            {
                adres.TamAd = model.TamAd;
                adres.AdresBasligi = model.AdresBasligi;
                adres.Adres = model.Adres;
                adres.Sehir = model.Sehir;
                adres.Mahalle = model.Mahalle;
                adres.Sokak = model.Sokak;
                adres.PostaKodu = model.PostaKodu;
                adres.Telefon = model.Telefon;

                db.SaveChanges();
                return RedirectToAction("KayitliAdreslerim");
            }
            var adresler = db.KayitliAdresler.Where(a => a.KullaniciId == userId).ToList();
            return View("KayitliAdreslerim", adresler);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteAdres(int id)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            var adres = db.KayitliAdresler.FirstOrDefault(a => a.Id == id && a.KullaniciId == userId);

            if (adres != null)
            {
                db.KayitliAdresler.Remove(adres);
                db.SaveChanges();
            }

            return RedirectToAction("KayitliAdreslerim");
        }
        public ActionResult KayitliKartlarim()
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            var kartlar = db.KayitliOdemeYontemleri.Where(k => k.KullaniciId == userId).ToList();

            return View(kartlar);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult EditKart(kayitliOdemeYontemi model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            var kart = db.KayitliOdemeYontemleri.FirstOrDefault(k => k.Id == model.Id && k.KullaniciId == userId);

            if (kart == null)
            {
                return HttpNotFound();
            }

            if (ModelState.IsValid)
            {
                kart.KartSahibi = model.KartSahibi;
                kart.KartNumarasi = model.KartNumarasi;
                kart.SKT = model.SKT;
                kart.CVV = model.CVV;

                db.SaveChanges();
                return RedirectToAction("KayitliKartlarim");
            }
            var kartlar = db.KayitliOdemeYontemleri.Where(k => k.KullaniciId == userId).ToList();
            return View("KayitliKartlarim", kartlar);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteKart(int id)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            var kart = db.KayitliOdemeYontemleri.FirstOrDefault(k => k.Id == id && k.KullaniciId == userId);

            if (kart != null)
            {
                db.KayitliOdemeYontemleri.Remove(kart);
                db.SaveChanges();
            }

            return RedirectToAction("KayitliKartlarim");
        }
        public static Dictionary<string, string> Kodlar = new Dictionary<string, string>();

        [HttpGet]
        public ActionResult SifreSifirla()
        {
            return View(new SifreSifirlaViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SifreSifirlaMailGonder(SifreSifirlaViewModel model)
        {
            var user = UserManager.FindByEmail(model.Email);
            if (user == null)
            {
                ModelState.AddModelError("", "Bu e-posta sistemde kayıtlı değil.");
                return View("SifreSifirla", model);
            }

            var kod = new Random().Next(100000, 999999).ToString();
            Session[model.Email + "_SifreKodu"] = kod;
            Session.Timeout = 15;

            MailGonder(model.Email, "Şifre Sıfırlama Kodu", $"Şifre sıfırlama kodunuz: {kod}");

            model.KodGonderildi = true;
            ModelState.Clear();
            return View("SifreSifirla", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SifreSifirlaKodDogrula(SifreSifirlaViewModel model)
        {
            var dogruKod = Session[model.Email + "_SifreKodu"] as string;

            if (string.IsNullOrEmpty(dogruKod))
            {
                ModelState.AddModelError("", "Kodun süresi dolmuş. Yeni kod isteyin.");
                model.KodGonderildi = true; // Tekrar kod istemesi için formu doğru durumda tut
                return View("SifreSifirla", model);
            }

            if (dogruKod != model.GirilenKod)
            {
                ModelState.AddModelError("", "Kod yanlış.");
                model.KodGonderildi = true; // Yanlış kod girdi, formu doğru durumda tut
                return View("SifreSifirla", model);
            }

            Session[model.Email + "_Onay"] = true; // Kodun doğru olduğunu bir sonraki adıma taşımak için
            Session.Remove(model.Email + "_SifreKodu");
            model.KodDogruMu = true;
            ModelState.Clear();
            return View("SifreSifirla", model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> SifreSifirlaSifreGuncelle(SifreSifirlaViewModel model)
        {
            // Güvenlik için, bir önceki adımda kodun doğrulandığından emin ol
            if (Session[model.Email + "_Onay"] == null || !(bool)Session[model.Email + "_Onay"])
            {
                ModelState.AddModelError("", "Güvenlik doğrulama adımı tamamlanmamış. Lütfen tekrar deneyin.");
                return View("SifreSifirla", new SifreSifirlaViewModel()); // Süreci başa döndür
            }

            if (!ModelState.IsValid)
            {
                model.KodDogruMu = true; // Formun doğru şekilde görüntülenmesi için
                return View("SifreSifirla", model);
            }

            var user = await UserManager.FindByEmailAsync(model.Email);
            if (user == null) return HttpNotFound();

            // Önce mevcut şifreyi kaldır
            var removeResult = await UserManager.RemovePasswordAsync(user.Id);

            if (removeResult.Succeeded)
            {
                // Sonra yeni şifreyi ekle
                var addResult = await UserManager.AddPasswordAsync(user.Id, model.YeniSifre);
                if (addResult.Succeeded)
                {
                    Session.Remove(model.Email + "_Onay"); // İşlem bitti, session'ı temizle
                    TempData["Mesaj"] = "Şifreniz başarıyla güncellendi.";
                    return RedirectToAction("girisYap");
                }
                // Hata durumunda, hataları ModelState'e ekle
                foreach (var error in addResult.Errors)
                {
                    ModelState.AddModelError("", error);
                }
            }
            else
            {
                foreach (var error in removeResult.Errors)
                {
                    ModelState.AddModelError("", error);
                }
            }

            model.KodDogruMu = true; // Hata durumunda formun doğru görüntülenmesi için
            return View("SifreSifirla", model);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult AddAdres(kayitliAdres model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            model.KullaniciId = userId; // Kullanıcı ID'sini modele ata

            if (ModelState.IsValid)
            {
                db.KayitliAdresler.Add(model);
                db.SaveChanges();
                return RedirectToAction("KayitliAdreslerim");
            }

            // Model geçerli değilse, adresler listesini tekrar yükleyip sayfayı geri döndür
            var adresler = db.KayitliAdresler.Where(a => a.KullaniciId == userId).ToList();
            return View("KayitliAdreslerim", adresler);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult AddKart(kayitliOdemeYontemi model)
        {
            if (!User.Identity.IsAuthenticated)
                return RedirectToAction("Index", "Home");

            var userId = User.Identity.GetUserId();
            model.KullaniciId = userId; // Kullanıcı ID'sini modele ata

            if (ModelState.IsValid)
            {
                db.KayitliOdemeYontemleri.Add(model);
                db.SaveChanges();
                return RedirectToAction("KayitliKartlarim");
            }

            // Model geçerli değilse, kartlar listesini tekrar yükleyip sayfayı geri döndür
            var kartlar = db.KayitliOdemeYontemleri.Where(k => k.KullaniciId == userId).ToList();
            return View("KayitliKartlarim", kartlar);
        }
        private void MailGonder(string aliciEmail, string konu, string icerik)
        {
            try
            {
                var mail = new MailMessage();
                mail.From = new MailAddress("örnek@gmail.com");
                mail.To.Add(aliciEmail);
                mail.Subject = konu;
                mail.Body = icerik;
                mail.IsBodyHtml = true;

                var smtp = new SmtpClient();
                smtp.Send(mail);
            }
            catch (Exception ex)
            {
                TempData["MailHata"] = "Mail gönderim hatası: " + ex.Message;
            }
        }
        #endregion
    }
}
