import hashlib
from datetime import timedelta

from django.contrib.auth.hashers import check_password, make_password
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    ApiToken, Ativo, Cargo, GrupoA, LogAcao, MovimentacoesA,
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
        self.assertEqual(deleted.status_code, 405)

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
