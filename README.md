# Repositório Científico de Zitundo

Plataforma web para organizar, preservar e partilhar materiais da investigação em Zitundo-Sede, Matutuíne, Moçambique.

## Estado da versão

A interface está em `index.html`. A autenticação, a base de dados e os ficheiros dependem de um projecto Supabase configurado pelo administrador. O código não contém credenciais privadas.

## Publicar gratuitamente com GitHub Pages

1. Abra **Settings** deste repositório.
2. Entre em **Pages**.
3. Em **Build and deployment**, escolha **Deploy from a branch**.
4. Seleccione a branch `main` e a pasta `/ (root)); carregue em **Save**.
5. Aguarde a publicação. O endereço será `https://heliomaguele.github.io/repositorio-cientifico-zitundo/`.

## Configurar o Supabase

1. Crie um projecto gratuito em [supabase.com](https://supabase.com/).
2. O esquema inicial já foi aplicado automaticamente no projecto criado. O ficheiro `supabase/schema.sql` fica guardado no GitHub para referência e futuras instalações.
3. Em **Project Settings → API** (ou **Data API**), copie o Project URL e a chave pública **anon/publishable**.
4. No ficheiro `index.html`, substitua:
   - `COLOCAR_URL_DO_SUPABASE` pelo Project URL;
   - `COLOCAR_CHAVE_PUBLICA_ANON` pela chave pública anon/publishable.
5. Guarde a alteração no GitHub. Nunca coloque a chave `service_role` ou qualquer segredo no HTML ou neste repositório.

## Autorizar o primeiro administrador

1. Abra a plataforma publicada, crie a sua conta com o seu email e confirme o email, se o Supabase solicitar.
2. No Supabase, abra **Authentication → Users** e copie o UUID da conta.
3. No **SQL Editor**, execute (substitua o UUID):

```sql
insert into public.team_members (user_id, role)
values ('COLOQUE-AQUI-O-UUID', 'admin')
on conflict (user_id) do update set role = 'admin';
```

4. Termine e inicie novamente a sessão na plataforma. A conta passará a poder carregar documentos.

## Autorizar outros investigadores

Cada investigador cria a sua própria conta. O administrador localiza o UUID em **Authentication → Users** e executa:

```sql
insert into public.team_members (user_id, role)
values ('UUID-DO-INVESTIGADOR', 'researcher')
on conflict (user_id) do nothing;
```

Apenas os utilizadores registados em `team_members` podem consultar ficheiros restritos, carregar materiais ou eliminar registos. Os documentos públicos podem ser consultados sem autenticação. A base de dados e o armazenamento aplicam políticas de segurança (RLS).

## Limites e protecção de dados

- Os planos gratuitos têm limites de armazenamento, tráfego e utilização, que podem mudar. Não são recursos ilimitados.
- O limite de carregamento configurado nesta versão é 25 MB por ficheiro.
- Não carregue entrevistas identificáveis, dados pessoais ou informação sensível sem consentimento e medidas de protecção adequadas.
- Mantenha cópias de segurança dos documentos e dos dados importantes.
- A criação de conta, por si só, não concede acesso à equipa; é necessária autorização do administrador.

## Estrutura

- `index.html` — aplicação web.
- `supabase/schema.sql` — tabelas, buckets e políticas de segurança.
