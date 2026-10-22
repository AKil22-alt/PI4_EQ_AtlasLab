from django.contrib.auth.hashers import make_password
from rest_framework import serializers

from .models import (
    Ativo, DenunciaF, GrupoA, LogAcao, ManutencaoA, MovimentacoesA,
    OrdemServico, SalaLab, Usuario,
)


class UsuarioResumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ["id_user", "nome", "email", "cargo"]
        read_only_fields = fields


class UsuarioSerializer(serializers.ModelSerializer):
    senha = serializers.CharField(write_only=True, min_length=8, required=True, trim_whitespace=False)
    salas_responsaveis = serializers.PrimaryKeyRelatedField(many=True, read_only=True)

    class Meta:
        model = Usuario
        fields = [
            "id_user", "nome", "email", "cargo", "foto", "senha",
            "salas_responsaveis", "criado_em", "atualizado_em",
        ]
        read_only_fields = ["id_user", "criado_em", "atualizado_em"]

    def validate_nome(self, value):
        value = value.strip()
        if len(value) < 3:
            raise serializers.ValidationError("O nome deve ter pelo menos 3 caracteres.")
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        qs = Usuario.objects.filter(email__iexact=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("Este e-mail já está cadastrado.")
        return value

    def create(self, validated_data):
        validated_data["senha"] = make_password(validated_data["senha"])
        return super().create(validated_data)

    def update(self, instance, validated_data):
        senha = validated_data.get("senha")
        if senha:
            validated_data["senha"] = make_password(senha)
        return super().update(instance, validated_data)


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    senha = serializers.CharField(write_only=True, trim_whitespace=False)


class GrupoASerializer(serializers.ModelSerializer):
    class Meta:
        model = GrupoA
        fields = "__all__"


class SalaLabSerializer(serializers.ModelSerializer):
    responsavel_detalhes = UsuarioResumoSerializer(source="responsavel", read_only=True)

    class Meta:
        model = SalaLab
        fields = [
            "id_sala", "nome", "numero_ta", "localizacao", "descricao",
            "responsavel", "responsavel_detalhes",
        ]


class DenunciaFSerializer(serializers.ModelSerializer):
    usuario = UsuarioResumoSerializer(read_only=True)

    class Meta:
        model = DenunciaF
        fields = ["id_denuncia", "descricao", "imagem", "classificacao", "usuario", "criado_em"]
        read_only_fields = ["id_denuncia", "usuario", "criado_em"]


class AtivoSerializer(serializers.ModelSerializer):
<<<<<<< Updated upstream
    grupo_detalhes = GrupoASerializer(source='grupo', read_only=True)
    sala_detalhes = SalaLabSerializer(source='sala', read_only=True)
=======
    grupo_detalhes = GrupoASerializer(source="grupo", read_only=True)
    sala_detalhes = SalaLabSerializer(source="sala", read_only=True)
>>>>>>> Stashed changes

    class Meta:
        model = Ativo
        fields = [
            "id_ativos", "nome", "qr_code", "status", "local_origem", "local_atual",
            "descricao", "grupo", "grupo_detalhes", "sala", "sala_detalhes",
            "criado_em", "atualizado_em",
        ]
        read_only_fields = ["id_ativos", "qr_code", "criado_em", "atualizado_em"]


class ManutencaoASerializer(serializers.ModelSerializer):
    class Meta:
        model = ManutencaoA
        fields = "__all__"


class OrdemServicoSerializer(serializers.ModelSerializer):
    usuario_ids = serializers.PrimaryKeyRelatedField(
        source="usuarios", queryset=Usuario.objects.all(), many=True, required=False, write_only=True
    )
    sala_ids = serializers.PrimaryKeyRelatedField(
        source="salas", queryset=SalaLab.objects.all(), many=True, required=False, write_only=True
    )
    ativo_ids = serializers.PrimaryKeyRelatedField(
        source="ativos", queryset=Ativo.objects.all(), many=True, required=False, write_only=True
    )
    manutencao_ids = serializers.PrimaryKeyRelatedField(
        source="manutencoes", queryset=ManutencaoA.objects.all(), many=True, required=False, write_only=True
    )
    usuarios_detalhes = UsuarioResumoSerializer(source="usuarios", many=True, read_only=True)
    salas_detalhes = SalaLabSerializer(source="salas", many=True, read_only=True)
    ativos_detalhes = AtivoSerializer(source="ativos", many=True, read_only=True)
    manutencoes_detalhes = ManutencaoASerializer(source="manutencoes", many=True, read_only=True)

    class Meta:
        model = OrdemServico
        fields = [
            "id_ordem", "titulo", "descricao", "data_hora", "status",
            "usuario_ids", "sala_ids", "ativo_ids", "manutencao_ids",
            "usuarios_detalhes", "salas_detalhes", "ativos_detalhes", "manutencoes_detalhes",
        ]
        read_only_fields = ["id_ordem"]


class MovimentacoesASerializer(serializers.ModelSerializer):
    usuario_detalhes = UsuarioResumoSerializer(source="usuario", read_only=True)
    ativo_detalhes = AtivoSerializer(source="ativo", read_only=True)

    class Meta:
        model = MovimentacoesA
        fields = [
            "id_mov", "justificativa", "previsao_data_hora", "contagem_mov_a", "local_m",
            "data_hora", "data_hora_entrada", "data_hora_saida", "usuario", "usuario_detalhes",
            "ativo", "ativo_detalhes", "manutencao",
        ]
        read_only_fields = ["id_mov", "usuario", "data_hora", "data_hora_entrada"]


class LogAcaoSerializer(serializers.ModelSerializer):
    usuario_detalhes = UsuarioResumoSerializer(source="usuario", read_only=True)

    class Meta:
        model = LogAcao
        fields = [
            "id", "usuario", "usuario_detalhes", "acao", "entidade", "entidade_id",
            "detalhes", "ip", "criado_em",
        ]
        read_only_fields = fields
