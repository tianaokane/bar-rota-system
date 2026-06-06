import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm'

const SUPABASE_URL  = window.ENV_SUPABASE_URL
const SUPABASE_ANON = window.ENV_SUPABASE_ANON_KEY

if (!SUPABASE_URL || !SUPABASE_ANON) {
  throw new Error('Supabase env vars missing — check your env.js file')
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON)

// ── Auth helpers ──────────────────────────────────────────────

export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

export async function getUser() {
  const session = await getSession()
  if (!session) return null

  const { data, error } = await supabase
    .from('users')
    .select('*, user_roles(*, roles(*))')
    .eq('id', session.user.id)
    .single()

  if (error) { console.error('getUser error', error); return null }
  return data
}

export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  return { data, error }
}

export async function signOut() {
  await supabase.auth.signOut()
  window.location.href = '/login.html'
}

// ── Role helpers ──────────────────────────────────────────────

export function isManager(user) {
  return user?.role === 'manager' || user?.role === 'admin'
}

export function hasRole(user, roleName) {
  return user?.user_roles?.some(ur => ur.roles?.name === roleName) ?? false
}

// ── Guard: redirect to login if not authenticated ─────────────

export async function requireAuth() {
  const session = await getSession()
  if (!session) {
    window.location.href = '/login.html'
    return null
  }
  return getUser()
}

// ── Guard: redirect to index if not manager ───────────────────

export async function requireManager() {
  const user = await requireAuth()
  if (user && !isManager(user)) {
    window.location.href = '/index.html'
    return null
  }
  return user
}