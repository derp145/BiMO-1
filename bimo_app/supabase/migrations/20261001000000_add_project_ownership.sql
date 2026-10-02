-- Existing projects remain unowned until an administrator assigns each row to
-- its real auth.users account. No legacy owner is guessed by this migration.
alter table public.projects
  add column if not exists user_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'projects_user_id_fkey'
      and conrelid = 'public.projects'::regclass
  ) then
    alter table public.projects
      add constraint projects_user_id_fkey
      foreign key (user_id) references auth.users(id);
  end if;
end $$;

alter table public.projects enable row level security;
alter table public.project_components enable row level security;
alter table public.activity_logs enable row level security;

drop policy if exists "Public access projects" on public.projects;
drop policy if exists "Public access project_components" on public.project_components;
drop policy if exists "Public access activity_logs" on public.activity_logs;

create policy "Users can view their projects"
  on public.projects for select to authenticated
  using (auth.uid() = user_id);

create policy "Users can create their projects"
  on public.projects for insert to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their projects"
  on public.projects for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their projects"
  on public.projects for delete to authenticated
  using (auth.uid() = user_id);

create policy "Users can view their project components"
  on public.project_components for select to authenticated
  using (
    exists (
      select 1 from public.projects
      where projects.id = project_components.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can create their project components"
  on public.project_components for insert to authenticated
  with check (
    exists (
      select 1 from public.projects
      where projects.id = project_components.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can update their project components"
  on public.project_components for update to authenticated
  using (
    exists (
      select 1 from public.projects
      where projects.id = project_components.project_id
        and projects.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.projects
      where projects.id = project_components.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can delete their project components"
  on public.project_components for delete to authenticated
  using (
    exists (
      select 1 from public.projects
      where projects.id = project_components.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can view their project activity logs"
  on public.activity_logs for select to authenticated
  using (
    exists (
      select 1 from public.projects
      where projects.id = activity_logs.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can create their project activity logs"
  on public.activity_logs for insert to authenticated
  with check (
    exists (
      select 1 from public.projects
      where projects.id = activity_logs.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can update their project activity logs"
  on public.activity_logs for update to authenticated
  using (
    exists (
      select 1 from public.projects
      where projects.id = activity_logs.project_id
        and projects.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.projects
      where projects.id = activity_logs.project_id
        and projects.user_id = auth.uid()
    )
  );

create policy "Users can delete their project activity logs"
  on public.activity_logs for delete to authenticated
  using (
    exists (
      select 1 from public.projects
      where projects.id = activity_logs.project_id
        and projects.user_id = auth.uid()
    )
  );
