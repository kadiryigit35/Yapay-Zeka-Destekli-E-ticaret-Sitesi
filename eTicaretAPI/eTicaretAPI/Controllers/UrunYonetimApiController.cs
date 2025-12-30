using System;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity;
using Microsoft.AspNet.Identity;

namespace eTicaretSitesi.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [Authorize(Roles = "satici")]
    [RoutePrefix("api/satici/urunler")]
    public class UrunYonetimApiController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // GET: api/satici/urunler
        [HttpGet, Route("")]
        public IHttpActionResult GetUrunlerim()
        {
            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            if (satici == null) return Unauthorized();

            var urunler = db.urunler
                .Where(u => u.saticiId == satici.Id)
                .Select(u => new
                {
                    u.Id,
                    u.Adi,
                    u.Aciklama,
                    u.Fiyat,
                    u.Stok,
                    u.Resim,
                    u.kategoriId,
                    u.saticiId
                })
                .ToList();

            return Ok(urunler);
        }

        // POST: api/satici/urunler
        [HttpPost, Route("")]
        public IHttpActionResult CreateUrun(urun urunModel)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest("Geçersiz model verisi.");
            }

            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            if (satici == null)
            {
                return Unauthorized();
            }

            urunModel.saticiId = satici.Id;
            db.urunler.Add(urunModel);
            db.SaveChanges();
            return Ok(urunModel);
        }

        // PUT: api/satici/urunler/{id}
        [HttpPut, Route("{id:int}")]
        public IHttpActionResult UpdateUrun(int id, urun urunModel)
        {
            if (!ModelState.IsValid || id != urunModel.Id)
            {
                return BadRequest("Geçersiz model verisi.");
            }

            var kategoriVarMi = db.kategori.Any(k => k.Id == urunModel.kategoriId);
            if (!kategoriVarMi)
            {
                return BadRequest("Geçersiz bir kategori seçtiniz.");
            }

            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            if (satici == null) return Unauthorized();

            var mevcutUrun = db.urunler.AsNoTracking().FirstOrDefault(u => u.Id == id && u.saticiId == satici.Id);
            if (mevcutUrun == null) return NotFound();

            urunModel.saticiId = satici.Id;
            db.Entry(urunModel).State = EntityState.Modified;
            db.SaveChanges();
            return Ok(new { message = "Ürün başarıyla güncellendi." });
        }

        // YENİ EKLENDİ: Ürün silme metodu
        // DELETE: api/satici/urunler/{id}
        [HttpDelete, Route("{id:int}")]
        public IHttpActionResult DeleteUrun(int id)
        {
            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            if (satici == null)
            {
                return Unauthorized();
            }

            var urun = db.urunler.FirstOrDefault(u => u.Id == id && u.saticiId == satici.Id);
            if (urun == null)
            {
                // Satıcı, kendisine ait olmayan bir ürünü silmeye çalışırsa veya ürün yoksa
                return NotFound();
            }

            db.urunler.Remove(urun);
            db.SaveChanges();

            return Ok(new { message = "Ürün başarıyla silindi." });
        }
    }
}