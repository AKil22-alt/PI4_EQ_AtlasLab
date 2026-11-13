import hashlib
from datetime import timedelta

from django.contrib.auth.hashers import check_password, make_password
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    ApiToken, Ativo, Cargo, GrupoA, LogAcao, MovimentacoesA, Notificacao,
    OrdemServico, SalaLab, SolicitacaoCadastro, Usuario,
)


class ApiViewsTests(TestCase):
    def setUp(self):
        self.admin = Usuario.objects.create(
            nome="Administradora Atlas",
            email="admin@example.com",
            cargo=Cargo.ADMINISTRADOR,
            senha=make_password("senha-segura-123"),
        )
        self.colaborador = Usuario.objects.create(
            nome="Colaborador Atlas",
            email="colaborador@example.com",
            cargo=Cargo.COLABORADOR,
            senha=make_password("senha-segura-123"),
        )
        self.grupo = GrupoA.objects.create(
            nome="Informática",
            numero_ta=1,
            tipo="Equipamento",
            setor="Tecnologia",
        )
        self.sala = SalaLab.objects.create(
            nome="Laboratório 1",
            numero_ta=1,
            localizacao="Laboratório 1",
        )
        self.ativo = Ativo.objects.create(
            nome="Notebook de testes",
            local_origem=self.sala,
            local_atual=self.sala,
            grupo=self.grupo,
        )

    def authenticate(self, user):
        raw_token = ApiToken.gerar_token()
        ApiToken.objects.create(
            usuario=user,
            token_hash=hashlib.sha256(raw_token.encode("utf-8")).hexdigest(),
            expira_em=timezone.now() + timedelta(hours=1),
        )
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f"Token {raw_token}")
        return client

    def test_health_endpoint_is_public(self):
        response = APIClient().get("/api/health/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {"status": "ok"})

    def test_dashboard_returns_aggregates_and_safe_recent_activity_to_colaborador(self):
        LogAcao.objects.create(
            usuario=self.colaborador,
            acao="MOVIMENTAR",
            entidade="Ativo",
            entidade_id=str(self.ativo.pk),
            detalhes={"local_anterior": "Interno"},
            ip="192.0.2.1",
        )

        response = self.authenticate(self.colaborador).get("/api/dashboard/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["totals"], {
            "users": 2,
            "laboratories": 1,
            "assets": 1,
            "service_orders": 0,
        })
        self.assertEqual(sum(response.data["weekly_activity"]["values"]), 1)
        self.assertEqual(response.data["asset_distribution"], {
            "labels": ["Laboratório 1"],
            "values": [1],
        })
        activity = response.data["recent_activities"][0]
        self.assertEqual(activity["title"], f"Colaborador Atlas movimentou Ativo #{self.ativo.pk}")
        self.assertEqual(activity["entity_id"], str(self.ativo.pk))
        self.assertNotIn("ip", activity)
        self.assertNotIn("detalhes", activity)
        self.assertEqual(APIClient().get("/api/dashboard/").status_code, 401)

    def test_login_issues_token_accepted_by_me_endpoint(self):
        client = APIClient()
        response = client.post(
            "/api/auth/login/",
            {"email": self.admin.email, "senha": "senha-segura-123"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn("token", response.data)
        client.credentials(HTTP_AUTHORIZATION=f"Token {response.data['token']}")
        me_response = client.get("/api/auth/me/")
        self.assertEqual(me_response.status_code, 200)
        self.assertEqual(me_response.data["id_user"], self.admin.pk)

    def test_public_signup_creates_pending_request_with_hashed_password(self):
        response = APIClient().post(
            "/api/auth/cadastro/",
            {"nome": "Nova Colaboradora", "email": "NOVA@example.com", "senha": "senha-nova-123"},
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertNotIn("token", response.data)
        self.assertFalse(Usuario.objects.filter(email__iexact="nova@example.com").exists())
        solicitacao = SolicitacaoCadastro.objects.get(email="nova@example.com")
        self.assertNotEqual(solicitacao.senha_hash, "senha-nova-123")
        self.assertTrue(check_password("senha-nova-123", solicitacao.senha_hash))

    def test_public_signup_creates_admin_notification_that_can_be_marked_read(self):
        APIClient().post(
            "/api/auth/cadastro/",
            {"nome": "Nova Colaboradora", "email": "NOVA@example.com", "senha": "senha-nova-123"},
            format="json",
        )
        client = self.authenticate(self.admin)

        listed = client.get("/api/auth/notificacoes/")
        notification = listed.data[0]
        marked = client.post(f"/api/auth/notificacoes/{notification['id']}/lida/")

        self.assertEqual(listed.status_code, 200)
        self.assertEqual(notification["entidade"], "SolicitacaoCadastro")
        self.assertEqual(notification["destino"], {
            "name": "Users",
            "query": {"tab": "requests", "requestId": str(SolicitacaoCadastro.objects.get().pk)},
        })
        self.assertTrue(marked.data["lida"])

    def test_audited_asset_creation_creates_notification_with_direct_target(self):
        client = self.authenticate(self.admin)
        created = client.post(
            "/api/ativos/",
            {
                "nome": "Projetor notificado",
                "local_origem": self.sala.pk,
                "local_atual": self.sala.pk,
                "grupo": self.grupo.pk,
                "status": True,
            },
            format="json",
        )

        listed = client.get("/api/auth/notificacoes/")

        self.assertEqual(created.status_code, 201)
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data[0]["destino"], {
            "name": "Labs",
            "query": {"tab": "assets", "assetId": str(created.data["id_ativos"])},
        })

    def test_notifications_expire_one_day_after_read_and_are_admin_only(self):
        now = timezone.now()
        old_read = Notificacao.objects.create(
            usuario=self.admin,
            mensagem="Notificação antiga",
            acao="CRIAR",
            entidade="Ativo",
            lida_em=now - timedelta(hours=25),
        )
        recent_read = Notificacao.objects.create(
            usuario=self.admin,
            mensagem="Notificação lida recentemente",
            acao="CRIAR",
            entidade="Ativo",
            lida_em=now - timedelta(hours=23),
        )
        unread = Notificacao.objects.create(
            usuario=self.admin,
            mensagem="Notificação não lida",
            acao="CRIAR",
            entidade="Ativo",
        )

        listed = self.authenticate(self.admin).get("/api/auth/notificacoes/")
        denied = self.authenticate(self.colaborador).get("/api/auth/notificacoes/")

        self.assertEqual(listed.status_code, 200)
        self.assertCountEqual(
            [item["id"] for item in listed.data],
            [recent_read.pk, unread.pk],
        )
        self.assertFalse(Notificacao.objects.filter(pk=old_read.pk).exists())
        self.assertEqual(denied.status_code, 403)

    def test_signup_rejects_existing_or_pending_email(self):
        client = APIClient()
        payload = {"nome": "Nova Colaboradora", "email": self.admin.email, "senha": "senha-nova-123"}
        existing_response = client.post("/api/auth/cadastro/", payload, format="json")
        self.assertEqual(existing_response.status_code, 400)

        payload["email"] = "nova@example.com"
        self.assertEqual(client.post("/api/auth/cadastro/", payload, format="json").status_code, 201)
        payload["email"] = "NOVA@example.com"
        duplicate_response = client.post("/api/auth/cadastro/", payload, format="json")
        self.assertEqual(duplicate_response.status_code, 400)

    def test_only_admin_can_list_approve_or_reject_signup_requests(self):
        solicitacao = SolicitacaoCadastro.objects.create(
            nome="Nova Colaboradora",
            email="nova@example.com",
            senha_hash=make_password("senha-nova-123"),
        )
        client = self.authenticate(self.colaborador)

        self.assertEqual(client.get("/api/auth/solicitacoes/").status_code, 403)
        self.assertEqual(
            client.post(f"/api/auth/solicitacoes/{solicitacao.pk}/aprovar/").status_code,
            403,
        )
        self.assertEqual(client.delete(f"/api/auth/solicitacoes/{solicitacao.pk}/").status_code, 403)

    def test_admin_can_approve_signup_as_colaborador_and_reject_request(self):
        solicitacao = SolicitacaoCadastro.objects.create(
            nome="Nova Colaboradora",
            email="nova@example.com",
            senha_hash=make_password("senha-nova-123"),
        )
        client = self.authenticate(self.admin)

        listed = client.get("/api/auth/solicitacoes/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data[0]["nome"], "Nova Colaboradora")
        approved = client.post(f"/api/auth/solicitacoes/{solicitacao.pk}/aprovar/")
        self.assertEqual(approved.status_code, 201)
        usuario = Usuario.objects.get(email="nova@example.com")
        self.assertEqual(usuario.cargo, Cargo.COLABORADOR)
        self.assertTrue(check_password("senha-nova-123", usuario.senha))
        self.assertFalse(SolicitacaoCadastro.objects.filter(pk=solicitacao.pk).exists())
        notifications = client.get("/api/auth/notificacoes/")
        approval_notification = next(
            item for item in notifications.data if item["acao"] == "APROVAR"
        )
        self.assertEqual(approval_notification["destino"], {
            "name": "Users",
            "query": {"userId": str(usuario.pk)},
        })

        rejeitada = SolicitacaoCadastro.objects.create(
            nome="Outra Colaboradora",
            email="outra@example.com",
            senha_hash=make_password("senha-outra-123"),
        )
        rejected = client.delete(f"/api/auth/solicitacoes/{rejeitada.pk}/")
        self.assertEqual(rejected.status_code, 204)
        self.assertFalse(SolicitacaoCadastro.objects.filter(pk=rejeitada.pk).exists())

    def test_colaborador_can_open_service_order(self):
        client = self.authenticate(self.colaborador)
        response = client.post(
            "/api/ordens-servico/",
            {
                "titulo": "Inspecionar equipamento",
                "descricao": "Verificar o notebook do laboratório.",
                "data_hora": "2026-11-06T09:00:00-03:00",
                "data_termino": "2026-11-08",
                "usuario_ids": [],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        ordem = OrdemServico.objects.get(pk=response.data["id_ordem"])
        self.assertEqual(list(ordem.usuarios.all()), [self.colaborador])
        self.assertEqual(response.data["data_termino"], "2026-11-08")

    def test_service_order_can_be_created_with_responsible(self):
        tecnico = Usuario.objects.create(
            nome="Técnico Atlas",
            email="tecnico@example.com",
            cargo=Cargo.TECNICO,
            senha=make_password("senha-segura-123"),
        )

        response = self.authenticate(self.admin).post(
            "/api/ordens-servico/",
            {
                "titulo": "Manutenção do notebook",
                "descricao": "Verificar o equipamento.",
                "responsavel": tecnico.pk,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["responsavel"], tecnico.pk)
        self.assertEqual(response.data["responsavel_detalhes"]["nome"], "Técnico Atlas")

    def test_service_orders_are_listed_newest_first(self):
        older_order = OrdemServico.objects.create(
            titulo="Ordem antiga",
            descricao="Descrição da ordem antiga.",
        )
        newer_order = OrdemServico.objects.create(
            titulo="Ordem nova",
            descricao="Descrição da ordem nova.",
        )

        response = self.authenticate(self.admin).get("/api/ordens-servico/")
        orders = response.data.get("results", response.data)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [order["id_ordem"] for order in orders],
            [newer_order.pk, older_order.pk],
        )

    def test_service_order_cannot_be_completed_without_completion_description(self):
        order = OrdemServico.objects.create(
            titulo="Manutenção do equipamento",
            descricao="Equipamento com falha.",
        )

        response = self.authenticate(self.admin).patch(
            f"/api/ordens-servico/{order.pk}/",
            {
                "status": OrdemServico.Status.CONCLUIDA,
                "descricao_conclusao": " \n ",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("descricao_conclusao", response.data)
        order.refresh_from_db()
        self.assertEqual(order.status, OrdemServico.Status.ABERTA)

    def test_service_order_completion_saves_completion_description_separately(self):
        order = OrdemServico.objects.create(
            titulo="Manutenção do equipamento",
            descricao="Equipamento com falha.",
        )

        response = self.authenticate(self.admin).patch(
            f"/api/ordens-servico/{order.pk}/",
            {
                "status": OrdemServico.Status.CONCLUIDA,
                "descricao_conclusao": "  Cabo substituído e equipamento testado.  ",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        order.refresh_from_db()
        self.assertEqual(order.status, OrdemServico.Status.CONCLUIDA)
        self.assertEqual(order.descricao, "Equipamento com falha.")
        self.assertEqual(order.descricao_conclusao, "Cabo substituído e equipamento testado.")

    def test_asset_movement_updates_location_and_audit(self):
        client = self.authenticate(self.admin)
        sala_destino = SalaLab.objects.create(
            nome="Laboratório 2",
            numero_ta=2,
            localizacao="B-102",
        )
        response = client.post(
            f"/api/ativos/{self.ativo.pk}/movimentar/",
            {
                "local_m": sala_destino.localizacao,
                "sala_id": sala_destino.pk,
                "justificativa": "Transferência para testes",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.ativo.refresh_from_db()
        self.assertEqual(self.ativo.local_atual, sala_destino)
        self.assertEqual(self.ativo.local_atual_id, sala_destino.pk)
        self.assertEqual(MovimentacoesA.objects.filter(ativo=self.ativo).count(), 1)
        log = LogAcao.objects.get(entidade="Ativo", entidade_id=str(self.ativo.pk))
        self.assertEqual(log.acao, "MOVIMENTAR")
        self.assertEqual(log.detalhes["local_anterior"], "Laboratório 1")

    def test_only_admin_can_permanently_clear_movement_history(self):
        MovimentacoesA.objects.create(
            justificativa="Transferência para testes",
            local_m=self.sala.localizacao,
            usuario=self.colaborador,
            ativo=self.ativo,
        )

        denied = self.authenticate(self.colaborador).delete("/api/movimentacoes/limpar-historico/")
        self.assertEqual(denied.status_code, 403)
        self.assertEqual(MovimentacoesA.objects.count(), 1)

        response = self.authenticate(self.admin).delete("/api/movimentacoes/limpar-historico/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {"removidas": 1})
        self.assertEqual(MovimentacoesA.objects.count(), 0)
        log = LogAcao.objects.get(acao="LIMPAR_HISTORICO")
        self.assertEqual(log.detalhes["quantidade"], 1)

    def test_asset_crud_uses_qr_group_location_and_room_fields(self):
        client = self.authenticate(self.admin)
        sala = SalaLab.objects.create(
            nome="Laboratório de testes",
            numero_ta=101,
            localizacao="B-101",
        )
        created = client.post(
            "/api/ativos/",
            {
                "nome": "Projetor de testes",
                "local_origem": sala.pk,
                "local_atual": sala.pk,
                "grupo": self.grupo.pk,
                "descricao": "Projetor para testes da API.",
                "status": True,
            },
            format="json",
        )

        self.assertEqual(created.status_code, 201)
        self.assertIn("id_ativos", created.data)
        self.assertTrue(created.data["qr_code"].startswith("ATLASLAB-"))
        self.assertEqual(created.data["grupo"], self.grupo.pk)
        self.assertEqual(created.data["grupo_detalhes"]["nome"], self.grupo.nome)
        self.assertEqual(created.data["local_origem"], sala.pk)
        self.assertEqual(created.data["local_origem_detalhes"]["localizacao"], sala.localizacao)
        self.assertEqual(created.data["local_atual"], sala.pk)

        sala_destino = SalaLab.objects.create(
            nome="Laboratório B-102",
            numero_ta=102,
            localizacao="B-102",
        )

        listed = client.get("/api/ativos/")
        self.assertEqual(listed.status_code, 200)
        self.assertIn(created.data["id_ativos"], {asset["id_ativos"] for asset in listed.data["results"]})

        updated = client.patch(
            f"/api/ativos/{created.data['id_ativos']}/",
            {"local_atual": sala_destino.pk, "status": False},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["local_atual"], sala_destino.pk)
        self.assertEqual(updated.data["local_atual_detalhes"]["localizacao"], sala_destino.localizacao)
        self.assertFalse(updated.data["status"])

        deleted = client.delete(f"/api/ativos/{created.data['id_ativos']}/")
        self.assertEqual(deleted.status_code, 204)
        self.assertFalse(Ativo.objects.filter(pk=created.data["id_ativos"]).exists())
        self.assertTrue(LogAcao.objects.filter(
            acao="EXCLUIR",
            entidade="Ativo",
            entidade_id=str(created.data["id_ativos"]),
        ).exists())

    def test_asset_qr_image_is_png_and_only_available_to_managers(self):
        url = f"/api/ativos/{self.ativo.pk}/qr-code-imagem/"

        response = self.authenticate(self.admin).get(url)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "image/png")
        self.assertTrue(response.content.startswith(b"\x89PNG\r\n\x1a\n"))

        denied = self.authenticate(self.colaborador).get(url)
        self.assertEqual(denied.status_code, 403)

    def test_asset_can_be_looked_up_by_qr_code(self):
        client = self.authenticate(self.colaborador)

        found = client.get("/api/ativos/por-qr/", {"codigo": self.ativo.qr_code})
        missing_code = client.get("/api/ativos/por-qr/")
        unknown_code = client.get("/api/ativos/por-qr/", {"codigo": "ATLASLAB-INVALIDO"})

        self.assertEqual(found.status_code, 200)
        self.assertEqual(found.data["id_ativos"], self.ativo.pk)
        self.assertEqual(found.data["qr_code"], self.ativo.qr_code)
        self.assertEqual(missing_code.status_code, 400)
        self.assertEqual(unknown_code.status_code, 404)

    def test_asset_with_service_order_cannot_be_deleted(self):
        order = OrdemServico.objects.create(
            titulo="Manutenção de teste",
            descricao="OS vinculada ao ativo.",
        )
        order.ativos.add(self.ativo)
        movement = MovimentacoesA.objects.create(
            justificativa="Transferência para manutenção.",
            local_m=self.sala.localizacao,
            usuario=self.admin,
            ativo=self.ativo,
        )

        response = self.authenticate(self.admin).delete(f"/api/ativos/{self.ativo.pk}/")

        self.assertEqual(response.status_code, 409)
        self.assertEqual(response.data["movimentacoes"][0]["id_mov"], movement.pk)
        self.assertEqual(response.data["ordens_servico"][0]["id_ordem"], order.pk)
        self.assertTrue(Ativo.objects.filter(pk=self.ativo.pk).exists())
        self.assertFalse(LogAcao.objects.filter(
            acao="EXCLUIR",
            entidade="Ativo",
            entidade_id=str(self.ativo.pk),
        ).exists())

    def test_force_delete_removes_asset_movements_and_order_links_only(self):
        order = OrdemServico.objects.create(
            titulo="Manutenção de teste",
            descricao="OS vinculada ao ativo.",
        )
        order.ativos.add(self.ativo)
        MovimentacoesA.objects.create(
            justificativa="Transferência para manutenção.",
            local_m=self.sala.localizacao,
            usuario=self.admin,
            ativo=self.ativo,
        )

        response = self.authenticate(self.admin).delete(
            f"/api/ativos/{self.ativo.pk}/?force=true"
        )

        self.assertEqual(response.status_code, 204)
        self.assertFalse(Ativo.objects.filter(pk=self.ativo.pk).exists())
        self.assertFalse(MovimentacoesA.objects.filter(ativo=self.ativo).exists())
        self.assertTrue(OrdemServico.objects.filter(pk=order.pk).exists())
        self.assertFalse(order.vinculos_ativos.exists())

    def test_laboratory_crud_uses_paginated_salas_contract(self):
        client = self.authenticate(self.admin)
        created = client.post(
            "/api/salas/",
            {
                "nome": "Laboratório de testes",
                "numero_ta": 101,
                "localizacao": "B-101",
                "responsavel": self.admin.pk,
            },
            format="json",
        )

        self.assertEqual(created.status_code, 201)
        self.assertIn("id_sala", created.data)
        self.assertEqual(created.data["numero_ta"], 101)
        self.assertEqual(created.data["responsavel"], self.admin.pk)
        self.assertEqual(created.data["responsavel_detalhes"]["nome"], self.admin.nome)

        listed = client.get("/api/salas/")
        self.assertEqual(listed.status_code, 200)
        self.assertIn(
            created.data["id_sala"],
            {sala["id_sala"] for sala in listed.data["results"]},
        )

        updated = client.patch(
            f"/api/salas/{created.data['id_sala']}/",
            {"nome": "Laboratório atualizado", "numero_ta": 102},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["nome"], "Laboratório atualizado")
        self.assertEqual(updated.data["numero_ta"], 102)

        deleted = client.delete(f"/api/salas/{created.data['id_sala']}/")
        self.assertEqual(deleted.status_code, 204)
        self.assertFalse(SalaLab.objects.filter(pk=created.data["id_sala"]).exists())

    def test_laboratory_with_assets_returns_conflict_details(self):
        order = OrdemServico.objects.create(
            titulo="Manutenção do laboratório",
            descricao="OS vinculada ao laboratório.",
        )
        order.salas.add(self.sala)

        response = self.authenticate(self.admin).delete(f"/api/salas/{self.sala.pk}/")

        self.assertEqual(response.status_code, 409)
        self.assertEqual(response.data["detail"], "Não é possível excluir este laboratório enquanto houver ativos ou ordens de serviço vinculados.")
        self.assertEqual(response.data["ativos"][0]["id_ativos"], self.ativo.pk)
        self.assertEqual(response.data["ordens_servico"][0]["id_ordem"], order.pk)
        self.assertTrue(SalaLab.objects.filter(pk=self.sala.pk).exists())

    def test_asset_group_can_be_created_and_updated_by_staff_only(self):
        client = self.authenticate(self.admin)
        created = client.post(
            "/api/grupos/",
            {"nome": "Equipamentos", "numero_ta": 2, "tipo": "Equipamento", "setor": "TI"},
            format="json",
        )

        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.data["nome"], "Equipamentos")
        updated = client.patch(
            f"/api/grupos/{created.data['id_grupo_a']}/",
            {"setor": "Infraestrutura"},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["setor"], "Infraestrutura")

        denied = self.authenticate(self.colaborador).post(
            "/api/grupos/",
            {"nome": "Outro grupo", "numero_ta": 3, "tipo": "Equipamento", "setor": "TI"},
            format="json",
        )
        self.assertEqual(denied.status_code, 403)

    def test_sala_responsible_options_are_available_to_admin_and_technician_only(self):
        technician = Usuario.objects.create(
            nome="Técnico Atlas",
            email="tecnico@example.com",
            cargo=Cargo.TECNICO,
            senha=make_password("senha-segura-123"),
        )

        response = self.authenticate(technician).get("/api/usuarios/responsaveis/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual({user["id_user"] for user in response.data}, {self.admin.pk, self.colaborador.pk, technician.pk})
        self.assertNotIn("email", response.data[0])
        self.assertEqual(
            self.authenticate(self.colaborador).get("/api/usuarios/responsaveis/").status_code,
            403,
        )
