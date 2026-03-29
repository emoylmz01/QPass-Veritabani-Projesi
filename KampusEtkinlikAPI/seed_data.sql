-- =====================================================================
-- Q-Pass (KampusEtkinlikDB) - Suni Veri Oluşturma Script'i
-- ~5000+ eşsiz kayıt: Kulüpler, Kullanıcılar, Etkinlikler, Katılımlar, Sertifikalar
-- =====================================================================

USE KampusEtkinlikDB;
GO

-- Mevcut verileri temizle (sıra: FK bağımlılıkları nedeniyle)
DELETE FROM Sertifika;
DELETE FROM Katilim_Kaydi;
DELETE FROM Etkinlik;
DELETE FROM Kullanici;
DELETE FROM Kulup;
GO

-- IDENTITY sıfırla
DBCC CHECKIDENT ('Kulup', RESEED, 0);
DBCC CHECKIDENT ('Kullanici', RESEED, 0);
DBCC CHECKIDENT ('Etkinlik', RESEED, 0);
DBCC CHECKIDENT ('Katilim_Kaydi', RESEED, 0);
DBCC CHECKIDENT ('Sertifika', RESEED, 0);
GO

-- =====================================================================
-- 1. KULÜPLER (~20 adet)
-- =====================================================================
INSERT INTO Kulup (KulupAdi, IletisimEmail, OrtalamaPuan) VALUES
(N'Bilişim Kulübü', 'bilisim@kampus.edu.tr', 4.50),
(N'Yapay Zeka ve Veri Bilimi Topluluğu', 'aiveri@kampus.edu.tr', 4.70),
(N'Siber Güvenlik Kulübü', 'siber@kampus.edu.tr', 4.60),
(N'Robotik ve Otomasyon Kulübü', 'robotik@kampus.edu.tr', 4.30),
(N'Yazılım Mühendisleri Topluluğu', 'yazilim@kampus.edu.tr', 4.80),
(N'Elektrik-Elektronik Kulübü', 'elektrik@kampus.edu.tr', 4.20),
(N'Girişimcilik Kulübü', 'girisimcilik@kampus.edu.tr', 4.40),
(N'Tasarım ve UX Kulübü', 'tasarim@kampus.edu.tr', 4.10),
(N'Fotoğrafçılık Kulübü', 'foto@kampus.edu.tr', 3.90),
(N'Münazara Kulübü', 'munazara@kampus.edu.tr', 4.00),
(N'Çevre ve Doğa Kulübü', 'cevre@kampus.edu.tr', 3.80),
(N'Spor Kulübü', 'spor@kampus.edu.tr', 4.50),
(N'Müzik Kulübü', 'muzik@kampus.edu.tr', 4.00),
(N'Tiyatro Kulübü', 'tiyatro@kampus.edu.tr', 3.70),
(N'Gönüllülük ve Sosyal Sorumluluk', 'gonulluluk@kampus.edu.tr', 4.60),
(N'Havacılık ve Uzay Kulübü', 'havacilik@kampus.edu.tr', 4.90),
(N'Oyun Geliştirme Kulübü', 'oyun@kampus.edu.tr', 4.30),
(N'Makine Mühendisleri Topluluğu', 'makine@kampus.edu.tr', 4.10),
(N'İnşaat Mühendisleri Topluluğu', 'insaat@kampus.edu.tr', 3.90),
(N'Uluslararası İlişkiler Kulübü', 'uluslararasi@kampus.edu.tr', 4.20);
GO

-- =====================================================================
-- 2. KULLANICILAR (~520 adet: 500 öğrenci + 20 organizatör)
-- =====================================================================

