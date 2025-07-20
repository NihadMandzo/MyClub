using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class OrderItemSeeder
{
    public static void SeedData(this EntityTypeBuilder<OrderItem> entity)
    {
        var random = new Random(700);
        var orderItems = new List<OrderItem>();
        
        int counter = 1;
        
        // Create multiple items for each order
        for (int orderId = 1; orderId <= 50; orderId++)
        {
            int numberOfItems = random.Next(1, 6); // Each order has 1-5 items
            
            for (int j = 0; j < numberOfItems; j++)
            {
                int productSizeId = random.Next(1, 30); // Assuming ProductSize IDs from 1-30
                int quantity = random.Next(1, 6); // 1-5 items of each product
                decimal unitPrice = Math.Round((decimal)(random.NextDouble() * 100 + 10), 2);
                
                orderItems.Add(new OrderItem
                {
                    Id = counter++,
                    OrderId = orderId,
                    ProductSizeId = productSizeId,
                    Quantity = quantity,
                    UnitPrice = unitPrice
                });
            }
        }

        entity.HasData(orderItems);
    }
}
