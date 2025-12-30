using eTicaretSitesi.MvcWebUI.Entity;
using eTicaretSitesi.MvcWebUI.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using Microsoft.AspNet.Identity;
using System.Web.Mvc;
using System.Linq;


public class BaseController : Controller
{
    protected DataContext context = new DataContext();

    protected override void OnActionExecuting(ActionExecutingContext filterContext)
    {
        if (User.Identity.IsAuthenticated)
        {
            var userId = User.Identity.GetUserId();

            var identityContext = new IdentityDataContext();
            var userManager = new UserManager<kullanici>(new UserStore<kullanici>(identityContext));
            var kullanici = userManager.FindById(userId);

            if (kullanici != null)
            {
                ViewBag.UserName = kullanici.UserName;
                ViewBag.ProfilResmi = kullanici.ProfilResmi ?? "default.jpg";

                var roller = userManager.GetRoles(userId);
                ViewBag.IsAdmin = roller.Contains("admin");
                ViewBag.IsSatici = roller.Contains("satici");

                bool hasSaticiProfile = context.saticilar.Any(s => s.KullaniciId == userId);
                ViewBag.HasSaticiProfile = hasSaticiProfile;
            }
        }

        base.OnActionExecuting(filterContext);
    }
}