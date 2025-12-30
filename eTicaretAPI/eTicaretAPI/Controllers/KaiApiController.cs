using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Cors;
using eTicaretAPI.Entity; // Entity namespace'inizin doğru olduğundan emin olun
using Newtonsoft.Json;

namespace eTicaretSitesi.API.Controllers
{
    // --- MODELLER ---

    public class KaiMessageModel
    {
        public string message { get; set; }
        public List<OllamaMessage> history { get; set; } = new List<OllamaMessage>();
    }

    public class KaiProductModel
    {
        public int Id { get; set; }
        public string Adi { get; set; }
        public string Fiyat { get; set; }
        public string Resim { get; set; }
        public string DetayUrl { get; set; }
        public int YorumSayisi { get; set; }
        public string StokDurumu { get; set; }
    }

    public class BotResult
    {
        public string Reply { get; set; }
        public bool IsProductSearch { get; set; }
        public string Emotion { get; set; } = "neutral";
        public int ConfidenceScore { get; set; } = 100;
    }

    // GÜNCELLEME: Python eğitim verisine uygun hale getirildi (tool, query, reason)
    public class LLMAnalysisResult
    {
        [JsonProperty("tool")]
        public string Tool { get; set; }

        [JsonProperty("query")]
        public string Query { get; set; }

        [JsonProperty("reason")]
        public string Reason { get; set; }

        [JsonProperty("order_id")]
        public string OrderId { get; set; }
    }

    public class OllamaRequest { public string model { get; set; } public List<OllamaMessage> messages { get; set; } public bool stream { get; set; } public string format { get; set; } }
    public class OllamaMessage { public string role { get; set; } public string content { get; set; } }
    public class OllamaResponse { public OllamaMessage message { get; set; } }

    [EnableCors(origins: "*", headers: "*", methods: "*")]
    [RoutePrefix("api/kai")]
    public class KaiApiController : ApiController
    {
        private readonly DataContext _context = new DataContext();
        private static readonly HttpClient _httpClient = new HttpClient();

        [HttpPost, Route("getreply")]
        public async Task<IHttpActionResult> GetReply([FromBody] KaiMessageModel model)
        {
            if (string.IsNullOrWhiteSpace(model.message))
            {
                return Ok(new { reply = "Üzgünüm, sizi duyamadım.", products = new List<object>() });
            }

            // 1. ADIM: Mesajı Analiz Et (tool ve query bul)
            var analysis = await AnalyzeMessageWithLLM(model.message);

            // Eğer analiz JSON parse edemezse veya boş gelirse 'chat' moduna al
            if (analysis == null || string.IsNullOrEmpty(analysis.Tool))
            {
                analysis = new LLMAnalysisResult { Tool = "chat" };
            }

            // 2. ADIM: Analize göre cevap üret veya işlem yap
            var result = await GenerateReplyFromLLMAnalysis(analysis, model);

            // 3. ADIM: Eğer ürün aramasıysa veritabanından ürünleri çek
            List<KaiProductModel> products = new List<KaiProductModel>();
            if (result.IsProductSearch && !string.IsNullOrEmpty(analysis.Query))
            {
                // Query string'ini kelimelere bölüp arama fonksiyonuna gönderiyoruz
                var keywords = analysis.Query.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).ToList();
                products = GetMatchingProductsApi(keywords);

                if (products.Count == 0)
                {
                    result.IsProductSearch = false; // Ürün bulunamadıysa layout bozulmasın
                    result.Reply += " Ancak maalesef kriterlerinize uygun stokta ürün bulamadım.";
                }
            }

            return Ok(new
            {
                reply = result.Reply,
                products = products,
                isProductSearch = result.IsProductSearch,
                emotion = result.Emotion,
                confidence = result.ConfidenceScore
            });
        }

