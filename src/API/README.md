# AtlasLab API — Sistema de Gestão de Laboratórios e Ativos

API REST em Django REST Framework para apoiar o painel Web e o aplicativo Android do projeto AtlasLab. A estrutura contempla os relacionamentos do diagrama lógico (inclusive as tabelas de ligação entre ordens de serviço, usuários, salas, ativos e manutenções), os requisitos da Sprint 1 corrigida e uma coleção importável no Thunder Client.

## 1. Requisitos

- Python 3.10 ou superior (use uma versão suportada pela versão do Django instalada).
- SQLite
- Pacotes listados em `requirements.txt`.

## 2. Preparar e iniciar

No terminal, a partir da pasta do projeto:

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py criar_admin_atlaslab
python manage.py runserver
```

A configuração lê o arquivo `.env` com `python-dotenv`; você também pode definir as variáveis diretamente no ambiente. O padrão é SQLite no arquivo `db.sqlite3`.

Para MySQL, instale também `mysqlclient`, configure `DB_ENGINE=mysql`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST` e `DB_PORT`, e então execute as migrações.

API local: `http://127.0.0.1:8000/api/`

## 3. Autenticação e perfis

1. Envie `POST /api/auth/login/` com `email` e `senha`.
2. Copie o valor `token` retornado.
3. Nas requisições protegidas, use o cabeçalho `Authorization: Token SEU_TOKEN`.
4. O token expira em 12 horas. Use `POST /api/auth/logout/` para invalidá-lo.

Cargos usados na API:

- `ADM`: administração de usuários, consulta aos logs e acesso total às rotas de gestão.
- `TEC`: gerenciamento de grupos, salas, ativos, ordens de serviço, manutenções e movimentações.
- `CLB`: consulta dos ativos, abertura de denúncia/ordem de serviço e registro/consulta das próprias movimentações.

A senha é gravada com BCrypt via `BCryptSHA256PasswordHasher`. Ela nunca é devolvida pela API. Crie o primeiro administrador com o comando `criar_admin_atlaslab`; não há credenciais fixas no projeto.

## 4. Endpoints principais

