using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Web.Mvc;
using eTicaretSitesi.MvcWebUI.Entity;
using eTicaretSitesi.MvcWebUI.Identity;
using eTicaretSitesi.MvcWebUI.Models;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using System.Data.Entity; // Bu using ifadesinin olduğundan emin olun

namespace eTicaretSitesi.MvcWebUI.Controllers
{
    public class HomeController : BaseController
    {
        DataContext context = new DataContext();
        private UserManager<kullanici> UserManager;

        public HomeController()
        {
            var userStore = new UserStore<kullanici>(new IdentityDataContext());
            UserManager = new UserManager<kullanici>(userStore);
        }

        public ActionResult Index()
        {
            if (User.Identity.IsAuthenticated)
            {
                var userId = User.Identity.GetUserId();
                if (UserManager.IsInRole(userId, "admin"))
                {
                    return RedirectToAction("Index", "kategori");
                }
                if (UserManager.IsInRole(userId, "satici"))
                {
                    return RedirectToAction("Index", "urun");
                }
            }

            var urunler = context.urunler.Select(i => new urunModel
            {
                Id = i.Id,
                Adi = i.Adi.Length > 50 ? i.Adi.Substring(0, 47) + "..." : i.Adi,
                Aciklama = i.Aciklama.Length > 50 ? i.Aciklama.Substring(0, 47) + "..." : i.Aciklama,
                Fiyat = i.Fiyat,
                Stok = i.Stok,
                Resim = i.Resim ?? "default.jpg",
                kategoriId = i.kategoriId
            }).ToList();

            var kullaniciId = GetCurrentUserId();
            var onerilenUrunler = GetOnerilenUrunler(kullaniciId);

            ViewBag.OnerilenUrunler = onerilenUrunler;
            ViewBag.PopulerUrunler = GetPopulerUrunlerFromCSV();
            ViewBag.Markalar = context.saticilar.ToList();
            return View(urunler);
        }

        public ActionResult detaylar(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }

            // DÜZELTİLMİŞ KOD BLOKU
            var urun = context.urunler
                       .Include("Satici.Puanlar") // Satıcıyı ve satıcının puanlarını getir
                       .Include("Yorumlar")       // Ürünün yorumlarını getir
                       .Include("Puanlar")        // Ürünün kendi puanlarını getir
                       .FirstOrDefault(u => u.Id == id);

            if (urun == null)
            {
                return HttpNotFound();
            }

            if (User.Identity.IsAuthenticated)
            {
                var userName = User.Identity.Name;
                ViewBag.IsFavorited = context.Favoriler.Any(f => f.UrunId == id && f.KullaniciAdi == userName);
            }
            else
            {
                ViewBag.IsFavorited = false;
            }

            return View(urun);
        }


        [HttpPost]
        [Authorize]
        [ValidateAntiForgeryToken]
        public JsonResult YorumSikayetEt(int yorumId)
        {
            var userId = User.Identity.GetUserId();
            var zatenSikayetEdilmis = context.YorumSikayetleri.Any(s => s.YorumId == yorumId && s.SikayetEdenKullaniciId == userId);

            if (zatenSikayetEdilmis)
            {
                return Json(new { success = true, message = "Bu yorumu zaten şikayet ettiniz." });
            }

            var sikayet = new YorumSikayet
            {
                YorumId = yorumId,
                SikayetEdenKullaniciId = userId,
                Tarih = DateTime.Now,
                IslemYapildiMi = false
            };

            context.YorumSikayetleri.Add(sikayet);
            context.SaveChanges();

            return Json(new { success = true, message = "Yorum şikayetiniz yöneticiye iletildi." });
        }


