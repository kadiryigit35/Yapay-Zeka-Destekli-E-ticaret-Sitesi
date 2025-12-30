// eTicaretAPI/Controllers/AdminController.cs

using eTicaretAPI.Entity;
using eTicaretAPI.Identity;
using eTicaretAPI.Models;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Cors;

[EnableCors(origins: "*", headers: "*", methods: "*")]
[RoutePrefix("api/admin")]
public class AdminController : ApiController
{
    private readonly DataContext db = new DataContext();
    private readonly IdentityDataContext identityDb = new IdentityDataContext();
    private readonly UserManager<kullanici> userManager;

    public AdminController()
    {
        var userStore = new UserStore<kullanici>(identityDb);
        userManager = new UserManager<kullanici>(userStore);
    }

    // ... GetKullanicilar() metodu aynı kalabilir ...
    [HttpGet, Route("kullanicilar")]
    public IHttpActionResult GetKullanicilar()
    {
        var adminRoleId = identityDb.Roles.FirstOrDefault(r => r.Name == "admin")?.Id;
        var kullanicilar = userManager.Users
            .Where(u => u.Roles.All(r => r.RoleId != adminRoleId))
            .Select(u => new KullaniciYonetimViewModel
            {
                Id = u.Id,
                KullaniciAdi = u.UserName,
                Email = u.Email,
                BanliMi = u.BanliMi,
                BanBitisTarihi = u.BanBitisTarihi,
                BanSebebi = u.BanSebebi,
                Roller = u.Roles.Join(identityDb.Roles, ur => ur.RoleId, r => r.Id, (ur, r) => r.Name).ToList()
            }).ToList();
        return Ok(kullanicilar);
    }


    [HttpGet, Route("sikayetler")]
    public IHttpActionResult GetSikayetler()
    {
        var sikayetlerData = db.YorumSikayetleri.Include(s => s.Yorum).OrderByDescending(s => s.Tarih).ToList();
        var sikayetEdenKullaniciIdleri = sikayetlerData.Select(s => s.SikayetEdenKullaniciId).Distinct().ToList();

        // Yorumu yapan kullanıcı adlarını da toplayalım
        var yorumYapanKullaniciAdlari = sikayetlerData.Select(s => s.Yorum.KullaniciAdi).Distinct().ToList();

        var kullaniciIdleri = sikayetEdenKullaniciIdleri.Union(yorumYapanKullaniciAdlari).ToList();

        var kullanicilar = identityDb.Users
            .Where(u => kullaniciIdleri.Contains(u.Id) || yorumYapanKullaniciAdlari.Contains(u.UserName))
            .ToDictionary(u => u.UserName, u => u); // Bu kez key'i UserName, value'yu tüm kullanıcı nesnesi yapalım

        var viewModel = sikayetlerData.Select(s =>
        {
            var yorumuYapanUser = kullanicilar.ContainsKey(s.Yorum.KullaniciAdi) ? kullanicilar[s.Yorum.KullaniciAdi] : null;
            var sikayetEdenUser = identityDb.Users.FirstOrDefault(u => u.Id == s.SikayetEdenKullaniciId); // Bu satırı basit tuttuk

            return new SikayetViewModel
            {
                SikayetId = s.Id,
                YorumId = s.Yorum.Id,
                YorumIcerik = s.Yorum.Icerik,
                YorumuYapanKullanici = s.Yorum.KullaniciAdi,
                YorumuYapanKullaniciId = yorumuYapanUser?.Id,
                SikayetEdenKullanici = sikayetEdenUser?.UserName ?? "Bulunamadı",
                SikayetTarihi = s.Tarih,
                IslemYapildiMi = s.IslemYapildiMi
            };
        }).ToList();

        return Ok(viewModel);
    }
    // GÜNCELLENDİ: Banlama metodu artık tekil yorum silme seçeneği içeriyor
    [HttpPost, Route("banla")]
    public async Task<IHttpActionResult> BanlaKullanici(BanlamaModel model)
    {
        var kullanici = await userManager.FindByIdAsync(model.KullaniciId);
        if (kullanici == null) return NotFound();

        kullanici.BanliMi = true;
        kullanici.BanSebebi = model.Sebep;
        kullanici.BanBitisTarihi = model.SureGun.HasValue ? DateTime.Now.AddDays(model.SureGun.Value) : (DateTime?)null;

        var result = await userManager.UpdateAsync(kullanici);

        if (result.Succeeded)
        {
            // Seçenek 1: Kullanıcının tüm yorumlarını sil
            if (model.YorumlariSil)
            {
                var yorumlar = db.Yorumlar.Where(y => y.KullaniciAdi == kullanici.UserName).ToList();
                db.Yorumlar.RemoveRange(yorumlar);
            }
            // Seçenek 2: Sadece şikayet edilen tek bir yorumu sil
            else if (model.SilinecekYorumId.HasValue)
            {
                var yorum = db.Yorumlar.FirstOrDefault(y => y.Id == model.SilinecekYorumId.Value && y.KullaniciAdi == kullanici.UserName);
                if (yorum != null)
                {
                    db.Yorumlar.Remove(yorum);
                }
            }

            await db.SaveChangesAsync();

            // Banlama işleminden sonra ilgili tüm şikayetleri "işlendi" olarak işaretle
            var ilgiliSikayetler = db.YorumSikayetleri
                .Where(s => s.Yorum.KullaniciAdi == kullanici.UserName && !s.IslemYapildiMi)
                .ToList();
            foreach (var sikayet in ilgiliSikayetler)
            {
                sikayet.IslemYapildiMi = true;
            }
            await db.SaveChangesAsync();

            return Ok(new { success = true, message = $"{kullanici.UserName} başarıyla yasaklandı." });
        }
        return BadRequest("Kullanıcı yasaklanamadı.");
    }

