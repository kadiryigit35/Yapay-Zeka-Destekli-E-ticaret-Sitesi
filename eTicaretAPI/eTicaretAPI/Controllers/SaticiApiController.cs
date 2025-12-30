using System;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity;
using Microsoft.AspNet.Identity;

// Bu DTO sınıfı, ProductController'daki ile aynı olduğu için
// oradan referans alınabilir veya ortak bir yere taşınabilir.
// Şimdilik burada da tanımlıyorum.
public class PuanDto
{
    public int Deger { get; set; }
}

public class SaticiProfilModel
{
    public string Adi { get; set; }
    public string Hakkinda { get; set; }
    public string Resim { get; set; }

}

namespace eTicaretSitesi.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class SaticiApiController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // api/saticilar/{id} - Satıcı profili ve ürünleri
        [HttpGet]
        [Route("api/saticilar/{id:int}")]
        public IHttpActionResult GetSaticiProfiliVeUrunleri(int id)
        {
            // GÜNCELLEME: Satıcının puanlarını da sorguya dahil ediyoruz (Include).
            var satici = db.saticilar.Include(s => s.Puanlar).FirstOrDefault(s => s.Id == id);
            if (satici == null)
            {
                return NotFound();
            }

            var urunler = db.urunler
                .Where(u => u.saticiId == id)
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
                    Satici = new { u.Satici.Id, u.Satici.Adi }
                })
                .ToList();

            var saticiProfili = new
            {
                satici.Id,
                satici.Adi,
                satici.Hakkinda,
                satici.Resim,
                // YENİ EKLENEN ALANLAR
                OrtalamaPuan = satici.Puanlar.Any() ? satici.Puanlar.Average(p => p.Deger) : 0,
                ToplamPuanSayisi = satici.Puanlar.Count(),
                Urunler = urunler
            };

            return Ok(saticiProfili);
        }

        // api/satici/profil - Satıcının kendi profilini yönetmesi için (Yetki Gerekir)
        [HttpGet]
        [Authorize(Roles = "satici")]
        [Route("api/satici/profil")]
        public IHttpActionResult GetSaticiProfili()
        {
            string kullaniciId = User.Identity.GetUserId();
            if (string.IsNullOrEmpty(kullaniciId))
            {
                return Unauthorized();
            }

            var satici = db.saticilar
                .Where(s => s.KullaniciId == kullaniciId)
                .Select(s => new {
                    s.Id,
                    s.Adi,
                    s.Hakkinda,
                    s.Resim
                })
                .FirstOrDefault();

            if (satici == null)
            {
                return NotFound();
            }

            return Ok(satici);
        }

        // api/satici/profil - Satıcının kendi profilini güncellemesi için (Yetki Gerekir)
        [HttpPut]
        [Authorize(Roles = "satici")]
        [Route("api/satici/profil")]
        public IHttpActionResult UpdateSaticiProfili(SaticiProfilModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);

            if (satici == null)
            {
                return NotFound();
            }

            satici.Adi = model.Adi;
            satici.Hakkinda = model.Hakkinda;

            if (!string.IsNullOrEmpty(model.Resim))
            {
                satici.Resim = model.Resim;
            }
            db.Entry(satici).State = EntityState.Modified;
            db.SaveChanges();

            return Ok(new { message = "Profil başarıyla güncellendi." });
        }

        [HttpPost]
        [Authorize] // Sadece giriş yapanlar puan verebilir
        [Route("api/saticilar/{id:int}/puanla")]
        public IHttpActionResult Puanla(int id, PuanDto puanModel)
        {
            if (puanModel == null || puanModel.Deger < 1 || puanModel.Deger > 5)
            {
                return BadRequest("Geçersiz puan değeri.");
            }

            string kullaniciId = User.Identity.GetUserId();
            var mevcutPuan = db.SaticiPuanlari.FirstOrDefault(p => p.SaticiId == id && p.KullaniciId == kullaniciId);

            if (mevcutPuan != null)
            {
                mevcutPuan.Deger = puanModel.Deger;
                mevcutPuan.Tarih = DateTime.Now;
            }
            else
            {
                var yeniPuan = new SaticiPuan
                {
                    SaticiId = id,
                    KullaniciId = kullaniciId,
                    Deger = puanModel.Deger,
                    Tarih = DateTime.Now
                };
                db.SaticiPuanlari.Add(yeniPuan);
            }

            db.SaveChanges();
            return Ok(new { message = "Satıcıya verdiğiniz puan kaydedildi." });
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}