-- Türkçe ad/soyad havuzları
DECLARE @Adlar TABLE (Ad NVARCHAR(50));
INSERT INTO @Adlar VALUES
(N'Ahmet'),(N'Mehmet'),(N'Mustafa'),(N'Ali'),(N'Hasan'),
(N'Hüseyin'),(N'İbrahim'),(N'Emre'),(N'Burak'),(N'Cem'),
(N'Deniz'),(N'Ege'),(N'Furkan'),(N'Gökhan'),(N'Halil'),
(N'Kadir'),(N'Kerem'),(N'Mert'),(N'Oğuz'),(N'Onur'),
(N'Serkan'),(N'Taha'),(N'Uğur'),(N'Volkan'),(N'Yusuf'),
(N'Ayşe'),(N'Fatma'),(N'Zeynep'),(N'Elif'),(N'Merve'),
(N'Esra'),(N'Büşra'),(N'Seda'),(N'Gül'),(N'Derya'),
(N'İrem'),(N'Nur'),(N'Ceren'),(N'Pınar'),(N'Tuğba'),
(N'Beren'),(N'Defne'),(N'Ece'),(N'Gamze'),(N'Hande'),
(N'Lale'),(N'Nisa'),(N'Selin'),(N'Yaren'),(N'Zehra');

DECLARE @Soyadlar TABLE (Soyad NVARCHAR(50));
INSERT INTO @Soyadlar VALUES
(N'Yılmaz'),(N'Kaya'),(N'Demir'),(N'Çelik'),(N'Şahin'),
(N'Yıldız'),(N'Yıldırım'),(N'Öztürk'),(N'Aydın'),(N'Özdemir'),
(N'Arslan'),(N'Doğan'),(N'Kılıç'),(N'Aslan'),(N'Çetin'),
(N'Koç'),(N'Kurt'),(N'Özkan'),(N'Şimşek'),(N'Polat'),
(N'Korkmaz'),(N'Güneş'),(N'Erdoğan'),(N'Tekin'),(N'Acar'),
(N'Aktaş'),(N'Bayrak'),(N'Coşkun'),(N'Durmaz'),(N'Eroğlu'),
(N'Güler'),(N'İnan'),(N'Karaca'),(N'Mutlu'),(N'Sarı'),
(N'Taş'),(N'Uçar'),(N'Yavuz'),(N'Zengin'),(N'Bozkurt');

-- Öğrenciler ekle (~500)
DECLARE @i INT = 1;
DECLARE @adSayisi INT = 50;
DECLARE @soyadSayisi INT = 40;
DECLARE @ad NVARCHAR(50), @soyad NVARCHAR(50);

WHILE @i <= 500
BEGIN
    -- Index-bazlı ad/soyad seçimi (farklı kombinasyonlar)
    SELECT @ad = Ad FROM (SELECT Ad, ROW_NUMBER() OVER (ORDER BY Ad) AS RN FROM @Adlar) A WHERE RN = ((@i - 1) % @adSayisi) + 1;
    SELECT @soyad = Soyad FROM (SELECT Soyad, ROW_NUMBER() OVER (ORDER BY Soyad) AS RN FROM @Soyadlar) S WHERE RN = ((@i - 1) / @adSayisi % @soyadSayisi) + 1;

    INSERT INTO Kullanici (Ad, Soyad, Email, Sifre, Rol, GuvenilirlikPuani, OyunlastirmaPuani)
    VALUES (
        @ad,
        @soyad,
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            @ad + '.' + @soyad,
            N'ı',N'i'),N'ö',N'o'),N'ü',N'u'),N'ş',N's'),N'ç',N'c'),N'ğ',N'g'),
            N'İ',N'I'),N'Ö',N'O'),N'Ü',N'U'),N'Ş',N'S'),N'Ç',N'C'),N'Ğ',N'G'),
            N' ',N''))
            + CAST(@i AS VARCHAR(10)) + '@ogrenci.edu.tr',
        'sifre' + CAST(@i AS VARCHAR(10)),
        'Ogrenci',
        50 + ABS(CHECKSUM(NEWID())) % 51,  -- 50-100 arası
        ABS(CHECKSUM(NEWID())) % 500         -- 0-499 arası
    );

    SET @i = @i + 1;
END

