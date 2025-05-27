using Microsoft.EntityFrameworkCore;
using MyClub.Services;
using MyClub.Services.Database;
using Mapster;
using MapsterMapper;

var builder = WebApplication.CreateBuilder(args);
// Add services to the container.
builder.Services.AddTransient<IProductService, DummyProductService>();
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IColorService, ColorService>();
builder.Services.AddTransient<ISizeService, SizeService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();

builder.Services.AddMapster();

// Add database services
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=MyClubDb;Trusted_Connection=True;TrustServerCertificate=True";
builder.Services.AddMyClubDbContext(connectionString);



builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Ensure database creation
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<MyClubContext>();
    context.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
