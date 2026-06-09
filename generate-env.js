// generate-env.js
// Runs at Netlify build time to create env.js from environment variables
// Never committed — generated fresh each deploy

const fs = require('fs')

const url  = process.env.SUPABASE_URL
const anon = process.env.SUPABASE_ANON_KEY

if (!url || !anon) {
  console.error('ERROR: SUPABASE_URL and SUPABASE_ANON_KEY must be set in Netlify environment variables')
  process.exit(1)
}

const content = `// Auto-generated at build time — do not edit
window.ENV_SUPABASE_URL      = '${url}'
window.ENV_SUPABASE_ANON_KEY = '${anon}'
`

fs.writeFileSync('env.js', content)
console.log('✓ env.js generated successfully')