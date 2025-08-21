using MyClub.Model.Responses;

namespace MyClub.Services.Interfaces
{
    public interface IRecommendationService
    {
        // Train/refresh the content-based model (lightweight transforms)
        Task TrainModelAsync();

        // Get top-N recommendations for a user. If model not trained,
        // caller can decide to trigger TrainModelAsync (ProductService does that).
        Task<List<ProductResponse>> GetRecommendationsAsync(int userId, int count = 10);

        bool IsModelTrained();
    }
}