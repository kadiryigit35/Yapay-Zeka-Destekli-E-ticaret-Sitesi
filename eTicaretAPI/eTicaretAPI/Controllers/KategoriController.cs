using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity;
using eTicaretAPI.Models;

namespace eTicaretSitesi.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/kategoriler")]
    public class KategorilerController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // GET: api/kategoriler
        [HttpGet]
        [Route("")] // Sadece prefix'e gelen istekler için
        public IHttpActionResult GetKategoriler()
        {
            try
            {
                var kategoriler = db.kategori.Select(k => new
                {
                    Id = k.Id,
                    Adi = k.Adi,
                    Aciklama = k.Aciklama,
                    UrunSayisi = k.uruns.Count()
                }).ToList();

                return Ok(kategoriler);
            }
            catch (Exception ex)
            {
                return BadRequest("Kategoriler yüklenirken hata oluştu: " + ex.Message);
            }
        }

        // GET: api/kategoriler/{id}/saticilar
        [HttpGet]
        [Route("{id:int}/saticilar")] // Sadece kategori ID'sine göre satıcıları getirir
        public IHttpActionResult GetKategoriSaticilari(int id)
        {
            try
            {
                var saticilar = db.urunler
                    .Where(u => u.kategoriId == id)
                    .Select(u => u.Satici)
                    .Distinct()
                    .Where(s => s != null)
                    .Select(s => new
                    {
                        Id = s.Id,
                        Adi = s.Adi
                    })
                    .ToList();

                return Ok(saticilar);
            }
            catch (Exception ex)
            {
                return BadRequest("Kategoriye ait satıcılar yüklenirken hata oluştu: " + ex.Message);
            }
        }

        // GET: api/kategoriler/{id}
        [HttpGet]
        [Route("{id:int}")] // Sadece kategori ID'sine göre kategoriyi getirir
        public IHttpActionResult GetKategori(int id)
        {
            try
            {
                var kategori = db.kategori
                    .Where(k => k.Id == id)
                    .Select(k => new
                    {
                        Id = k.Id,
                        Adi = k.Adi,
                        Aciklama = k.Aciklama,
                        UrunSayisi = k.uruns.Count()
                    })
                    .FirstOrDefault();

                if (kategori == null)
                {
                    return NotFound();
                }

                return Ok(kategori);
            }
            catch (Exception ex)
            {
                return BadRequest("Kategori yüklenirken hata oluştu: " + ex.Message);
            }
        }

        // GET: api/kategoriler/{id}/urunler
        [HttpGet]
        [Route("{id:int}/urunler")] // Sadece kategori ID'sine göre ürünleri getirir
        public IHttpActionResult GetKategoriUrunleri(int id, double? minFiyat = null, double? maxFiyat = null, string saticiIds = null)
        {
            try
            {
                var query = db.urunler
                    .Include(u => u.Satici)
                    .Where(u => u.kategoriId == id);

                if (minFiyat.HasValue)
                {
                    query = query.Where(u => u.Fiyat >= minFiyat.Value);
                }

                if (maxFiyat.HasValue)
                {
                    query = query.Where(u => u.Fiyat <= maxFiyat.Value);
                }

                if (!string.IsNullOrEmpty(saticiIds))
                {
                    var ids = saticiIds.Split(',').Select(int.Parse).ToList();
                    query = query.Where(u => ids.Contains(u.saticiId));
                }

                var urunler = query.Select(u => new
                {
                    Id = u.Id,
                    Adi = u.Adi,
                    Aciklama = u.Aciklama,
                    Fiyat = u.Fiyat,
                    Stok = u.Stok,
                    Resim = u.Resim,
                    kategoriId = u.kategoriId,
                    saticiId = u.saticiId,
                    Satici = new
                    {
                        Id = u.Satici.Id,
                        Adi = u.Satici.Adi
                    }
                }).ToList();

                return Ok(urunler);
            }
            catch (Exception ex)
            {
                return BadRequest("Ürünler yüklenirken hata oluştu: " + ex.Message);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}