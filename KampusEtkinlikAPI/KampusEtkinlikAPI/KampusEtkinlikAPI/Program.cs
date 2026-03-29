using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// === SERVİSLER ===

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Veritabanı bağlantısı
builder.Services.AddDbContext<KampusEtkinlikAPI.Models.KampusEtkinlikDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// CORS — Mobil uygulamanın API'ye erişebilmesi için
builder.Services.AddCors(options =>
{
    options.AddPolicy("MobilUygulama", policy =>
    {
        policy.AllowAnyOrigin()    // Tüm kaynaklara izin ver (mobil dahil)
              .AllowAnyMethod()    // GET, POST, PUT, DELETE hepsine izin ver
              .AllowAnyHeader();   // Tüm header'lara izin ver
    });
});

var app = builder.Build();

// === MIDDLEWARE PIPELINE ===

// Swagger her zaman açık (test kolaylığı için)
app.UseSwagger();
app.UseSwaggerUI();

// CORS politikasını aktifleştir
app.UseCors("MobilUygulama");

// app.UseHttpsRedirection(); // Mobil uygulama HTTP kullandığı için devre dışı
app.UseAuthorization();
app.MapControllers();

app.Run();
