using System.Web.Http;
using System.Web.Http.Cors;

namespace eTicaretAPI
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // CORS aktif et (tüm domainlerden erişime izin ver)
            config.EnableCors(new EnableCorsAttribute("*", "*", "*"));

            // JSON formatını varsayılan yap
            config.Formatters.Remove(config.Formatters.XmlFormatter);
            config.Formatters.JsonFormatter.SerializerSettings.ReferenceLoopHandling =
                Newtonsoft.Json.ReferenceLoopHandling.Ignore;

            // Attribute routing
            config.MapHttpAttributeRoutes();

            // Default API route
            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );
        }
    }
}
