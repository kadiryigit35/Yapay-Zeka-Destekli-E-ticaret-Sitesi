using System;
using System.Data.Entity;
using System.Linq;
using eTicaretAPI.Identity;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace eTicaretAPI.Identity
{
    public class IdentityInitializer : CreateDatabaseIfNotExists<IdentityDataContext>
    {
        protected override void Seed(IdentityDataContext context)
        {
            var roleStore = new RoleStore<yetki>(context);
            var roleManager = new RoleManager<yetki>(roleStore);

            // Roller
            if (!roleManager.RoleExists("admin"))
            {
                var role = new yetki { Name = "admin", Aciklama = "admin rolü" };
                roleManager.Create(role);
            }
            if (!roleManager.RoleExists("Kullanici"))
            {
                var role = new yetki { Name = "Kullanici", Aciklama = "Kullanici rolü" };
                roleManager.Create(role);
            }
            if (!roleManager.RoleExists("satici"))
            {
                var role = new yetki { Name = "satici", Aciklama = "satıcı rolü" };
                roleManager.Create(role);
            }

            var userStore = new UserStore<kullanici>(context);
            var userManager = new UserManager<kullanici>(userStore);

            // Admin kullanıcılar
            if (!context.Users.Any(u => u.UserName == "kadiryigit"))
            {
                var user = new kullanici
                {
                    Adi = "kadir",
                    Soyadi = "yigit",
                    UserName = "kadiryigit",
                    Email = "kadiryigit@example.com"
                };
                userManager.Create(user, "1234567");
                userManager.AddToRole(user.Id, "admin");
                userManager.AddToRole(user.Id, "Kullanici");
            }

            if (!context.Users.Any(u => u.UserName == "furkanenes"))
            {
                var user = new kullanici
                {
                    Adi = "furkan",
                    Soyadi = "enes",
                    UserName = "furkanenes",
                    Email = "furkanenes@example.com"
                };
                userManager.Create(user, "1234567");
                userManager.AddToRole(user.Id, "admin");
                userManager.AddToRole(user.Id, "Kullanici");
            }

            // Satıcı kullanıcılar listesi
            var saticiKullanicilar = new[]
            {
                new { Adi = "HyperX", UserName = "hyperx", Email = "hyperx@firma.com" },
                new { Adi = "CORSAIR", UserName = "corsair", Email = "corsair@firma.com" },
                new { Adi = "Logitech", UserName = "logitech", Email = "logitech@firma.com" },
                new { Adi = "Gamepower", UserName = "gamepower", Email = "gamepower@firma.com" },
                new { Adi = "İTOPYA", UserName = "itopya", Email = "itopya@firma.com" },
                new { Adi = "VATAN Bilgisayar", UserName = "vatan", Email = "vatan@firma.com" },
                new { Adi = "Razer", UserName = "razer", Email = "razer@firma.com" },
                new { Adi = "Wraith Esports", UserName = "wraith", Email = "wraith@firma.com" },
            };

            foreach (var saticiUser in saticiKullanicilar)
            {
                if (!context.Users.Any(u => u.UserName == saticiUser.UserName))
                {
                    var user = new kullanici
                    {
                        Adi = saticiUser.Adi,
                        Soyadi = "Firma",
                        UserName = saticiUser.UserName,
                        Email = saticiUser.Email
                    };
                    userManager.Create(user, "satici123");
                    userManager.AddToRole(user.Id, "satici");
                }
            }

            base.Seed(context);
        }
    }
}
