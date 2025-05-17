using MyClub.Model;
using MyClub.Model.SearchObjects;
using MyClub.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MyClub.Services
{
    public class ProductService : IProductService
    {
        public List<Product> Get(ProductSearchObject search)
        {
            throw new NotImplementedException();
        }

        public Product Get(int id)
        {
            throw new NotImplementedException();
        }
    }
}