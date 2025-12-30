using Newtonsoft.Json;
using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace eTicaretSitesi.MvcWebUI.Helpers
{
    // API'den gelen JSON yanıtını modellemek için bir sınıf
    public class UploadResponse
    {
        public string FileName { get; set; }
    }

    public class ApiUploader
    {
        // API'nizin dosya yükleme adresini buraya girin
        private const string ApiUrl = "https://localhost:44366/api/dosya/yukle";

        /// <summary>
        /// Verilen dosyayı merkezi API'ye yükler ve sunucudaki yeni dosya adını döndürür.
        /// </summary>
        /// <param name="file">Yüklenecek dosya (HttpPostedFileBase)</param>
        /// <returns>API'ye kaydedilen yeni dosya adı veya hata durumunda null.</returns>
        public static async Task<string> UploadImageAsync(HttpPostedFileBase file)
        {
            if (file == null || file.ContentLength == 0)
            {
                return null;
            }

            // Geliştirme ortamında (localhost) SSL sertifika hatalarını yoksaymak için.
            // DİKKAT: Bu kodu canlı (production) ortamda KULLANMAYIN!
            var handler = new HttpClientHandler
            {
                ServerCertificateCustomValidationCallback = (sender, cert, chain, sslPolicyErrors) => true
            };

            using (var client = new HttpClient(handler))
            {

                using (var content = new MultipartFormDataContent())
                {
                    // Dosyayı byte dizisine dönüştür
                    byte[] fileBytes;
                    using (var binaryReader = new BinaryReader(file.InputStream))
                    {
                        fileBytes = binaryReader.ReadBytes(file.ContentLength);
                    }
                    var fileContent = new ByteArrayContent(fileBytes);

                    // Form verisi olarak dosyayı ve adını ekle
                    content.Add(fileContent, "file", file.FileName);

                    try
                    {
                        var response = await client.PostAsync(ApiUrl, content);

                        if (response.IsSuccessStatusCode)
                        {
                            var jsonString = await response.Content.ReadAsStringAsync();
                            var result = JsonConvert.DeserializeObject<UploadResponse>(jsonString);
                            return result.FileName; // Yeni dosya adını döndür
                        }
                        else
                        {
                            // Hata durumunu loglayabilirsiniz.
                            // var errorMessage = await response.Content.ReadAsStringAsync();
                            // System.Diagnostics.Debug.WriteLine($"API Upload Error: {errorMessage}");
                            return null;
                        }
                    }
                    catch (Exception ex)
                    {
                        // Exception'ı loglayabilirsiniz.
                        // System.Diagnostics.Debug.WriteLine($"API Upload Exception: {ex.Message}");
                        return null;
                    }
                }
            }
        }
    }
}