        // --- LLM ANALİZ (EĞİTİME UYGUN FORMAT) ---
        private async Task<LLMAnalysisResult> AnalyzeMessageWithLLM(string userMessage)
        {
            const string ollamaApiUrl = "http://localhost:11434/api/chat";

            // SİSTEM PROMPT GÜNCELLENDİ: Python'daki eğitim verisinin aynısı
            const string systemPrompt = @"Sen bir e-ticaret asistanısın. Görevin kullanıcının mesajını analiz edip JSON formatında yanıt vermektir.
            
            Kullanılabilir Araçlar (Tools):
            - search_product: Ürün arama, fiyat sorma. (Örn: 'mouse var mı', 'ucuz laptop')
            - get_orders: Sipariş durumu, kargo takibi.
            - return_request: İade ve değişim talepleri.
            - cancel_order: Sipariş iptali.
            - chat: Genel sohbet, selamlaşma, kimlik soruları.

            ÖRNEK ÇIKTILAR:
            User: 'Kablosuz mouse arıyorum' -> JSON: {""tool"": ""search_product"", ""query"": ""kablosuz mouse""}
            User: 'Siparişim nerede?' -> JSON: {""tool"": ""get_orders""}
            User: 'Selam' -> JSON: {""tool"": ""chat""}
            
            SADECE JSON DÖNDÜR.";

            var requestPayload = new OllamaRequest
            {
                model = "kai", // Eğittiğiniz modelin adı
                stream = false,
                format = "json", // JSON zorlaması
                messages = new List<OllamaMessage>
                {
                    new OllamaMessage { role = "system", content = systemPrompt },
                    new OllamaMessage { role = "user", content = userMessage }
                }
            };

            try
            {
                var jsonPayload = JsonConvert.SerializeObject(requestPayload);
                var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync(ollamaApiUrl, content);

                if (!response.IsSuccessStatusCode) return null;

                var responseBody = await response.Content.ReadAsStringAsync();
                var ollamaResponse = JsonConvert.DeserializeObject<OllamaResponse>(responseBody);

                // Modelden gelen JSON'u parse et
                return JsonConvert.DeserializeObject<LLMAnalysisResult>(ollamaResponse.message.content);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LLM Analiz Hatası: " + ex.Message);
                return null;
            }
        }

        // --- CEVAP VE AKSİYON YÖNETİMİ ---
        private async Task<BotResult> GenerateReplyFromLLMAnalysis(LLMAnalysisResult analysis, KaiMessageModel model)
        {
            var result = new BotResult();
            string tool = analysis.Tool?.ToLower() ?? "chat";

            switch (tool)
            {
                case "search_product":
                    result.IsProductSearch = true;
                    // Eğer query boşsa varsayılan bir cevap ver
                    if (string.IsNullOrEmpty(analysis.Query))
                        result.Reply = "Hangi ürünü aradığınızı tam anlayamadım, tekrar eder misiniz?";
                    else
                        result.Reply = $"Elbette, '{analysis.Query}' için bulduğum sonuçlar şunlar:";
                    break;

                case "get_orders":
                    string currentUserId = "ornek_kullanici_id"; // Auth sistemi varsa User.Identity.GetUserId()
                    // Sipariş sorgulama mantığına entity listesi yerine direkt query veya genel sorgu gönderiyoruz
                    result.Reply = GetMatchingOrdersApi(analysis.OrderId, currentUserId);
                    break;

                case "return_request":
                    result.Reply = "İade işlemleri için 'Hesabım > Siparişlerim' menüsünden ilgili siparişi seçip 'İade Talebi Oluştur' butonuna tıklayabilirsiniz. İade süremiz 21 gündür.";
                    break;

                case "cancel_order":
                    result.Reply = "Siparişiniz henüz 'Hazırlanıyor' aşamasındaysa iptal edebilirsiniz. Sipariş numaranızı verirseniz kontrol edebilirim.";
                    break;

                case "chat":
                default:
                    // Normal sohbet için yine Kai modelini kullanıyoruz ama sistem promptu farklı
                    result.Reply = await GetNaturalChatResponse(model.message, model.history);
                    break;
            }

            return result;
        }

        // --- DOĞAL SOHBET MODU (Chat Tool) ---
        private async Task<string> GetNaturalChatResponse(string userMessage, List<OllamaMessage> history)
        {
            const string ollamaApiUrl = "http://localhost:11434/api/chat";
            // Burada modelin eğitimdeki kişiliğini koruyoruz
            const string personalityPrompt = "Sen Kai, yardımsever bir e-ticaret asistanısın. Kısa, nazik ve samimi cevaplar ver. Veritabanı sorgusu yapma, sadece sohbet et.";

            var messages = new List<OllamaMessage>();
            messages.Add(new OllamaMessage { role = "system", content = personalityPrompt });
            if (history != null) messages.AddRange(history);
            messages.Add(new OllamaMessage { role = "user", content = userMessage });

            var requestPayload = new OllamaRequest
            {
                model = "kai", // Eğittiğiniz model
                stream = false,
                messages = messages // Burada 'format: json' YOK, normal metin istiyoruz
            };

            try
            {
                var jsonPayload = JsonConvert.SerializeObject(requestPayload);
                var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync(ollamaApiUrl, content);
                if (!response.IsSuccessStatusCode) return "Şu an bağlantıda bir sorun var.";

                var responseBody = await response.Content.ReadAsStringAsync();
                var ollamaResponse = JsonConvert.DeserializeObject<OllamaResponse>(responseBody);
                return ollamaResponse.message.content;
            }
            catch (Exception)
            {
                return "Üzgünüm, şu an cevap veremiyorum.";
            }
        }

