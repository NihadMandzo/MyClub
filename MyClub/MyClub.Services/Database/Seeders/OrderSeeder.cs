using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class OrderSeeder
{
    public static void SeedData(this EntityTypeBuilder<Order> entity)
    {
        var random = new Random(600);
        var orders = new List<Order>();
        
        string[] paymentMethods = { "Kreditna Kartica", "Debitna Kartica", "PayPal", "Bankovni Transfer", "Plaćanje po Dostavi" };
        string[] notes = { 
            "Molimo dostavite na vrata",
            "Nazovite prije dostave",
            "Ostavite kod susjeda ako niste kod kuće",
            "Krtki predmeti, pažljivo rukovati",
            "Posebna narudžba za člana kluba",
            "Kontaktirajte me za bilo kakve probleme",
            ""
        };
        
        for (int i = 1; i <= 50; i++)
        {
            int userId = random.Next(1, 4); // User IDs from your UserSeeder
            
            // For some orders, link to a payment
            int? paymentId = i <= 40 ? i : null; // First 40 orders have payments
            
            var orderDate = DateTime.Now.AddDays(-random.Next(1, 365));
            
            OrderStatus status;
            if (paymentId == null)
            {
                status = OrderStatus.Pending;
            }
            else
            {
                int statusIndex = random.Next(0, 6);
                status = (OrderStatus)statusIndex;
            }
            
            decimal totalAmount = Math.Round((decimal)(random.NextDouble() * 500 + 20), 2);
            
            // Some orders have shipping details
            int? shippingDetailsId = random.Next(0, 10) < 8 ? random.Next(1, 20) : null;
            
            string paymentMethod = paymentMethods[random.Next(0, paymentMethods.Length)];
            
            DateTime? shippedDate = status == OrderStatus.Shipped || status == OrderStatus.Delivered ? 
                orderDate.AddDays(random.Next(1, 5)) : null;
                
            DateTime? deliveredDate = status == OrderStatus.Delivered ? 
                shippedDate?.AddDays(random.Next(1, 7)) : null;
            
            string note = notes[random.Next(0, notes.Length)];
            
            orders.Add(new Order
            {
                Id = i,
                UserId = userId,
                PaymentId = paymentId,
                OrderDate = orderDate,
                Status = status,
                TotalAmount = totalAmount,
                ShippingDetailsId = shippingDetailsId,
                PaymentMethod = paymentMethod,
                ShippedDate = shippedDate,
                DeliveredDate = deliveredDate,
                Notes = note
            });
        }

        entity.HasData(orders);
    }
}
