using Microsoft.EntityFrameworkCore;
using MyClub.Services;
using MyClub.Services.Database;

var builder = WebApplication.CreateBuilder(args);

// Add database services
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=MyClubDb;Trusted_Connection=True;TrustServerCertificate=True";
builder.Services.AddMyClubDbContext(connectionString);

// Add services to the container.
builder.Services.AddTransient<IProductService, DummyProductService>();
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IColorService, ColorService>();

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
