import hashlib
from datetime import timedelta
from io import BytesIO

import qrcode
from django.contrib.auth.hashers import check_password
from django.db import transaction
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .audit import registrar_acao
from .models import (
    ApiToken,
    Ativo,
    DenunciaF,
    GrupoA,
    LogAcao,
    ManutencaoA,
    MovimentacoesA,
    OrdemServico,
    SalaLab,
    Usuario,
)
from .permissions import ADMIN, TODOS, TECNICO, CargoPermission
from .serializers import (
    AtivoSerializer,
    DenunciaFSerializer,
    GrupoASerializer,
    LogAcaoSerializer,
    LoginSerializer,
    ManutencaoASerializer,
    MovimentacoesASerializer,
    OrdemServicoSerializer,
    SalaLabSerializer,
    UsuarioSerializer,
)


class HealthView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({"status": "ok"})


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
    queryset = Usuario.objects.all().order_by("id_user")
    serializer_class = UsuarioSerializer
    lookup_field = "id_user"
    roles_read = ADMIN
    roles_create = ADMIN
    roles_write = ADMIN
    entity_name = "Usuario"
    search_fields = ["nome", "email"]


class GrupoAViewSet(AuditedModelViewSet):
    queryset = GrupoA.objects.all().order_by("id_grupo_a")
    serializer_class = GrupoASerializer
    lookup_field = "id_grupo_a"
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "GrupoA"
    search_fields = ["nome", "tipo", "setor"]


class SalaLabViewSet(AuditedModelViewSet):
    queryset = SalaLab.objects.select_related("responsavel").all().order_by("id_sala")
    serializer_class = SalaLabSerializer
    lookup_field = "id_sala"
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "SalaLab"
    search_fields = ["nome", "localizacao", "descricao"]


class AtivoViewSet(AuditedModelViewSet):
    serializer_class = AtivoSerializer
    lookup_field = "id_ativos"
    http_method_names = ["get", "post", "put", "patch", "head", "options"]
    roles_create = TECNICO
    roles_write = TECNICO
    entity_name = "Ativo"
    search_fields = ["nome", "qr_code", "local_atual", "local_origem", "descricao"]

    def get_queryset(self):
        queryset = Ativo.objects.select_related("grupo", "sala").all().order_by("id_ativos")
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
        sala_id = self.request.query_params.get("sala")
        if sala_id:
            queryset = queryset.filter(sala_id=sala_id)
        return queryset

    def get_permissions(self):
        self.action_roles = {"movimentar": TODOS}
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

        data["ativo"] = ativo.pk
        serializer = MovimentacoesASerializer(data=data)
        serializer.is_valid(raise_exception=True)
        destino = serializer.validated_data["local_m"]
        local_anterior = ativo.local_atual
        with transaction.atomic():
            movimentacao = serializer.save(usuario=request.user, ativo=ativo)
            ativo.local_atual = destino
            update_fields = ["local_atual", "atualizado_em"]
            if sala is not None:
                ativo.sala = sala
                update_fields.append("sala")
            ativo.save(update_fields=update_fields)
            registrar_acao(
                request,
                "MOVIMENTAR",
                "Ativo",
                ativo.pk,
                {"local_anterior": local_anterior, "local_atual": destino},
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
    queryset = OrdemServico.objects.all().prefetch_related(
        "usuarios", "salas", "ativos", "manutencoes"
    ).order_by("id_ordem")
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
    http_method_names = ["get", "post", "head", "options"]
    roles_create = TODOS
    roles_write = TODOS
    entity_name = "MovimentacoesA"
    search_fields = ["justificativa", "local_m", "ativo__nome", "ativo__qr_code"]

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
            movimentacao = serializer.save(usuario=self.request.user)
            ativo = movimentacao.ativo
            local_anterior = ativo.local_atual
            ativo.local_atual = movimentacao.local_m
            ativo.save(update_fields=["local_atual", "atualizado_em"])
            registrar_acao(
                self.request,
                "MOVIMENTAR",
                "Ativo",
                ativo.pk,
                {"local_anterior": local_anterior, "local_atual": ativo.local_atual},
            )


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
