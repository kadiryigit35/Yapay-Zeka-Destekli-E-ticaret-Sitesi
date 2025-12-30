using eTicaretSitesi.MvcWebUI.Entity;
using System;

public class Yorum
{
    public int Id { get; set; }
    public int UrunId { get; set; }
    public string KullaniciAdi { get; set; }
    public string Icerik { get; set; }
    public DateTime Tarih { get; set; }

    public virtual urun Urun { get; set; }
}
