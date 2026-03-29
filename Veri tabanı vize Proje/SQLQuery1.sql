-- Kulüpleri Ekleyelim
INSERT INTO Kulup (KulupAdi, IletisimEmail)
VALUES 
('GDG On Campus Kastamonu', 'iletisim@gdgkastamonu.com'),
('Siber Güvenlik Kulübü', 'info@siberkastamonu.com');

-- Kullanýcýlarý (Öðrenci, Organizatör, Admin) Ekleyelim
INSERT INTO Kullanici (Ad, Soyad, Email, Rol)
VALUES 
('Emirhan', 'K.', 'emirhan@email.com', 'Ogrenci'),
('Ahmet', 'Y.', 'ahmet@email.com', 'Ogrenci'),
('Ayþe', 'D.', 'ayse@email.com', 'Organizator'),
('Sistem', 'Admin', 'admin@sistem.com', 'Admin');

-- Etkinlikleri Ekleyelim (KulupID'lere dikkat, yukarýda eklediðimiz 1 ve 2 numaralý kulüpler)
INSERT INTO Etkinlik (KulupID, EtkinlikAdi, TarihSaat, Konum, Kontenjan, PuanDegeri)
VALUES 
(1, 'Clean Code Atölyesi', '2026-03-10 14:00:00', 'Mühendislik Fakültesi', 50, 15),
(2, 'Siber Güvenlik 101', '2026-03-15 10:00:00', 'Konferans Salonu 1', 100, 20);

-- Öðrencileri Etkinliklere Kaydedelim
-- Emirhan ve Ahmet, Clean Code atölyesine (EtkinlikID = 1) kaydoluyor
INSERT INTO Katilim_Kaydi (KullaniciID, EtkinlikID, Durum)
VALUES 
(1, 1, 'Kayitli'),
(2, 1, 'Katildi'); -- Ahmet etkinliðe katýlmýþ ve QR kodunu okutmuþ olsun

-- Ahmet katýldýðý için sistem ona bir sertifika üretsin
INSERT INTO Sertifika (KayitID, SertifikaKodu)
VALUES 
(2, 'CERT-987654321-AHMET');