using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;
using System.Data.Entity;
using eTicaretAPI.Entity;
using System.IO;
using Microsoft.AspNet.Identity;

namespace eTicaretAPI.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/urunler")]
    public class UrunlerController : ApiController // Sınıf adını dosya adıyla aynı yaptım
    {
        private readonly DataContext db = new DataContext();

        [HttpGet]
        [Route("")]
        public IHttpActionResult GetUrunler(
                 // DEĞİŞİKLİK 1: Parametreleri List<int> yerine string olarak alıyoruz.
                 [FromUri] string kategoriIds = null,
                 [FromUri] string saticiIds = null,
                 [FromUri] double? minFiyat = null,
                 [FromUri] double? maxFiyat = null,
                 [FromUri] string searchQuery = null)
        {
            try
            {
                var query = db.urunler
                              .Where(u => u.kategoriId != null && u.saticiId != null)
                              .Include(u => u.Satici)
                              .AsQueryable();

                if (!string.IsNullOrEmpty(searchQuery))
                {
                    searchQuery = searchQuery.ToLower();
                    query = query.Where(u => u.Adi.ToLower().Contains(searchQuery));
                }

                // DEĞİŞİKLİK 2: Gelen string'i (örn: "1,5") virgülden ayırıp integer listesine çeviriyoruz.
                if (!string.IsNullOrEmpty(kategoriIds))
                {
                    List<int> kategoriIdList = kategoriIds.Split(',').Select(int.Parse).ToList();
                    if (kategoriIdList.Any())
                    {
                        // Sorguyu bu yeni oluşturduğumuz liste ile yapıyoruz.
                        query = query.Where(u => kategoriIdList.Contains(u.kategoriId));
                    }
                }

                // DEĞİŞİKLİK 3: Aynı işlemi satıcılar için de yapıyoruz.
                if (!string.IsNullOrEmpty(saticiIds))
                {
                    List<int> saticiIdList = saticiIds.Split(',').Select(int.Parse).ToList();
                    if (saticiIdList.Any())
                    {
                        query = query.Where(u => saticiIdList.Contains(u.saticiId));
                    }
                }

                if (minFiyat.HasValue)
                {
                    query = query.Where(u => u.Fiyat >= minFiyat.Value);
                }

                if (maxFiyat.HasValue)
                {
                    query = query.Where(u => u.Fiyat <= maxFiyat.Value);
                }

                var urunler = query.ToList().Select(u => new {
                    u.Id,
                    u.Adi,
                    u.Aciklama,
                    u.Fiyat,
                    u.Stok,
                    u.Resim,
                    u.kategoriId,
                    u.saticiId,
                    OrtalamaPuan = u.Puanlar.Any() ? u.Puanlar.Average(p => p.Deger) : 0.0,
                    ToplamPuanSayisi = u.Puanlar.Count(),
                    Satici = u.Satici != null ? new { u.Satici.Id, u.Satici.Adi } : null
                });

                return Ok(urunler);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }


        [HttpGet]
        [Route("{id:int}")]
        public IHttpActionResult GetUrun(int id)
        {
            try
            {
                // GÜNCELLEME: Puanları da sorguya dahil ediyoruz (Include)
                var urun = db.urunler
                    .Include(u => u.Satici)
                    .Include(u => u.Yorumlar)
                    .Include(u => u.Puanlar) // YENİ EKLENDİ
                    .Where(u => u.Id == id)
                    .Select(u => new
                    {
                        u.Id,
                        u.Adi,
                        u.Aciklama,
                        u.Fiyat,
                        u.Stok,
                        u.Resim,
                        u.kategoriId,
                        u.saticiId,
                        Satici = u.Satici == null ? null : new { u.Satici.Id, u.Satici.Adi },
                        Yorumlar = u.Yorumlar.Select(y => new { y.Id, y.KullaniciAdi, y.Icerik, y.Tarih }).OrderByDescending(y => y.Tarih).ToList(),
                        // GÜNCELLEME: Ortalama puan ve toplam oy sayısını da API cevabına ekliyoruz.
                        OrtalamaPuan = u.Puanlar.Any() ? u.Puanlar.Average(p => p.Deger) : 0,
                        ToplamPuanSayisi = u.Puanlar.Count()
                    })
                    .FirstOrDefault();

                if (urun == null)
                {
                    return NotFound();
                }

                return Ok(urun);
            }
            catch (Exception ex)
            {
                return BadRequest("Ürün detayı yüklenirken hata oluştu: " + ex.Message);
            }
        }

        // YENİ METOT: Ürüne puan vermek için endpoint
        // POST: api/urunler/{id}/puanla
        [HttpPost]
        [Route("{id:int}/puanla")]
        [Authorize] // Sadece giriş yapmış kullanıcılar puan verebilir
        public IHttpActionResult PuanEkle(int id, PuanDto puanModel)
        {
            if (puanModel == null || puanModel.Deger < 1 || puanModel.Deger > 5)
            {
                return BadRequest("Geçersiz puan değeri. Puan 1 ile 5 arasında olmalıdır.");
            }

            string kullaniciId = User.Identity.GetUserId();
            if (string.IsNullOrEmpty(kullaniciId))
            {
                return Unauthorized();
            }

            // Kullanıcı bu ürüne daha önce puan vermiş mi kontrol et
            var mevcutPuan = db.Puanlar.FirstOrDefault(p => p.UrunId == id && p.KullaniciId == kullaniciId);

            if (mevcutPuan != null)
            {
                // Eğer daha önce puan verdiyse, puanını güncelle
                mevcutPuan.Deger = puanModel.Deger;
                mevcutPuan.Tarih = DateTime.Now;
            }
            else
            {
                // Daha önce puan vermediyse, yeni puan oluştur
                var yeniPuan = new Puan
                {
                    UrunId = id,
                    KullaniciId = kullaniciId,
                    Deger = puanModel.Deger,
                    Tarih = DateTime.Now
                };
                db.Puanlar.Add(yeniPuan);
            }

            db.SaveChanges();
            return Ok(new { message = "Puanınız başarıyla kaydedildi." });
        }

        // GET: api/urunler/onerilen/{kullaniciId}
        [HttpGet]
        [Route("onerilen/{kullaniciId}")]
        public IHttpActionResult GetOnerilenUrunler(string kullaniciId)
        {
            if (string.IsNullOrEmpty(kullaniciId))
            {
                return BadRequest("Kullanıcı ID'si gereklidir.");
            }
            // GÜNCELLENDİ: Artık IHttpActionResult döndürmeyen doğru metodu çağırıyor
            var onerilenler = GetOneriler(kullaniciId);
            return Ok(onerilenler);
        }

        private List<object> GetOneriler(string kullaniciId)
        {
            string path = System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/Siparisler.csv");
            if (!File.Exists(path))
            {
                // GÜNCELLENDİ: Popüler ürün mantığını çağıran yeni özel metot kullanılıyor.
                return FetchPopulerUrunlerLogic();
            }

            var satirlar = File.ReadAllLines(path)
                .Skip(1)
                .Select(line => line.Split(','))
                .Where(parts => parts.Length >= 3)
                .Select(parts => new { UserId = parts[0], ProductId = parts[1] })
                .GroupBy(x => new { x.UserId, x.ProductId })
                .Select(g => g.First())
                .ToList();

            var benimUrunlerim = satirlar
                .Where(p => p.UserId == kullaniciId)
                .Select(p => p.ProductId)
                .Distinct().ToList();

            if (!benimUrunlerim.Any())
            {
                // GÜNCELLENDİ: Popüler ürün mantığını çağıran yeni özel metot kullanılıyor.
                return FetchPopulerUrunlerLogic();
            }

            var digerKullanicilar = satirlar
                .Where(p => p.UserId != kullaniciId && benimUrunlerim.Contains(p.ProductId))
                .Select(p => p.UserId)
                .Distinct().ToList();

            var digerUrunIds = satirlar
                .Where(p => digerKullanicilar.Contains(p.UserId) && !benimUrunlerim.Contains(p.ProductId))
                .Select(p => p.ProductId)
                .Distinct()
                .Select(int.Parse)
                .ToList();

            var onerilenUrunler = db.urunler
                .Where(u => digerUrunIds.Contains(u.Id))
                .OrderByDescending(u => u.Id)
                .Take(5)
                .Select(u => new { u.Id, u.Adi, u.Aciklama, u.Fiyat, u.Stok, u.Resim, u.kategoriId, u.saticiId })
                .ToList<object>();

            // GÜNCELLENDİ: Popüler ürün mantığını çağıran yeni özel metot kullanılıyor.
            return onerilenUrunler.Any() ? onerilenUrunler : FetchPopulerUrunlerLogic();
        }

        // GET: api/urunler/populer
        [HttpGet]
        [Route("populer")]
        public IHttpActionResult GetPopulerUrunler()
        {
            try
            {
                // GÜNCELLENDİ: Tüm mantık yeni özel metoda taşındı, sadece onu çağırıyor.
                var urunler = FetchPopulerUrunlerLogic();
                return Ok(urunler);
            }
            catch (Exception ex)
            {
                return BadRequest("Popüler ürünler yüklenirken hata oluştu: " + ex.Message);
            }
        }

        // YENİ ÖZEL METOT: Popüler ürünleri getiren mantığı içerir ve List<object> döndürür.
        private List<object> FetchPopulerUrunlerLogic()
        {
            string path = System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/Siparisler.csv");
            if (!File.Exists(path))
            {
                return new List<object>();
            }

            var populerUrunIds = File.ReadAllLines(path)
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

            var urunler = db.urunler
                .Where(u => populerUrunIds.Contains(u.Id))
                .Select(u => new { u.Id, u.Adi, u.Aciklama, u.Fiyat, u.Stok, u.Resim, u.kategoriId, u.saticiId })
                .ToList<object>();

            return urunler;
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
        // Bu sınıfı projenizde uygun bir yere ekleyin.
        public class PuanDto
        {
            // Değer 1-5 arasında olmalı
            public int Deger { get; set; }
        }
    }
}