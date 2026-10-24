-- Chạy toàn bộ file này trong Supabase → SQL Editor.
-- Cấu trúc bảng bám theo các kiểu trong lib/mock-data.ts.

-- ───────── Enum (giữ nguyên giá trị snake_case của mock-data) ─────────
create type doc_status as enum ('chua_nop', 'dang_xu_ly', 'hop_le', 'can_nop_lai');
create type request_status as enum ('cho_duyet', 'da_duyet', 'tu_choi');
create type service_package as enum ('co_ban', 'toan_dien');
create type chat_sender as enum ('bot', 'user');
create type degree_level as enum ('thpt', 'dai_hoc', 'thac_si');

-- ───────── Bảng ─────────
create table schools (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  country     text not null,
  min_gpa     numeric(3,1) not null,
  min_ielts   numeric(2,1) not null,
  created_at  timestamptz not null default now()
);

create table service_packages (
  id           service_package primary key,
  name         text not null,
  price        bigint not null,
  description  text not null,
  benefits     text[] not null default '{}'
);

create table admission_requests (
  id             uuid primary key default gen_random_uuid(),
  customer_name  text not null,
  customer_email text not null,
  country        text not null,
  degree_level   degree_level not null,
  package        service_package not null references service_packages(id),
  quote          bigint not null,
  status         request_status not null default 'cho_duyet',
  created_at     timestamptz not null default now()
);

create table student_profiles (
  id                uuid primary key default gen_random_uuid(),
  student_name      text not null,
  email             text not null unique,
  transcript_status doc_status not null default 'chua_nop',
  ielts_status      doc_status not null default 'chua_nop',
  identity_status   doc_status not null default 'chua_nop',
  gpa               numeric(3,1),
  ielts             numeric(2,1),
  date_of_birth     date,
  submitted_at      timestamptz not null default now()
);

create table conversations (
  id          uuid primary key default gen_random_uuid(),
  channel     text not null default 'Web',
  started_at  timestamptz not null default now()
);

create table chat_messages (
  id               bigint generated always as identity primary key,
  conversation_id  uuid not null references conversations(id) on delete cascade,
  sender           chat_sender not null,
  text             text not null,
  created_at       timestamptz not null default now()
);

create index on chat_messages (conversation_id, created_at);

-- ───────── RLS ─────────
-- Chưa có đăng nhập (Tuần 6), nên chỉ mở tối thiểu cho khách ẩn danh.
-- Các bảng không có policy (student_profiles, conversations, chat_messages)
-- chỉ truy cập được bằng secret key ở phía server (lib/supabase/admin.ts).
alter table schools            enable row level security;
alter table service_packages   enable row level security;
alter table admission_requests enable row level security;
alter table student_profiles   enable row level security;
alter table conversations      enable row level security;
alter table chat_messages      enable row level security;

create policy "Ai cũng xem được danh sách trường"
  on schools for select using (true);

create policy "Ai cũng xem được gói dịch vụ"
  on service_packages for select using (true);

-- admission_requests chứa dữ liệu khách hàng: không có policy và thu hồi quyền,
-- chỉ server (secret key) đọc/ghi được. Form báo giá gửi qua server action.
revoke all on admission_requests from anon, authenticated;

-- ───────── Dữ liệu mẫu ─────────
insert into schools (name, country, min_gpa, min_ielts) values
  ('University of Toronto',     'Canada',   8.0, 6.5),
  ('RMIT University',           'Úc',       7.0, 6.0),
  ('University of Manchester',  'Anh',      7.5, 6.5),
  ('Arizona State University',  'Mỹ',       6.5, 6.0),
  ('Yonsei University',         'Hàn Quốc', 8.5, 7.0);