-- Organizatörler ekle (~20)
DECLARE @orgAdlar TABLE (Id INT IDENTITY, Ad NVARCHAR(50), Soyad NVARCHAR(50));
INSERT INTO @orgAdlar VALUES
(N'Barış', N'Özkan'),
(N'Serhat', N'Yılmaz'),
(N'Damla', N'Kara'),
(N'Tolga', N'Arslan'),
(N'Elif', N'Demir'),
(N'Kaan', N'Çelik'),
(N'Sude', N'Aydın'),
(N'Berk', N'Koç'),
(N'Aslı', N'Kurt'),
(N'Arda', N'Polat'),
(N'Merih', N'Tekin'),
(N'Cansu', N'Güler'),
(N'Ozan', N'Yavuz'),
(N'İpek', N'Sarı'),
(N'Alper', N'Taş'),
(N'Gizem', N'Güneş'),
(N'Berke', N'Doğan'),
(N'Mine', N'Aktaş'),
(N'Taylan', N'Korkmaz'),
(N'Sena', N'Erdoğan');

INSERT INTO Kullanici (Ad, Soyad, Email, Sifre, Rol, GuvenilirlikPuani, OyunlastirmaPuani)
SELECT
    o.Ad,
    o.Soyad,
    LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        o.Ad + '.' + o.Soyad,
        N'ı',N'i'),N'ö',N'o'),N'ü',N'u'),N'ş',N's'),N'ç',N'c'),N'ğ',N'g'),
        N'İ',N'I'),N'Ö',N'O'),N'Ü',N'U'),N'Ş',N'S'),N'Ç',N'C'),N'Ğ',N'G'),
        N' ',N''))
        + '@organizator.edu.tr',
    'org' + CAST(o.Id AS VARCHAR(10)),
    'Organizator',
    100,
    0
FROM @orgAdlar o;
GO

-- =====================================================================
-- 3. ETKİNLİKLER (~100 adet, farklı kulüplere dağıtılmış)
-- =====================================================================
DECLARE @KonumListesi TABLE (Id INT IDENTITY, Konum NVARCHAR(100));
INSERT INTO @KonumListesi VALUES
(N'Mühendislik Fakültesi A-101'),
(N'Mühendislik Fakültesi B-203'),
(N'Fen Fakültesi Anfisi'),
(N'Kütüphane Konferans Salonu'),
(N'Rektörlük Konferans Salonu'),
(N'Merkez Yemekhane Salonu'),
(N'Bilgisayar Lab-1'),
(N'Bilgisayar Lab-2'),
(N'Spor Salonu'),
(N'Açık Hava Amfisi'),
(N'İşletme Fakültesi Z-10'),
(N'Teknoloji Merkezi'),
(N'İnovasyon Merkezi'),
(N'Kampüs Bahçesi'),
(N'Sanat Galerisi'),
(N'Medya Lab'),
(N'Hukuk Fakültesi Salonu'),
(N'Eğitim Fakültesi Amfi'),
(N'Mimarlık Fakültesi Sergi Salonu'),
(N'Kongre Merkezi');

