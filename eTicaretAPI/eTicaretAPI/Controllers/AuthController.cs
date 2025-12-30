using System;
using System.Linq;
using System.Web.Http;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using eTicaretAPI.Identity; // Kendi IdentityContext dosyanızın yolu
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Configuration;
using System.Net;
using System.Threading.Tasks;

namespace eTicaretAPI.Controllers
{
    [RoutePrefix("api/auth")]
    public class AuthController : ApiController
    {
        private readonly UserManager<kullanici> _userManager;
        private readonly RoleManager<yetki> _roleManager;

        public AuthController()
        {
            var context = new IdentityDataContext();
            var userStore = new UserStore<kullanici>(context);
            var roleStore = new RoleStore<yetki>(context);
            _userManager = new UserManager<kullanici>(userStore);
            _roleManager = new RoleManager<yetki>(roleStore);
        }

        // POST api/auth/register
        [HttpPost]
        [Route("register")]
        public IHttpActionResult Register(RegisterModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                if (_userManager.FindByName(model.KullaniciAdi) != null)
                {
                    return BadRequest("Bu kullanıcı adı zaten kullanılıyor.");
                }

                if (_userManager.FindByEmail(model.Email) != null)
                {
                    return BadRequest("Bu email adresi zaten kullanılıyor.");
                }

                var user = new kullanici
                {
                    Adi = model.Adi,
                    Soyadi = model.Soyadi,
                    Email = model.Email,
                    UserName = model.KullaniciAdi,
                    ProfilResmi = "default.png"
                };

                var result = _userManager.Create(user, model.Sifre);

                if (result.Succeeded)
                {
                    if (_roleManager.RoleExists("Kullanici"))
                    {
                        _userManager.AddToRole(user.Id, "Kullanici");
                    }
                    return Ok(new { success = true, message = "Kayıt başarılı" });
                }
                else
                {
                    return BadRequest(string.Join(", ", result.Errors));
                }
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("login")]
        public async Task<IHttpActionResult> Login(LoginModel model) // Metodu async Task olarak güncelledik
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                // FindAsync kullanarak asenkron sorgu yapıyoruz
                var user = await _userManager.FindAsync(model.KullaniciAdi, model.Sifre);
                if (user == null)
                {
                    return BadRequest("Kullanıcı adı veya şifre yanlış.");
                }

                // --- YENİ EKLENEN BAN KONTROLÜ BAŞLANGICI ---
                if (user.BanliMi)
                {
                    // Süresi dolmuş bir ban varsa, banı kaldır ve girişine izin ver.
                    if (user.BanBitisTarihi.HasValue && user.BanBitisTarihi.Value <= DateTime.Now)
                    {
                        user.BanliMi = false;
                        user.BanBitisTarihi = null;
                        user.BanSebebi = null;
                        await _userManager.UpdateAsync(user); // Kullanıcıyı güncelle
                    }
                    else // Ban hala aktifse, girişini engelle.
                    {
                        string banMesaji = "Hesabınız askıya alınmıştır.";
                        if (user.BanBitisTarihi.HasValue)
                        {
                            banMesaji += $" Yasağınız {user.BanBitisTarihi.Value:dd.MM.yyyy HH:mm} tarihinde sona erecektir.";
                        }
                        else
                        {
                            banMesaji += " Yasağınız kalıcıdır.";
                        }
                        // 403 Forbidden (Yasaklandı) durum kodu ile özel mesajı döndür.
                        return Content(HttpStatusCode.Forbidden, new { success = false, message = banMesaji });
                    }
                }
                // --- BAN KONTROLÜ SONU ---

                var roles = await _userManager.GetRolesAsync(user.Id); // GetRolesAsync kullanarak asenkron sorgu
                var claims = new[]
                {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim(ClaimTypes.Name, user.UserName)
        }.Union(roles.Select(role => new Claim(ClaimTypes.Role, role)));

                var secretKey = ConfigurationManager.AppSettings["JwtSecretKey"];
                var issuer = ConfigurationManager.AppSettings["JwtIssuer"];
                var audience = ConfigurationManager.AppSettings["JwtAudience"];

                var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
                var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

                var token = new JwtSecurityToken(
                    issuer: issuer,
                    audience: audience,
                    claims: claims,
                    expires: DateTime.Now.AddDays(30),
                    signingCredentials: creds
                );

                var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

                return Ok(new
                {
                    success = true,
                    message = "Giriş başarılı",
                    token = tokenString,
                    user = new
                    {
                        id = user.Id,
                        adi = user.Adi,
                        soyadi = user.Soyadi,
                        email = user.Email,
                        kullaniciAdi = user.UserName,
                        profilResmi = user.ProfilResmi,
                        roles = roles
                    }
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _userManager?.Dispose();
                _roleManager?.Dispose();
            }
            base.Dispose(disposing);
        }
    }

    public class RegisterModel
    {
        public string Adi { get; set; }
        public string Soyadi { get; set; }
        public string Email { get; set; }
        public string KullaniciAdi { get; set; }
        public string Sifre { get; set; }
    }

    public class LoginModel
    {
        public string KullaniciAdi { get; set; }
        public string Sifre { get; set; }
    }
}