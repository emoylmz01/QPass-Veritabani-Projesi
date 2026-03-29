using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace KampusEtkinlikAPI.Models;

public partial class KampusEtkinlikDbContext : DbContext
{
    public KampusEtkinlikDbContext()
    {
    }

    public KampusEtkinlikDbContext(DbContextOptions<KampusEtkinlikDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Etkinlik> Etkinliks { get; set; }

    public virtual DbSet<KatilimKaydi> KatilimKaydis { get; set; }

    public virtual DbSet<Kullanici> Kullanicis { get; set; }

    public virtual DbSet<Kulup> Kulups { get; set; }

    public virtual DbSet<KulupUyesi> KulupUyeleris { get; set; }

    public virtual DbSet<Sertifika> Sertifikas { get; set; }

    public virtual DbSet<VwDetayliKatilimListesi> VwDetayliKatilimListesis { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=.;Database=KampusEtkinlikDB;Trusted_Connection=True;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Etkinlik>(entity =>
        {
            entity.HasKey(e => e.EtkinlikId).HasName("PK__Etkinlik__0299F2AD2F834E82");

            entity.ToTable("Etkinlik");

            entity.Property(e => e.EtkinlikId).HasColumnName("EtkinlikID");
            entity.Property(e => e.EtkinlikAdi).HasMaxLength(150);
            entity.Property(e => e.Konum).HasMaxLength(100);
            entity.Property(e => e.KulupId).HasColumnName("KulupID");
            entity.Property(e => e.PuanDegeri).HasDefaultValue(10);
            entity.Property(e => e.TarihSaat).HasColumnType("datetime");
            entity.Property(e => e.YedekKontenjan).HasDefaultValue(0);

            entity.HasOne(d => d.Kulup).WithMany(p => p.Etkinliks)
                .HasForeignKey(d => d.KulupId)
                .HasConstraintName("FK__Etkinlik__KulupI__534D60F1");
        });

        modelBuilder.Entity<KatilimKaydi>(entity =>
        {
            entity.HasKey(e => e.KayitId).HasName("PK__Katilim___BD28AF6B67AC3A77");

            entity.ToTable("Katilim_Kaydi", tb => tb.HasTrigger("trg_OtomatikSertifikaUret"));

            entity.HasIndex(e => new { e.KullaniciId, e.EtkinlikId }, "UQ_KullaniciEtkinlik").IsUnique();

            entity.Property(e => e.KayitId).HasColumnName("KayitID");
            entity.Property(e => e.Durum)
                .HasMaxLength(20)
                .HasDefaultValue("Kayitli");
            entity.Property(e => e.EtkinlikId).HasColumnName("EtkinlikID");
            entity.Property(e => e.KayitZamani)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.KullaniciId).HasColumnName("KullaniciID");

            entity.HasOne(d => d.Etkinlik).WithMany(p => p.KatilimKaydis)
                .HasForeignKey(d => d.EtkinlikId)
                .HasConstraintName("FK__Katilim_K__Etkin__5AEE82B9");

            entity.HasOne(d => d.Kullanici).WithMany(p => p.KatilimKaydis)
                .HasForeignKey(d => d.KullaniciId)
                .HasConstraintName("FK__Katilim_K__Kulla__59FA5E80");
        });

        modelBuilder.Entity<Kullanici>(entity =>
        {
            entity.HasKey(e => e.KullaniciId).HasName("PK__Kullanic__E011F09B5846743E");

            entity.ToTable("Kullanici");

            entity.HasIndex(e => e.Email, "UQ__Kullanic__A9D105342905A2BA").IsUnique();

            entity.Property(e => e.KullaniciId).HasColumnName("KullaniciID");
            entity.Property(e => e.Ad).HasMaxLength(50);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.GuvenilirlikPuani).HasDefaultValue(100);
            entity.Property(e => e.OyunlastirmaPuani).HasDefaultValue(0);
            entity.Property(e => e.Rol).HasMaxLength(20);
            entity.Property(e => e.Soyad).HasMaxLength(50);
        });

        modelBuilder.Entity<Kulup>(entity =>
        {
            entity.HasKey(e => e.KulupId).HasName("PK__Kulup__20C5DEBE8D8CF12B");

            entity.ToTable("Kulup");

            entity.Property(e => e.KulupId).HasColumnName("KulupID");
            entity.Property(e => e.IletisimEmail).HasMaxLength(100);
            entity.Property(e => e.KulupAdi).HasMaxLength(100);
            entity.Property(e => e.OrtalamaPuan)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(3, 2)");
        });

        modelBuilder.Entity<KulupUyesi>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.ToTable("KulupUyesi");
            entity.HasIndex(e => new { e.KulupId, e.KullaniciId }).IsUnique();
            
            entity.Property(e => e.Durum).HasMaxLength(20).HasDefaultValue("Bekliyor");
            entity.Property(e => e.BasvuruTarihi).HasColumnType("datetime").HasDefaultValueSql("(getdate())");

            entity.HasOne(d => d.Kulup)
                .WithMany()
                .HasForeignKey(d => d.KulupId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(d => d.Kullanici)
                .WithMany()
                .HasForeignKey(d => d.KullaniciId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Sertifika>(entity =>
        {
            entity.HasKey(e => e.SertifikaId).HasName("PK__Sertifik__D58873DBB04D9822");

            entity.ToTable("Sertifika");

            entity.HasIndex(e => e.SertifikaKodu, "UQ__Sertifik__21A9EDD7B310B6CB").IsUnique();

            entity.HasIndex(e => e.KayitId, "UQ__Sertifik__BD28AF6ACB5A99BC").IsUnique();

            entity.Property(e => e.SertifikaId).HasColumnName("SertifikaID");
            entity.Property(e => e.KayitId).HasColumnName("KayitID");
            entity.Property(e => e.SertifikaKodu).HasMaxLength(100);
            entity.Property(e => e.UretimTarihi)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Kayit).WithOne(p => p.Sertifika)
                .HasForeignKey<Sertifika>(d => d.KayitId)
                .HasConstraintName("FK__Sertifika__Kayit__628FA481");
        });

        modelBuilder.Entity<VwDetayliKatilimListesi>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_DetayliKatilimListesi");

            entity.Property(e => e.Durum).HasMaxLength(20);
            entity.Property(e => e.EtkinlikAdi).HasMaxLength(150);
            entity.Property(e => e.KayitZamani).HasColumnType("datetime");
            entity.Property(e => e.OgrenciAdi).HasMaxLength(101);
            entity.Property(e => e.SertifikaKodu).HasMaxLength(100);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
