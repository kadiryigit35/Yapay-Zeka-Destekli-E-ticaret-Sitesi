using System;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity;

namespace eTicaretAPI.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [Authorize(Roles = "admin")] // Bu işlemleri sadece admin rolündeki kullanıcılar yapabilir
    [RoutePrefix("api/admin/kategoriler")]
    public class KategoriYonetimApiController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // GET: api/admin/kategoriler (Tüm kategorileri listeler)
        [HttpGet, Route("")]
        public IHttpActionResult GetKategoriler()
        {
            var kategoriler = db.kategori.Select(k => new { k.Id, k.Adi, k.Aciklama }).ToList();
            return Ok(kategoriler);
        }

        // GET: api/admin/kategoriler/{id} (Tek bir kategoriyi getirir)
        [HttpGet, Route("{id:int}")]
        public IHttpActionResult GetKategori(int id)
        {
            var kategori = db.kategori.FirstOrDefault(k => k.Id == id);
            if (kategori == null)
            {
                return NotFound();
            }
            return Ok(kategori);
        }

        // POST: api/admin/kategoriler (Yeni kategori oluşturur)
        [HttpPost, Route("")]
        public IHttpActionResult CreateKategori(kategori model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            db.kategori.Add(model);
            db.SaveChanges();
            return Ok(model); // Oluşturulan kategoriyi geri döndür
        }

        // PUT: api/admin/kategoriler/{id} (Kategoriyi günceller)
        [HttpPut, Route("{id:int}")]
        public IHttpActionResult UpdateKategori(int id, kategori model)
        {
            if (!ModelState.IsValid || id != model.Id)
            {
                return BadRequest();
            }

            db.Entry(model).State = EntityState.Modified;
            try
            {
                db.SaveChanges();
            }
            catch (Exception)
            {
                if (db.kategori.All(k => k.Id != id))
                {
                    return NotFound();
                }
                throw;
            }
            return Ok(new { message = "Kategori başarıyla güncellendi." });
        }

        // DELETE: api/admin/kategoriler/{id} (Kategoriyi siler)
        [HttpDelete, Route("{id:int}")]
        public IHttpActionResult DeleteKategori(int id)
        {
            kategori kategori = db.kategori.Find(id);
            if (kategori == null)
            {
                return NotFound();
            }

            // ÖNEMLİ: Eğer bu kategoriye bağlı ürünler varsa silme işlemi hata verir.
            // Gerçek bir projede, önce bağlı ürünlerin kategorisini null yapmak veya
            // "Bu kategoriye ait ürünler olduğu için silemezsiniz" diye bir uyarı vermek gerekir.
            // Şimdilik basit bir silme işlemi yapıyoruz.
            db.kategori.Remove(kategori);
            db.SaveChanges();

            return Ok(new { message = "Kategori başarıyla silindi." });
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