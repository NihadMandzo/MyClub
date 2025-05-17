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
    public class DummyProductService : IProductService
    {
        public virtual List<Product> Get(ProductSearchObject search)
        {
            throw new NotImplementedException();
        }

        public virtual Product Get(int id)
        {
            throw new NotImplementedException();
        }
    }
}