insert into service_packages (id, name, price, description, benefits) values
  ('co_ban', 'Cơ bản', 18000000,
   'Phù hợp nếu hồ sơ của bạn đơn giản và đã chuẩn bị sẵn phần lớn giấy tờ.',
   array[
     'Đối chiếu điểm chuẩn tự động',
     'Kiểm tra hợp lệ giấy tờ (bảng điểm, IELTS, CMND/hộ chiếu)',
     'Hỗ trợ qua email trong 24h',
     '1 lần nộp lại hồ sơ miễn phí'
   ]),
  ('toan_dien', 'Toàn diện', 45000000,
   'Đồng hành trọn gói từ tư vấn trường đến nộp hồ sơ.',
   array[
     'Toàn bộ quyền lợi gói Cơ bản',
     'Tư vấn chọn trường 1:1 với chuyên viên',
     'Rà soát hồ sơ không giới hạn số lần',
     'Hỗ trợ ưu tiên qua điện thoại + email',
     'Theo dõi tiến độ xét duyệt hằng tuần'
   ]);

insert into admission_requests
  (customer_name, customer_email, country, degree_level, package, quote, status, created_at) values
  ('Trần Thị Bích',  'bich.tran@example.com',   'Úc',       'dai_hoc', 'toan_dien', 45000000, 'cho_duyet', '2026-08-06 08:20+07'),
  ('Đỗ Ngọc Lan',    'lan.do@example.com',      'Canada',   'dai_hoc', 'toan_dien', 45000000, 'cho_duyet', '2026-08-05 09:12+07'),
  ('Lê Văn Hùng',    'hung.le@example.com',     'Mỹ',       'dai_hoc', 'co_ban',    18000000, 'da_duyet',  '2026-08-04 14:30+07'),
  ('Phạm Thu Hà',    'ha.pham@example.com',     'Anh',      'dai_hoc', 'toan_dien', 45000000, 'da_duyet',  '2026-08-03 10:05+07'),
  ('Nguyễn Đức Anh', 'anh.nguyen@example.com',  'Hàn Quốc', 'dai_hoc', 'co_ban',    18000000, 'tu_choi',   '2026-08-02 16:47+07');

insert into student_profiles
  (student_name, email, transcript_status, ielts_status, identity_status, submitted_at) values
  ('Nguyễn Minh Anh',  'minhanh.nguyen@example.com', 'hop_le',      'dang_xu_ly', 'can_nop_lai', '2026-08-01'),
  ('Vũ Thị Mai',       'mai.vu@example.com',         'hop_le',      'hop_le',     'hop_le',      '2026-07-30'),
  ('Hoàng Gia Bảo',    'bao.hoang@example.com',      'hop_le',      'hop_le',     'dang_xu_ly',  '2026-08-02'),
  ('Trịnh Thu Trang',  'trang.trinh@example.com',    'can_nop_lai', 'hop_le',     'hop_le',      '2026-08-04'),
  ('Bùi Anh Tuấn',     'tuan.bui@example.com',       'dang_xu_ly',  'dang_xu_ly', 'dang_xu_ly',  '2026-08-05');

update student_profiles
  set gpa = 8.2, ielts = 6.5, date_of_birth = '2005-05-12'
  where email = 'minhanh.nguyen@example.com';

with c as (
  insert into conversations (channel, started_at) values
    ('Web', '2026-08-06 09:03+07')
  returning id
)
insert into chat_messages (conversation_id, sender, text, created_at)
select c.id, m.sender::chat_sender, m.text, m.created_at::timestamptz
from c, (values
  ('bot',  'Chào bạn! Mình có thể giúp gì cho hồ sơ du học của bạn?',                                                        '2026-08-06 09:03+07'),
  ('user', 'Gói Toàn diện có gì khác gói Cơ bản vậy ạ?',                                                                     '2026-08-06 09:04+07'),
  ('bot',  'Gói Toàn diện gồm tư vấn chọn trường 1:1, rà soát hồ sơ không giới hạn và hỗ trợ ưu tiên qua điện thoại.',       '2026-08-06 09:04+07')
) as m(sender, text, created_at);
