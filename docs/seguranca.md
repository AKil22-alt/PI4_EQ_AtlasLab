# 3.5 Ameaças e controles de segurança

**Projeto:** Sistema de Gestão de Laboratórios e Ativos — AtlasLab  
**Escopo:** PoC de leitura de QR Code/Code 128, aplicativo mobile, aplicação Web, API REST e banco de dados.

A tabela relaciona ameaças específicas do fluxo do AtlasLab aos controles da Sprint 1 e ao que existe nesta versão da API. **“Implementado no código” não significa que a validação de aceitação já foi concluída:** execute os testes descritos abaixo no ambiente do grupo e guarde as evidências para a entrega.

## Ameaças e controles

| Componente | Ameaça / cenário | Consequência | Controle de segurança | Situação nesta versão |
|---|---|---|---|---|
| Leitor de QR Code/Code 128 e consulta na API | Um marcador é adulterado, trocado ou contém um identificador inexistente ou pertencente a outro ativo. | A aplicação pode exibir informações do patrimônio errado ou associar uma movimentação ao equipamento incorreto. | A API gera um identificador único no cadastro, consulta o valor recebido contra o registro central e retorna `404` quando não encontra correspondência. O endpoint de imagem gera o QR a partir do identificador guardado no banco. | 

**Implementado parcialmente no código — validar no leitor mobile.** A validação da existência está implementada; a leitura e integração com app/RA precisam de teste integrado. |
| Campos enviados à API | Um usuário envia dados malformados, campos fora do limite ou identificadores inválidos. | Erros de processamento, consulta indevida ou corrupção dos dados do ativo. | Serializers do DRF validam tipos, obrigatoriedade e limites definidos nos modelos; as consultas usam o ORM; filtros numéricos inválidos retornam erro de validação. | 

**Implementado no código — executar testes com payloads inválidos.** |
| Login e endpoints administrativos | Um usuário tenta chamar diretamente um endpoint reservado a perfil de maior privilégio. | Consulta, cadastro, alteração ou exclusão de dados sem autorização. | Login emite token aleatório com expiração de 12 horas; o banco guarda apenas o hash SHA-256 do token; as rotas verificam o cargo (`ADM`, `TEC`, `CLB`) no servidor. | 

**Implementado no código — executar testes de RBAC** (RS01, RF01–RF04 e CA05). |
| Movimentação e histórico dos ativos | Uma mudança de sala é realizada sem registro ou o histórico é alterado sem rastreabilidade. | Perda do histórico, localização incorreta e dificuldade de auditoria. | A movimentação registra usuário, data/hora, ativo, justificativa e local. A API atualiza `local_atual`, registra auditoria da mudança e mantém o endpoint de movimentações somente para consulta/criação, sem edição ou exclusão direta. | 

**Implementado no código — validar a sequência de movimentações e o histórico.** |
| Senhas, tokens, segredos e comunicação cliente-servidor | Credenciais são expostas no tráfego, nos logs ou em arquivos versionados no Git. | Comprometimento de contas e acesso indevido. | Senhas são processadas com `BCryptSHA256PasswordHasher`; tokens de API não são gravados em texto puro; logs omitem senha e token; `.env` está no `.gitignore`; a configuração permite redirecionamento HTTPS em produção. | 

**Implementado na configuração/código.** A exigência de HTTPS só pode ser validada após publicar a API atrás de HTTPS. |
| Banco de dados e cópias de segurança | Uma falha ou exclusão acidental torna os registros indisponíveis ou incorretos. | Perda de cadastros, movimentações e histórico de manutenção. | Os comandos `backup_db` e `restore_db` copiam/restauram SQLite e verificam `PRAGMA integrity_check`; restauração exige confirmação explícita e deve ser feita com o servidor parado. | 

**Comandos implementados para SQLite — realizar e registrar um teste de restauração.** Para MySQL, usar `mysqldump` e o procedimento de restauração do servidor. |

## Fluxo de validação do marcador

```mermaid
flowchart LR
    A --> Aplicativo lê QR Code --> B[API consulta o identificador recebido]
    B --> C{Ativo existe?}
    C -- Sim --> D[Retorna dados do ativo]
    D --> E[Movimentação autorizada atualiza local e histórico]
    C -- Não --> F[Retorna 404 sem alterar dados]
```

O QR Code identifica o ativo, mas não substitui autenticação. As operações protegidas precisam ser enviadas com o cabeçalho `Authorization: Token <token>`; a API aplica as regras de cargo no servidor.

## Verificações para demonstrar os controles

| Teste | Resultado esperado |
|---|---|
| Consultar um QR Code inválido ou inexistente. | A API retorna `404` e não mostra dados de outro ativo nem altera registros. |
| Enviar dados inválidos à API. | A API retorna erro de validação e não grava a alteração inválida. |
| Fazer login como `CLB` e tentar cadastrar um ativo. | A API retorna `403`; a consulta de ativos continua permitida. |
| Registrar uma movimentação autorizada. | `local_atual` é atualizado e o histórico mostra autor, data/hora e justificativa. |
| Tentar editar ou excluir uma movimentação. | A API retorna `405 Method Not Allowed`; a correção deve ser registrada como novo evento. |
| Gerar um backup de teste e restaurá-lo em ambiente controlado. | O comando valida integridade e os registros necessários são recuperados. |
| Publicar a API para teste. | As requisições HTTP são encaminhadas para HTTPS; nenhum segredo é versionado no Git. |

## Referências no documento do projeto

- **Documento 3 — Requisitos e Critérios de Aceite:** RF01–RF10, requisitos de segurança RS01–RS05 e cenário CA05.
- **Documento 4 — Backlog, Papéis, Cronograma, Riscos e SAGA:** B05 (PoC de leitura), B07 (login e níveis de acesso), B09 (leitura de QR Code no mobile), B10 (movimentação/histórico) e B11 (testes de segurança e backup), além do risco R03 sobre exposição de segredos no Git.
- **Documento 5 — Canvas Inicial e Registro de Decisões:** decisão D03 sobre uso de BCrypt para hash de senhas e D06 sobre uso de dados fictícios nos testes.