    // ... BanKaldir() metodu aynı kalabilir ...
    [HttpPost, Route("ban-kaldir/{kullaniciId}")]
    public async Task<IHttpActionResult> BanKaldir(string kullaniciId)
    {
        var kullanici = await userManager.FindByIdAsync(kullaniciId);
        if (kullanici == null) return NotFound();

        kullanici.BanliMi = false;
        kullanici.BanSebebi = null;
        kullanici.BanBitisTarihi = null;

        var result = await userManager.UpdateAsync(kullanici);

        if (result.Succeeded)
        {
            return Ok(new { success = true, message = $"{kullanici.UserName} kullanıcısının yasağı kaldırıldı." });
        }
        return BadRequest("Yasak kaldırılamadı.");
    }

    // ... SikayetYoksay() metodu aynı kalabilir ...
    [HttpPost, Route("sikayet-yoksay/{sikayetId:int}")]
    public IHttpActionResult SikayetYoksay(int sikayetId)
    {
        var sikayet = db.YorumSikayetleri.Find(sikayetId);
        if (sikayet == null) return NotFound();

        sikayet.IslemYapildiMi = true;
        db.SaveChanges();

        return Ok(new { success = true, message = "Şikayet işlendi olarak işaretlendi." });
    }

    // ... GetKullaniciYorumlari() metodu aynı kalabilir ...
    [HttpGet, Route("kullanici-yorumlari/{username}")]
    public IHttpActionResult GetKullaniciYorumlari(string username)
    {
        var yorumlar = db.Yorumlar
            .Where(y => y.KullaniciAdi == username)
            .OrderByDescending(y => y.Tarih)
            .Select(y => new { y.Icerik, y.Tarih })
            .ToList();
        return Ok(yorumlar);
    }
}

// BanlamaModel'i güncellendi
public class BanlamaModel
{
    public string KullaniciId { get; set; }
    public string Sebep { get; set; }
    public int? SureGun { get; set; }
    public bool YorumlariSil { get; set; } // Tüm yorumları silmek için
    public int? SilinecekYorumId { get; set; } // Tek bir yorumu silmek için
}