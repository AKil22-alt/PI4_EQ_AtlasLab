import hashlib
from datetime import timedelta
from io import BytesIO

import qrcode
from django.contrib.auth.hashers import check_password
from django.db import transaction
from django.db.models.deletion import ProtectedError
from django.db.models import Count, Q
from django.db.models.functions import TruncDate
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .audit import registrar_acao
from .models import (
    ApiToken,
    Ativo,
    Cargo,
    DenunciaF,
    GrupoA,
    LogAcao,
    ManutencaoA,
    MovimentacoesA,
    OSAtivo,
    OSSalaLab,
    OrdemServico,
    SalaLab,
    SolicitacaoCadastro,
    Usuario,
)
from .permissions import ADMIN, TODOS, TECNICO, CargoPermission
from .serializers import (
    AtivoSerializer,
    CadastroSerializer,
    DenunciaFSerializer,
    GrupoASerializer,
    LogAcaoSerializer,
    LoginSerializer,
    ManutencaoASerializer,
    MovimentacoesASerializer,
    OrdemServicoSerializer,
    ResponsavelSalaSerializer,
    SalaLabSerializer,
    SolicitacaoCadastroSerializer,
    UsuarioSerializer,
)


class HealthView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({"status": "ok"})


class DashboardView(APIView):
    permission_classes = [IsAuthenticated, CargoPermission]
    roles_read = TODOS

    def get(self, request):
        today = timezone.localdate()
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=7)
        activity_logs = LogAcao.objects.exclude(acao__in=["LOGIN", "LOGOUT"])

        weekly_counts = activity_logs.filter(
            criado_em__date__gte=week_start,
            criado_em__date__lt=week_end,
        ).annotate(day=TruncDate("criado_em")).values("day").annotate(total=Count("id"))
        weekly_values = [0] * 7
        for item in weekly_counts:
            day_index = (item["day"] - week_start).days
            weekly_values[day_index] = item["total"]

        asset_distribution = Ativo.objects.values(
            "local_atual__localizacao"
        ).annotate(total=Count("id_ativos")).order_by("local_atual__localizacao")
        recent_activities = [
            self._serialize_activity(log)
            for log in activity_logs.select_related("usuario")[:4]
        ]

        return Response({
            "totals": {
                "users": Usuario.objects.count(),
                "laboratories": SalaLab.objects.count(),
                "assets": Ativo.objects.count(),
                "service_orders": OrdemServico.objects.count(),
            },
            "weekly_activity": {
                "labels": ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"],
                "values": weekly_values,
            },
            "asset_distribution": {
                "labels": [item["local_atual__localizacao"] for item in asset_distribution],
                "values": [item["total"] for item in asset_distribution],
            },
            "recent_activities": recent_activities,
        })

    @staticmethod
    def _serialize_activity(log):
        actor = log.usuario.nome if log.usuario else "Usuário"
        entity_names = {
            "Ativo": "Ativo",
            "OrdemServico": "Ordem de Serviço",
            "SalaLab": "Laboratório",
            "Usuario": "Usuário",
            "GrupoA": "Grupo de Ativos",
            "ManutencaoA": "Manutenção",
            "MovimentacoesA": "Movimentação",
            "DenunciaF": "Denúncia",
            "SolicitacaoCadastro": "Solicitação de Cadastro",
        }
        action_verbs = {
            "CRIAR": "criou",
            "ATUALIZAR": "atualizou",
            "EXCLUIR": "removeu",
            "MOVIMENTAR": "movimentou",
            "ATIVAR": "ativou",
            "INATIVAR": "inativou",
            "APROVAR": "aprovou",
        }
        entity = entity_names.get(log.entidade, log.entidade)
        verb = action_verbs.get(log.acao, "registrou uma ação em")
        suffix = f" #{log.entidade_id}" if log.entidade_id else ""
        return {
            "id": log.pk,
            "entity_id": log.entidade_id,
            "title": f"{actor} {verb} {entity}{suffix}",
            "created_at": log.criado_em,
            "type": log.entidade,
        }


