-- Chạy trong Supabase → SQL Editor (database đã chạy schema.sql bản đầu).
-- Bổ sung email, quốc gia, bậc học cho yêu cầu báo giá và khoá truy cập từ trình duyệt.

create type degree_level as enum ('thpt', 'dai_hoc', 'thac_si');

alter table admission_requests
  add column customer_email text,
  add column country        text,
  add column degree_level   degree_level;

-- Điền dữ liệu cho 5 dòng mẫu cũ rồi mới đặt not null.
update admission_requests set
  customer_email = case customer_name
    when 'Trần Thị Bích'  then 'bich.tran@example.com'
    when 'Đỗ Ngọc Lan'    then 'lan.do@example.com'
    when 'Lê Văn Hùng'    then 'hung.le@example.com'
    when 'Phạm Thu Hà'    then 'ha.pham@example.com'
    when 'Nguyễn Đức Anh' then 'anh.nguyen@example.com'
    else 'unknown@example.com' end,
  country = case customer_name
    when 'Trần Thị Bích'  then 'Úc'
    when 'Đỗ Ngọc Lan'    then 'Canada'
    when 'Lê Văn Hùng'    then 'Mỹ'
    when 'Phạm Thu Hà'    then 'Anh'
    when 'Nguyễn Đức Anh' then 'Hàn Quốc'
    else 'Mỹ' end,
  degree_level = 'dai_hoc';

alter table admission_requests
  alter column customer_email set not null,
  alter column country        set not null,
  alter column degree_level   set not null;

-- Dữ liệu khách hàng: trình duyệt (anon/authenticated) không được đọc hay ghi.
-- Mọi truy cập đi qua server bằng secret key (lib/supabase/admin.ts).
drop policy "Khách gửi yêu cầu báo giá" on admission_requests;
revoke all on admission_requests from anon, authenticated;
-- RLS vẫn bật và không có policy nào: chặn thêm một lớp nữa.
