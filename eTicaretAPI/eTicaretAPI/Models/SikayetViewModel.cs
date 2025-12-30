// eTicaretAPI/Models/SikayetViewModel.cs
using System;

namespace eTicaretAPI.Models
{
    public class SikayetViewModel
    {
        public int SikayetId { get; set; }
        public int YorumId { get; set; }
        public string YorumIcerik { get; set; }
        public string YorumuYapanKullanici { get; set; }
        public string YorumuYapanKullaniciId { get; set; } // BU SATIRI EKLEYİN
        public string SikayetEdenKullanici { get; set; }
        public DateTime SikayetTarihi { get; set; }
        public bool IslemYapildiMi { get; set; }
    }
}