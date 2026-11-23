-- FATEC APROVA — esquema inicial para Supabase
-- Execute no SQL Editor do seu projeto Supabase.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Estudante',
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  subject_id text not null,
  topic text not null,
  level text not null default 'Médio',
  statement text not null,
  options jsonb not null,
  answer integer not null check (answer between 0 and 4),
  explanation text not null default '',
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  total integer not null check (total > 0),
  correct integer not null check (correct between 0 and total),
  subject text not null default 'Misto',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.attempts enable row level security;

-- Cada usuário pode ler e atualizar somente seu próprio perfil.
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Estudantes veem somente questões publicadas. Administradores gerenciam o banco.
create policy "questions_read_published" on public.questions for select to authenticated using (published = true);
create policy "questions_admin_all" on public.questions for all to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Cada estudante vê e grava apenas suas tentativas.
create policy "attempts_select_own" on public.attempts for select to authenticated using (auth.uid() = user_id);
create policy "attempts_insert_own" on public.attempts for insert to authenticated with check (auth.uid() = user_id);

-- Perfil criado automaticamente quando o usuário é convidado e aceita o convite.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)), 'student')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- IMPORTANTE: depois de criar sua conta de administrador por convite,
-- execute este comando substituindo pelo seu e-mail:
-- update public.profiles p set role = 'admin'
-- from auth.users u where p.id = u.id and u.email = 'SEU_EMAIL@EXEMPLO.COM';

-- Inserção das questões demonstrativas no Supabase:
insert into public.questions(subject_id,topic,level,statement,options,answer,explanation,published)
values
('portugues','Interpretação de textos','Médio','Leia a afirmação: “Embora a tecnologia amplie o acesso à informação, isso não garante, por si só, a formação de leitores críticos.” A ideia central é que:','["A tecnologia impede a formação de leitores.","O acesso à informação é suficiente para desenvolver senso crítico.","O acesso ampliado precisa ser acompanhado de capacidade de análise.","Leitores críticos dependem exclusivamente de livros impressos.","A tecnologia reduz necessariamente a qualidade da informação."]'::jsonb,2,'O conectivo “embora” estabelece uma concessão: a tecnologia amplia o acesso, mas essa condição não basta para desenvolver leitura crítica.',true),
('matematica','Razão e proporção','Médio','Uma gráfica imprime 240 apostilas em 4 horas, mantendo ritmo constante. No mesmo ritmo, quantas apostilas serão impressas em 7 horas?','["360","400","420","440","480"]'::jsonb,2,'A taxa é 240 ÷ 4 = 60 apostilas por hora. Em 7 horas: 60 × 7 = 420.',true),
('geografia','Urbanização','Médio','A expansão urbana sem planejamento tende a intensificar problemas socioambientais. Um exemplo é:','["A redução automática das desigualdades.","A ocupação de áreas de risco e a impermeabilização do solo.","A eliminação das ilhas de calor.","A recuperação espontânea de mananciais.","A diminuição da demanda por transporte."]'::jsonb,1,'A ocupação de áreas de risco e a impermeabilização ampliam a exposição a deslizamentos e enchentes.',true),
('fisica','Eletricidade','Médio','Um resistor de 20 Ω é ligado a uma fonte ideal de 10 V. De acordo com a Lei de Ohm, a corrente elétrica é:','["0,2 A","0,5 A","2 A","10 A","200 A"]'::jsonb,1,'Pela Lei de Ohm, I = U/R = 10/20 = 0,5 A.',true),
('historia','Brasil República','Médio','Na Primeira República brasileira, a política dos governadores esteve associada principalmente:','["À centralização do poder nas mãos dos sindicatos.","À articulação entre o governo federal e oligarquias estaduais.","À implantação do voto feminino.","À extinção das elites agrárias.","À adoção do parlamentarismo monárquico."]'::jsonb,1,'O arranjo político articulava apoio entre governo federal e oligarquias estaduais.',true),
('quimica','Química geral','Fácil','Uma solução com pH igual a 3, a 25 °C, é classificada como:','["Básica","Neutra","Ácida","Saturada","Alcalina"]'::jsonb,2,'A 25 °C, pH menor que 7 indica solução ácida.',true),
('biologia','Ecologia','Médio','Em uma cadeia alimentar, a energia disponível geralmente diminui nos níveis tróficos mais elevados porque:','["A energia é reciclada integralmente.","Parte da energia é dissipada no metabolismo e na forma de calor.","Os produtores não realizam fotossíntese.","Consumidores produzem energia do nada.","A matéria deixa de circular nos ecossistemas."]'::jsonb,1,'Parte da energia é utilizada no metabolismo e dissipada como calor a cada transferência trófica.',true),
('ingles','Reading','Fácil','In the sentence “The results were reliable, although the sample was small”, the word “although” indicates:','["Cause","Addition","Contrast","Time","Purpose"]'::jsonb,2,'“Although” é uma conjunção concessiva e indica contraste.',true);
