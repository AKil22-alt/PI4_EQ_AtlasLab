import hashlib
from datetime import timedelta

from django.contrib.auth.hashers import check_password, make_password
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    ApiToken, Ativo, Cargo, GrupoA, LogAcao, MovimentacoesA,
    OrdemServico, SolicitacaoCadastro, Usuario,
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
        self.ativo = Ativo.objects.create(
            nome="Notebook de testes",
            local_origem="Laboratório 1",
            local_atual="Laboratório 1",
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
                "usuario_ids": [],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        ordem = OrdemServico.objects.get(pk=response.data["id_ordem"])
        self.assertEqual(list(ordem.usuarios.all()), [self.colaborador])

    def test_asset_movement_updates_location_and_audit(self):
        client = self.authenticate(self.admin)
        response = client.post(
            f"/api/ativos/{self.ativo.pk}/movimentar/",
            {
                "local_m": "Laboratório 2",
                "justificativa": "Transferência para testes",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.ativo.refresh_from_db()
        self.assertEqual(self.ativo.local_atual, "Laboratório 2")
        self.assertEqual(MovimentacoesA.objects.filter(ativo=self.ativo).count(), 1)
        log = LogAcao.objects.get(entidade="Ativo", entidade_id=str(self.ativo.pk))
        self.assertEqual(log.acao, "MOVIMENTAR")
        self.assertEqual(log.detalhes["local_anterior"], "Laboratório 1")
