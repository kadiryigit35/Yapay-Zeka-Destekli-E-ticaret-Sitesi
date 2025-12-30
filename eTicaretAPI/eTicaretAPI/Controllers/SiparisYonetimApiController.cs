using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity;
using Microsoft.AspNet.Identity;

// Bu DTO modeli Models klasörüne ekleyin
public class SiparisDurumUpdateModel
{
    public string YeniDurum { get; set; }
}

namespace eTicaretSitesi.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [Authorize(Roles = "satici")]
    [RoutePrefix("api/satici/siparisler")]
    public class SiparisYonetimApiController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // GET: api/satici/siparisler
        [HttpGet, Route("")]
        public IHttpActionResult GetSiparisler()
        {
            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            if (satici == null) return Unauthorized();

            var urunIds = db.urunler.Where(u => u.saticiId == satici.Id).Select(u => u.Id).ToList();

            var siparisler = db.siparisler
                .Where(s => s.GetSiparisYolu.Any(sy => urunIds.Contains(sy.UrunId)))
                .Select(s => new
                {
                    // Flutter'daki Order modeline göre alan isimleri düzenlendi
                    Id = s.Id,
                    SiparisNumarasi = s.SiparisNumarasi,
                    SiparisTarihi = s.SiparisTarihi,
                    siparisDurum = s.siparisDurum.ToString(),
                    Toplam = s.Toplam,
                    // Flutter'daki OrderItem modeline göre düzenlendi
                    SiparisKalemleri = s.GetSiparisYolu
                                .Where(sy => urunIds.Contains(sy.UrunId))
                                .Select(urun => new {
                                    UrunId = urun.UrunId,
                                    UrunAdi = urun.urun.Adi,
                                    Adet = urun.Adet,
                                    Fiyat = urun.Fiyat,
                                    UrunResim = urun.urun.Resim
                                }),
                    // Flutter'daki Address modeline göre düzenlendi
                    TeslimatAdresi = new
                    {
                        Id = 0, // Adresler ayrı bir tabloda ise oradan çekilebilir, şimdilik sabit
                        TamAd = s.TamAd,
                        Adres = s.Adres,
                        Sehir = s.Sehir,
                        Mahalle = s.Mahalle,
                        Sokak = "", // Veritabanınızda bu alanlar varsa ekleyin
                        PostaKodu = s.PostaKodu,
                        Telefon = s.telefon
                    }
                })
                .OrderByDescending(s => s.SiparisTarihi)
                .ToList();

            return Ok(siparisler);
        }

        // POST: api/satici/siparisler/{siparisId}/durum
        [HttpPost]
        [Route("{siparisId:int}/durum")]
        public IHttpActionResult UpdateSiparisDurumu(int siparisId, SiparisDurumUpdateModel model)
        {
            var siparis = db.siparisler.FirstOrDefault(s => s.Id == siparisId);
            if (siparis == null) return NotFound();

            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            var urunIds = db.urunler.Where(u => u.saticiId == satici.Id).Select(u => u.Id).ToList();
            bool yetkili = siparis.GetSiparisYolu.Any(sy => urunIds.Contains(sy.UrunId));

            if (!yetkili) return Unauthorized();

            if (System.Enum.TryParse(model.YeniDurum, out EnumsiparisDurum yeniDurum))
            {
                siparis.siparisDurum = yeniDurum;
                db.SaveChanges();
                return Ok(new { message = "Sipariş durumu güncellendi." });
            }

            return BadRequest("Geçersiz sipariş durumu.");
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