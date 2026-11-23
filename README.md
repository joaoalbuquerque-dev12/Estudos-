# FATEC APROVA — versão inicial

Plataforma web responsiva de preparação para o vestibular FATEC. Este projeto foi preparado para abrir no **Visual Studio Code**.

## O que já está implementado

- Interface responsiva para desktop e celular.
- Login por e-mail e senha.
- Modo de demonstração local (sem sincronização entre dispositivos).
- Estrutura de disciplinas e tópicos.
- Banco inicial de questões autorais demonstrativas, com alternativas e explicações.
- Prática de questões e diagnóstico geral.
- Histórico e indicadores locais de desempenho.
- Biblioteca com as provas oficiais do 1º e 2º semestres de 2026 e seus gabaritos (PDFs hospedados no site oficial).
- Área de administração preparada para convite de estudantes.
- Integração preparada com Supabase (Auth + PostgreSQL + RLS).
- Função segura do Supabase para envio de convites por administrador.

## 1. Abrir no VS Code

1. Extraia o ZIP.
2. Abra a pasta `FATEC-APROVA` no Visual Studio Code.
3. Instale o Node.js LTS: https://nodejs.org/
4. Abra o terminal integrado do VS Code.
5. Execute:

```bash
npm install
npm run dev
```

6. Abra o endereço local exibido pelo Vite (normalmente `http://localhost:5173`).

Sem Supabase configurado, a tela oferece um modo de demonstração local. Nesse modo, os dados ficam apenas no navegador e não são compartilhados com outros usuários.

## 2. Configurar usuários reais e acesso por convite

Para que várias pessoas entrem com suas próprias contas, configure um projeto Supabase:

1. Crie um projeto em https://supabase.com/.
2. No painel do Supabase, abra **SQL Editor**.
3. Execute todo o conteúdo de `supabase/schema.sql`.
4. Em **Project Settings > API**, copie a Project URL e a chave `anon`/publishable.
5. Crie um arquivo `.env` na raiz (use `.env.example` como modelo) e preencha:

```env
VITE_SUPABASE_URL=https://SEU-PROJETO.supabase.co
VITE_SUPABASE_ANON_KEY=SUA_CHAVE_ANON_PUBLICA
```

6. Reinicie `npm run dev`.

### Criar o primeiro administrador

Depois de executar o SQL, convide/crie o primeiro usuário pelo painel do Supabase (Authentication > Users > Invite user). Depois que o usuário existir, execute no SQL Editor, substituindo pelo seu e-mail:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id and u.email = 'SEU_EMAIL@EXEMPLO.COM';
```

Saia e entre novamente no aplicativo para carregar o perfil de administrador.

### Publicar a função de convites

A área de administração envia convites reais por meio de uma Supabase Edge Function. Instale a CLI do Supabase e autentique:

```bash
npm install -g supabase
supabase login
supabase link --project-ref SEU_PROJECT_REF
supabase functions deploy invite-user
```

A função usa as variáveis padrão `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY` fornecidas pelo ambiente Supabase. **Nunca coloque a chave service_role no frontend ou no arquivo `.env` do Vite.**

No Supabase, configure também SMTP/e-mail de produção em Authentication > SMTP Settings para melhorar a entrega dos convites. O provedor padrão pode ter limites de envio.

## 3. Acesso restrito por convite

- Não existe cadastro público no aplicativo.
- O administrador convida o e-mail do estudante.
- O estudante aceita o convite e define sua senha pelo fluxo do Supabase.
- O perfil novo recebe papel `student` por padrão.
- Apenas o papel `admin` pode convidar outros usuários, validado também no servidor pela Edge Function.
- As políticas RLS limitam a leitura de perfil e tentativas ao próprio usuário.

## 4. Estrutura

```text
FATEC-APROVA/
├── public/
├── src/
│   ├── App.jsx
│   ├── data.js
│   ├── main.jsx
│   ├── style.css
│   └── supabase.js
├── supabase/
│   ├── schema.sql
│   └── functions/
│       └── invite-user/
│           └── index.ts
├── .env.example
├── index.html
├── package.json
└── README.md
```

## 5. Provas oficiais incluídas no acervo

A tela **Provas anteriores** disponibiliza as duas provas mais recentes publicadas para 2026, com visualização incorporada e links para abrir prova e gabarito:

- Vestibular Fatec 2º semestre de 2026 — prova aplicada em 28/06/2026.
- Vestibular Fatec 1º semestre de 2026.

Os documentos são carregados diretamente do repositório oficial `fatweb.s3.amazonaws.com`; por isso, o estudante precisa estar conectado à internet. A página oficial de consulta é https://vestibular.fatec.sp.gov.br/provas-gabaritos/detalhe.asp?q=2026.

## 6. Observações importantes

- Esta é a primeira versão funcional/base do produto, não um cursinho com todo o conteúdo do edital já preenchido.
- As questões que acompanham o projeto são **autorais e demonstrativas**, criadas para testar o fluxo. Não são questões oficiais da FATEC.
- O conteúdo programático e o formato da prova devem ser conferidos no edital oficial do processo seletivo vigente antes de fechar o banco de questões.
- O ranking coletivo, gerenciamento completo de questões pela interface, temporizador fiel ao exame, redação com avaliação e relatórios avançados são etapas de evolução.
- Antes de abrir ao público, faça testes de autenticação, recuperação de senha, permissões e políticas RLS.

## Próximas melhorias recomendadas

1. Importador de questões por planilha/CSV e painel CRUD completo.
2. Simulado com tempo configurável e navegação entre questões.
3. Painel de desempenho por disciplina e assunto.
4. Ranking coletivo com consentimento e regras de privacidade.
5. Módulo de redação e plano de estudos personalizado.
6. PWA instalável e publicação em hospedagem web.
