"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { countries } from "@/lib/mock-data";

const degreeLevels = ["thpt", "dai_hoc", "thac_si"] as const;
const packages = ["co_ban", "toan_dien"] as const;

export type CreateRequestResult =
  | { ok: true; quote: number }
  | { ok: false; error: string };

// Giá lấy từ bảng service_packages trên server, không tin giá do trình duyệt gửi lên.
export async function createRequest(input: {
  customerName: string;
  email: string;
  country: string;
  degreeLevel: string;
  package: string;
}): Promise<CreateRequestResult> {
  const customerName = input.customerName?.trim();
  const email = input.email?.trim();

  if (!customerName || customerName.length > 120) {
    return { ok: false, error: "Vui lòng nhập họ tên hợp lệ." };
  }
  if (!email || email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { ok: false, error: "Email không hợp lệ." };
  }
  if (!(countries as readonly string[]).includes(input.country)) {
    return { ok: false, error: "Vui lòng chọn quốc gia." };
  }
  if (!(degreeLevels as readonly string[]).includes(input.degreeLevel)) {
    return { ok: false, error: "Bậc học không hợp lệ." };
  }
  if (!(packages as readonly string[]).includes(input.package)) {
    return { ok: false, error: "Gói dịch vụ không hợp lệ." };
  }

  const supabase = createAdminClient();

  const { data: pkg, error: pkgError } = await supabase
    .from("service_packages")
    .select("price")
    .eq("id", input.package)
    .single();
  if (pkgError || !pkg) {
    return { ok: false, error: "Không lấy được giá gói dịch vụ." };
  }

  const quote = Number(pkg.price);
  const { error } = await supabase.from("admission_requests").insert({
    customer_name: customerName,
    customer_email: email,
    country: input.country,
    degree_level: input.degreeLevel,
    package: input.package,
    quote,
    status: "cho_duyet",
  });
  if (error) {
    return { ok: false, error: "Không gửi được yêu cầu, vui lòng thử lại." };
  }

  return { ok: true, quote };
}
