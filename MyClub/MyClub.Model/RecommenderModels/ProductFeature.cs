using Microsoft.ML.Data;

namespace MyClub.Model.RecommenderModels
{
    // Input used to create the product feature IDataView
    public class ProductFeature
    {
        // Product id kept as float/float-compatible so ML.NET can handle it
        public float ProductId { get; set; }

        // Raw categorical/text/numeric features
        public string CategoryName { get; set; } = string.Empty;
        public string ColorName { get; set; } = string.Empty;
        public float Price { get; set; }
        public string Description { get; set; } = string.Empty;
    }

    public class ProductWithFeatures
    {
        public float ProductId { get; set; }

        [VectorType]
        public float[] Features { get; set; } = System.Array.Empty<float>();
    }

}