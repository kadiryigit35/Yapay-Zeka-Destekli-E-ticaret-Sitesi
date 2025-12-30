using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.Cors;

namespace eTicaretAPI.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/dosya")]
    public class FileUploadController : ApiController
    {
        [HttpPost]
        [Route("yukle")]
        public async Task<HttpResponseMessage> UploadImage()
        {
            // Gelen isteğin multipart olup olmadığını kontrol et
            if (!Request.Content.IsMimeMultipartContent())
            {
                return Request.CreateResponse(HttpStatusCode.UnsupportedMediaType);
            }

            // Resimlerin kaydedileceği klasörün yolunu al
            string root = HttpContext.Current.Server.MapPath("~/Upload");
            if (!Directory.Exists(root))
            {
                Directory.CreateDirectory(root);
            }

            var provider = new MultipartFormDataStreamProvider(root);

            try
            {
                await Request.Content.ReadAsMultipartAsync(provider);

                // Yüklenen dosyayı bul
                var postedFile = provider.FileData[0];
                if (postedFile == null)
                {
                    return Request.CreateErrorResponse(HttpStatusCode.BadRequest, "Dosya yüklenemedi.");
                }

                // Benzersiz bir dosya adı oluştur
                var originalFileName = postedFile.Headers.ContentDisposition.FileName.Trim('\"');
                var fileExtension = Path.GetExtension(originalFileName);
                var newFileName = Guid.NewGuid().ToString() + fileExtension;
                var newFilePath = Path.Combine(root, newFileName);

                // Dosyayı yeni adıyla taşı
                File.Move(postedFile.LocalFileName, newFilePath);

                // Flutter tarafına yeni dosya adını döndür
                return Request.CreateResponse(HttpStatusCode.OK, new { fileName = newFileName });
            }
            catch (Exception e)
            {
                return Request.CreateErrorResponse(HttpStatusCode.InternalServerError, e);
            }
        }
    }
}