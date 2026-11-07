-- Chat CSKH giua khach hang va nhan vien Menly.
create table if not exists public.support_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  assigned_staff_id uuid references auth.users on delete set null,
  status text not null default 'open' check (status in ('open', 'closed')),
  last_message text,
  last_message_at timestamptz not null default now(),
  unread_user_count int not null default 0,
  unread_staff_count int not null default 0,
  created_at timestamptz not null default now()
);

create unique index if not exists support_conversations_one_open_per_user
  on public.support_conversations(user_id)
  where status = 'open';

create index if not exists support_conversations_inbox_order
  on public.support_conversations(status, last_message_at desc);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.support_conversations on delete cascade,
  sender_id uuid not null references auth.users on delete cascade,
  sender_role text not null check (sender_role in ('customer', 'staff', 'admin')),
  content text not null check (char_length(trim(content)) between 1 and 2000),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists support_messages_conversation_order
  on public.support_messages(conversation_id, created_at);

create or replace function public.update_support_conversation_on_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.support_conversations
  set last_message = new.content,
      last_message_at = new.created_at,
      unread_staff_count = unread_staff_count + case when new.sender_role = 'customer' then 1 else 0 end,
      unread_user_count = unread_user_count + case when new.sender_role in ('staff', 'admin') then 1 else 0 end,
      assigned_staff_id = case
        when new.sender_role in ('staff', 'admin') then new.sender_id
        else assigned_staff_id
      end
  where id = new.conversation_id;

  return new;
end;
$$;

drop trigger if exists support_messages_update_conversation on public.support_messages;
create trigger support_messages_update_conversation
after insert on public.support_messages
for each row execute function public.update_support_conversation_on_message();

-- Backend truy cap bang service role; client truy cap truc tiep bi chan mac dinh.
alter table public.support_conversations enable row level security;
alter table public.support_messages enable row level security;
