# bar-rota-system

A web-based shift management system for the Student Union bar — availability submission, rota building, fairness tracking, and shift swapping.

---

## Tech stack

- **Frontend** — plain HTML, CSS, JavaScript (no build step)
- **Backend** — [Supabase](https://supabase.com) (Postgres + Auth + Row Level Security)
- **Hosting** — Netlify (free tier)

---

## Local setup (Windows)

### 1. Clone the repo

```bash
git clone https://github.com/tianaokane/bar-rota-system.git
cd bar-rota-system
```

### 2. Create your env file

Copy the example and fill in your Supabase keys:

```bash
copy env.example.js env.js
```

Then open `env.js` and replace the placeholder values with your real keys from **Supabase → Settings → API**:

```js
window.ENV_SUPABASE_URL      = 'https://xxxx.supabase.co'
window.ENV_SUPABASE_ANON_KEY = 'your-anon-key'
```

> `env.js` is in `.gitignore` — it will never be committed.

### 3. Run the database schema

1. Go to your [Supabase project](https://supabase.com)
2. Open **Database → SQL Editor**
3. Paste the contents of `supabase/migrations/0001_initial_schema.sql`
4. Click **Run**

### 4. Serve locally

No build step needed. Use any static file server. The easiest on Windows:

```bash
npx serve .
```

Then open [http://localhost:3000](http://localhost:3000)

---

## Project structure

```
bar-rota-system/
├── supabase/
│   └── migrations/
│       └── 0001_initial_schema.sql   # Full DB schema — run once in Supabase
├── src/
│   ├── lib/
│   │   └── supabase.js               # Supabase client + auth helpers
│   ├── components/                   # Reusable HTML/JS UI components
│   └── pages/                        # Page-specific JS logic
├── public/                           # Static assets (CSS, images)
├── env.example.js                    # Copy to env.js and fill in your keys
├── .gitignore
└── README.md
```

---

## Roles

| Role | Areas covered |
|---|---|
| `bar` | Main bar, Wee Bar, Mandela, barista morning |
| `kp` | Kitchen |

---

## Shift types

| Shift | Type | Times |
|---|---|---|
| Main bar | Regular | Varies |
| Barista morning | Regular | 09:00–13:00 |
| Wee Bar | Ad hoc | Varies |
| Mandela concert | Ad hoc | Varies |
| KP shift | Regular | Varies |

---

## User roles

| Role | Access |
|---|---|
| `staff` | Submit availability, view own rota, swap requests |
| `manager` | Everything above + build/publish rota, manage ad hoc shifts |
| `admin` | Full access |

---

## Development roadmap

### v1
- [x] Database schema
- [ ] Auth (login / logout)
- [ ] Staff: availability submission
- [ ] Staff: my shifts view
- [ ] Staff: swap requests
- [ ] Manager: rota builder
- [ ] Manager: publish rota
- [ ] Manager: ad hoc shift posting
- [ ] In-app notifications

### v2
- [ ] Drag-and-drop rota grid
- [ ] Email notifications
- [ ] Fairness dashboard
- [ ] Export rota to PDF