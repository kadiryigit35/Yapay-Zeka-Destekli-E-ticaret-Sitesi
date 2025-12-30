using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using eTicaretAPI.Entity;

namespace eTicaretAPI.Models
{
    public class sepet
    {
        private List<sepetOgesi> _sepetOgeleri = new List<sepetOgesi>();
        public List<sepetOgesi> sepetOgeleri
        {
            get { return _sepetOgeleri; }
        }
        public void urunEkleme(urun Urun, int adet)
        {
            var oge = _sepetOgeleri.FirstOrDefault(i => i.urun.Id == Urun.Id);
            if (oge == null)
            {
                _sepetOgeleri.Add(new sepetOgesi { urun = Urun, Adet = adet });
            }
            else
            {
                oge.Adet += adet;
            }
        }
    
            public void urunCikarma(urun Urun)
        {
             _sepetOgeleri.RemoveAll(i => i.urun.Id == Urun.Id);
        }

        public double sepetTutari()
        {
            return _sepetOgeleri.Sum(i => i.urun.Fiyat*i.Adet);
        }
        public void sepetiTemizle()
        {
            _sepetOgeleri.Clear();
        }
    }


    public class sepetOgesi
    {
        public urun urun { get; set; }
        public int Adet { get; set; }
    }
}