Base: `http://127.0.0.1:8000/api`

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/health/` | Verificação de disponibilidade; não exige token |
| POST | `/auth/login/` | Login e emissão de token |
| GET | `/auth/me/` | Dados do usuário autenticado |
| POST | `/auth/logout/` | Revoga o token atual |
| GET/POST | `/usuarios/` | Listar/criar usuários (ADM) |
| GET/PATCH/DELETE | `/usuarios/{id_user}/` | Consultar/alterar/remover usuário (ADM) |
| GET/POST | `/grupos/` | Listar/criar grupos de ativos |
| GET/POST | `/salas/` | Listar/criar salas/laboratórios |
| GET/POST | `/ativos/` | Consultar/cadastrar ativos |
| GET/PATCH | `/ativos/{id_ativos}/` | Consultar/alterar ativo; não há exclusão física pela API |
| GET | `/ativos/por-qr/?codigo=ATLASLAB-...` | Localizar ativo pelo QR Code |
| GET | `/ativos/{id_ativos}/qr-code-imagem/` | Receber a imagem PNG do QR Code |
| POST | `/ativos/{id_ativos}/movimentar/` | Registrar movimentação e atualizar a localização do ativo |
| POST | `/ativos/{id_ativos}/inativar/` | Inativar ativo sem apagar seu histórico |
| POST | `/ativos/{id_ativos}/ativar/` | Reativar um ativo inativado |
| GET | `/ativos/{id_ativos}/historico/` | Consultar movimentações e ordens ligadas ao ativo |
| GET/POST | `/ordens-servico/` | Consultar/abrir ordem de serviço |
| GET/PATCH/DELETE | `/ordens-servico/{id_ordem}/` | Consultar/atualizar/remover ordem |
| GET/POST | `/manutencoes/` | Consultar/cadastrar manutenções |
| GET/POST | `/movimentacoes/` | Consultar/criar movimentações; histórico é append-only (sem edição/exclusão) |
| GET/POST | `/denuncias/` | Listar/criar denúncias; usuários comuns veem apenas as próprias |
| GET | `/logs/` | Auditoria de ações (ADM) |

Listas são paginadas com até 50 registros por página. Parâmetros úteis: `/ativos/?search=notebook`, `/ativos/?status=ativo`, `/ativos/?grupo=1`, `/ativos/?sala=1`, `/ordens-servico/?status=ABERTA` e `/movimentacoes/?ativo=1`.

## 5. Exemplos de payloads

### Criar grupo

```json
{
  "nome": "Equipamentos de informática",
  "numero_ta": 1,
  "tipo": "Equipamento",
  "setor": "Tecnologia"
}
```

### Criar sala

```json
{
  "nome": "Laboratório 01",
  "numero_ta": 101,
  "localizacao": "Bloco A",
  "descricao": "Laboratório de testes",
  "responsavel": 2
}
```

### Criar ativo

O `qr_code` é gerado automaticamente e é único. Não envie senha, token ou dados pessoais desnecessários.

```json
{
  "nome": "Notebook Dell",
  "status": true,
  "local_origem": "Laboratório 01",
  "local_atual": "Laboratório 01",
  "descricao": "Notebook para testes",
  "grupo": 1,
  "sala": 1
}
```

### Abrir ordem de serviço com vínculos do diagrama

```json
{
  "titulo": "Verificar notebook",
  "descricao": "Equipamento não inicia",
  "status": "ABERTA",
  "usuario_ids": [2],
  "sala_ids": [1],
  "ativo_ids": [1],
  "manutencao_ids": []
}
```

As listas de IDs preenchem as relações `OS_User`, `OS_Salas/Labs`, `OS_Ativo` e `OS_Manutenção`; o modelo registra a data/hora de cada vínculo.

### Movimentar ativo

```json
{
  "local_m": "Laboratório 02",
  "justificativa": "Transferência para manutenção",
  "sala_id": 2,
  "contagem_mov_a": 1
}
```

Envie o corpo para `/api/ativos/1/movimentar/`. A API registra o usuário responsável, atualiza `local_atual` e grava auditoria.

## 6. Testes

```bash
python manage.py check
python manage.py test ativos
```

O detalhamento das ameaças, cenários de teste e controles também está em [`docs/seguranca.md`](docs/seguranca.md).

## 7. Segurança e operação

- RS01: autorização por cargo nas rotas.
- RS02: backup/restore local do SQLite por comandos, sem expor o arquivo do banco via API. `python manage.py backup_db` cria e valida uma cópia; `python manage.py restore_db CAMINHO_DO_BACKUP --confirmar` restaura após checar integridade. Faça um backup separado e pare o servidor da API antes da restauração.
- RS03: o modelo `LogAcao` registra criação, alteração, exclusão, inativação/reativação e movimentação; o histórico de movimentações é append-only e pode ser consultado sem ser editado/apagado; a consulta HTTP dos logs é somente para ADM e o admin Django não permite alterar/apagar logs.
- RS04: em produção, publique somente por HTTPS e configure `DJANGO_SECURE_SSL_REDIRECT=true` quando houver proxy HTTPS corretamente configurado. O servidor de desenvolvimento usa HTTP local.
- RS05: BCrypt SHA-256 por meio do hasher do Django; tokens de API são aleatórios, expiram e ficam armazenados no banco apenas como hash SHA-256.
- Use somente dados fictícios ou anonimizados nos testes, conforme a Sprint 1 e a LGPD. Nunca comite `.env`, senhas, tokens ou bancos reais.

## 8. Decisões de implementação

Os nomes e entidades principais seguem os diagramas enviados. Foram acrescentados o campo de status da ordem de serviço (necessário para controlar estados de OS, conforme a pesquisa da Sprint 1), timestamps de criação/atualização e `LogAcao` para apoiar rastreabilidade. A RA é uma funcionalidade do aplicativo e está fora do escopo desta API além da consulta de dados do ativo; o fallback convencional continua disponível via REST.
