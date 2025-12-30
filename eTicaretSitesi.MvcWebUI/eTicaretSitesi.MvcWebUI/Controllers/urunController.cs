using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using eTicaretSitesi.MvcWebUI.Entity;
using eTicaretSitesi.MvcWebUI.Helpers;
using Microsoft.AspNet.Identity;

namespace eTicaretSitesi.MvcWebUI.Controllers
{
    [Authorize(Roles = "satici")]
    public class urunController : BaseController
    {
        private DataContext db = new DataContext();
        private const string ApiUploadUrl = "https://localhost:44366/upload/";

        // GET: urun
        public ActionResult Index()
        {
            string currentUserId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(x => x.KullaniciId == currentUserId);

            if (satici == null)
            {
                return RedirectToAction("SaticiProfilDuzenle", "Satici");
            }

            var urunler = db.urunler
                            .Include(u => u.Kategori)
                            .Where(u => u.saticiId == satici.Id)
                            .ToList();

            // View'da resimleri gösterebilmek için API adresini gönder.
            ViewBag.ApiUploadUrl = ApiUploadUrl;
            return View(urunler);
        }

        // GET: urun/Create
        public ActionResult Create()
        {
            ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi");
            return View();
        }

        // POST: urun/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        // DÜZELTME: Parametre adı 'Resim' yerine 'dosyaUpload' olarak değiştirildi.
        public async Task<ActionResult> Create(urun urun, HttpPostedFileBase dosyaUpload)
        {
            if (ModelState.IsValid)
            {
                string currentUserId = User.Identity.GetUserId();
                var satici = db.saticilar.FirstOrDefault(x => x.KullaniciId == currentUserId);

                if (satici != null)
                {
                    // DÜZELTME: Parametre adı 'dosyaUpload' olarak kullanıldı.
                    if (dosyaUpload != null && dosyaUpload.ContentLength > 0)
                    {
                        string newFileName = await ApiUploader.UploadImageAsync(dosyaUpload);
                        if (!string.IsNullOrEmpty(newFileName))
                        {
                            urun.Resim = newFileName;
                        }
                        else
                        {
                            ModelState.AddModelError("", "Ürün resmi API'ye yüklenemedi.");
                            ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi", urun.kategoriId);
                            return View(urun);
                        }
                    }

                    urun.saticiId = satici.Id;
                    db.urunler.Add(urun);
                    db.SaveChanges();
                    return RedirectToAction("Index");
                }
                else
                {
                    ModelState.AddModelError("", "Satıcı profili bulunamadı.");
                }
            }

            ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi", urun.kategoriId);
            return View(urun);
        }

        // GET: urun/Edit/5
        public ActionResult Edit(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            urun urun = db.urunler.Find(id);
            if (urun == null)
            {
                return HttpNotFound();
            }
            ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi", urun.kategoriId);
            // View'da mevcut resmi gösterebilmek için API adresini gönder.
            ViewBag.ApiUploadUrl = ApiUploadUrl;
            return View(urun);
        }

        // POST: urun/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        // DÜZELTME: Parametre adı 'Resim' yerine 'dosyaUpload' olarak değiştirildi.
        public async Task<ActionResult> Edit(urun urun, HttpPostedFileBase dosyaUpload)
        {
            if (ModelState.IsValid)
            {
                string currentUserId = User.Identity.GetUserId();
                var satici = db.saticilar.FirstOrDefault(x => x.KullaniciId == currentUserId);

                if (satici == null)
                {
                    ModelState.AddModelError("", "Bu ürünü düzenlemek için yetkili satıcı bulunamadı.");
                    ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi", urun.kategoriId);
                    return View(urun);
                }

                // DÜZELTME: Parametre adı 'dosyaUpload' olarak kullanıldı.
                if (dosyaUpload != null && dosyaUpload.ContentLength > 0)
                {
                    string newFileName = await ApiUploader.UploadImageAsync(dosyaUpload);
                    if (!string.IsNullOrEmpty(newFileName))
                    {
                        urun.Resim = newFileName;
                    }
                    else
                    {
                        ModelState.AddModelError("", "Yeni ürün resmi API'ye yüklenemedi.");
                        ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi", urun.kategoriId);
                        return View(urun);
                    }
                }
                else
                {
                    var mevcutUrun = db.urunler.AsNoTracking().FirstOrDefault(u => u.Id == urun.Id);
                    if (mevcutUrun != null)
                    {
                        urun.Resim = mevcutUrun.Resim;
                    }
                }

                urun.saticiId = satici.Id;
                db.Entry(urun).State = EntityState.Modified;
                db.SaveChanges();
                return RedirectToAction("Index");
            }
            ViewBag.kategoriId = new SelectList(db.kategori, "Id", "Adi", urun.kategoriId);
            return View(urun);
        }

        #region Diğer Metotlar
        public ActionResult Details(int? id)
        {
            if (id == null)
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            string currentUserId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(x => x.KullaniciId == currentUserId);

            var urun = db.urunler.FirstOrDefault(u => u.Id == id && u.saticiId == satici.Id);

            if (urun == null)
                return HttpNotFound();

            return View(urun);
        }

        public ActionResult Delete(int? id)
        {
            if (id == null)
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);

            string currentUserId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(x => x.KullaniciId == currentUserId);

            var urun = db.urunler.FirstOrDefault(u => u.Id == id && u.saticiId == satici.Id);

            if (urun == null)
                return HttpNotFound();

            return View(urun);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            string currentUserId = User.Identity.GetUserId();
            var satici = db.saticilar.FirstOrDefault(x => x.KullaniciId == currentUserId);

            var urun = db.urunler.FirstOrDefault(u => u.Id == id && u.saticiId == satici.Id);

            if (urun == null)
                return HttpNotFound();

            db.urunler.Remove(urun);
            db.SaveChanges();
            return RedirectToAction("Index");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
        #endregion
    }
}
