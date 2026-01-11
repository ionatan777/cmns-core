import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    'https://juooxzbexwkgvofkeare.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1b294emJleHdrZ3ZvZmtlYXJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MDE5MjMsImV4cCI6MjA4Mjk3NzkyM30.lZkDicFqR1UGER031sqci3dE0Tl5qu9rhgqIXNB6910'
  )
}