class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "login"

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = Usuario.objects.filter(email__iexact=serializer.validated_data["email"]).first()
        if user is None or not check_password(serializer.validated_data["senha"], user.senha):
            return Response(
                {"detail": "E-mail ou senha inválidos."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        raw_token = ApiToken.gerar_token()
        ApiToken.objects.create(
            usuario=user,
            token_hash=hashlib.sha256(raw_token.encode("utf-8")).hexdigest(),
            expira_em=timezone.now() + timedelta(hours=12),
        )
        registrar_acao(request, "LOGIN", "Usuario", user.pk)
        return Response(
            {"token": raw_token, "usuario": UsuarioSerializer(user).data},
            status=status.HTTP_200_OK,
        )


class CadastroView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = CadastroSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {"detail": "Cadastro enviado. Aguarde a aprovação do administrador."},
            status=status.HTTP_201_CREATED,
        )


class SolicitacoesCadastroView(APIView):
    permission_classes = [IsAuthenticated, CargoPermission]
    roles_read = ADMIN

    def get(self, request):
        solicitacoes = SolicitacaoCadastro.objects.all().order_by("-criada_em", "-id")
        serializer = SolicitacaoCadastroSerializer(solicitacoes, many=True)
        return Response(serializer.data)


class SolicitacaoCadastroActionView(APIView):
    permission_classes = [IsAuthenticated, CargoPermission]
    roles_create = ADMIN
    roles_write = ADMIN

    def post(self, request, solicitacao_id):
        with transaction.atomic():
            solicitacao = get_object_or_404(
                SolicitacaoCadastro.objects.select_for_update(), pk=solicitacao_id
            )
            if Usuario.objects.filter(email__iexact=solicitacao.email).exists():
                return Response(
                    {"email": ["Este e-mail já está cadastrado."]},
                    status=status.HTTP_409_CONFLICT,
                )
            usuario = Usuario.objects.create(
                nome=solicitacao.nome,
                email=solicitacao.email,
                cargo=Cargo.COLABORADOR,
                senha=solicitacao.senha_hash,
            )
            registrar_acao(request, "APROVAR", "SolicitacaoCadastro", solicitacao.pk)
            solicitacao.delete()

        return Response(UsuarioSerializer(usuario).data, status=status.HTTP_201_CREATED)

    def delete(self, request, solicitacao_id):
        solicitacao = get_object_or_404(SolicitacaoCadastro, pk=solicitacao_id)
        solicitacao.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated, CargoPermission]

    def post(self, request):
        token = request.auth
        if isinstance(token, ApiToken):
            token.delete()
        registrar_acao(request, "LOGOUT", "Usuario", request.user.pk)
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(APIView):
    permission_classes = [IsAuthenticated, CargoPermission]

    def get(self, request):
        return Response(UsuarioSerializer(request.user).data)


class AuditedModelViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, CargoPermission]
    filter_backends = [filters.SearchFilter]
    roles_read = TODOS
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = ""

    def perform_create(self, serializer):
        with transaction.atomic():
            instance = serializer.save()
            registrar_acao(
                self.request,
                "CRIAR",
                self.entity_name,
                instance.pk,
            )

    def perform_update(self, serializer):
        with transaction.atomic():
            instance = serializer.save()
            registrar_acao(
                self.request,
                "ATUALIZAR",
                self.entity_name,
                instance.pk,
            )

    def perform_destroy(self, instance):
        with transaction.atomic():
            object_id = instance.pk
            instance.delete()
            registrar_acao(self.request, "EXCLUIR", self.entity_name, object_id)


class UsuarioViewSet(AuditedModelViewSet):
    queryset = Usuario.objects.all().order_by("-id_user")
    serializer_class = UsuarioSerializer
    lookup_field = "id_user"
    roles_read = ADMIN
    roles_create = ADMIN
    roles_write = ADMIN
    entity_name = "Usuario"
    search_fields = ["nome", "email"]

    def get_permissions(self):
        self.action_roles = {"responsaveis": TECNICO}
        return super().get_permissions()

    @action(detail=False, methods=["get"], url_path="responsaveis")
    def responsaveis(self, request):
        usuarios = Usuario.objects.all().order_by("nome", "id_user")
        serializer = ResponsavelSalaSerializer(usuarios, many=True)
        return Response(serializer.data)


class GrupoAViewSet(AuditedModelViewSet):
    queryset = GrupoA.objects.all().order_by("id_grupo_a")
    serializer_class = GrupoASerializer
    lookup_field = "id_grupo_a"
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "GrupoA"
    search_fields = ["nome", "tipo", "setor"]


