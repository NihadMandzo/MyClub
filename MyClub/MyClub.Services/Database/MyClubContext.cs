using Microsoft.EntityFrameworkCore;
using MyClub.Services.Database.Seeders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace MyClub.Services.Database
{
    public class MyClubContext : DbContext
    {
        public MyClubContext(DbContextOptions<MyClubContext> options) : base(options)
        {
        }

        // Users and Roles
        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }

        // News
        public DbSet<News> News { get; set; }
        public DbSet<NewsComment> NewsComments { get; set; }

        // Products
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<ProductCategory> ProductCategories { get; set; }
        public DbSet<Size> Sizes { get; set; }
        public DbSet<Color> Colors { get; set; }
        public DbSet<ProductSize> ProductSizes { get; set; }

        // Images
        public DbSet<Asset> Assets { get; set; }
        public DbSet<ProductImage> ProductImages { get; set; }

        // Cart and Orders
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }

        // Club and Membership
        public DbSet<Club> Clubs { get; set; }
        public DbSet<MembershipCard> MembershipCards { get; set; }
        public DbSet<UserMembership> UserMemberships { get; set; }

        // Stadium
        public DbSet<StadiumSide> StadiumSides { get; set; }
        public DbSet<StadiumSector> StadiumSectors { get; set; }

        // Players and Matches
        public DbSet<Player> Players { get; set; }
        public DbSet<Match> Matches { get; set; }
        public DbSet<CommentType> CommentTypes { get; set; }
        public DbSet<MatchComment> MatchComments { get; set; }
        public DbSet<MatchSquad> MatchSquads { get; set; }
        public DbSet<MatchTicket> MatchTickets { get; set; }
        public DbSet<UserTicket> UserTickets { get; set; }

        // League Table
        public DbSet<LeagueTable> LeagueTable { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // First, set the default delete behavior to NoAction for all relationships
            // This prevents SQL Server cascade delete cycles
            foreach (var relationship in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                relationship.DeleteBehavior = DeleteBehavior.NoAction;
            }

            // Configure composite keys
            modelBuilder.Entity<ProductImage>()
                .HasKey(pi => new { pi.ProductId, pi.ImageId });

            // Configure ProductImage relationships explicitly
            modelBuilder.Entity<ProductImage>()
                .HasOne(pi => pi.Product)
                .WithMany()
                .HasForeignKey(pi => pi.ProductId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ProductImage>()
                .HasOne(pi => pi.Image)
                .WithMany()
                .HasForeignKey(pi => pi.ImageId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserMembership>()
                .HasKey(um => new { um.UserId, um.MembershipCardId });

            // Configure UserMembership relationships explicitly
            modelBuilder.Entity<UserMembership>()
                .HasOne(um => um.User)
                .WithMany()
                .HasForeignKey(um => um.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserMembership>()
                .HasOne(um => um.MembershipCard)
                .WithMany(mc => mc.UserMemberships)
                .HasForeignKey(um => um.MembershipCardId)
                .OnDelete(DeleteBehavior.NoAction);
           
            // Configure unique constraints
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<Role>()
                .HasIndex(r => r.Name)
                .IsUnique();

            modelBuilder.Entity<Size>()
                .HasIndex(s => s.Name)
                .IsUnique();
                
            modelBuilder.Entity<CommentType>()
                .HasIndex(ct => ct.Name)
                .IsUnique();
                
            modelBuilder.Entity<StadiumSide>()
                .HasIndex(ss => ss.Name)
                .IsUnique();

            // Configure ProductCategory (many-to-many) relationships
            modelBuilder.Entity<ProductCategory>()
                .HasOne(pc => pc.Product)
                .WithMany(p => p.ProductCategories)
                .HasForeignKey(pc => pc.ProductId)
                .OnDelete(DeleteBehavior.NoAction);
                
            modelBuilder.Entity<ProductCategory>()
                .HasOne(pc => pc.Category)
                .WithMany(c => c.ProductCategories)
                .HasForeignKey(pc => pc.CategoryId)
                .OnDelete(DeleteBehavior.NoAction);
                
            // Create a composite index for ProductId and CategoryId to ensure uniqueness
            modelBuilder.Entity<ProductCategory>()
                .HasIndex(pc => new { pc.ProductId, pc.CategoryId })
                .IsUnique();
                
            modelBuilder.Entity<Cart>()
                .HasMany(c => c.Items)
                .WithOne(i => i.Cart)
                .HasForeignKey(i => i.CartId)
                .OnDelete(DeleteBehavior.Cascade); // This is safe to cascade
                
            modelBuilder.Entity<Order>()
                .HasMany(o => o.OrderItems)
                .WithOne(i => i.Order)
                .HasForeignKey(i => i.OrderId)
                .OnDelete(DeleteBehavior.Cascade); // This is safe to cascade
                

            // Configure ProductSize relationships
            modelBuilder.Entity<ProductSize>()
                .HasIndex(ps => new { ps.ProductId, ps.SizeId })
                .IsUnique();

            modelBuilder.Entity<ProductSize>()
                .HasOne(ps => ps.Product)
                .WithMany(p => p.ProductSizes)
                .HasForeignKey(ps => ps.ProductId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ProductSize>()
                .HasOne(ps => ps.Size)
                .WithMany(s => s.ProductSizes)
                .HasForeignKey(ps => ps.SizeId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure User-Role relationship
            modelBuilder.Entity<User>()
                .HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId)
                .OnDelete(DeleteBehavior.NoAction);

            // News-User relationship - prevent cascade delete from User to News
            modelBuilder.Entity<News>()
                .HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            // NewsComment relationships - prevent cascade delete cycles
            modelBuilder.Entity<NewsComment>()
                .HasOne(nc => nc.News)
                .WithMany(n => n.Comments)
                .HasForeignKey(nc => nc.NewsId)
                .OnDelete(DeleteBehavior.Cascade); // Safe to cascade delete comments when news is deleted

            modelBuilder.Entity<NewsComment>()
                .HasOne(nc => nc.User)
                .WithMany()
                .HasForeignKey(nc => nc.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Club-Player relationship
            modelBuilder.Entity<Player>()
                .HasOne(p => p.Club)
                .WithMany(c => c.Players)
                .HasForeignKey(p => p.ClubId)
                .OnDelete(DeleteBehavior.NoAction);

            // Player-Image relationship
            modelBuilder.Entity<Player>()
                .HasOne(p => p.Image)
                .WithMany()
                .HasForeignKey(p => p.ImageId)
                .OnDelete(DeleteBehavior.NoAction);

            // Club-Match relationship
            modelBuilder.Entity<Match>()
                .HasOne(m => m.Club)
                .WithMany(c => c.Matches)
                .HasForeignKey(m => m.ClubId)
                .OnDelete(DeleteBehavior.NoAction);
                
            // Configure MatchComment-CommentType relationship
            modelBuilder.Entity<MatchComment>()
                .HasOne(mc => mc.CommentType)
                .WithMany(ct => ct.MatchComments)
                .HasForeignKey(mc => mc.CommentTypeId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure MatchComment-Match relationship
            modelBuilder.Entity<MatchComment>()
                .HasOne(mc => mc.Match)
                .WithMany(m => m.Comments)
                .HasForeignKey(mc => mc.MatchId)
                .OnDelete(DeleteBehavior.Cascade); // Safe to cascade delete comments when match is deleted
                
            // Configure StadiumSector-StadiumSide relationship
            modelBuilder.Entity<StadiumSector>()
                .HasOne(ss => ss.StadiumSide)
                .WithMany(s => s.Sectors)
                .HasForeignKey(ss => ss.StadiumSideId)
                .OnDelete(DeleteBehavior.NoAction);
                
            // Configure MatchTicket-StadiumSector relationship
            modelBuilder.Entity<MatchTicket>()
                .HasOne(mt => mt.StadiumSector)
                .WithMany(ss => ss.MatchTickets)
                .HasForeignKey(mt => mt.StadiumSectorId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure MatchTicket-Match relationship
            modelBuilder.Entity<MatchTicket>()
                .HasOne(mt => mt.Match)
                .WithMany(m => m.Tickets)
                .HasForeignKey(mt => mt.MatchId)
                .OnDelete(DeleteBehavior.Cascade); // Safe to cascade delete tickets when match is deleted
                
            // Make StadiumSector FullName unique
            modelBuilder.Entity<StadiumSector>()
                .HasIndex(ss => ss.FullName)
                .IsUnique();

            // Fix other potential cascade delete issues
            modelBuilder.Entity<CartItem>()
                .HasOne(ci => ci.ProductSize)
                .WithMany()
                .HasForeignKey(ci => ci.ProductSizeId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.ProductSize)
                .WithMany()
                .HasForeignKey(oi => oi.ProductSizeId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserTicket>()
                .HasOne(ut => ut.User)
                .WithMany()
                .HasForeignKey(ut => ut.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserTicket>()
                .HasOne(ut => ut.MatchTicket)
                .WithMany(mt => mt.UserTickets)
                .HasForeignKey(ut => ut.MatchTicketId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<MatchComment>()
                .HasOne(mc => mc.Player)
                .WithMany()
                .HasForeignKey(mc => mc.PlayerId)
                .OnDelete(DeleteBehavior.NoAction);

            // Club-Logo relationship
            modelBuilder.Entity<Club>()
                .HasOne(c => c.LogoImage)
                .WithMany()
                .HasForeignKey(c => c.LogoImageId)
                .OnDelete(DeleteBehavior.NoAction);

            // LeagueTable-Logo relationship
            modelBuilder.Entity<LeagueTable>()
                .HasOne(lt => lt.LogoImage)
                .WithMany()
                .HasForeignKey(lt => lt.LogoImageId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Color>().SeedData();
            modelBuilder.Entity<Size>().SeedData();
            modelBuilder.Entity<Role>().SeedData();
            modelBuilder.Entity<Category>().SeedData();
        }
    }
}