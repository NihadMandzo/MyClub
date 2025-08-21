using Microsoft.ML;
using Microsoft.EntityFrameworkCore;
using MyClub.Services.Database;
using MyClub.Services.Interfaces;
using MyClub.Model.RecommenderModels;
using MyClub.Model.Responses;
using MapsterMapper;

namespace MyClub.Services.Services
{
    /// <summary>
    /// Content-based recommender using Euclidean distance only.
    /// </summary>
    public class RecommendationService : IRecommendationService
    {
        private readonly MyClubContext _context;
        private readonly IMapper _mapper;
        private readonly MLContext _ml;
        private ITransformer? _model;
        private readonly string _modelPath;
        private readonly string _lastTrainPath;
        private readonly TimeSpan _minRetrainInterval = TimeSpan.FromMinutes(5);
        private Dictionary<int, float[]> _productEmbeddings = new();

        public RecommendationService(MyClubContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
            _ml = new MLContext(seed: 0);
            _modelPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "content_recommender_euclid.zip");
            _lastTrainPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "content_last_train_euclid.txt");
            LoadModelIfExists();
        }

        // Train lightweight transforms and cache product vectors
        public async Task TrainModelAsync()
        {
            // skip retrain if recently trained
            if (File.Exists(_lastTrainPath) &&
                DateTime.TryParse(await File.ReadAllTextAsync(_lastTrainPath), out var last) &&
                DateTime.UtcNow - last < _minRetrainInterval)
            {
                return;
            }

            var products = await _context.Products
                .Where(p => p.IsActive)
                .Include(p => p.Category)
                .Include(p => p.Color)
                .Select(p => new ProductFeature
                {
                    ProductId = p.Id,
                    CategoryName = p.Category != null ? p.Category.Name : string.Empty,
                    ColorName = p.Color != null ? p.Color.Name : string.Empty,
                    Price = (float)p.Price,
                    Description = p.Description ?? string.Empty
                })
                .ToListAsync();

            if (!products.Any()) return;

            var data = _ml.Data.LoadFromEnumerable(products);

            var pipeline = _ml.Transforms.Categorical.OneHotEncoding("CategoryVec", nameof(ProductFeature.CategoryName))
                .Append(_ml.Transforms.Categorical.OneHotEncoding("ColorVec", nameof(ProductFeature.ColorName)))
                .Append(_ml.Transforms.NormalizeMinMax("PriceNorm", nameof(ProductFeature.Price)))
                .Append(_ml.Transforms.Text.FeaturizeText("DescVec", nameof(ProductFeature.Description)))
                .Append(_ml.Transforms.Concatenate("Features", "CategoryVec", "ColorVec", "PriceNorm", "DescVec"));

            _model = pipeline.Fit(data);

            var transformed = _model.Transform(data);
            var feats = _ml.Data.CreateEnumerable<ProductWithFeatures>(transformed, reuseRowObject: false);

            _productEmbeddings.Clear();
            foreach (var f in feats)
                _productEmbeddings[(int)f.ProductId] = f.Features;

            _ml.Model.Save(_model, data.Schema, _modelPath);
            await File.WriteAllTextAsync(_lastTrainPath, DateTime.UtcNow.ToString("o"));
        }

        // Euclidean-only recommendations: user profile = mean vector of purchased products,
        // calculate Euclidean distance to each candidate, order ascending (closest first).
        public async Task<List<ProductResponse>> GetRecommendationsAsync(int userId, int count = 10)
        {
            if (_model == null || !_productEmbeddings.Any())
                throw new InvalidOperationException("Model not trained");

            var purchasedIds = await _context.Orders
                .Where(o => o.UserId == userId)
                .SelectMany(o => o.OrderItems)
                .Select(oi => oi.ProductSize.ProductId)
                .Distinct()
                .ToListAsync();

            if (!purchasedIds.Any())
                return new List<ProductResponse>(); // caller should fallback to newest

            var purchasedVectors = purchasedIds.Where(id => _productEmbeddings.ContainsKey(id))
                                               .Select(id => _productEmbeddings[id])
                                               .ToList();

            if (!purchasedVectors.Any())
                return new List<ProductResponse>();

            int dim = purchasedVectors.First().Length;
            var userProfile = new float[dim];
            foreach (var v in purchasedVectors)
                for (int i = 0; i < dim; i++)
                    userProfile[i] += v[i];
            for (int i = 0; i < dim; i++)
                userProfile[i] /= purchasedVectors.Count;

            var distances = new List<(int ProductId, double Distance)>();
            foreach (var kv in _productEmbeddings)
            {
                int pid = kv.Key;
                if (purchasedIds.Contains(pid)) continue;

                double dist = EuclideanDistance(userProfile, kv.Value);
                distances.Add((pid, dist));
            }

            var topIds = distances.OrderBy(d => d.Distance) // ascending = closest
                                  .Take(count)
                                  .Select(d => d.ProductId)
                                  .ToList();

            if (!topIds.Any()) return new List<ProductResponse>();

            var products = await _context.Products
                .Where(p => topIds.Contains(p.Id) && p.IsActive)
                .Include(p => p.Category)
                .Include(p => p.Color)
                .Include(p => p.ProductAssets)
                .ThenInclude(pa => pa.Asset)
                .Include(p => p.ProductSizes)
                .ThenInclude(ps => ps.Size)
                .ToListAsync();

            // preserve ordering by topIds
            var ordered = topIds.Select(id => products.First(p => p.Id == id)).ToList();
            return ordered.Select(p => _mapper.Map<ProductResponse>(p)).ToList();
        }

        public bool IsModelTrained() => _model != null && _productEmbeddings.Any();

        // Euclidean distance helper
        private static double EuclideanDistance(float[] a, float[] b)
        {
            if (a.Length != b.Length) throw new ArgumentException("Vector length mismatch");
            double sum = 0;
            for (int i = 0; i < a.Length; i++)
            {
                var d = a[i] - b[i];
                sum += d * d;
            }
            return Math.Sqrt(sum);
        }

        private void LoadModelIfExists()
        {
             if (!File.Exists(_modelPath)) return;
            
            try
            {
                _model = _ml.Model.Load(_modelPath, out var schema);
                // Note: _productEmbeddings will be empty until TrainModelAsync is called
                // This is fine because IsModelTrained() checks both _model and _productEmbeddings
            }
            catch
            {
                // ignore load errors
            }
        }
    }
}