        // --- Diğer metotlarınız burada değişikliğe uğramadan devam ediyor ---
        #region Diğer Metotlar
        [HttpPost]
        [Authorize]
        [ValidateAntiForgeryToken]
        public JsonResult PuanEkle(int urunId, int puanDegeri)
        {
            if (puanDegeri < 1 || puanDegeri > 5)
            {
                return Json(new { success = false, message = "Geçersiz puan değeri." });
            }

            var userId = User.Identity.GetUserId();
            var mevcutPuan = context.Puanlar.FirstOrDefault(p => p.UrunId == urunId && p.KullaniciId == userId);

            if (mevcutPuan != null)
            {
                mevcutPuan.Deger = puanDegeri;
                mevcutPuan.Tarih = DateTime.Now;
            }
            else
            {
                var yeniPuan = new Puan
                {
                    UrunId = urunId,
                    KullaniciId = userId,
                    Deger = puanDegeri,
                    Tarih = DateTime.Now
                };
                context.Puanlar.Add(yeniPuan);
            }

            context.SaveChanges();

            var urun = context.urunler.Include("Puanlar").FirstOrDefault(u => u.Id == urunId);
            return Json(new
            {
                success = true,
                message = "Puanınız başarıyla kaydedildi!",
                ortalamaPuan = urun.OrtalamaPuan.ToString("F1"),
                toplamPuan = urun.ToplamPuanSayisi
            });
        }
        public PartialViewResult _getkategori()
        {
            return PartialView(context.kategori.ToList());
        }
        private string GetCurrentUserId()
        {
            if (User.Identity.IsAuthenticated)
            {
                var userId = User.Identity.GetUserId();
                System.Diagnostics.Debug.WriteLine($"Oturum açmış kullanıcı ID: {userId}");
                return userId;
            }

            if (Session["guestId"] == null)
            {
                Session["guestId"] = Guid.NewGuid().ToString();
            }
            System.Diagnostics.Debug.WriteLine($"Misafir kullanıcı ID: {Session["guestId"]}");
            return Session["guestId"].ToString();
        }
        private List<urunModel> GetOnerilenUrunler(string kullaniciId)
        {
            string path = Server.MapPath("~/App_Data/Siparisler.csv");
            if (!System.IO.File.Exists(path))
            {
                System.Diagnostics.Debug.WriteLine("CSV dosyası bulunamadı.");
                return GetPopulerUrunler();
            }

            var satirlar = System.IO.File.ReadAllLines(path)
                .Skip(1)
                .Select(line => line.Split(','))
                .Where(parts => parts.Length >= 3)
                .Select(parts => new
                {
                    UserId = parts[0],
                    ProductId = parts[1],
                    Adet = int.TryParse(parts[2], out int adet) ? adet : 0
                })
                .GroupBy(x => new { x.UserId, x.ProductId })
                .Select(g => g.First())
                .ToList();

            System.Diagnostics.Debug.WriteLine($"CSV'den okunan satır sayısı: {satirlar.Count}");

            var benimUrunlerim = satirlar
                .Where(p => p.UserId == kullaniciId)
                .Select(p => p.ProductId)
                .Distinct()
                .ToList();

            var digerKullanicilar = satirlar
                .Where(p => p.UserId != kullaniciId && benimUrunlerim.Contains(p.ProductId))
                .Select(p => p.UserId)
                .Distinct()
                .ToList();

            var digerUrunler = satirlar
                .Where(p => digerKullanicilar.Contains(p.UserId) && !benimUrunlerim.Contains(p.ProductId))
                .Select(p => p.ProductId)
                .Distinct()
                .ToList();

            var onerilenler = context.urunler
                .Where(u => digerUrunler.Contains(u.Id.ToString()))
                .OrderByDescending(u => u.Id)
                .Take(5)
                .Select(u => new urunModel
                {
                    Id = u.Id,
                    Adi = u.Adi.Length > 50 ? u.Adi.Substring(0, 47) + "..." : u.Adi,
                    Aciklama = u.Aciklama.Length > 50 ? u.Aciklama.Substring(0, 47) + "..." : u.Aciklama,
                    Fiyat = u.Fiyat,
                    Stok = u.Stok,
                    Resim = u.Resim ?? "default.jpg",
                    kategoriId = u.kategoriId
                })
                .ToList();

            if (!onerilenler.Any())
            {
                var benimKategoriler = context.urunler
                    .Where(u => benimUrunlerim.Contains(u.Id.ToString()))
                    .Select(u => u.kategoriId)
                    .Distinct()
                    .ToList();

                var kategoriOnerileri = context.urunler
                    .Where(u => benimKategoriler.Contains(u.kategoriId) && !benimUrunlerim.Contains(u.Id.ToString()))
                    .OrderByDescending(u => u.Stok)
                    .Take(5)
                    .Select(u => new urunModel
                    {
                        Id = u.Id,
                        Adi = u.Adi.Length > 50 ? u.Adi.Substring(0, 47) + "..." : u.Adi,
                        Aciklama = u.Aciklama.Length > 50 ? u.Aciklama.Substring(0, 47) + "..." : u.Aciklama,
                        Fiyat = u.Fiyat,
                        Stok = u.Stok,
                        Resim = u.Resim ?? "default.jpg",
                        kategoriId = u.kategoriId
                    })
                    .ToList();

                onerilenler.AddRange(kategoriOnerileri);
            }

            var iliskiliUrunler = new Dictionary<int, List<int>>
            {
                { 9, new List<int> { 10 } },
                { 13, new List<int> { 14 } }
            };

            foreach (var urunId in benimUrunlerim)
            {
                if (int.TryParse(urunId, out int id) && iliskiliUrunler.ContainsKey(id))
                {
                    var iliskiliIds = iliskiliUrunler[id];
                    var iliskiliOneriler = context.urunler
                        .Where(u => iliskiliIds.Contains(u.Id) && !benimUrunlerim.Contains(u.Id.ToString()))
                        .Select(u => new urunModel
                        {
                            Id = u.Id,
                            Adi = u.Adi.Length > 50 ? u.Adi.Substring(0, 47) + "..." : u.Adi,
                            Aciklama = u.Aciklama.Length > 50 ? u.Aciklama.Substring(0, 47) + "..." : u.Aciklama,
                            Fiyat = u.Fiyat,
                            Stok = u.Stok,
                            Resim = u.Resim ?? "default.jpg",
                            kategoriId = u.kategoriId
                        })
                        .ToList();
                    onerilenler.AddRange(iliskiliOneriler);
                }
            }

            return onerilenler.Any() ? onerilenler.Take(5).ToList() : GetPopulerUrunler();
        }

