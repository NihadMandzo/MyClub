using System;
using System.Collections.Generic;
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
        
        // Define order states as strings
        string[] orderStates = { "Procesiranje", "Potvrđeno", "Dostava",};
        
        for (int i = 1; i <= 50; i++)
        {
            int userId = random.Next(1, 4); // User IDs from your UserSeeder
            
            // For some orders, link to a payment
            int? paymentId = i <= 40 ? i : null; // First 40 orders have payments
            
            var orderDate = DateTime.Now.AddDays(-random.Next(1, 365));
            
            decimal totalAmount = Math.Round((decimal)(random.NextDouble() * 500 + 20), 2);
            
            // Some orders have shipping details
            int? shippingDetailsId = random.Next(0, 10) < 8 ? random.Next(1, 20) : null;
            
            string paymentMethod = paymentMethods[random.Next(0, paymentMethods.Length)];
            
            // Randomly select an order state
            string orderState = orderStates[random.Next(0, orderStates.Length)];
            
            // Set shipped date only for orders in "Dostava" or "Završeno" state
            DateTime? shippedDate = (orderState == "Dostava" || orderState == "Završeno") ? 
                orderDate.AddDays(random.Next(1, 5)) : null;
            // Set delivered date only for orders in "Završeno" state
            DateTime? deliveredDate = orderState == "Završeno" ? 
                shippedDate?.AddDays(random.Next(1, 7)) : null;
            
            string note = notes[random.Next(0, notes.Length)];
            
            orders.Add(new Order
            {
                Id = i,
                UserId = userId,
                PaymentId = paymentId,
                OrderDate = orderDate,
                OrderState = orderState,
                TotalAmount = totalAmount,
                ShippingDetailsId = shippingDetailsId,
                ShippedDate = shippedDate,
                DeliveredDate = deliveredDate,
                Notes = note
            });
        }

        entity.HasData(orders);
    }
}