DECLARE @EtkinlikAdlari TABLE (Id INT IDENTITY, EtkinlikAdi NVARCHAR(150));
INSERT INTO @EtkinlikAdlari VALUES
(N'Yapay Zeka ve Geleceğimiz Paneli'),
(N'Siber Güvenlik Zirvesi 2026'),
(N'Web Geliştirme Workshop'),
(N'Flutter ile Mobil Uygulama Geliştirme'),
(N'Python ile Veri Analizi'),
(N'Robotik Kodlama Atölyesi'),
(N'Girişimcilik Hikâyeleri'),
(N'Startup Pitch Gecesi'),
(N'UI/UX Tasarım Maratonu'),
(N'Hackathon: Sürdürülebilir Teknoloji'),
(N'Blockchain ve Kripto Semineri'),
(N'IoT ile Akıllı Ev Projesi'),
(N'Bulut Bilişim 101'),
(N'DevOps ve CI/CD Pipeline'),
(N'Linux Sistem Yönetimi'),
(N'Veritabanı Optimizasyon Teknikleri'),
(N'C# ile Oyun Geliştirme'),
(N'Unity 3D Workshop'),
(N'Fotoğraf Teknik Eğitimi'),
(N'Dijital Pazarlama Trendleri'),
(N'Kariyer Günleri 2026'),
(N'Mezun Buluşması'),
(N'Münazara Turnuvası'),
(N'Kısa Film Festivali'),
(N'Kampüs Koşusu'),
(N'Yoga ve Meditasyon'),
(N'Gitar Workshop'),
(N'Satranç Turnuvası'),
(N'E-Spor Turnuvası: Valorant'),
(N'E-Spor Turnuvası: League of Legends'),
(N'Çevre Farkındalık Yürüyüşü'),
(N'Gönüllü Kan Bağışı Kampanyası'),
(N'Kitap Okuma Etkinliği'),
(N'Tiyatro: Bir Yaz Gecesi Rüyası'),
(N'Konser: Kampüs Müzik Festivali'),
(N'Arduino ile Proje Geliştirme'),
(N'3D Yazıcı Atölyesi'),
(N'Drone Yarışması'),
(N'Makine Öğrenmesi Bootcamp'),
(N'React.js ile Frontend Geliştirme'),
(N'Node.js Backend Workshop'),
(N'API Tasarımı ve REST'),
(N'Mobil Oyun Geliştirme Jam'),
(N'Sosyal Medya Yönetimi'),
(N'Grafik Tasarım Temelleri'),
(N'Proje Yönetimi ve Scrum'),
(N'Patent ve Fikri Mülkiyet'),
(N'TÜBİTAK Proje Yazımı'),
(N'Erasmus Bilgilendirme'),
(N'Staj ve İş Fırsatları Paneli'),
(N'Network Güvenliği Lab'),
(N'Etik Hacking Eğitimi'),
(N'Veri Görselleştirme Workshop'),
(N'NLP ile Chatbot Geliştirme'),
(N'Kubernetes ve Docker Eğitimi'),
(N'Mikroservis Mimarisi'),
(N'AWS Cloud Practitioner Hazırlık'),
(N'Azure Fundamentals Workshop'),
(N'Google Cloud Eğitimi'),
(N'Embedded Systems Workshop'),
(N'FPGA ile Dijital Tasarım'),
(N'Mobil Güvenlik Semineri'),
(N'Tersine Mühendislik 101'),
(N'CTF Yarışması'),
(N'Kadınlar için Kodlama'),
(N'Açık Kaynak Katkı Günü'),
(N'Git ve GitHub Eğitimi'),
(N'Agile Metodolojileri'),
(N'İngilizce Konuşma Kulübü'),
(N'Japonca Başlangıç Kursu'),
(N'Almanca Tanışma Etkinliği'),
(N'Matematik Olimpiyat Hazırlık'),
(N'Fizik Deneyleri Gösterisi'),
(N'Kimya Lab Deneyimleri'),
(N'Astronomi Gece Gözlemi'),
(N'Biyoteknoloji Semineri'),
(N'Nanoteknoloji ve Gelecek'),
(N'Yapay Sinir Ağları Eğitimi'),
(N'GAN ile Görüntü Üretimi'),
(N'Bilgisayarlı Görü Workshop'),
(N'Doğal Dil İşleme Atölyesi'),
(N'Derin Öğrenme ile Sınıflandırma'),
(N'Reinforcement Learning Semineri'),
(N'MLOps ve Model Deployment'),
(N'Veri Bilimi Case Study'),
(N'Büyük Veri Analizi ve Spark'),
(N'SQL İleri Seviye Eğitimi'),
(N'NoSQL ve MongoDB Workshop'),
(N'Redis ve Caching Stratejileri'),
(N'Dağıtık Sistemler Semineri'),
(N'Akıllı Şehirler ve IoT'),
(N'Yenilenebilir Enerji Paneli'),
(N'Elektrikli Araçlar Semineri'),
(N'Mars Kolonizasyonu Paneli'),
(N'Uzay Teknolojileri Konferansı'),
(N'Havacılık Kariyer Günü'),
(N'Oyun Tasarımı Temelleri'),
(N'Pixel Art Workshop'),
(N'Dijital Müzik Prodüksiyon'),
(N'Podcast Nasıl Yapılır?'),
(N'Yazarlık Atölyesi');

-- Etkinlikleri ekle
DECLARE @e INT = 1;
DECLARE @kulupSayisi INT = 20;
DECLARE @konumSayisi INT = 20;
DECLARE @toplamEtkinlik INT = 100;

