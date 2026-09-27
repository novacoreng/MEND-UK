-- MEND UK Phase 8: Messaging & Notifications
-- Conversation access, read receipts, notification inbox, preferences and server-created events.

create index if not exists conversations_repair_idx on public.conversations(repair_id, created_at desc);
create index if not exists conversation_members_user_idx on public.conversation_members(user_id, conversation_id);
create index if not exists messages_unread_idx on public.messages(conversation_id, read_at, sent_at desc);
create index if not exists notifications_unread_idx on public.notifications(user_id, created_at desc) where read = false;

-- Prevent arbitrary clients from changing message ownership/content through updates.
create or replace function public.prevent_message_mutation()
returns trigger language plpgsql as $$
begin
  if new.sender_id is distinct from old.sender_id
     or new.conversation_id is distinct from old.conversation_id
     or new.body is distinct from old.body
     or new.message_type is distinct from old.message_type
     or new.attachment_path is distinct from old.attachment_path
     or new.sent_at is distinct from old.sent_at then
    raise exception 'Message content cannot be modified';
  end if;
  return new;
end;
$$;

drop trigger if exists messages_immutable_content on public.messages;
create trigger messages_immutable_content before update on public.messages
for each row execute function public.prevent_message_mutation();

-- Read receipts are only allowed for a conversation member and only on messages they did not send.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns integer language plpgsql security invoker as $$
declare v_count integer;
begin
  if not exists (select 1 from public.conversation_members cm where cm.conversation_id=p_conversation_id and cm.user_id=auth.uid()) then
    raise exception 'Not a conversation member';
  end if;
  update public.messages
     set read_at = coalesce(read_at, now())
   where conversation_id=p_conversation_id
     and sender_id is distinct from auth.uid()
     and read_at is null;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- Notification inbox controls.
create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean language plpgsql security invoker as $$
begin
  update public.notifications set read=true
   where id=p_notification_id and user_id=auth.uid();
  return found;
end;
$$;
revoke all on function public.mark_notification_read(uuid) from public;
grant execute on function public.mark_notification_read(uuid) to authenticated;

-- Default preferences are created server-side for every new profile.
insert into public.notification_preferences(user_id)
select id from public.profiles p
where not exists (select 1 from public.notification_preferences np where np.user_id=p.id)
on conflict (user_id) do nothing;

-- System notification helper. It respects the in-app inbox regardless of channel preferences.
create or replace function public.create_user_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_data jsonb default '{}'::jsonb
) returns uuid language plpgsql security invoker as $$
declare v_id uuid;
begin
  if p_user_id is null then return null; end if;
  insert into public.notifications(user_id,type,title,body,data)
  values(p_user_id,p_type,p_title,p_body,coalesce(p_data,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.create_user_notification(uuid,text,text,text,jsonb) from public;
grant execute on function public.create_user_notification(uuid,text,text,text,jsonb) to authenticated;

-- New message => notify every other conversation member. The trigger is the source of truth;
-- clients never manufacture notification success.
create or replace function public.notify_new_message()
returns trigger language plpgsql security definer set search_path=public as $$
declare r record; v_sender_name text;
begin
  select coalesce(nullif(full_name,''), 'A MEND user') into v_sender_name from public.profiles where id=new.sender_id;
  for r in select cm.user_id from public.conversation_members cm where cm.conversation_id=new.conversation_id and cm.user_id is distinct from new.sender_id loop
    perform public.create_user_notification(r.user_id,'message','New message',v_sender_name || ' sent you a message.',jsonb_build_object('conversation_id',new.conversation_id,'message_id',new.id));
  end loop;
  return new;
end;
$$;
drop trigger if exists notify_message on public.messages;
create trigger notify_message after insert on public.messages
for each row execute function public.notify_new_message();

-- Appointment events => in-app notifications. Provider delivery is a Phase 8 channel adapter concern.
create or replace function public.notify_appointment_event()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_title text; v_body text; v_type text;
begin
  if tg_op='INSERT' then
    v_type:='appointment_requested'; v_title:='Appointment requested'; v_body:='A repair appointment has been requested.';
  elsif new.status is distinct from old.status then
    v_type:='appointment_'||new.status; v_title:='Appointment updated'; v_body:='Your repair appointment is now '||replace(new.status,'_',' ')||'.';
  else return new;
  end if;
  perform public.create_user_notification(new.customer_id,v_type,v_title,v_body,jsonb_build_object('repair_id',new.repair_id,'appointment_id',new.id));
  if new.trade_id is not null then
    perform public.create_user_notification((select user_id from public.trade_profiles where id=new.trade_id),v_type,v_title,v_body,jsonb_build_object('repair_id',new.repair_id,'appointment_id',new.id));
  end if;
  return new;
end;
$$;
drop trigger if exists notify_appointment on public.appointments;
create trigger notify_appointment after insert or update of status on public.appointments
for each row execute function public.notify_appointment_event();

-- Enable realtime for the user-facing streams when not already present.
do $$
begin
  begin alter publication supabase_realtime add table public.messages; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.notifications; exception when duplicate_object then null; end;
end $$;

-- RLS: explicit member/owner rules, never just authenticated-role access.
create policy "conversation members read" on public.conversations for select
  to authenticated using (exists(select 1 from public.conversation_members cm where cm.conversation_id=conversations.id and cm.user_id=auth.uid()) or public.is_admin());
create policy "conversation members read own membership" on public.conversation_members for select
  to authenticated using (user_id=auth.uid() or public.is_admin());
create policy "messages member insert" on public.messages for insert
  to authenticated with check (sender_id=auth.uid() and exists(select 1 from public.conversation_members cm where cm.conversation_id=messages.conversation_id and cm.user_id=auth.uid()));
create policy "notification preferences own read" on public.notification_preferences for select
  to authenticated using (user_id=auth.uid() or public.is_admin());
create policy "notification preferences own update" on public.notification_preferences for update
  to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "notification preferences own insert" on public.notification_preferences for insert
  to authenticated with check (user_id=auth.uid());

create table if not exists public.notification_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null check (provider in ('expo','apns','fcm')),
  token text not null,
  platform text not null check (platform in ('ios','android','web')),
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(provider,token)
);
create index if not exists notification_devices_user_idx on public.notification_devices(user_id,is_active);
alter table public.notification_devices enable row level security;
create policy "notification devices own" on public.notification_devices for select to authenticated using (user_id=auth.uid() or public.is_admin());
create policy "notification devices own insert" on public.notification_devices for insert to authenticated with check (user_id=auth.uid());
create policy "notification devices own update" on public.notification_devices for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "notification devices own delete" on public.notification_devices for delete to authenticated using (user_id=auth.uid());

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  channel text not null check (channel in ('push','email','sms')),
  status text not null default 'queued' check (status in ('queued','sent','failed','skipped')),
  provider_message_id text,
  error text,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);
create unique index if not exists notification_delivery_unique on public.notification_deliveries(notification_id,channel);
create index if not exists notification_delivery_user_idx on public.notification_deliveries(user_id,created_at desc);
alter table public.notification_deliveries enable row level security;
create policy "notification deliveries own" on public.notification_deliveries for select to authenticated using (user_id=auth.uid() or public.is_admin());
