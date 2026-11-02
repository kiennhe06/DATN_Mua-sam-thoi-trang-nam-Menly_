import { createClient } from '@supabase/supabase-js';
const url = 'https://lqxtanwymtfdbfktxsts.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxeHRhbnd5bXRmZGJma3R4c3RzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzQ0OTI0NiwiZXhwIjoyMTA5MDI1MjQ2fQ.JYirGh1qd3sKjolQ-W-3jPNTlp8VYWDFeaCpZMMCEGw';
const supabase = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
const payload = { email: 'newuser2026test@gmail.com', password: '123456', options: { data: { full_name: 'Nguyen Quoc Anh', phone: '0972302183', role: 'customer' } } };
const res = await supabase.auth.signUp(payload);
console.log(JSON.stringify(res, null, 2));
