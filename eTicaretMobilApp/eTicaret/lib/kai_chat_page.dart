import 'package:flutter/material.dart';
import 'main.dart'; // ApiService için
import 'models.dart'; // ChatMessage ve KaiProduct için
import 'product_detail_page.dart'; // Ürün detayına gitmek için

class KaiChatPage extends StatefulWidget {
  @override
  _KaiChatPageState createState() => _KaiChatPageState();
}

class _KaiChatPageState extends State<KaiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Kai'nin başlangıç mesajı
    _messages.add(ChatMessage(
      text: "Merhaba! Ben Kai, alışveriş asistanınız. Size nasıl yardımcı olabilirim? 😊",
      isUser: false,
    ));
  }

  // --- YENİ: Yeni Sohbet Metodu ---
  void _startNewChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Merhaba! Ben Kai, alışveriş asistanınız. Size nasıl yardımcı olabilirim? 😊",
        isUser: false,
      ));
      _isLoading = false;
    });
    // Varsa klavyeyi kapat
    FocusScope.of(context).unfocus();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Kullanıcı mesajını ekle
    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.insert(0, userMessage);
      _isLoading = true;
    });
    _scrollToBottom();
    _controller.clear();

    // --- GÜNCELLENDİ: API'ye göndermek için sohbet geçmişi oluştur ---
    // Mesajlar ters sırada (en yeni en üstte), bu yüzden skip(1)
    // (yeni eklenen mesajı atla) ve sonra listeyi API formatına çevirip ters çevir (kronolojik olsun).
    List<Map<String, String>> historyForApi = _messages
        .skip(1) // Yeni eklenen anlık mesajı atla
        .map((msg) {
      return {"role": msg.isUser ? "user" : "assistant", "content": msg.text};
    })
        .toList()
        .reversed // Kronolojik sıraya (en eski en altta) çevir
        .toList();


    try {
      // --- GÜNCELLENDİ: API'ye mesajı ve geçmişi gönder ---
      // DİKKAT: Bu çağrı değişti. `main.dart` içindeki
      // `ApiService.sendMessageToKai` metodunuzu da
      // (String message, List<Map<String, String>> history) alacak şekilde güncellemeniz gerekir.
      final response = await ApiService.sendMessageToKai(text, historyForApi);

      final String reply = response['reply'];
      final List<dynamic> productsJson = response['products'] ?? [];
      final List<KaiProduct> products = productsJson.map((p) => KaiProduct.fromJson(p)).toList();

      // Kai'nin cevabını ekle
      setState(() {
        _messages.insert(0, ChatMessage(text: reply, isUser: false, products: products));
      });
    } catch (e) {
      // Hata mesajı ekle
      setState(() {
        _messages.insert(0, ChatMessage(text: "Üzgünüm, bir sorun oluştu. Lütfen tekrar deneyin.", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🤖 Kai ile Sohbet"),
        // --- YENİ: AppBar'a Yeni Sohbet butonu eklendi ---
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined),
            onPressed: _startNewChat,
            tooltip: "Yeni Sohbet",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Mesajları aşağıdan yukarıya sırala
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text("Kai yazıyor...", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // ... (Bu metotta değişiklik yok) ...
    // ... (Mevcut _buildMessageBubble kodunuz buraya gelecek) ...
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser ? Theme.of(context).primaryColor : Colors.grey[200];
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(message.text, style: TextStyle(color: textColor)),
          ),
          if (message.products.isNotEmpty)
            _buildProductCarousel(message.products),
        ],
      ),
    );
  }

  Widget _buildProductCarousel(List<KaiProduct> products) {
    // ... (Bu metotta değişiklik yok) ...
    // ... (Mevcut _buildProductCarousel kodunuz buraya gelecek) ...
    return Container(
      height: 220,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      margin: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
        key: UniqueKey(),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];

          // --- DÜZENLEME BAŞLANGICI ---
          // API'den gelen resim yolunu kontrol edip doğru URL'yi oluşturan mantık
          final String imageUrl;
          if (product.resim != null && product.resim!.isNotEmpty) {
            if (product.resim!.startsWith('/')) {
              // Eğer resim yolu '/' ile başlıyorsa (örn: /Upload/resim.jpg), doğrudan baseUrl ile birleştir.
              imageUrl = '${ApiService.baseUrl}${product.resim}';
            } else {
              // Eğer sadece dosya adı geliyorsa (örn: resim.jpg), araya '/Upload/' ekle.
              imageUrl = '${ApiService.baseUrl}/Upload/${product.resim}';
            }
          } else {
            // Resim null ise boş bir string ata (hata vermemesi için)
            imageUrl = '';
          }
          // --- DÜZENLEME SONU ---

          return GestureDetector(
            onTap: () async {
              try {
                final fullProduct = await ApiService.getProductDetails(product.id);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(product: fullProduct)));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ürün detayı yüklenemedi.")));
              }
            },
            child: SizedBox(
              width: 150,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: product.resim != null && imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl, // Düzeltilmiş URL'yi kullan
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (ctx, err, st) => Icon(Icons.image_not_supported, size: 40),
                      )
                          : Center(child: Icon(Icons.image, size: 40)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.adi,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${product.fiyat} ₺',
                            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextInput() {
    // ... (Bu metotta değişiklik yok) ...
    // ... (Mevcut _buildTextInput kodunuz buraya gelecek) ...
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12, offset: Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Mesajınızı yazın...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}