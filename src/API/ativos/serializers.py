from rest_framework import serializers
from .models import (
    DenunciaF, GrupoA, SalaLab, Usuario, 
    DenunciaFaz, Ativo, OrdemServico, 
    ManutencaoA, MovimentacoesA
)

class DenunciaFSerializer(serializers.ModelSerializer):
    class Meta:
        model = DenunciaF
        fields = '__all__'

class GrupoASerializer(serializers.ModelSerializer):
    class Meta:
        model = GrupoA
        fields = '__all__'

class SalaLabSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalaLab
        fields = '__all__'

class UsuarioSerializer(serializers.ModelSerializer):
    # Oculta a senha em leituras por segurança
    
    senha = serializers.CharField(write_only=True)

    class Meta:
        model = Usuario
        fields = ['id_user', 'nome', 'email', 'cargo', 'foto', 'senha', 'salas_responsaveis']

class DenunciaFazSerializer(serializers.ModelSerializer):
    class Meta:
        model = DenunciaFaz
        fields = '__all__'

class AtivoSerializer(serializers.ModelSerializer):
    # Opcional: aninha os serializers para exibição detalhada nas consultas (GET)
    grupo_detalhes = GrupoASerializer(source='grupo', read_only=True)
    sala_detalhes = SalaLabSerializer(source='sala', read_only=True)

    class Meta:
        model = Ativo
        fields = '__all__'

class OrdemServicoSerializer(serializers.ModelSerializer):
    usuario_detalhes = UsuarioSerializer(source='usuario', read_only=True)
    ativo_detalhes = AtivoSerializer(source='ativo', read_only=True)
    sala_detalhes = SalaLabSerializer(source='sala', read_only=True)

    class Meta:
        model = OrdemServico
        fields = '__all__'

class ManutencaoASerializer(serializers.ModelSerializer):
    ordem_servico_detalhes = OrdemServicoSerializer(source='ordem_servico', read_only=True)

    class Meta:
        model = ManutencaoA
        fields = '__all__'

class MovimentacoesASerializer(serializers.ModelSerializer):
    ativo_detalhes = AtivoSerializer(source='ativo', read_only=True)
    manutencao_detalhes = ManutencaoASerializer(source='manutencao', read_only=True)

    class Meta:
        model = MovimentacoesA
        fields = '__all__'