WHILE @e <= @toplamEtkinlik
BEGIN
    INSERT INTO Etkinlik (KulupID, EtkinlikAdi, TarihSaat, Konum, Kontenjan, YedekKontenjan, PuanDegeri, Aciklama, SertifikaliMi, AktifMi)
    SELECT
        ((@e - 1) % @kulupSayisi) + 1,  -- Kulüp ID dağılımı
        ea.EtkinlikAdi,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()),  -- Son 6 ay
        k.Konum,
        50 + ABS(CHECKSUM(NEWID())) % 151,  -- 50-200 kontenjan
        5 + ABS(CHECKSUM(NEWID())) % 16,     -- 5-20 yedek
        5 + ABS(CHECKSUM(NEWID())) % 16,     -- 5-20 puan
        N'Bu etkinlik ' + ea.EtkinlikAdi + N' hakkında detaylı bilgi içerir.',
        CASE WHEN ABS(CHECKSUM(NEWID())) % 5 = 0 THEN 0 ELSE 1 END,  -- %80 sertifikalı
        CASE WHEN @e <= 15 THEN 1 ELSE 0 END  -- İlk 15 aktif, geri kalan bitmiş
    FROM (SELECT EtkinlikAdi FROM @EtkinlikAdlari WHERE Id = @e) ea
    CROSS JOIN (SELECT Konum FROM @KonumListesi WHERE Id = ((@e - 1) % @konumSayisi) + 1) k;

    SET @e = @e + 1;
END
GO

-- =====================================================================
-- 4. KATILIM KAYITLARI (~3000 adet, unique KullaniciID-EtkinlikID)
-- =====================================================================
-- Her etkinliğe rastgele 20-40 öğrenci kaydet
DECLARE @etkinlikId INT = 1;
DECLARE @maxEtkinlik INT = 100;

WHILE @etkinlikId <= @maxEtkinlik
BEGIN
    -- Bu etkinliğe kaç kişi katılacak (20-40 arası)
    DECLARE @katilimciSayisi INT = 20 + ABS(CHECKSUM(NEWID())) % 21;

    INSERT INTO Katilim_Kaydi (KullaniciID, EtkinlikID, Durum, KayitZamani)
    SELECT TOP (@katilimciSayisi)
        KullaniciId,
        @etkinlikId,
        CASE
            WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Kayitli'
            ELSE 'Katildi'
        END,
        DATEADD(HOUR, -ABS(CHECKSUM(NEWID())) % 720, GETDATE())
    FROM Kullanici
    WHERE Rol = 'Ogrenci'
    ORDER BY NEWID();  -- rastgele seçim

    SET @etkinlikId = @etkinlikId + 1;
END
GO

-- =====================================================================
-- 5. SERTİFİKALAR (~durumu 'Katildi' olan kayıtlar için)
-- =====================================================================
INSERT INTO Sertifika (KayitID, SertifikaKodu, UretimTarihi)
SELECT
    kk.KayitID,
    UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 8)),
    DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 60, kk.KayitZamani)
FROM Katilim_Kaydi kk
INNER JOIN Etkinlik e ON kk.EtkinlikID = e.EtkinlikID
WHERE kk.Durum = 'Katildi'
  AND e.SertifikaliMi = 1
  AND NOT EXISTS (SELECT 1 FROM Sertifika s WHERE s.KayitID = kk.KayitID);
GO

-- =====================================================================
-- İSTATİSTİKLER
-- =====================================================================
PRINT '=== VERİ OLUŞTURMA TAMAMLANDI ==='
SELECT 'Kulüpler' AS Tablo, COUNT(*) AS Kayit FROM Kulup
UNION ALL SELECT 'Kullanıcılar', COUNT(*) FROM Kullanici
UNION ALL SELECT 'Etkinlikler', COUNT(*) FROM Etkinlik
UNION ALL SELECT 'Katılım Kayıtları', COUNT(*) FROM Katilim_Kaydi
UNION ALL SELECT 'Sertifikalar', COUNT(*) FROM Sertifika;
GO
