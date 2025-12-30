namespace eTicaretSitesi.MvcWebUI.Entity
{ 
public class kayitliAdres
{
    public int Id { get; set; }
    public string KullaniciId { get; set; }
    public string AdresBasligi { get; set; }
    public string Adres { get; set; }
    public string Sehir { get; set; }
    public string Mahalle { get; set; }
    public string Sokak { get; set; }
    public string PostaKodu { get; set; }
    public string Telefon { get; set; }
    public string TamAd { get; set; }
}
}