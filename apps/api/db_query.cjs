const { Pool } = require('pg');
const PUBLIC_URL = 'postgresql://postgres:mJPSPftTaEccyjAEdHAQCGJDHakKVxIP@metro.proxy.rlwy.net:32432/railway';
const p = new Pool({ connectionString: PUBLIC_URL, ssl: { rejectUnauthorized: false } });
p.query(`
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public'
  ORDER BY table_name
`)
  .then(r => { console.log(r.rows.map(x => x.table_name).join('\n')); p.end(); })
  .catch(e => { console.error(e.message); p.end(); });
