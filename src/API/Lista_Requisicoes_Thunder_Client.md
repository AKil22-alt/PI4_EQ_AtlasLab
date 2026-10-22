# Requisições para o Thunder Client

A coleção importável está em `thunder-client/AtlasLab.postman_collection.json` (formato Postman Collection v2.1, importável pelo Thunder Client).

## Como importar e usar

1. Inicie a API: `python manage.py runserver`.
2. No VS Code, abra a extensão Thunder Client e use **Import** → **Postman Collection**.
3. Selecione `thunder-client/AtlasLab.postman_collection.json`.
4. A coleção já vem com `baseUrl=http://127.0.0.1:8000/api` e as variáveis de IDs.
5. Execute **Health - API disponível**.
6. Edite **Login - obter token** e substitua o exemplo de e-mail/senha pelos dados configurados pelo comando `python manage.py criar_admin_atlaslab`.
7. Execute o login. Se a importação não preencher a variável `token` automaticamente, copie o campo `token` da resposta e cole na variável da coleção `token`.
8. Execute as requisições protegidas. IDs como `grupoId`, `salaId` e `ativoId` devem corresponder aos registros existentes no banco. Atualize `qrCode` com o valor retornado quando criar um ativo.

## Lista resumida de requisições

| Grupo | Métodos e rotas presentes na coleção |
|---|---|
| Saúde/autenticação | `GET /health/`, `POST /auth/login/`, `GET /auth/me/`, `POST /auth/logout/` |
| Usuários | `GET/POST /usuarios/`, `GET/PATCH/DELETE /usuarios/{id}/` |
| Grupos | `GET/POST /grupos/`, `GET/PATCH/DELETE /grupos/{id}/` |
| Salas/laboratórios | `GET/POST /salas/`, `GET/PATCH/DELETE /salas/{id}/` |
| Ativos | `GET/POST /ativos/`, `GET/PATCH /ativos/{id}/`, pesquisa/filtro, QR Code, movimentar, inativar/reativar e histórico (sem exclusão física) |
| Ordens de serviço | `GET/POST /ordens-servico/`, `GET/PATCH/DELETE /ordens-servico/{id}/`, filtro por status |
| Manutenções | `GET/POST /manutencoes/`, `GET/PATCH/DELETE /manutencoes/{id}/` |
| Movimentações | `GET/POST /movimentacoes/`, `GET /movimentacoes/{id}/`, filtro por ativo; histórico append-only |
| Denúncias | `GET/POST /denuncias/`, `GET /denuncias/{id}/` |
| Auditoria | `GET /logs/` (ADM) |

## Observações de teste

- Os exemplos com IDs `1` e `2` pressupõem que esses registros existam. Crie grupo e sala antes do ativo e atualize as variáveis conforme as respostas.
- Para validar RBAC, faça login como `CLB` e teste uma criação de ativo (deve retornar `403`); a consulta deve retornar `200`.
- A imagem do QR Code retorna `image/png`, por isso o visualizador do Thunder Client pode mostrá-la como binário ou oferecer download.
- Códigos esperados: `200` para consulta/edição bem-sucedida, `201` para criação, `204` para exclusão, `401` para token ausente/inválido e `403` para cargo sem permissão. Dados inválidos normalmente retornam `400`.
