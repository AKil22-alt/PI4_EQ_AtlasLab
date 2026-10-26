import hashlib
from datetime import timedelta

from django.contrib.auth.hashers import make_password
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import ApiToken, Ativo, Cargo, GrupoA, LogAcao, MovimentacoesA, OrdemServico, Usuario


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
