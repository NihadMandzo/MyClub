using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;

namespace MyClub.Services.Database
{
    public static class DatabaseConfig
    {
        public static void AddMyClubDbContext(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<MyClubContext>(options =>
                options.UseSqlServer(connectionString));
        }
    }
} 