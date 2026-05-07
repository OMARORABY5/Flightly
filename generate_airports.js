const fs = require('fs');
const https = require('https');

const URL = 'https://raw.githubusercontent.com/davidmegginson/ourairports-data/main/airports.csv';
const ARAB_COUNTRIES = ['AE','BH','DZ','EG','IQ','JO','KW','LB','LY','MA','MR','OM','PS','QA','SA','SD','SY','TN','YE','SO','DJ','KM'];

// List of some specific top 100 global IATA codes to explicitly include to guarantee popular ones
const TOP_GLOBAL_IATA = new Set([
  'ATL','PEK','LAX','DXB','HND','ORD','LHR','PVG','CDG','DFW','CAN','AMS','HKG','ICN','FRA',
  'DEN','DEL','SIN','BKK','JFK','KUL','MAD','SFO','CTU','CGK','BCN','IST','SEA','LAS','MCO',
  'YYZ','MEX','CLT','SVO','TPE','MUC','BOM','EWR','MNL','PHX','MIA','SYD','BOS','JNB','GRU',
  'FCO','CUN','NRT','LGW','SZX','BNE','BWI','MEL','YVR','ZRH','CPH','OSL','DME','DUB','VIE',
  'HEL','ARN','ATH','LIS','GVA','BRU','WAW','PRG','BUD','OTP','KBP','DOH','AUH','MCT','RUH',
  'JED','AMM','BEY','CAI','CMN','ALG','TUN','KRT','SJU','BOG','LIM','SCL','EZE','GIG','CPT',
  'LOS','NBO','ADD','AKL','HNL','ANC','GUM','PPT','NAN','POM','VTE','PNH','RGN','KTM','CMB',
  'DAC','KHI','LHE','ISB','KBL','TAS','ALA','GYD','TBS','EVN'
]);

https.get(URL, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const lines = data.split('\n');
    const headers = lines[0].replace(/"/g, '').split(',');
    
    // Create an array of airport objects
    let airports = [];
    for (let i = 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;
      // Handle commas inside quotes
      const row = lines[i].split(/,(?=(?:(?:[^"]*"){2})*[^"]*$)/).map(v => v.replace(/^"|"$/g, '').replace(/""/g, '"'));
      
      const type = row[2];
      const name = row[3];
      const lat = row[4];
      const lon = row[5];
      const iso_country = row[8];
      const city = row[10];
      const scheduled = row[11];
      const icao_code = row[12]; // gps_code
      const iata_code = row[13];
      
      // We only want airports with an IATA code and scheduled service
      if (!iata_code || iata_code === '0' || iata_code === '-' || scheduled !== 'yes') continue;
      if (!icao_code) continue;
      
      airports.push({ iata_code, icao_code, name, city: city || name, country_code: iso_country, lat, lon });
    }

    // Filter logic
    let selectedAirports = new Map();

    const regionNames = new Intl.DisplayNames(['en'], { type: 'region' });

    for (const apt of airports) {
      if (ARAB_COUNTRIES.includes(apt.country_code) || TOP_GLOBAL_IATA.has(apt.iata_code)) {
        try {
          apt.country = regionNames.of(apt.country_code) || apt.country_code;
        } catch (e) {
          apt.country = apt.country_code;
        }
        selectedAirports.set(apt.iata_code, apt);
      }
    }

    // Generate SQL
    let sql = `-- FLIGHTLY — Airport Data Seeder\n`;
    sql += `-- File: 002_seed_airports.sql\n`;
    sql += `-- Injects ${selectedAirports.size} global & Arabic airports for the Flight Search Autocomplete feature.\n\n`;
    sql += `INSERT INTO airports (iata_code, icao_code, name, city, country, country_code, latitude, longitude, timezone, is_active)\nVALUES\n`;
    
    let values = [];
    for (const [iata, apt] of selectedAirports.entries()) {
      const nameEscaped = apt.name.replace(/'/g, "''");
      const cityEscaped = apt.city.replace(/'/g, "''");
      const countryEscaped = apt.country.replace(/'/g, "''");
      values.push(`('${iata}', '${apt.icao_code}', '${nameEscaped}', '${cityEscaped}', '${countryEscaped}', '${apt.country_code}', ${apt.lat}, ${apt.lon}, 'UTC', true)`);
    }
    
    sql += values.join(',\n') + '\nON CONFLICT (iata_code) DO NOTHING;\n';
    
    fs.writeFileSync('database/migrations/002_seed_airports.sql', sql);
    console.log(`Generated SQL with ${selectedAirports.size} airports!`);
  });
}).on('error', (e) => {
  console.error(e);
});
