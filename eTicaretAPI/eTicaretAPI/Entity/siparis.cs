using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace eTicaretAPI.Entity
{
    public class siparis
    {
        public int Id { get; set; }
        public string SiparisNumarasi { get; set; }
        public double Toplam { get; set; }
        public DateTime SiparisTarihi { get; set; }
        public EnumsiparisDurum siparisDurum { get; set; }
        public virtual List<siparisYolu> GetSiparisYolu {  get; set; }
        public string TamAd { get; set; }
        public string AdresBasligi { get; set; }
        public string Adres { get; set; }
        public string Sehir { get; set; }
        public string Mahalle { get; set; }
        public string Sokak { get; set; }
        public string PostaKodu { get; set; }
        public string UserId { get; set; }
        public string GuestId { get; set; }
        public string Eposta { get; set; }

        public string telefon { get; set; }
    }
    public class siparisYolu
    {
        public int Id { get; set; }
        public int SiparisId { get; set; }
        public virtual siparis Siparis { get; set; }
        public int Adet { get; set; }
        public double Fiyat { get; set; }
        public int UrunId { get; set; }
        public virtual urun urun { get; set;}   

    }
}