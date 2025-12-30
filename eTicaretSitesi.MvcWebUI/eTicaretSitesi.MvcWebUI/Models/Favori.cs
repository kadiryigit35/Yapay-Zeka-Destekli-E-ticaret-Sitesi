using eTicaretSitesi.MvcWebUI.Entity;
using System;

public class Favori
{
    public int Id { get; set; }
    public int UrunId { get; set; }
    public string KullaniciAdi { get; set; }
    public DateTime Tarih { get; set; }

    public virtual urun Urun { get; set; }
}
