using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using eTicaretAPI.Entity;
using eTicaretAPI.Identity; // IdentityDataContext burada tanımlı varsayıyorum

namespace eTicaretAPI.Entity
{
    public class DataInitializer : CreateDatabaseIfNotExists<DataContext>
    {
        protected override void Seed(DataContext context)
        {
            using (var identityContext = new IdentityDataContext())
            {
                // Kullanıcıları kullanıcı adıyla çekiyoruz
                var kullaniciHyperX = identityContext.Users.FirstOrDefault(u => u.UserName == "hyperx");
                var kullaniciCorsair = identityContext.Users.FirstOrDefault(u => u.UserName == "corsair");
                var kullaniciLogitech = identityContext.Users.FirstOrDefault(u => u.UserName == "logitech");
                var kullaniciGamepower = identityContext.Users.FirstOrDefault(u => u.UserName == "gamepower");
                var kullaniciItopya = identityContext.Users.FirstOrDefault(u => u.UserName == "itopya");
                var kullaniciVatan = identityContext.Users.FirstOrDefault(u => u.UserName == "vatan");
                var kullaniciRazer = identityContext.Users.FirstOrDefault(u => u.UserName == "razer");
                var kullaniciWraith = identityContext.Users.FirstOrDefault(u => u.UserName == "wraith");

                List<satici> saticilar = new List<satici>
                {
                    new satici { Adi = "HyperX", Hakkinda = "Teknoloji ürünlerinde öncü", Resim = "HyperX.jpg", KullaniciId = kullaniciHyperX?.Id },
                    new satici { Adi = "CORSAIR", Hakkinda = "Oyun severler için", Resim = "CORSAIR.jpg", KullaniciId = kullaniciCorsair?.Id },
                    new satici { Adi = "Logitech", Hakkinda = "Oyun severler için", Resim = "Logitech.png", KullaniciId = kullaniciLogitech?.Id },
                    new satici { Adi = "Gamepower", Hakkinda = "Oyun severler için", Resim = "Gamepower.jpg", KullaniciId = kullaniciGamepower?.Id },
                    new satici { Adi = "İTOPYA", Hakkinda = "Oyun severler için", Resim = "İTOPYA.jpg", KullaniciId = kullaniciItopya?.Id },
                    new satici { Adi = "VATAN Bilgisayar", Hakkinda = "Oyun severler için", Resim = "VATAN.jpg", KullaniciId = kullaniciVatan?.Id },
                    new satici { Adi = "Razer", Hakkinda = "Oyun severler için", Resim = "Razer.jpg", KullaniciId = kullaniciRazer?.Id },
                    new satici { Adi = "Wraith Esports", Hakkinda = "Türkiye'nin espor ekipmanı markası. Cosmic Glass Mousepad, Hoverpad Skatez, Armor Grip Tape. Lamzu ve Ninjutso Türkiye Distribütörü.", Resim = "wraith.jpg", KullaniciId = kullaniciWraith?.Id }
                };

                foreach (var satici in saticilar)
                {
                    context.saticilar.Add(satici);
                }
                context.SaveChanges();
            }

            // Kategoriler
            List<kategori> kategoriler = new List<kategori>
            {
                new kategori() { Adi = "Kulaklık", Aciklama = "Kulaklık Çeşitleri ve Modelleri" },
                new kategori() { Adi = "Klavye", Aciklama = "Klavye Çeşitleri ve Modelleri" },
                new kategori() { Adi = "Mouse", Aciklama = "Mouse Çeşitleri ve Modelleri" },
                new kategori() { Adi = "Hazır Sistemler", Aciklama = "Hazır Sistem ve Bilgisayar Bileşenleri" }
            };

            foreach (var kategori in kategoriler)
            {
                context.kategori.Add(kategori);
            }
            context.SaveChanges();

            // Ürünler
            List<urun> urunler = new List<urun>
            {
              new urun() { Adi = "HyperX Cloud II KHX-HSCP 7.1 Kablolu Kulak Üstü Oyuncu Kulaklığı",Aciklama="İster PC'niz için sanal 7\r\n1 surround sese sahip bir kulaklık isterse konsol ihtiyaçlarını karşılamak için uyarlanmış bir stereo kurulum arıyor olun, sizin için mutlaka bir Cloud mevcut\r\nTüm Cloud modelleri, HyperX™ imzalı hafızalı köpük ile ödüllü konfor sunarak, oyunlarınızda daha uzun süre önde olmanızı sağlamak üzere tasarlandı\r\n53 mm sürücüler, kristal berraklığında hassas ses sunar ve kapalı kulak kapakları sizi tamamen oyunun içine almak için dışarıdan gelen gürültüleri ortadan kaldırır\r\nDayanıklı bir alüminyum çerçeve takviyesine sahip Cloud ürün yelpazesindeki tüm kulaklıklar, günlük oyunlardaki zorlu koşullara dayanmak üzere tasarlandı\r\nCloud’un çıkarılabilir gürültü önleyici mikrofonu, sesinizin her zaman yüksek ve net bir şekilde duyulmasını sağlayacaktır", Fiyat = 3670,Stok=10,Resim="cloud2.jpg",kategoriId=1,saticiId=1},
 new urun() { Adi = "HyperX Cloud III Kablosuz Kulak Üstü Oyuncu Kulaklığı",Aciklama="HyperX Cloud III Wireless oyun kulaklığı\r\n120 Saate Varan Pil Ömrü\r\nÖzel HyperX Konforu ve Dayanıklılığı\r\nAyarlanmış, Açılı 53 mm Sürücüler\r\nDTS Headphone:X Uzamsal Ses", Fiyat = 4343,Stok=10,Resim="cloud3.jpg",kategoriId=1,saticiId=1},
 new urun() { Adi = "CORSAIR K70 MK.2 Cherry MX Red Türkçe RGB Gaming Mekanik Klavye",Aciklama="Alman yapımı CHERRY MX anahtarlı anahtarlar, sorunsuz, doğrusal bir yanıtla talep ettiğiniz güvenilirliği ve doğruluğu sağlar.\r\nUçak sınıfı fırçalanmış anodize alüminyum çerçeve, binlerce saatlik oyun deneyimine dayanacak şekilde hafif ve sağlam dayanıklılık sağlar.\r\nFareniz veya kulaklığınız için ek bir USB bağlantı noktasına kolay erişim.", Fiyat = 1333,Stok=0,Resim="corsairkb70.jpg",kategoriId=2 ,saticiId=2},
 new urun() { Adi = "Corsair Void Elite Surround 7.1 Kablolu Kulak Üstü Oyuncu Kulaklığı",Aciklama="Corsair Void Elite Surround 7.1 CA-9011205-EU Kablolu Mikrofonlu Kulak Üstü Oyuncu Kulaklığı Siyah", Fiyat = 5219,Stok=7,Resim="corsairvoid.jpg",kategoriId=1 ,saticiId=2},
 new urun() { Adi = "Logitech G203 LIGHTSYNC RGB 6 Tuşlu Oyun Faresi",Aciklama="Çeşitli canlı renklere sahip G203 oyun mouse’u ile oyun süresini en iyi şekilde değerlendirin. LIGHTSYNC teknolojisi, oyun sınıfı bir sensör ve klasik 6 tuşlu tasarımla oyununuzda ve masanızda ışık saçacaksınız", Fiyat = 499,Stok=14,Resim="g203.jpg",kategoriId=3,saticiId=3 },
 new urun() { Adi = "Logitech G402 Hyperion Fury FPS Gaming Mouse",Aciklama="Ergonomik Tasarım: Logitech G402 Hyperion Fury FPS Oyuncu Mouse'u, uzun oyun seansları sırasında konfor sağlamak için ergonomik bir tasarıma sahiptir.\r\nLazer Sensör: Fare, hareketi doğru bir şekilde izlemek ve kaydırmayı algılamak için bir lazer sensör kullanır, bu da hassas nişan alma ve gezinme olanağı sağlar.\r\n8 Tuşlu Yapılandırma: Farede tuş atamalarını ve komutları özelleştirmek için 8 adet programlanabilir tuş bulunur.\r\nKompakt ve Taşınabilir: Fare, kompakt ve hafiftir; bu sayede hareket halindeyken taşınması ve kullanılması kolaydır.\r\nOyun Sınıfı Performans: Fare, oyun deneyiminizi optimize etmek için özelleştirilebilir ayarlarla rekabetçi oyunlar için akıcı ve duyarlı bir performans sunar.", Fiyat = 949,Stok=12,Resim="g402.jpg",kategoriId=3 ,saticiId=3},
 new urun() { Adi = "LOGITECH G G435 LIGHTSPEED Kablosuz Oyuncu Kulaklığı - Siyah",Aciklama="Oyun sonlanır, eğlence sonlanmaz. Oyun oynayabilir, müzik çalabilir ve arkadaşlarınızla oynayabilirsiniz. Size her zaman uyum sağlar. Bu yüzden G435 Kulaklığı hayatınızın her alanı için tasarladık. Oyun sınıfı LIGHTSPEED kablosuz ve Bluetooth, bilgisayarınıza, telefonunuza ve diğer cihazlarınıza kablosuz bağlanma özgürlüğü sunar. 40 mm sürücüleri olağanüstü ses sunarken çift hüzmelemeli mikrofon, mikrofon kolunu ve arka plan gürültüsünü ortadan kaldırır. Ayrıca CarbonNeutral® sertifikalıdır ve en az %22 geri dönüştürülmüş plastikten üretilmiştir. G435 ile oyun asla sona ermez. Tarzınıza uygun farklı renk seçenekleri bulunur.", Fiyat = 3222,Stok=2,Resim="g435.jpg",kategoriId=1,saticiId=3 },
 new urun() { Adi = "logitech G G733 LIGHTSPEED RGB Kablosuz 7.1 Surround Ses Oyuncu Kulaklığı - Siyah",Aciklama="Logitech G G733 en yüksek frekans 20 kHz, en düşük frekans 20 Hz olarak kullanılır. 88 desibele kadar gürültü önleme hassasiyeti bulunur.\r\nRGB oyuncu kulaklığı USB alıcı ile çalışmaya uygundur. 20 metre kullanım mesafesi bulunur.\r\nSiyah kulaküstü kulaklık 88 desibel ses hassasiyeti ile konforlu kullanım sunar. Cihazın 29 saat genel kullanım süresi bulunur.\r\nLogitech G G733 lightspeed empedans 39 0hm’dir.\r\nLogitech G G733 kablosuz RGB 7.1 kulaklık kumandalı olarak da kullanılır. Kumanda işlevi ise mikrofon kontrolünü sağlamak ve ses kontrolünü sağlamaktır.\r\nLogitech G G733 kablosuz kulaklığın aydınlatma özelliği mevcuttur. Aydınlatma tipi ise RGB tip aydınlatmadır.\r\nLogitech G G733 lightspeed RGB 7.1 surround siyah gaming kulaklık modelinin 278 gram ağırlığı mevcuttur.\r\nLogitech G G733 kablosuz 7.1 kulaklık 40 mm sürücü çapı ile kullanılır.", Fiyat = 5867,Stok=5,Resim="g733.jpg",kategoriId=1,saticiId=3 },
 new urun() { Adi = "Gamepower Gasket Elite RGB Wireless/Bluetooth/Kablolu Mekanik Red Switch Gasket Gaming Klavye",Aciklama="GamePower Gasket Elite RGB Wireless/Bluetooth/Kablolu Mekanik Red Switch Gasket Gaming Klavye Genel Özellikler\r\n\r\nGamePower Gasket Elite ile Tanışın\r\nGasket Elite ile tanışın; hız ve yenilik deneyimi yaşayın. Yeni nesil tasarım, son nesil teknoloji ve eşsiz performans.\r\n\r\n60 Milyon Ömürlü Switchler\r\nGasket Elite’de lehimsiz tasarımlı 60 milyon ömürlü mekanik switchleri deneyimleyin.\r\n\r\nYenil Nesil LCD Ekran – En Üst Düzey Özelleştirme\r\n1.14 inçlik LCD ekran tüm ayarlar için özelleştirme sunar. Kendine özgü ve etkileyici bir deneyimin tadını çıkarın.\r\n\r\nGasket Tasarım – Ses Yalıtım Teknolojisi\r\nGamePower’da gasket teknoloji yapısını keşfedin. Gasket tasarımı, tuşlardaki titreşimleri ve yay seslerini azaltan ses yalıtım köpükleri ile gelir. Yumuşak, esnek ve sessiz bir hisle tanışın.\r\n\r\nSınırsız Bağlantı: Kablolu, 2.4GHz, Bluetooth 5.1\r\nGasket Elite ile çok yönlülüğün tadını çıkarın; kablolu, 2.4GHz ve bluetooth 5.1 bağlantı seçeneklerini sunar.\r\n\r\nÖzelleştirilebilir RGB: En İyi Modu Ayarlayın\r\nGasket Elite üzerinde etkileyici RGB aydınlatmayı deneyimleyin. Renkleri kişiselleştirin ve ambiyansı artırın.\r\n\r\nUzun Süreli Güç: 4000mAh Batarya\r\nGasket Elite 4000mAh lityum bataryası ile uzatılmış kullanım süresini deneyimleyin.", Fiyat = 4199,Stok=12,Resim="gamepowergasket.jpg",kategoriId=2 ,saticiId=4},
 new urun() { Adi = "LogitechG Pro X 2 Lightspeed Bluetooth Oyuncu Kulak Üstü Kulaklık",Aciklama="LogitechG Pro X 2 Lightspeed Bluetooth Oyuncu Kulak Üstü Kulaklık\r\n", Fiyat = 9250,Stok=0,Resim="gprox2.jpg",kategoriId=1,saticiId=3 },
 new urun() { Adi = "Logitech G Pro X TKL Kablosuz Mekanik Oyuncu Klavyesi",Aciklama="Logitech G Pro X, LIGHTSPEED kablosuz teknolojisi sayesinde 1 ms'lik ultra düşük gecikme süresi sunar. Bu, kablolu bağlantılarla eş değer bir performans sağlayarak, oyunlarda hız ve tepki sürenizi maksimize eder.\r\n\r\nÖzelleştirilebilir RGB Aydınlatma\r\nKlavyenin her tuşu, tercihinize göre özelleştirilebilen 16.8 milyon renk seçeneği sunan RGB aydınlatmaya sahiptir. Logitech G HUB yazılımı üzerinden kolayca ayarlanabilen bu özellik, oyun deneyiminizi kişiselleştirmenizi ve oyun alanınızı aydınlatmanızı sağlar.\r\n\r\nKompakt ve Dayanıklı Tasarım\r\nTKL (tenkeyless) tasarımı sayesinde daha fazla masa alanı kazandıran Logitech G Pro X, dayanıklı yapısı ile uzun süreli kullanım için idealdir. Çıkarılabilir kablo özelliği ve taşıma kolaylığı, özellikle turnuvalar ve LAN partileri için ideal bir seçenektir.", Fiyat = 7500,Stok=23,Resim="gprox2tkl.jpg",kategoriId=2 ,saticiId=3},
 new urun() { Adi = "Genetik Storm V1 Intel Core i5 13400F 16GB RTX 4060 Ti 500GB M.2 Hazır Sistem",Aciklama="İşlemci\tIntel Core i5 13400F 3.30 Ghz 10 Çekirdek 30MB 10nm 1700p İşlemci\r\nAnakart\tAsus Prime H610M-K DDR4 3200(OC) m.2 mATX Anakart 1700p\r\nBellek\tKingston 16GB (2x8) Fury Beast 3200mhz CL16 DDR4 Siyah Gaming Ram Bellek (KF432C16BBK2/16)\r\nEkran Kartı\r\nManli GeForce RTX 4060 Ti 8GB 128Bit GDDR6 Nvidia Gaming Ekran Kartı M-NRTX4060TI/6RGHPPP-M2546\r\nSSD\tKingston NV2 500GB 3500/2100MB/s PCIe Gen 4x4 NVMe M.2 SSD Disk SNV2S/500G\r\nKasa\tGamdias ATHENA M6 Lite White Mesh 500w Tempered Glass ARGB Mid Tower Kasa", Fiyat = 45891,Stok=1,Resim="hazırsistem1.png",kategoriId=4,saticiId=5},
 new urun() { Adi = "Sıfır Ryzen 7 9800X3D / RTX 4080 / 2TB M2/ Lian Li LCD Özel Kasa",Aciklama="Gigabyte AERO White RTX 4080 16GB DLLS3 Ekran Kartı\r\nAMD Ryzen 7 9800X3D İşlemci\r\nAsus Rog Strix White B650-A Anakart\r\nG-Skill Trident Z Neo White 2x16 32GB 6400MHz CL32 Ram\r\nKinston KC3000 Gen4 2TB M2 NVME SSD (7100W/6900R)\r\nLian Li Vision O11 White Gaming Kasa\r\nCOOLER MASTER MWE V2 80PLUS GOLD 1050W GEN5 FULL MODÜLER 140MM FANLI GÜÇ KAYNAĞI\r\nCORSAIR iCUE H150i ELITE LCD XT WHITE 360MM INTEL AMD UYUMLU SIVI SOĞUTUCU\r\nLIAN LI UNI FAN TL-LCD Reverse 4X120 ARGB BEYAZ KASA FANI\r\nLIAN LI UNI FAN TL-LCD 3X120 ARGB BEYAZ KASA FANI \r\nLian Li Strimer Wireless 24P (G89.PW24-1W-T.00)\r\nLian Li Strimer Wireless 16+12 (G89.PW16-121W.00)", Fiyat = 85000,Stok=11,Resim="hazırsistem2.jpg",kategoriId=4,saticiId=6 },
 new urun() { Adi = "Turbox Tx4456 Ryzen 5 3600 16GB DDR4 512GB NVMe 8GB RTX 2060 SUPER Hazır Sistem Oyun Bilgisayarı",Aciklama="Turbox Tx4456 Ryzen 5 3600 16GB DDR4 512GB NVMe 8GB RTX 2060 SUPER Hazır Sistem Oyun Bilgisayarı", Fiyat = 21941.77,Stok=8,Resim="hazırsistem3.jpg",kategoriId=4,saticiId=5 },
 new urun() { Adi = "RexDragon I7 12700F 32GB (2X16GB) 512GB SSD 12GB RTX3060 W11PRO Gaming Hazır Pc",Aciklama="Bellek : 32GB (2x16GB)\r\nEkran Kartı : 12GB RTX3060\r\nGüç Kaynağı : 650W 80+ BRONZE\r\nİşlemci Hızı : 12700F\r\nİşlemcisi : i7\r\nİşletim Sistemi : W11PRO\r\nKasa tipi : Gaming Hazır PC\r\nMarka : REXDRAGON\r\nSabit Diski : 512GB SSD", Fiyat = 41666.43,Stok=9,Resim="hazırsistem4.png",kategoriId=4 ,saticiId=6},
 new urun() { Adi = "Ninjutso Sora V2",Aciklama="Polikarbonattan üretilen ve sadece 39 gram ağırlığında olan Sora V2, deliksiz dünyanın en hafif kablosuz oyun faresidir. 8000 Hz'e kadar yoklama oranı ve rekabetçi mod ile son derece düşük gecikme süresi sağlayan yepyeni SnappyFire kablosuz teknolojisiyle donatılmış olan her şey saf performans için tasarlanmıştır.", Fiyat = 3500,Stok=16,Resim="ninjutsosorav2.png",kategoriId=3 ,saticiId=8},
 new urun() { Adi = "Razer DeathAdder Essential Beyaz Kablolu Gaming Mouse",Aciklama="ESASLI OYUN FARESİ\r\nOn yıldan fazla bir süredir, Razer DeathAdder serisi küresel espor sahnesinde temel bir oyuncu ekipmanı olmuştur. Sağlamlığı ve ergonomik yapısı sayesinde oyuncuların güvendiği bir üne sahip olmuştur. Şimdi, en son halef modeli olan Razer DeathAdder Essential ile bu fareyi daha da erişilebilir hale getiriyoruz.\r\n\r\nPERFORMANSIN KANITLANMIŞ GEÇMİŞİ\r\nRazer DeathAdder ailesi, dünyanın en ünlü ve tanınmış oyun farelerinden biridir. Dünya genelinde 9 milyondan fazla ünite satıldı ve onlarca ödül kazandı. Bu nedenle, Razer DeathAdder’ın başlangıcından bu yana bir hayran kitlesi oluşturması şaşırtıcı değildir. Aşağıda, bu fareye ait önemli anları inceleyebilirsiniz.\r\n\r\n\r\nERGONOMİK TASARIM\r\nRazer DeathAdder Essential, önceki Razer DeathAdder nesillerinin de temel özelliği olan klasik ergonomik tasarımı koruyor. Şık ve farklı bir gövdeye sahip olan bu fare, konfor için tasarlanmıştır. Uzun oyun maratonları boyunca yüksek performansı sürdürebilmenizi sağlar, böylece savaşın hararetinde hiç tereddüt etmezsiniz.", Fiyat = 849,Stok=8,Resim="razerdeathAdder.jpg",kategoriId=3,saticiId=7},
 new urun() { Adi = "LOGITECH G PRO X SUPERLIGHT 2 LIGHTSPEED Kablosuz Oyuncu Mouse - Siyah",Aciklama="En iyi e-spor oyuncuları ile devam eden iş birliğimizin bir sonucu olan PRO X SUPERLIGHT tek bir amaçla tasarlanmıştır: kaliteyi, yapısal bütünlüğü ve Logitech G’nin sunduğu profesyonel sınıf standartları koruyacak mümkün olan en hafif PRO kablosuz oyun faresini yaratmak. Hiç olmadığı kadar hızlı şekilde birinciliğe ulaşın.", Fiyat = 4449,Stok=10,Resim="süperlight2.jpg",kategoriId=3 ,saticiId=3}
            };

            foreach (var urun in urunler)
            {
                context.urunler.Add(urun);
            }
            context.SaveChanges();

            base.Seed(context);
        }
    }
}
