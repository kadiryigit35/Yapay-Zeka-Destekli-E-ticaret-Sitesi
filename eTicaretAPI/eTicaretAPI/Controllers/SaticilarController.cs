using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity;
using eTicaretAPI.Models;

namespace eTicaretSitesi.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/saticilar")]
    public class SaticilarController : ApiController
    {
        private readonly DataContext db = new DataContext();

        // GET: api/saticilar
        [HttpGet]
        [Route("")]
        public IHttpActionResult GetSaticilar()
        {
            try
            {
                var saticilar = db.saticilar.Select(s => new
                {
                    Id = s.Id,
                    Adi = s.Adi,
                    Hakkinda = s.Hakkinda,
                    Resim = s.Resim
                }).ToList();

                return Ok(saticilar);
            }
            catch (Exception ex)
            {
                return BadRequest("Satıcılar yüklenirken hata oluştu: " + ex.Message);
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