using System;
using System.Linq;
using System.Web.Http;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using eTicaretAPI.Identity;
using eTicaretAPI.Entity;
using System.Data.Entity;
using System.Collections.Generic;

namespace eTicaretAPI.Controllers
{
    [RoutePrefix("api/user")]
    public class UserController : ApiController
    {
        private readonly UserManager<kullanici> _userManager;
        private readonly DataContext db = new DataContext();

        public UserController()
        {
            var context = new IdentityDataContext();
            var userStore = new UserStore<kullanici>(context);
            _userManager = new UserManager<kullanici>(userStore);
        }

        // GET api/user/orders/{userId}
        [HttpGet]
        [Route("orders/{userId}")]
        public IHttpActionResult GetUserOrders(string userId)
        {
            try
            {
                var orders = db.siparisler
                    .Where(i => i.UserId == userId)
                    .Select(i => new
                    {
                        i.Id,
                        SiparisNumarasi = i.SiparisNumarasi,
                        i.SiparisTarihi,
                        siparisDurum = i.siparisDurum.ToString(),
                        i.Toplam
                    })
                    .OrderByDescending(i => i.SiparisTarihi)
                    .ToList();

                return Ok(new { success = true, orders });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // GET api/user/favorites/{username}
        [HttpGet]
        [Route("favorites/{username}")]
        public IHttpActionResult GetUserFavorites(string username)
        {
            try
            {
                var favorites = db.Favoriler
                    .Where(f => f.KullaniciAdi == username)
                    .Select(f => f.Urun)
                    .Select(u => new
                    {
                        u.Id,
                        u.Adi,
                        u.Aciklama,
                        u.Fiyat,
                        u.Stok,
                        u.Resim,
                        u.kategoriId,
                        u.saticiId,
                        Satici = u.Satici == null ? null : new { u.Satici.Id, u.Satici.Adi }
                    })
                    .ToList();

                return Ok(new { success = true, favorites });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // POST api/user/favorites/{username}
        [HttpPost]
        [Route("favorites/{username}")]
        public IHttpActionResult AddToFavorites(string username, FavoriteAddModel model)
        {
            try
            {
                var existingFavorite = db.Favoriler.FirstOrDefault(f => f.KullaniciAdi == username && f.UrunId == model.ProductId);
                if (existingFavorite != null)
                {
                    return Ok(new { success = true, message = "Ürün zaten favorilerde." });
                }

                var favorite = new Favori
                {
                    UrunId = model.ProductId,
                    KullaniciAdi = username,
                    Tarih = DateTime.Now
                };

                db.Favoriler.Add(favorite);
                db.SaveChanges();

                return Ok(new { success = true, message = "Ürün favorilere eklendi." });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }


        // DELETE api/user/favorites/{username}/{productId}
        [HttpDelete]
        [Route("favorites/{username}/{productId:int}")]
        public IHttpActionResult RemoveFromFavorites(string username, int productId)
        {
            try
            {
                var favorite = db.Favoriler.FirstOrDefault(f => f.KullaniciAdi == username && f.UrunId == productId);
                if (favorite != null)
                {
                    db.Favoriler.Remove(favorite);
                    db.SaveChanges();
                }

                return Ok(new { success = true, message = "Favorilerden kaldırıldı" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // GET api/user/addresses/{userId}
        [HttpGet]
        [Route("addresses/{userId}")]
        public IHttpActionResult GetUserAddresses(string userId)
        {
            try
            {
                var addresses = db.KayitliAdresler
                    .Where(a => a.KullaniciId == userId)
                    .ToList();

                return Ok(new { success = true, addresses });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // POST api/user/addresses/{userId}
        [HttpPost]
        [Route("addresses/{userId}")]
        public IHttpActionResult AddAddress(string userId, AddressModel model)
        {
            try
            {
                var address = new kayitliAdres
                {
                    KullaniciId = userId,
                    TamAd = model.TamAd,
                    AdresBasligi = model.AdresBasligi,
                    Adres = model.Adres,
                    Sehir = model.Sehir,
                    Mahalle = model.Mahalle,
                    Sokak = model.Sokak,
                    PostaKodu = model.PostaKodu,
                    Telefon = model.Telefon
                };

                db.KayitliAdresler.Add(address);
                db.SaveChanges();

                return Ok(new { success = true, message = "Adres başarıyla eklendi", address });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // PUT api/user/addresses/{userId}/{addressId}
        [HttpPut]
        [Route("addresses/{userId}/{addressId:int}")]
        public IHttpActionResult UpdateAddress(string userId, int addressId, AddressModel model)
        {
            try
            {
                var address = db.KayitliAdresler.FirstOrDefault(a => a.Id == addressId && a.KullaniciId == userId);
                if (address == null) return NotFound();

                address.TamAd = model.TamAd;
                address.AdresBasligi = model.AdresBasligi;
                address.Adres = model.Adres;
                address.Sehir = model.Sehir;
                address.Mahalle = model.Mahalle;
                address.Sokak = model.Sokak;
                address.PostaKodu = model.PostaKodu;
                address.Telefon = model.Telefon;

                db.SaveChanges();

                return Ok(new { success = true, message = "Adres başarıyla güncellendi" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // DELETE api/user/addresses/{userId}/{addressId}
        [HttpDelete]
        [Route("addresses/{userId}/{addressId:int}")]
        public IHttpActionResult DeleteAddress(string userId, int addressId)
        {
            try
            {
                var address = db.KayitliAdresler.FirstOrDefault(a => a.Id == addressId && a.KullaniciId == userId);
                if (address != null)
                {
                    db.KayitliAdresler.Remove(address);
                    db.SaveChanges();
                }
                return Ok(new { success = true, message = "Adres başarıyla silindi" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // GET api/user/cards/{userId}
        [HttpGet]
        [Route("cards/{userId}")]
        public IHttpActionResult GetUserCards(string userId)
        {
            try
            {
                var cards = db.KayitliOdemeYontemleri
                    .Where(k => k.KullaniciId == userId)
                    .Select(k => new
                    {
                        k.Id,
                        k.KartSahibi,
                        k.KartNumarasi,
                        k.SKT,
                        k.CVV
                    })
                    .ToList();

                return Ok(new { success = true, cards });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // POST api/user/cards/{userId}
        [HttpPost]
        [Route("cards/{userId}")]
        public IHttpActionResult AddCard(string userId, CardModel model)
        {
            try
            {
                var card = new kayitliOdemeYontemi
                {
                    KullaniciId = userId,
                    KartSahibi = model.KartSahibi,
                    KartNumarasi = model.KartNumarasi,
                    SKT = model.SKT,
                    CVV = model.CVV
                };
                db.KayitliOdemeYontemleri.Add(card);
                db.SaveChanges();
                return Ok(new { success = true, message = "Kart başarıyla eklendi" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // YENİ EKLENDİ: Kart güncellemek için endpoint
        // PUT api/user/cards/{userId}/{cardId}
        [HttpPut]
        [Route("cards/{userId}/{cardId:int}")]
        public IHttpActionResult UpdateCard(string userId, int cardId, CardModel model)
        {
            try
            {
                var card = db.KayitliOdemeYontemleri.FirstOrDefault(c => c.Id == cardId && c.KullaniciId == userId);
                if (card == null)
                {
                    return NotFound();
                }

                card.KartSahibi = model.KartSahibi;
                card.KartNumarasi = model.KartNumarasi;
                card.SKT = model.SKT;
                card.CVV = model.CVV;

                db.SaveChanges();

                return Ok(new { success = true, message = "Kart başarıyla güncellendi" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // DELETE api/user/cards/{userId}/{cardId}
        [HttpDelete]
        [Route("cards/{userId}/{cardId:int}")]
        public IHttpActionResult DeleteCard(string userId, int cardId)
        {
            try
            {
                var card = db.KayitliOdemeYontemleri.FirstOrDefault(k => k.Id == cardId && k.KullaniciId == userId);
                if (card != null)
                {
                    db.KayitliOdemeYontemleri.Remove(card);
                    db.SaveChanges();
                }
                return Ok(new { success = true, message = "Kart başarıyla silindi" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        // PUT api/user/profile/{userId}
        [HttpPut]
        [Route("profile/{userId}")]
        public IHttpActionResult UpdateProfile(string userId, ProfileUpdateModel model)
        {
            try
            {
                var user = _userManager.FindById(userId);
                if (user == null) return NotFound();

                user.Adi = model.Adi;
                user.Soyadi = model.Soyadi;
                user.Email = model.Email;
                if (!string.IsNullOrEmpty(model.ProfilResmi))
                {
                    user.ProfilResmi = model.ProfilResmi; // YENİ EKLENDİ
                }
                if (!string.IsNullOrEmpty(model.MevcutSifre) && !string.IsNullOrEmpty(model.YeniSifre))
                {
                    var result = _userManager.ChangePassword(userId, model.MevcutSifre, model.YeniSifre);
                    if (!result.Succeeded)
                    {
                        return BadRequest("Şifre güncellenemedi.");
                    }
                }

                var updateResult = _userManager.Update(user);
                if (!updateResult.Succeeded)
                {
                    return BadRequest("Profil güncellenemedi.");
                }

                return Ok(new { success = true, message = "Profil başarıyla güncellendi" });
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
                db?.Dispose();
            }
            base.Dispose(disposing);    
        }
    }

    // --- API Modelleri ---
    public class FavoriteAddModel
    {
        public int ProductId { get; set; }
    }

    public class AddressModel
    {
        public string TamAd { get; set; }
        public string AdresBasligi { get; set; }
        public string Adres { get; set; }
        public string Sehir { get; set; }
        public string Mahalle { get; set; }
        public string Sokak { get; set; }
        public string PostaKodu { get; set; }
        public string Telefon { get; set; }
    }

    public class CardModel
    {
        public string KartSahibi { get; set; }
        public string KartNumarasi { get; set; }
        public string SKT { get; set; }
        public string CVV { get; set; }
    }

    public class ProfileUpdateModel
    {
        public string Adi { get; set; }
        public string Soyadi { get; set; }
        public string Email { get; set; }
        public string MevcutSifre { get; set; }
        public string YeniSifre { get; set; }
        public string ProfilResmi { get; set; } // YENİ EKLENDİ
    }
}