class SalaLabViewSet(AuditedModelViewSet):
    queryset = SalaLab.objects.select_related("responsavel").all().order_by("-id_sala")
    serializer_class = SalaLabSerializer
    lookup_field = "id_sala"
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "SalaLab"
    search_fields = ["nome", "localizacao", "descricao"]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        try:
            self.perform_destroy(instance)
        except ProtectedError:
            assets = list(
                Ativo.objects.filter(Q(local_origem=instance) | Q(local_atual=instance))
                .order_by("id_ativos")
                .values("id_ativos", "nome", "qr_code")
            )
            service_orders = list(
                OSSalaLab.objects.filter(sala=instance)
                .select_related("ordem_servico")
                .order_by("ordem_servico__id_ordem")
                .values(
                    "ordem_servico__id_ordem",
                    "ordem_servico__titulo",
                    "ordem_servico__status",
                    "ordem_servico__data_hora",
                )
            )
            return Response(
                {
                    "detail": "Não é possível excluir este laboratório enquanto houver ativos ou ordens de serviço vinculados.",
                    "ativos": assets,
                    "ordens_servico": [
                        {
                            "id_ordem": order["ordem_servico__id_ordem"],
                            "titulo": order["ordem_servico__titulo"],
                            "status": order["ordem_servico__status"],
                            "data_hora": order["ordem_servico__data_hora"],
                        }
                        for order in service_orders
                    ],
                },
                status=status.HTTP_409_CONFLICT,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


class AtivoViewSet(AuditedModelViewSet):
    serializer_class = AtivoSerializer
    lookup_field = "id_ativos"
    http_method_names = ["get", "post", "put", "patch", "delete", "head", "options"]
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "Ativo"
    search_fields = [
        "nome", "qr_code", "local_atual__localizacao", "local_origem__localizacao", "descricao"
    ]

    def get_queryset(self):
        queryset = Ativo.objects.select_related(
            "grupo", "local_origem", "local_atual"
        ).all().order_by("-id_ativos")
        status_param = self.request.query_params.get("status")
        if status_param is not None:
            normalized_status = status_param.strip().lower()
            if normalized_status in {"ativo", "true", "1"}:
                queryset = queryset.filter(status=True)
            elif normalized_status in {"inativo", "false", "0"}:
                queryset = queryset.filter(status=False)
            else:
                raise ValidationError(
                    {"status": "Use 'ativo', 'inativo', 'true' ou 'false'."}
                )
        grupo_id = self.request.query_params.get("grupo")
        if grupo_id:
            queryset = queryset.filter(grupo_id=grupo_id)
        sala_id = self.request.query_params.get("sala") or self.request.query_params.get("local_atual")
        if sala_id:
            queryset = queryset.filter(local_atual_id=sala_id)
        local_origem_id = self.request.query_params.get("local_origem")
        if local_origem_id:
            queryset = queryset.filter(local_origem_id=local_origem_id)
        return queryset

    def perform_destroy(self, instance):
        try:
            super().perform_destroy(instance)
        except ProtectedError as error:
            exception = APIException(
                "Não é possível excluir este ativo porque existem movimentações ou ordens de serviço vinculadas."
            )
            exception.status_code = status.HTTP_409_CONFLICT
            raise exception from error

    def destroy(self, request, *args, **kwargs):
        force_delete = request.query_params.get("force", "").lower() in {"1", "true", "yes"}

        with transaction.atomic():
            instance = self.get_object()
            movements = list(
                MovimentacoesA.objects.filter(ativo=instance)
                .order_by("data_hora", "id_mov")
                .values("id_mov", "data_hora", "local_m", "justificativa")
            )
            order_links = list(
                OSAtivo.objects.filter(ativo=instance)
                .select_related("ordem_servico")
                .order_by("ordem_servico__id_ordem")
            )
            orders = [
                {
                    "id_ordem": link.ordem_servico_id,
                    "titulo": link.ordem_servico.titulo,
                    "status": link.ordem_servico.status,
                    "data_hora": link.ordem_servico.data_hora,
                }
                for link in order_links
            ]

            if (movements or orders) and not force_delete:
                return Response(
                    {
                        "detail": "Este ativo possui movimentações ou ordens de serviço vinculadas.",
                        "movimentacoes": movements,
                        "ordens_servico": orders,
                    },
                    status=status.HTTP_409_CONFLICT,
                )

            if force_delete:
                MovimentacoesA.objects.filter(ativo=instance).delete()
                OSAtivo.objects.filter(ativo=instance).delete()

            self.perform_destroy(instance)

        return Response(status=status.HTTP_204_NO_CONTENT)

    def get_permissions(self):
        self.action_roles = {
            "movimentar": TODOS,
            "qr_code_imagem": TECNICO,
            "qr_code": TECNICO,
        }
        return super().get_permissions()

    @action(detail=False, methods=["get"], url_path="por-qr")
    def por_qr(self, request):
        codigo = request.query_params.get("codigo", "").strip()
        if not codigo:
            return Response(
                {"codigo": ["Este parâmetro é obrigatório."]},
                status=status.HTTP_400_BAD_REQUEST,
            )
        ativo = get_object_or_404(self.get_queryset(), qr_code=codigo)
        return Response(self.get_serializer(ativo).data)

    def _qr_code_image(self, ativo):
        image = qrcode.make(ativo.qr_code)
        image_buffer = BytesIO()
        image.save(image_buffer, format="PNG")
        response = HttpResponse(image_buffer.getvalue(), content_type="image/png")
        response["Content-Disposition"] = f'inline; filename="ativo-{ativo.pk}.png"'
        return response

    @action(detail=True, methods=["get"], url_path="qr-code-imagem")
    def qr_code_imagem(self, request, id_ativos=None):
        return self._qr_code_image(self.get_object())

    @action(detail=True, methods=["get"], url_path="qr-code")
    def qr_code(self, request, id_ativos=None):
        return self._qr_code_image(self.get_object())

    @action(detail=True, methods=["post"])
    def movimentar(self, request, id_ativos=None):
        ativo = self.get_object()
        data = request.data.copy()
        sala_id = data.pop("sala_id", None)
        if isinstance(sala_id, list):
            sala_id = sala_id[0] if sala_id else None

        sala = None
        if sala_id:
            sala = get_object_or_404(SalaLab, pk=sala_id)
        else:
            local = data.get("local_m", "").strip()
            salas = SalaLab.objects.filter(localizacao=local)
            if salas.count() != 1:
                raise ValidationError({"sala_id": "Informe um laboratório cadastrado como destino."})
            sala = salas.first()

        data["local_m"] = sala.localizacao
        data["ativo"] = ativo.pk
        serializer = MovimentacoesASerializer(data=data)
        serializer.is_valid(raise_exception=True)
        local_anterior = ativo.local_atual.localizacao
        with transaction.atomic():
            movimentacao = serializer.save(usuario=request.user, ativo=ativo)
            ativo.local_atual = sala
            ativo.save(update_fields=["local_atual", "atualizado_em"])
            registrar_acao(
                request,
                "MOVIMENTAR",
                "Ativo",
                ativo.pk,
                {"local_anterior": local_anterior, "local_atual": sala.localizacao},
            )

        return Response(
            MovimentacoesASerializer(movimentacao).data,
            status=status.HTTP_201_CREATED,
        )

    def _set_active_status(self, request, ativo, active):
        if ativo.status == active:
            return Response(
                {"detail": "O ativo já está " + ("ativo." if active else "inativo.")},
                status=status.HTTP_400_BAD_REQUEST,
            )
        with transaction.atomic():
            ativo.status = active
            ativo.save(update_fields=["status", "atualizado_em"])
            registrar_acao(
                request,
                "ATIVAR" if active else "INATIVAR",
                "Ativo",
                ativo.pk,
            )
        return Response(self.get_serializer(ativo).data)

    @action(detail=True, methods=["post"])
    def inativar(self, request, id_ativos=None):
        return self._set_active_status(request, self.get_object(), False)

    @action(detail=True, methods=["post"])
    def ativar(self, request, id_ativos=None):
        return self._set_active_status(request, self.get_object(), True)

    @action(detail=True, methods=["post"])
    def reativar(self, request, id_ativos=None):
        return self._set_active_status(request, self.get_object(), True)

    @action(detail=True, methods=["get"])
    def historico(self, request, id_ativos=None):
        ativo = self.get_object()
        movimentacoes = MovimentacoesA.objects.filter(ativo=ativo).select_related(
            "usuario", "ativo", "manutencao"
        )
        ordens = OrdemServico.objects.filter(ativos=ativo).prefetch_related(
            "usuarios", "salas", "ativos", "manutencoes"
        )
        return Response({
            "movimentacoes": MovimentacoesASerializer(movimentacoes, many=True).data,
            "ordens_servico": OrdemServicoSerializer(ordens, many=True).data,
        })


class OrdemServicoViewSet(AuditedModelViewSet):
    queryset = OrdemServico.objects.select_related("responsavel").prefetch_related(
        "usuarios", "salas", "ativos", "manutencoes"
    ).order_by("-id_ordem")
    serializer_class = OrdemServicoSerializer
    lookup_field = "id_ordem"
    entity_name = "OrdemServico"
    search_fields = ["titulo", "descricao", "status"]

    def get_queryset(self):
        queryset = super().get_queryset()
        if getattr(self.request.user, "cargo", None) == "CLB":
            queryset = queryset.filter(usuarios=self.request.user)
        status_param = self.request.query_params.get("status")
        if status_param:
            queryset = queryset.filter(status=status_param)
        return queryset.distinct()

    def get_permissions(self):
        self.action_roles = {"create": TODOS}
        return super().get_permissions()

    def perform_create(self, serializer):
        with transaction.atomic():
            if getattr(self.request.user, "cargo", None) == "CLB":
                serializer.validated_data["usuarios"] = [self.request.user]
            ordem = serializer.save()
            registrar_acao(self.request, "CRIAR", self.entity_name, ordem.pk)


class ManutencaoAViewSet(AuditedModelViewSet):
    queryset = ManutencaoA.objects.all().order_by("id_man")
    serializer_class = ManutencaoASerializer
    lookup_field = "id_man"
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "ManutencaoA"
    search_fields = ["tipo", "descricao", "numero_tag"]


class MovimentacoesAViewSet(AuditedModelViewSet):
    queryset = MovimentacoesA.objects.select_related(
        "usuario", "ativo", "manutencao"
    ).all().order_by("-data_hora", "-id_mov")
    serializer_class = MovimentacoesASerializer
    lookup_field = "id_mov"
    http_method_names = ["get", "post", "delete", "head", "options"]
    roles_create = TODOS
    roles_write = TODOS
    entity_name = "MovimentacoesA"
    search_fields = ["justificativa", "local_m", "ativo__nome", "ativo__qr_code"]

    def get_permissions(self):
        self.action_roles = {"limpar_historico": ADMIN}
        return super().get_permissions()

    def get_queryset(self):
        queryset = super().get_queryset()
        if getattr(self.request.user, "cargo", None) == "CLB":
            queryset = queryset.filter(usuario=self.request.user)
        ativo_id = self.request.query_params.get("ativo")
        if ativo_id:
            queryset = queryset.filter(ativo_id=ativo_id)
        return queryset

    def perform_create(self, serializer):
        with transaction.atomic():
            local = serializer.validated_data["local_m"].strip()
            salas = SalaLab.objects.filter(localizacao=local)
            if salas.count() != 1:
                raise ValidationError({"local_m": "O destino deve corresponder a um laboratório cadastrado."})
            sala = salas.first()
            serializer.validated_data["local_m"] = sala.localizacao
            movimentacao = serializer.save(usuario=self.request.user)
            ativo = movimentacao.ativo
            local_anterior = ativo.local_atual.localizacao
            ativo.local_atual = sala
            ativo.save(update_fields=["local_atual", "atualizado_em"])
            registrar_acao(
                self.request,
                "MOVIMENTAR",
                "Ativo",
                ativo.pk,
                {"local_anterior": local_anterior, "local_atual": ativo.local_atual.localizacao},
            )

    @action(detail=False, methods=["delete"], url_path="limpar-historico")
    def limpar_historico(self, request):
        with transaction.atomic():
            removidas, _ = MovimentacoesA.objects.all().delete()
            registrar_acao(
                request,
                "LIMPAR_HISTORICO",
                self.entity_name,
                detalhes={"quantidade": removidas},
            )
        return Response({"removidas": removidas}, status=status.HTTP_200_OK)


class DenunciaFViewSet(AuditedModelViewSet):
    queryset = DenunciaF.objects.select_related("usuario").all().order_by("-criado_em")
    serializer_class = DenunciaFSerializer
    lookup_field = "id_denuncia"
    http_method_names = ["get", "post", "head", "options"]
    roles_create = TODOS
    roles_write = TODOS
    entity_name = "DenunciaF"
    search_fields = ["descricao", "classificacao", "usuario__nome"]

    def get_queryset(self):
        queryset = super().get_queryset()
        if getattr(self.request.user, "cargo", None) == "CLB":
            queryset = queryset.filter(usuario=self.request.user)
        return queryset

    def perform_create(self, serializer):
        with transaction.atomic():
            denuncia = serializer.save(usuario=self.request.user)
            registrar_acao(self.request, "CRIAR", self.entity_name, denuncia.pk)


class LogAuditoriaViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = LogAcao.objects.select_related("usuario").all()
    serializer_class = LogAcaoSerializer
    permission_classes = [IsAuthenticated, CargoPermission]
    filter_backends = [filters.SearchFilter]
    roles_read = ADMIN
    roles_create = ADMIN
    roles_write = ADMIN
    search_fields = ["acao", "entidade", "entidade_id"]

    def get_queryset(self):
        queryset = super().get_queryset()
        entidade = self.request.query_params.get("entidade")
        if entidade:
            queryset = queryset.filter(entidade__iexact=entidade)
        return queryset
