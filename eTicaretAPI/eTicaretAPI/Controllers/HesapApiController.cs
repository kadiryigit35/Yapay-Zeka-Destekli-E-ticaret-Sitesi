using eTicaretAPI.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using Microsoft.AspNet.Identity.Owin;
using Microsoft.AspNet.Identity;
using Microsoft.Owin.Security.DataProtection;
using System.Collections.Generic;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web.Http.Cors;
using System.Web.Http;
using System;
using eTicaretAPI.Models;

[EnableCors(origins: "*", headers: "*", methods: "*")]
[RoutePrefix("api/hesap")]
public class HesapApiController : ApiController
{
    private readonly UserManager<kullanici> _userManager;
    private static readonly Dictionary<string, string> Kodlar = new Dictionary<string, string>();

    public HesapApiController()
    {
        var userStore = new UserStore<kullanici>(new IdentityDataContext());
        _userManager = new UserManager<kullanici>(userStore);

        var provider = new DpapiDataProtectionProvider("eTicaretSitesiApp");
        _userManager.UserTokenProvider = new DataProtectorTokenProvider<kullanici>(provider.Create("ASP.NET Identity"));
    }

    [HttpPost, Route("sifre-sifirlama/kod-gonder")]
    public async Task<IHttpActionResult> KodGonder(SifreSifirlaViewModel model)
    {
        try
        {
            System.Diagnostics.Debug.WriteLine($"POST isteği alındı. Email: {model?.Email}");

            if (model == null || string.IsNullOrWhiteSpace(model.Email))
            {
                return Json(new { success = false, Message = "E-posta adresi boş olamaz." });
            }

            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
            {
                return Content(System.Net.HttpStatusCode.BadRequest,
                    new { success = false, Message = "Bu e-posta adresi sistemde kayıtlı değil." });
            }

            var kod = new Random().Next(100000, 999999).ToString();

            if (Kodlar.ContainsKey(model.Email))
                Kodlar[model.Email] = kod;
            else
                Kodlar.Add(model.Email, kod);

            try
            {
                // <--- DEĞİŞİKLİK 1: E-posta gönderme satırı aktif edildi.
                await MailGonderAsync(model.Email, "Şifre Sıfırlama Kodu", $"Şifre sıfırlama kodunuz: <b>{kod}</b>");

                System.Diagnostics.Debug.WriteLine($"Oluşturulan kod: {kod}");

                return Json(new { success = true, Message = "Doğrulama kodu e-posta adresinize gönderildi." });
            }
            catch (Exception mailEx)
            {
                System.Diagnostics.Debug.WriteLine($"Mail gönderme hatası: {mailEx.Message}");
                return Content(System.Net.HttpStatusCode.InternalServerError,
                    new { success = false, Message = "E-posta gönderilirken hata oluştu: " + mailEx.Message });
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Genel hata: {ex.Message}");
            return Content(System.Net.HttpStatusCode.InternalServerError,
                new { success = false, Message = "Bir hata oluştu: " + ex.Message });
        }
    }

    [HttpPost, Route("sifre-sifirlama/kod-dogrula")]
    public IHttpActionResult KodDogrula(SifreSifirlaViewModel model)
    {
        try
        {
            if (model == null || string.IsNullOrWhiteSpace(model.Email) || string.IsNullOrWhiteSpace(model.GirilenKod))
            {
                return Content(System.Net.HttpStatusCode.BadRequest,
                    new { success = false, Message = "E-posta ve kod gereklidir." });
            }

            if (Kodlar.ContainsKey(model.Email) && Kodlar[model.Email] == model.GirilenKod)
            {
                return Json(new { success = true, Message = "Kod başarıyla doğrulandı." });
            }

            return Content(System.Net.HttpStatusCode.BadRequest,
                new { success = false, Message = "Girilen kod yanlış veya süresi dolmuş." });
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Kod doğrulama hatası: {ex.Message}");
            return Content(System.Net.HttpStatusCode.InternalServerError,
                new { success = false, Message = "Kod doğrulanırken hata oluştu: " + ex.Message });
        }
    }

    [HttpPost, Route("sifre-sifirlama/yeni-sifre")]
    public async Task<IHttpActionResult> YeniSifre(SifreSifirlaViewModel model)
    {
        try
        {
            if (model == null || string.IsNullOrWhiteSpace(model.Email) ||
                string.IsNullOrWhiteSpace(model.GirilenKod) || string.IsNullOrWhiteSpace(model.YeniSifre))
            {
                return Content(System.Net.HttpStatusCode.BadRequest,
                    new { success = false, Message = "Tüm alanlar gereklidir." });
            }

            if (!Kodlar.ContainsKey(model.Email) || Kodlar[model.Email] != model.GirilenKod)
            {
                return Content(System.Net.HttpStatusCode.BadRequest,
                    new { success = false, Message = "Kod doğrulama başarısız. Lütfen işlemi baştan başlatın." });
            }

            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
            {
                return Content(System.Net.HttpStatusCode.NotFound,
                    new { success = false, Message = "Kullanıcı bulunamadı." });
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(user.Id);
            var result = await _userManager.ResetPasswordAsync(user.Id, token, model.YeniSifre);

            if (result.Succeeded)
            {
                Kodlar.Remove(model.Email); // Kodu temizle
                return Json(new { success = true, Message = "Şifreniz başarıyla güncellendi." });
            }

            return Content(System.Net.HttpStatusCode.BadRequest,
                new { success = false, Message = string.Join(", ", result.Errors) });
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Şifre güncelleme hatası: {ex.Message}");
            return Content(System.Net.HttpStatusCode.InternalServerError,
                new { success = false, Message = "Şifre güncellenirken hata oluştu: " + ex.Message });
        }
    }

    // Test endpoint'leri
    [HttpGet, Route("test-get")]
    public IHttpActionResult TestGet()
    {
        return Json(new { message = "GET endpoint çalışıyor", timestamp = DateTime.Now });
    }

    [HttpPost, Route("test-post")]
    public IHttpActionResult TestPost(SifreSifirlaViewModel model)
    {
        return Json(new
        {
            message = "POST endpoint çalışıyor",
            receivedEmail = model?.Email,
            timestamp = DateTime.Now
        });
    }

    private async Task MailGonderAsync(string aliciEmail, string konu, string icerik)
    {
        var mail = new MailMessage { Subject = konu, Body = icerik, IsBodyHtml = true };
        mail.To.Add(aliciEmail);

        // <--- DEĞİŞİKLİK 2: Gönderen adresi ("From") zorunlu olarak eklendi.
        // BU ADRESİ KENDİ GÖNDERİCİ ADRESİNİZLE DEĞİŞTİRDİĞİNİZDEN EMİN OLUN!
        mail.From = new MailAddress("örnek@gmail.com");

        using (var smtp = new SmtpClient())
        {
            await smtp.SendMailAsync(mail);
        }
    }
}