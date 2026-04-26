-- FLIGHTLY — Airport Data Seeder
-- File: 002_seed_airports.sql
-- Injects popular global airports for the Flight Search Autocomplete feature.

INSERT INTO airports (iata_code, icao_code, name, city, country, country_code, latitude, longitude, timezone, is_active)
VALUES
('DXB', 'OMDB', 'Dubai International Airport', 'Dubai', 'United Arab Emirates', 'AE', 25.2532, 55.3657, 'Asia/Dubai', true),
('JFK', 'KJFK', 'John F. Kennedy International Airport', 'New York', 'United States', 'US', 40.6413, -73.7781, 'America/New_York', true),
('LHR', 'EGLL', 'Heathrow Airport', 'London', 'United Kingdom', 'GB', 51.4700, -0.4543, 'Europe/London', true),
('CDG', 'LFPG', 'Charles de Gaulle Airport', 'Paris', 'France', 'FR', 49.0097, 2.5479, 'Europe/Paris', true),
('HND', 'RJTT', 'Tokyo Haneda Airport', 'Tokyo', 'Japan', 'JP', 35.5494, 139.7798, 'Asia/Tokyo', true),
('LAX', 'KLAX', 'Los Angeles International Airport', 'Los Angeles', 'United States', 'US', 33.9416, -118.4085, 'America/Los_Angeles', true),
('FRA', 'EDDF', 'Frankfurt Airport', 'Frankfurt', 'Germany', 'DE', 50.0379, 8.5622, 'Europe/Berlin', true),
('SIN', 'WSSS', 'Singapore Changi Airport', 'Singapore', 'Singapore', 'SG', 1.3644, 103.9915, 'Asia/Singapore', true),
('AMS', 'EHAM', 'Amsterdam Airport Schiphol', 'Amsterdam', 'Netherlands', 'NL', 52.3105, 4.7683, 'Europe/Amsterdam', true),
('IST', 'LTFM', 'Istanbul Airport', 'Istanbul', 'Turkey', 'TR', 41.2753, 28.7519, 'Europe/Istanbul', true),
('CAI', 'HECA', 'Cairo International Airport', 'Cairo', 'Egypt', 'EG', 30.1219, 31.4056, 'Africa/Cairo', true),
('SYD', 'YSSY', 'Sydney Kingsford Smith Airport', 'Sydney', 'Australia', 'AU', -33.9399, 151.1753, 'Australia/Sydney', true),
('YYZ', 'CYYZ', 'Toronto Pearson International Airport', 'Toronto', 'Canada', 'CA', 43.6777, -79.6248, 'America/Toronto', true),
('MEX', 'MMMX', 'Mexico City International Airport', 'Mexico City', 'Mexico', 'MX', 19.4361, -99.0719, 'America/Mexico_City', true),
('GRU', 'SBGR', 'São Paulo/Guarulhos International Airport', 'São Paulo', 'Brazil', 'BR', -23.4356, -46.4731, 'America/Sao_Paulo', true),
('JNB', 'FAOR', 'O. R. Tambo International Airport', 'Johannesburg', 'South Africa', 'ZA', -26.1367, 28.2411, 'Africa/Johannesburg', true),
('BKK', 'VTBS', 'Suvarnabhumi Airport', 'Bangkok', 'Thailand', 'TH', 13.6900, 100.7501, 'Asia/Bangkok', true),
('HKG', 'VHHH', 'Hong Kong International Airport', 'Hong Kong', 'Hong Kong', 'HK', 22.3080, 113.9185, 'Asia/Hong_Kong', true)
ON CONFLICT (iata_code) DO NOTHING;
