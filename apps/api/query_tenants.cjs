const { Pool } = require('pg');
const p = new Pool({ connectionString: process.env.DATABASE_URL });
p.query(`
  SELECT t.id, t.name, t.slug, bp.whatsapp
  FROM tenants t
  LEFT JOIN business_profiles bp ON bp.tenant_id = t.id
`)
  .then(r => { console.log(JSON.stringify(r.rows, null, 2)); p.end(); })
  .catch(e => { console.error(e.message); p.end(); });
