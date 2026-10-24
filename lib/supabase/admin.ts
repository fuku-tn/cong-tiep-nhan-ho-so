import "server-only";
import { createClient } from "@supabase/supabase-js";

// Dùng secret key, bỏ qua RLS — chỉ gọi ở phía server (route handler, server action).
export function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SECRET_KEY!,
    { auth: { persistSession: false } },
  );
}
