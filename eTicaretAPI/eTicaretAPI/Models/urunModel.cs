using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eTicaretAPI.Models
{
    public class urunModel
    {
        public int Id { get; set; }
        public string Adi { get; set; }
        public string Aciklama { get; set; }
        public double Fiyat { get; set; }
        public int Stok { get; set; }
        public string Resim { get; set; }
        public int kategoriId { get; set; }
        public int saticiId { get; set; }
        public string SaticiAdi { get; set; }
    }
}

