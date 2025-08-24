using Microsoft.EntityFrameworkCore;
using MyClub.Services;
using MyClub.Services.Database;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.OpenApi.Models;
using System.Security.Claims;
using MyClub.WebAPI.Filters;
using MyClub.Services.Interfaces;
using MyClub.Services.Services;
using MyClub.Services.OrderStateMachine;
using DotNetEnv;

var builder = WebApplication.CreateBuilder(args);

// Try loading environment variables from a .env file in development/local scenarios
try { Env.TraversePath().Load(); } catch { /* ignore if .env not present */ }
// Add services to the container.
builder.Services.AddTransient<IProductService, ProductService>();
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IColorService, ColorService>();
builder.Services.AddTransient<ISizeService, SizeService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();
builder.Services.AddTransient<ICountryService, CountryService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<IBlobStorageService, BlobStorageService>();
builder.Services.AddTransient<INewsService, NewsService>();
builder.Services.AddTransient<ICommentService, CommentService>();
builder.Services.AddTransient<IStadiumSectorService, StadiumSectorService>();
builder.Services.AddTransient<IStadiumSideService, StadiumSideService>();
builder.Services.AddTransient<IClubService, ClubService>();
builder.Services.AddTransient<IPlayerInterface, PlayerService>();
builder.Services.AddTransient<ICartService, CartService>();
builder.Services.AddTransient<IMatchService, MatchService>();
builder.Services.AddTransient<IMembershipCardService, MembershipCardService>();
builder.Services.AddTransient<IUserMembershipService, UserMembershipService>();
builder.Services.AddTransient<IPaymentService, PaymentService>();
builder.Services.AddTransient<IOrderService, OrderService>();
builder.Services.AddTransient<IAdminDashboardService, AdminDashboardService>();
builder.Services.AddTransient<IRabbitMQService, RabbitMQService>();
builder.Services.AddTransient<IPositionService, PositionService>();
builder.Services.AddTransient<IRecommendationService, RecommendationService>();

builder.Services.AddTransient<BaseOrderState>();
builder.Services.AddTransient<InitialOrderState>();
builder.Services.AddTransient<ProcessingOrderState>();
builder.Services.AddTransient<ConfirmedOrderState>();
builder.Services.AddTransient<CancelledOrderState>();
builder.Services.AddTransient<DeliveryOrderState>();
builder.Services.AddTransient<FinishedOrderState>();

// Add HttpContextAccessor
builder.Services.AddHttpContextAccessor();

builder.Services.AddMapster();


// Add database services
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=MyClubDb;Trusted_Connection=True;TrustServerCertificate=True";
builder.Services.AddMyClubDbContext(connectionString);

// Configure JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["JwtConfig:Issuer"],
        ValidAudience = builder.Configuration["JwtConfig:Audience"],
    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["JwtConfig:Key"] ?? string.Empty)),
        ClockSkew = TimeSpan.Zero
    };
    
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            // Try to extract the token from the Authorization header
            var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();
            if (authHeader != null)
            {
                // If the header contains "Bearer", extract the token part
                if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                {
                    context.Token = authHeader.Substring("Bearer ".Length).Trim();
                }
                // If it doesn't start with "Bearer", assume the entire value is the token
                else
                {
                    context.Token = authHeader.Trim();
                }
            }
            
            return Task.CompletedTask;
        }
    };
});

// Add Authorization policies
builder.Services.AddAuthorization(options =>
{
    // Add policy for admin role
    options.AddPolicy("AdminOnly", policy => 
        policy.RequireClaim(ClaimTypes.Role, "Administrator"));
    
    // Add policy for user role
    options.AddPolicy("UserOnly", policy => 
        policy.RequireClaim(ClaimTypes.Role, "User"));
});

builder.Services.AddControllers(options =>
{
    options.Filters.Add<ErrorFilter>();
});
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MyClub API", Version = "v1" });
    
    // Define JWT security scheme
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Ensure database creation with simple retry (useful when SQL starts slower in Docker)
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<MyClubContext>();
    const int maxAttempts = 10;
    var delay = TimeSpan.FromSeconds(2);
    for (var attempt = 1; attempt <= maxAttempts; attempt++)
    {
        try
        {
            context.Database.EnsureCreated();
            break;
        }
        catch
        {
            if (attempt == maxAttempts) throw;
            await Task.Delay(delay);
        }
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();


// Add authentication middleware before authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
