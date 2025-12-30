// eTicaretSitesi.MvcWebUI/Controllers/KullaniciYonetimiController.cs
using System.Net;
using System.Web.Mvc;

namespace eTicaretSitesi.MvcWebUI.Controllers
{
    [Authorize(Roles = "admin")]
    public class KullaniciYonetimiController : Controller
    {
        // GET: KullaniciYonetimi
        public ActionResult Index()
        {
            // Bu View, API'den veri çekecek olan JavaScript kodunu barındıracak.
            return View();
        }
        public ActionResult YorumlariGor(string kullaniciAdi)
        {
            if (string.IsNullOrEmpty(kullaniciAdi))
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            ViewBag.KullaniciAdi = kullaniciAdi;
            return View();
        }
        public ActionResult Sikayetler()
        {
            return View();
        }
    }
}