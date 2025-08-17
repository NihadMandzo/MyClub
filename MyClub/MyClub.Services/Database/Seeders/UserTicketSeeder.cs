using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyClub.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;

namespace MyClub.Services.Database.Seeders
{
    public static class UserTicketSeeder
    {
        public static void SeedData(this EntityTypeBuilder<UserTicket> entity)
        {
            var userTickets = new List<UserTicket>
            {
                // User 1 tickets
                new UserTicket
                {
                    Id = 1,
                    TotalPrice = 25.00m,
                    PurchaseDate = DateTime.UtcNow.AddDays(-30),
                    QRCode = "QR_USER1_TICKET_001",
                    IsValid = true,
                    PaymentId = 1,
                    UserId = 1,
                    MatchTicketId = 1
                },
                new UserTicket
                {
                    Id = 2,
                    TotalPrice = 30.00m,
                    PurchaseDate = DateTime.UtcNow.AddDays(-25),
                    QRCode = "QR_USER1_TICKET_002",
                    IsValid = true,
                    PaymentId = 2,
                    UserId = 1,
                    MatchTicketId = 2
                },
                new UserTicket
                {
                    Id = 3,
                    TotalPrice = 45.00m,
                    PurchaseDate = DateTime.UtcNow.AddDays(-20),
                    QRCode = "QR_USER1_TICKET_003",
                    IsValid = false,
                    PaymentId = 3,
                    UserId = 1,
                    MatchTicketId = 3
                },
                // User 2 tickets
                new UserTicket
                {
                    Id = 4,
                    TotalPrice = 35.00m,
                    PurchaseDate = DateTime.UtcNow.AddDays(-28),
                    QRCode = "QR_USER2_TICKET_001",
                    IsValid = true,
                    PaymentId = 4,
                    UserId = 2,
                    MatchTicketId = 1
                },
                new UserTicket
                {
                    Id = 5,
                    TotalPrice = 40.00m,
                    PurchaseDate = DateTime.UtcNow.AddDays(-22),
                    QRCode = "QR_USER2_TICKET_002",
                    IsValid = true,
                    PaymentId = 5,
                    UserId = 2,
                    MatchTicketId = 4
                },
                new UserTicket
                {
                    Id = 6,
                    TotalPrice = 50.00m,
                    PurchaseDate = DateTime.UtcNow.AddDays(-15),
                    QRCode = "QR_USER2_TICKET_003",
                    IsValid = true,
                    PaymentId = 6,
                    UserId = 2,
                    MatchTicketId = 5
                }
            };

            entity.HasData(userTickets);
        }
    }
}