        private List<urunModel> GetPopulerUrunler()
        {
            return context.urunler
                .OrderByDescending(u => u.Stok)
                .ThenBy(u => Guid.NewGuid())
                .Take(5)
                .Select(u => new urunModel
                {
                    Id = u.Id,
                    Adi = u.Adi.Length > 50 ? u.Adi.Substring(0, 47) + "..." : u.Adi,
                    Aciklama = u.Aciklama.Length > 50 ? u.Aciklama.Substring(0, 47) + "..." : u.Aciklama,
                    Fiyat = u.Fiyat,
                    Stok = u.Stok,
                    Resim = u.Resim ?? "default.jpg",
                    kategoriId = u.kategoriId
                })
                .ToList();
        }
        [HttpGet]
        public JsonResult UrunOneriler(string term)
        {
            if (string.IsNullOrWhiteSpace(term))
                return Json(new List<string>(), JsonRequestBehavior.AllowGet);

            term = term.ToLower();

            var kelimeler = term.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

            var urunler = context.urunler
                .Where(u =>
                    kelimeler.Any(k =>
                        u.Adi.ToLower().Contains(k) ||
                        (u.Aciklama != null && u.Aciklama.ToLower().Contains(k))
                    )
                )
                .Select(u => u.Adi)
                .Distinct()
                .Take(10)
                .ToList();

            return Json(urunler, JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        [Authorize]
        [ValidateAntiForgeryToken]
        public JsonResult SaticiPuanla(int saticiId, int puanDegeri)
        {
            if (puanDegeri < 1 || puanDegeri > 5)
            {
                return Json(new { success = false, message = "Geçersiz puan değeri." });
            }

            var userId = User.Identity.GetUserId();
            var mevcutPuan = context.SaticiPuanlari.FirstOrDefault(p => p.SaticiId == saticiId && p.KullaniciId == userId);

            if (mevcutPuan != null)
            {
                mevcutPuan.Deger = puanDegeri;
                mevcutPuan.Tarih = DateTime.Now;
            }
            else
            {
                var yeniPuan = new SaticiPuan
                {
                    SaticiId = saticiId,
                    KullaniciId = userId,
                    Deger = puanDegeri,
                    Tarih = DateTime.Now
                };
                context.SaticiPuanlari.Add(yeniPuan);
            }

            context.SaveChanges();

            var satici = context.saticilar.Include(s => s.Puanlar).FirstOrDefault(s => s.Id == saticiId);

            return Json(new
            {
                success = true,
                message = "Puanınız kaydedildi!",
                ortalamaPuan = satici.OrtalamaPuan.ToString("F1"),
                toplamPuan = satici.ToplamPuanSayisi
            });
        }

        public JsonResult UrunAra(string query)
        {
            if (string.IsNullOrEmpty(query))
                return Json(new List<object>(), JsonRequestBehavior.AllowGet);

            var urunler = context.urunler
                .Where(u => u.Adi.Contains(query))
                .Select(u => new
                {
                    u.Id,
                    u.Adi,
                    u.Fiyat,
                    u.Resim
                })
                .ToList();

            var urunlerDto = urunler.Select(u => new
            {
                u.Id,
                Adi = u.Adi,
                Fiyat = u.Fiyat.ToString("C"),
                Resim = Url.Content("~/Upload/" + (string.IsNullOrEmpty(u.Resim) ? "default.jpg" : u.Resim)),
                DetayUrl = Url.Action("detaylar", "Home", new { id = u.Id })
            });

            return Json(urunlerDto, JsonRequestBehavior.AllowGet);
        }
        // Bu metot artık tek bir kategoriId yerine bir ID listesi (kategoriIds) alıyor.
        public ActionResult UrunListesi(List<int> kategoriIds, List<int> saticiIds, double? min, double? max, string arama = null)
        {
            var urunler = context.urunler.AsQueryable();

            if (!string.IsNullOrEmpty(arama))
            {
                arama = arama.ToLower();
                urunler = urunler.Where(u => u.Adi.ToLower().Contains(arama) ||
                                             (u.Aciklama != null && u.Aciklama.ToLower().Contains(arama)));
            }

            // Filtreleme mantığını gelen kategori listesine göre güncelliyoruz.
            if (kategoriIds != null && kategoriIds.Any())
            {
                urunler = urunler.Where(u => kategoriIds.Contains(u.kategoriId));
            }

            if (saticiIds != null && saticiIds.Any())
                urunler = urunler.Where(u => saticiIds.Contains(u.saticiId));

            if (min.HasValue)
                urunler = urunler.Where(u => u.Fiyat >= min.Value);

            if (max.HasValue)
                urunler = urunler.Where(u => u.Fiyat <= max.Value);

            var urunModelList = urunler.Select(i => new urunModel
            {
                Id = i.Id,
                Adi = i.Adi.Length > 50 ? i.Adi.Substring(0, 47) + "..." : i.Adi,
                Aciklama = i.Aciklama.Length > 50 ? i.Aciklama.Substring(0, 47) + "..." : i.Aciklama,
                Fiyat = i.Fiyat,
                Stok = i.Stok,
                Resim = i.Resim ?? "default.jpg",
                kategoriId = i.kategoriId,
                saticiId = i.saticiId,
                SaticiAdi = i.Satici.Adi
            }).ToList();

            ViewBag.Kategoriler = context.kategori.ToList();

            if (kategoriIds != null && kategoriIds.Any())
            {
                var saticiList = context.urunler
                    .Where(u => kategoriIds.Contains(u.kategoriId))
                    .Select(u => u.Satici)
                    .Distinct()
                    .OrderBy(s => s.Adi)
                    .ToList();
                ViewBag.Saticilar = saticiList;
            }
            else
            {
                ViewBag.Saticilar = context.saticilar.OrderBy(s => s.Adi).ToList();
            }

            // --- EN ÖNEMLİ KISIM ---
            // Gelen filtre değerlerini View'a geri gönderiyoruz ki form elemanları durumlarını korusun.
            ViewBag.KategoriIds = kategoriIds ?? new List<int>();
            ViewBag.SaticiIds = saticiIds ?? new List<int>();
            ViewBag.Min = min;
            ViewBag.Max = max;
            ViewBag.Arama = arama;

            return View(urunModelList);
        }
        public ActionResult KaiChatPage()
        {
            return View();
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize]
        public ActionResult YorumEkle(int id, string Icerik)
        {
            var urun = context.urunler.Find(id);

            if (urun == null)
                return HttpNotFound();

            if (string.IsNullOrWhiteSpace(Icerik))
            {
                TempData["YorumHata"] = "Yorum içeriği boş olamaz.";
                return RedirectToAction("detaylar", new { id = id });
            }

            var yorum = new Yorum
            {
                UrunId = id,
                KullaniciAdi = User.Identity.Name,
                Icerik = Icerik,
                Tarih = DateTime.Now
            };

            context.Yorumlar.Add(yorum);
            context.SaveChanges();

            return RedirectToAction("detaylar", new { id = id });
        }
        [HttpPost]
        [Authorize]
        public ActionResult FavorilereEkle(int id)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return Json(new { success = false, message = "Favorilere eklemek için giriş yapmalısınız." });
            }

            var urun = context.urunler.Find(id);
            if (urun == null)
            {
                return Json(new { success = false, message = "Ürün bulunamadı." });
            }

            var userName = User.Identity.Name;
            var mevcutFavori = context.Favoriler.FirstOrDefault(f => f.UrunId == id && f.KullaniciAdi == userName);

            if (mevcutFavori != null)
            {
                return Json(new { success = false, message = "Bu ürün zaten favorilerinizde." });
            }

            var favori = new Favori
            {
                UrunId = urun.Id,
                KullaniciAdi = userName,
                Tarih = DateTime.Now
            };

            context.Favoriler.Add(favori);
            context.SaveChanges();

            return Json(new { success = true, message = "Ürün favorilerinize eklendi!" });
        }

