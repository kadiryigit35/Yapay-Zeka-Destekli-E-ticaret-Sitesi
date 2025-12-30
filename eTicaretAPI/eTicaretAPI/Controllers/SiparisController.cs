using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.Http;
using System.Web.Http.Cors;

namespace eTicaretAPI.Controllers
{
    // DTOs (Data Transfer Objects) for receiving data
    public class SiparisCsvDto
    {
        public string UserId { get; set; }
        public List<SiparisOgesiDto> Urunler { get; set; }
    }

    public class SiparisOgesiDto
    {
        public int UrunId { get; set; }
        public int Adet { get; set; }
    }

    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/siparis")]
    public class SiparisController : ApiController
    {
        [HttpPost]
        [Route("csv-kaydet")]
        public IHttpActionResult SiparisiCsvyeYaz([FromBody] SiparisCsvDto siparis)
        {
            if (siparis == null || string.IsNullOrEmpty(siparis.UserId) || siparis.Urunler == null || !siparis.Urunler.Any())
            {
                return BadRequest("Geçersiz sipariş verisi.");
            }

            try
            {
                // API'de dosya yolunu almak için HostingEnvironment.MapPath kullanılır.
                string path = System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/Siparisler.csv");
                bool fileExists = File.Exists(path);

                var sb = new StringBuilder();

                if (!fileExists)
                {
                    sb.AppendLine("UserId,ProductId,Adet");
                }

                foreach (var urun in siparis.Urunler)
                {
                    sb.AppendLine($"{siparis.UserId},{urun.UrunId},{urun.Adet}");
                }

                File.AppendAllText(path, sb.ToString(), Encoding.UTF8);

                return Ok(new { message = "Sipariş CSV'ye başarıyla kaydedildi." });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }
}