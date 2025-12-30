using Microsoft.Owin;
using Owin;
using Microsoft.Owin.Security.Jwt;
using Microsoft.Owin.Security;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Configuration;
using System.Diagnostics;

// Bu satırı, projenizin namespace'i ile aynı olacak şekilde kontrol edin.
[assembly: OwinStartup(typeof(eTicaretAPI.Startup))]

namespace eTicaretAPI
{
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            Debug.WriteLine(">>> OWIN Startup.cs Configuration metodu KESİNLİKLE çalıştı!");
            var secretKey = ConfigurationManager.AppSettings["JwtSecretKey"];
            var issuer = ConfigurationManager.AppSettings["JwtIssuer"];
            var audience = ConfigurationManager.AppSettings["JwtAudience"];

            app.UseJwtBearerAuthentication(
                new JwtBearerAuthenticationOptions
                {
                    // DÜZELTME: Hatanın olduğu satır. Derleyiciye tam yolu belirttik.
                    AuthenticationMode = Microsoft.Owin.Security.AuthenticationMode.Active,
                    TokenValidationParameters = new TokenValidationParameters()
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = issuer,
                        ValidAudience = audience,
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
                    }
                });
        }
    }
}