        [HttpPost]
        [Authorize]
        public ActionResult FavorilerdenKaldir(int id)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return Json(new { success = false, message = "Favorilerden kaldırmak için giriş yapmalısınız." });
            }

            var userName = User.Identity.Name;
            var favori = context.Favoriler.FirstOrDefault(f => f.UrunId == id && f.KullaniciAdi == userName);

            if (favori == null)
            {
                return Json(new { success = false, message = "Bu ürün favorilerinizde bulunamadı." });
            }

            context.Favoriler.Remove(favori);
            context.SaveChanges();

            return Json(new { success = true, message = "Ürün favorilerinizden kaldırıldı!" });
        }
        private List<urunModel> GetPopulerUrunlerFromCSV()
        {
            string path = Server.MapPath("~/App_Data/Siparisler.csv");
            if (!System.IO.File.Exists(path))
                return new List<urunModel>();

            var satirlar = System.IO.File.ReadAllLines(path)
                .Skip(1)
                .Select(line => line.Split(','))
                .Where(parts => parts.Length >= 3)
                .Select(parts => new
                {
                    ProductId = parts[1],
                    Adet = int.TryParse(parts[2], out int adet) ? adet : 0
                })
                .GroupBy(x => x.ProductId)
                .Select(g => new { ProductId = g.Key, Total = g.Sum(x => x.Adet) })
                .OrderByDescending(x => x.Total)
                .Take(10)
                .Select(g => int.TryParse(g.ProductId, out int id) ? id : -1)
                .Where(id => id != -1)
                .ToList();

            var urunler = context.urunler
                .Where(u => satirlar.Contains(u.Id))
                .Select(u => new urunModel
                {
                    Id = u.Id,
                    Adi = u.Adi.Length > 50 ? u.Adi.Substring(0, 47) + "..." : u.Adi,
                    Aciklama = u.Aciklama.Length > 50 ? u.Aciklama.Substring(0, 47) + "..." : u.Aciklama,
                    Fiyat = u.Fiyat,
                    Stok = u.Stok,
                    Resim = u.Resim ?? "default.jpg",
                    kategoriId = u.kategoriId
                }).ToList();

            return urunler;
        }
        #endregion
    }
}