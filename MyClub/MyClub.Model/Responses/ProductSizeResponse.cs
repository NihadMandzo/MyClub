using System;

namespace MyClub.Model.Responses
{

    public class ProductSizeResponse
    {
        public int ProductSizeId { get; set; }
        public int Quantity { get; set; }
        public SizeResponse Size { get; set; }
    }
}