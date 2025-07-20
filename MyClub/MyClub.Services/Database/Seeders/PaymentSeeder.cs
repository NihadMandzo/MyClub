using System;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyClub.Services.Database.Seeders;

public static class PaymentSeeder
{
    public static void SeedData(this EntityTypeBuilder<Payment> entity)
    {
        var random = new Random(100);
        var payments = new List<Payment>();
        
        string[] paymentMethods = { "Credit Card", "Debit Card", "PayPal", "Bank Transfer", "Cash" };
        string[] paymentStatuses = { "Completed", "Pending", "Failed", "Refunded" };

        for (int i = 1; i <= 50; i++)
        {
            var amount = Math.Round((decimal)(random.NextDouble() * 200 + 10), 2);
            var createdDate = DateTime.Now.AddDays(-random.Next(1, 365));
            var status = paymentStatuses[random.Next(0, paymentStatuses.Length)];
            var completedDate = status == "Completed" ? createdDate.AddMinutes(random.Next(1, 60)) : (DateTime?)null;

            payments.Add(new Payment
            {
                Id = i,
                TransactionId = $"TX-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}",
                Amount = amount,
                Method = paymentMethods[random.Next(0, paymentMethods.Length)],
                Status = status,
                CreatedAt = createdDate,
                CompletedAt = completedDate
            });
        }

        entity.HasData(payments);
    }
}