        // --- VERİTABANI: ÜRÜN ARAMA ---
        private List<KaiProductModel> GetMatchingProductsApi(List<string> keywords)
        {
            var query = _context.urunler
                .Include(p => p.Yorumlar)
                .Include(p => p.Kategori)
                .Include(p => p.Satici)
                .AsQueryable();

            if (keywords == null || !keywords.Any()) return new List<KaiProductModel>();

            decimal? maxPrice = null;
            decimal? minPrice = null;
            string orderBy = null;
            var searchKeywords = new List<string>();

            // Basit kelime ayrıştırma
            foreach (var kw in keywords)
            {
                string lowerKw = kw.ToLower();
                if (lowerKw.Contains("altı") || lowerKw.Contains("altında"))
                {
                    var digits = new string(lowerKw.Where(char.IsDigit).ToArray());
                    if (decimal.TryParse(digits, out decimal price)) maxPrice = price;
                }
                else if (lowerKw.Contains("üzeri") || lowerKw.Contains("üstü"))
                {
                    var digits = new string(lowerKw.Where(char.IsDigit).ToArray());
                    if (decimal.TryParse(digits, out decimal price)) minPrice = price;
                }
                else if (lowerKw.Contains("ucuz")) orderBy = "price_asc";
                else if (lowerKw.Contains("pahalı")) orderBy = "price_desc";
                else searchKeywords.Add(lowerKw);
            }

            if (searchKeywords.Any())
            {
                // VEYA mantığı (Any) daha esnek sonuç verir, kullanıcı bazen yanlış yazabilir
                query = query.Where(p =>
                    searchKeywords.Any(keyword =>
                        p.Adi.ToLower().Contains(keyword) ||
                        (p.Aciklama != null && p.Aciklama.ToLower().Contains(keyword)) ||
                        (p.Kategori != null && p.Kategori.Adi.ToLower().Contains(keyword))
                    )
                );
            }

            if (maxPrice.HasValue) query = query.Where(p => p.Fiyat <= (double)maxPrice.Value);
            if (minPrice.HasValue) query = query.Where(p => p.Fiyat >= (double)minPrice.Value);

            var resultList = query.Take(20).ToList(); // Performans için limit

            // Bellekte sıralama
            if (orderBy == "price_asc") resultList = resultList.OrderBy(p => p.Fiyat).ToList();
            else if (orderBy == "price_desc") resultList = resultList.OrderByDescending(p => p.Fiyat).ToList();

            return resultList.Take(5).Select(p => MapToProductModel(p)).ToList();
        }

        // --- VERİTABANI: SİPARİŞ SORGULAMA ---
        private string GetMatchingOrdersApi(string orderId, string userId)
        {
            var query = _context.siparisler.Where(s => s.UserId == userId).AsQueryable();

            // Eğer model sipariş numarası yakaladıysa ona göre filtrele
            if (!string.IsNullOrEmpty(orderId))
            {
                query = query.Where(s => s.SiparisNumarasi.Contains(orderId));
            }

            var userOrders = query.OrderByDescending(s => s.SiparisTarihi).Take(3).ToList();

            if (!userOrders.Any()) return "Sisteme kayıtlı aktif bir siparişiniz bulunmuyor.";

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("İşte son siparişleriniz:");
            foreach (var order in userOrders)
            {
                sb.AppendLine($"- Sipariş No: {order.SiparisNumarasi} | Durum: {GetDisplayName(order.siparisDurum)} | Tutar: {order.Toplam:C2}");
            }
            return sb.ToString();
        }

        // --- HELPER METOTLAR ---
        private KaiProductModel MapToProductModel(urun p)
        {
            return new KaiProductModel
            {
                Id = p.Id,
                Adi = p.Adi,
                Fiyat = p.Fiyat.ToString("N2"),
                Resim = "/Upload/" + p.Resim, // Path kontrolü yapılabilir
                DetayUrl = "/Home/Detaylar/" + p.Id,
                YorumSayisi = p.Yorumlar?.Count ?? 0,
                StokDurumu = p.Stok > 0 ? "Stokta" : "Tükendi"
            };
        }

        public static string GetDisplayName(Enum enumValue)
        {
            try
            {
                var displayAttribute = enumValue.GetType()
                    .GetField(enumValue.ToString())
                    .GetCustomAttributes(typeof(System.ComponentModel.DataAnnotations.DisplayAttribute), false)
                    .SingleOrDefault() as System.ComponentModel.DataAnnotations.DisplayAttribute;
                return displayAttribute?.Name ?? enumValue.ToString();
            }
            catch { return enumValue.ToString(); }
        }
    }
}