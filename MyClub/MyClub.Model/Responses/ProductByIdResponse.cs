using System;
using System.Collections.Generic;
using System.Drawing;
using MyClub.Model.SearchObjects;

namespace MyClub.Model.Responses
{
    public class ProductByIdResponse : ProductResponse
    {
        public List<string> ImageUrls { get; set; } = new List<string>();

        public List<ProductSizeResponse> Sizes { get; set; } = new List<ProductSizeResponse>();
    }
} 