using eTicaretAPI.Entity;
using Microsoft.AspNet.Identity;
using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;

namespace eTicaretAPI.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/urunler/{urunId:int}/yorumlar")]
    public class CommentsController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // GET: api/urunler/{urunId}/yorumlar
        [HttpGet]
        [Route("")]
        public IHttpActionResult GetYorumlar(int urunId)
        {
            var yorumlar = db.Yorumlar
                .Where(y => y.UrunId == urunId)
                .OrderByDescending(y => y.Tarih)
                .Select(y => new { y.Id, y.KullaniciAdi, y.Icerik, y.Tarih })
                .ToList();

            return Ok(yorumlar);
        }
        // eTicaretAPI/Controllers/CommentsController.cs

        // ... using ifadeleri ve sınıf tanımı ...

        // POST: api/urunler/{urunId}/yorumlar/{yorumId}/sikayet-et
        [HttpPost]
        [Route("~/api/yorumlar/{yorumId:int}/sikayet-et")] // Yeni route tanımı
        [Authorize]
        public IHttpActionResult SikayetEt(int yorumId)
        {
            string kullaniciId = User.Identity.GetUserId();

            var zatenSikayetEdilmis = db.YorumSikayetleri.Any(s => s.YorumId == yorumId && s.SikayetEdenKullaniciId == kullaniciId);
            if (zatenSikayetEdilmis)
            {
                return Ok(new { success = true, message = "Bu yorumu zaten şikayet ettiniz." });
            }

            var sikayet = new YorumSikayet
            {
                YorumId = yorumId,
                SikayetEdenKullaniciId = kullaniciId,
                Tarih = DateTime.Now
            };

            db.YorumSikayetleri.Add(sikayet);
            db.SaveChanges();

            return Ok(new { success = true, message = "Yorum şikayetiniz yöneticiye iletildi." });
        }

        // POST: api/urunler/{urunId}/yorumlar
        [HttpPost]
        [Route("")]
        public IHttpActionResult PostYorum(int urunId, CommentAddModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            // Burada Authorize attribute'u ekleyerek sadece giriş yapanların yorum yapmasını sağlayabilirsiniz.
            // Örn: [Authorize]

            var yorum = new Yorum
            {
                UrunId = urunId,
                KullaniciAdi = model.KullaniciAdi, // Token'dan almak daha güvenlidir.
                Icerik = model.Icerik,
                Tarih = DateTime.Now
            };

            db.Yorumlar.Add(yorum);
            db.SaveChanges();

            return Ok(new { success = true, message = "Yorum başarıyla eklendi." });
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }
    }

    // Yorum eklemek için kullanılacak model
    public class CommentAddModel
    {
        public string KullaniciAdi { get; set; }
        public string Icerik { get; set; }
    }
}