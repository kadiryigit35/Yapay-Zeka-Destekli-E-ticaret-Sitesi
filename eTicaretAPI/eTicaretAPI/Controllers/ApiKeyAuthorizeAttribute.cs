// ApiKeyAuthorizeAttribute.cs (GÜNCELLENMİŞ HALİ)

using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Controllers;

public class ApiKeyAuthorizeAttribute : AuthorizeAttribute
{
    protected override bool IsAuthorized(HttpActionContext actionContext)
    {
        // 1. Önce mobil uygulamanın gönderdiği Bearer Token kontrol ediliyor.
        // base.IsAuthorized metodu, [Authorize] etiketinin standart kontrolünü yapar.
        if (base.IsAuthorized(actionContext))
        {
            // Eğer geçerli bir token varsa, isteğe izin ver.
            return true;
        }

        // 2. Eğer token yoksa veya geçersizse, web sitesinin gönderdiği API Key kontrol ediliyor.
        var apiKey = ConfigurationManager.AppSettings["ApiKey"];
        if (string.IsNullOrEmpty(apiKey))
        {
            // API Key web.config'de tanımlı değilse asla izin verme.
            return false;
        }

        if (actionContext.Request.Headers.TryGetValues("X-API-KEY", out var headerValues))
        {
            var requestApiKey = headerValues.FirstOrDefault();

            // Anahtarlar eşleşiyorsa isteğe izin ver
            if (requestApiKey != null && requestApiKey == apiKey)
            {
                return true;
            }
        }

        // Hem token hem de API anahtarı başarısız olursa isteği reddet
        return false;
    }

    protected override void HandleUnauthorizedRequest(HttpActionContext actionContext)
    {
        actionContext.Response = new HttpResponseMessage(HttpStatusCode.Unauthorized)
        {
            Content = new StringContent("Yetkisiz Erişim: Geçerli bir Bearer Token veya API anahtarı gereklidir.")
        };
    }
}