using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using eTicaretSitesi.MvcWebUI.Entity;
using eTicaretSitesi.MvcWebUI.Helpers;
using eTicaretSitesi.MvcWebUI.Identity; // Identity context için using eklendi
using eTicaretSitesi.MvcWebUI.Models;
using Microsoft.AspNet.Identity;

namespace eTicaretSitesi.MvcWebUI.Controllers
{
    [Authorize(Roles = "satici")]
    public class SaticiController : BaseController
    {
        private DataContext db = new DataContext();
        // Identity verilerine eriþmek için IdentityDataContext örneði oluþturuldu.
        private IdentityDataContext identityDb = new IdentityDataContext();

        // GET: Satýcý profil düzenleme veya oluþturma sayfasý
        public ActionResult SaticiProfilDuzenle()
        {
            string kullaniciId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);

            // Eðer satýcý profili veritabanýnda yoksa,
            // kullanýcý için yeni bir profil oluþturma formu hazýrla.
            if (satici == null)
            {
                // Hata veren satýr düzeltildi: Kullanýcý bilgisi artýk doðru context olan 'identityDb' üzerinden alýnýyor.
                var user = identityDb.Users.Find(kullaniciId);
                satici = new satici()
                {
                    KullaniciId = kullaniciId,
                    Adi = user?.UserName // Baþlangýç deðeri olarak kullanýcý adýný ata
                };
            }

            return View(satici);
        }

        // POST: Satýcý profil oluþturma veya güncelleme iþlemi
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> SaticiProfilDuzenle(satici model, HttpPostedFileBase Resim)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            string kullaniciId = User.Identity.GetUserId();
            model.KullaniciId = kullaniciId; // Güvenlik için kullanýcý ID'sini sunucu tarafýnda tekrar ata.

            // Resim yükleme iþlemi (API üzerinden)
            if (Resim != null && Resim.ContentLength > 0)
            {
                string newFileName = await ApiUploader.UploadImageAsync(Resim);
                if (!string.IsNullOrEmpty(newFileName))
                {
                    model.Resim = newFileName;
                }
                else
                {
                    ModelState.AddModelError("", "Satýcý resmi API'ye yüklenemedi.");
                    return View(model);
                }
            }

            // Eðer model.Id 0 ise, bu yeni bir kayýttýr.
            if (model.Id == 0)
            {
                db.saticilar.Add(model);
            }
            else // Aksi takdirde mevcut bir kaydý güncelle.
            {
                var dbSatici = db.saticilar.FirstOrDefault(s => s.Id == model.Id && s.KullaniciId == kullaniciId);
                if (dbSatici == null)
                {
                    return HttpNotFound("Güncellenecek satýcý profili bulunamadý veya bu profile eriþim yetkiniz yok.");
                }

                dbSatici.Adi = model.Adi;
                dbSatici.Hakkinda = model.Hakkinda;
                // Yeni resim yüklendiyse, model.Resim dolu olacaktýr.
                // Yüklenmediyse, eski resim bilgisi korunmuþ olur.
                if (!string.IsNullOrEmpty(model.Resim))
                {
                    dbSatici.Resim = model.Resim;
                }
            }

            db.SaveChanges();
            TempData["Mesaj"] = "Profiliniz baþarýyla kaydedildi.";

            // DÜZELTME: Profil kaydedildikten sonra ürünler sayfasýna deðil,
            // tekrar profil düzenleme sayfasýna yönlendir.
            return RedirectToAction("SaticiProfilDuzenle", "Satici");
        }


        // --- Diðer metotlarýnýz burada deðiþikliðe uðramadan devam ediyor ---
        #region Diðer Metotlar
    [AllowAnonymous]
public ActionResult Profil(int id)
{
    // Satýcýyý puanlarýyla birlikte getir (Include metodu eklendi)
    var satici = db.saticilar.Include(s => s.Puanlar).FirstOrDefault(s => s.Id == id);

    if (satici == null)
        return HttpNotFound();

    var urunler = db.urunler
        .Where(u => u.saticiId == id)
        .Select(u => new urunModel
        {
            Id = u.Id,
            Adi = u.Adi.Length > 50 ? u.Adi.Substring(0, 47) + "..." : u.Adi,
            Aciklama = u.Aciklama.Length > 50 ? u.Aciklama.Substring(0, 47) + "..." : u.Aciklama,
            Fiyat = u.Fiyat,
            Stok = u.Stok,
            Resim = string.IsNullOrEmpty(u.Resim) ? "default.jpg" : u.Resim,
            kategoriId = u.kategoriId,
            saticiId = u.saticiId,
            SaticiAdi = u.Satici.Adi
        })
        .ToList();

    ViewBag.Urunler = urunler;

    return View(satici);
}
        public ActionResult siparisYonet()
        {
            string kullaniciId = User.Identity.GetUserId();

            var satici = db.saticilar.FirstOrDefault(s => s.KullaniciId == kullaniciId);
            if (satici == null)
                return HttpNotFound("Satýcý bulunamadý.");

            var urunIds = db.urunler
                .Where(u => u.saticiId == satici.Id)
                .Select(u => u.Id)
                .ToList();

            var siparisDetaylar = db.siparisYolu
                .Where(sy => urunIds.Contains(sy.UrunId))
                .OrderByDescending(sy => sy.Siparis.SiparisTarihi)
                .ToList();

            return View(siparisDetaylar);
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SiparisDurumGuncelle(int siparisId, EnumsiparisDurum yeniDurum)
        {
            var siparis = db.siparisler.FirstOrDefault(s => s.Id == siparisId);
            if (siparis == null)
                return HttpNotFound("Sipariþ bulunamadý.");

            siparis.siparisDurum = yeniDurum;
            db.SaveChanges();

            return RedirectToAction("siparisYonet");
        }
        #endregion

        // Her iki veritabaný baðlantýsýný da sonlandýrmak için Dispose metodu eklendi.
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
                identityDb.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
