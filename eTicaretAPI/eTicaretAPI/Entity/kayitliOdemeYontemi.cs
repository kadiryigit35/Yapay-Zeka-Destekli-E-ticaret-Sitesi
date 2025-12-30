namespace eTicaretAPI.Entity
{
    public class kayitliOdemeYontemi
    {
        public int Id { get; set; }
        public string KullaniciId { get; set; }
        public string KartSahibi { get; set; }
        public string KartNumarasi { get; set; }
        public string SKT { get; set; }
        public string CVV { get; set; }
    }
}