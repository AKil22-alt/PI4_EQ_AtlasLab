import secrets
import uuid

from django.db import models
from django.utils import timezone


class Cargo(models.TextChoices):
    ADMINISTRADOR = "ADM", "Administrador"
    TECNICO = "TEC", "Técnico"
    COLABORADOR = "CLB", "Colaborador"


class Usuario(models.Model):
    id_user = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=150)
    email = models.EmailField(max_length=254, unique=True)
    cargo = models.CharField(max_length=3, choices=Cargo.choices, default=Cargo.COLABORADOR)
    foto = models.ImageField(upload_to="usuarios/", blank=True, null=True)
    # O valor armazenado é um hash BCrypt, nunca a senha em texto puro.
    senha = models.CharField(max_length=128)
    criado_em = models.DateTimeField(default=timezone.now, editable=False)
    atualizado_em = models.DateTimeField(auto_now=True)

    @property
    def is_authenticated(self):
        # Permite usar esta entidade com a autenticação customizada do DRF.
        return True

    @property
    def is_anonymous(self):
        return False

    def __str__(self):
        return self.nome


class GrupoA(models.Model):
    id_grupo_a = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    numero_ta = models.PositiveIntegerField()
    tipo = models.CharField(max_length=50)
    setor = models.CharField(max_length=100)

    def __str__(self):
        return self.nome


class SalaLab(models.Model):
    id_sala = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    numero_ta = models.PositiveIntegerField()
    localizacao = models.CharField(max_length=150)
    descricao = models.TextField(blank=True, null=True)
    responsavel = models.ForeignKey(
        Usuario,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="salas_responsaveis",
    )

    def __str__(self):
        return self.nome


class DenunciaF(models.Model):
    id_denuncia = models.AutoField(primary_key=True)
    descricao = models.TextField(max_length=1000)
    imagem = models.ImageField(upload_to="denuncias/", blank=True, null=True)
    classificacao = models.CharField(max_length=100)
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT, related_name="denuncias")
    criado_em = models.DateTimeField(default=timezone.now, editable=False)

    def __str__(self):
        return f"Denúncia {self.id_denuncia}"


class Ativo(models.Model):
    id_ativos = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    # Identificador único que pode ser codificado como QR Code no app.
    qr_code = models.CharField(max_length=150, unique=True, blank=True)
    status = models.BooleanField(default=True)
    local_origem = models.CharField(max_length=100)
    local_atual = models.CharField(max_length=100)
    descricao = models.TextField(blank=True, null=True)
    grupo = models.ForeignKey(GrupoA, on_delete=models.PROTECT, related_name="ativos")
    sala = models.ForeignKey(
        SalaLab, on_delete=models.SET_NULL, null=True, blank=True, related_name="ativos"
    )
    criado_em = models.DateTimeField(default=timezone.now, editable=False)
    atualizado_em = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.qr_code:
            self.qr_code = f"ATLASLAB-{uuid.uuid4().hex[:16].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return self.nome


class OrdemServico(models.Model):
    class Status(models.TextChoices):
        ABERTA = "ABERTA", "Aberta"
        EM_ANDAMENTO = "EM_ANDAMENTO", "Em andamento"
        CONCLUIDA = "CONCLUIDA", "Concluída"
        CANCELADA = "CANCELADA", "Cancelada"

    id_ordem = models.AutoField(primary_key=True)
    descricao = models.TextField()
    titulo = models.CharField(max_length=100)
    data_hora = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ABERTA)
    usuarios = models.ManyToManyField(Usuario, through="OSUser", related_name="ordens_servico")
    salas = models.ManyToManyField(SalaLab, through="OSSalaLab", related_name="ordens_servico")
    ativos = models.ManyToManyField(Ativo, through="OSAtivo", related_name="ordens_servico")
    manutencoes = models.ManyToManyField(
        "ManutencaoA", through="OSManutencao", related_name="ordens_servico"
    )

    def __str__(self):
        return f"OS {self.id_ordem} - {self.titulo}"


class ManutencaoA(models.Model):
    id_man = models.AutoField(primary_key=True)
    tipo = models.CharField(max_length=50)
    descricao = models.TextField()
    data_hora_prev = models.DateTimeField()
    data_hora_entrada = models.DateTimeField(default=timezone.now)
    data_hora_saida = models.DateTimeField(blank=True, null=True)
    prioridade = models.CharField(max_length=50)
    gravidade = models.CharField(max_length=50)
    numero_tag = models.CharField(max_length=50)
    ultima_manutencao = models.DateField(blank=True, null=True)

    def __str__(self):
        return f"Manutenção {self.id_man} - {self.tipo}"


class OSUser(models.Model):
    id = models.AutoField(primary_key=True)
    ordem_servico = models.ForeignKey(OrdemServico, on_delete=models.CASCADE, related_name="vinculos_usuarios")
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT, related_name="vinculos_ordem")
    data_hora_op = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["ordem_servico", "usuario"], name="uq_os_usuario")]
        verbose_name = "Vínculo OS/usuário"
        verbose_name_plural = "Vínculos OS/usuário"


class OSSalaLab(models.Model):
    id = models.AutoField(primary_key=True)
    ordem_servico = models.ForeignKey(OrdemServico, on_delete=models.CASCADE, related_name="vinculos_salas")
    sala = models.ForeignKey(SalaLab, on_delete=models.PROTECT, related_name="vinculos_ordem")
    data_hora = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["ordem_servico", "sala"], name="uq_os_sala")]
        verbose_name = "Vínculo OS/sala"
        verbose_name_plural = "Vínculos OS/sala"


class OSAtivo(models.Model):
    id = models.AutoField(primary_key=True)
    ordem_servico = models.ForeignKey(OrdemServico, on_delete=models.CASCADE, related_name="vinculos_ativos")
    ativo = models.ForeignKey(Ativo, on_delete=models.PROTECT, related_name="vinculos_ordem")
    data_hora = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["ordem_servico", "ativo"], name="uq_os_ativo")]
        verbose_name = "Vínculo OS/ativo"
        verbose_name_plural = "Vínculos OS/ativo"


class OSManutencao(models.Model):
    id = models.AutoField(primary_key=True)
    ordem_servico = models.ForeignKey(OrdemServico, on_delete=models.CASCADE, related_name="vinculos_manutencoes")
    manutencao = models.ForeignKey(ManutencaoA, on_delete=models.PROTECT, related_name="vinculos_ordem")
    data_hora = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["ordem_servico", "manutencao"], name="uq_os_manutencao")]
        verbose_name = "Vínculo OS/manutenção"
        verbose_name_plural = "Vínculos OS/manutenção"


class MovimentacoesA(models.Model):
    id_mov = models.AutoField(primary_key=True)
    justificativa = models.TextField()
    previsao_data_hora = models.DateTimeField(blank=True, null=True)
    contagem_mov_a = models.PositiveIntegerField(default=1)
    local_m = models.CharField(max_length=100)
    data_hora = models.DateTimeField(default=timezone.now)
    data_hora_entrada = models.DateTimeField(default=timezone.now)
    data_hora_saida = models.DateTimeField(blank=True, null=True)
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT, related_name="movimentacoes")
    ativo = models.ForeignKey(Ativo, on_delete=models.PROTECT, related_name="movimentacoes")
    manutencao = models.ForeignKey(
        ManutencaoA, on_delete=models.SET_NULL, null=True, blank=True, related_name="movimentacoes"
    )

    def __str__(self):
        return f"Movimentação {self.id_mov} - {self.ativo.nome}"


class ApiToken(models.Model):
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name="tokens_api")
    token_hash = models.CharField(max_length=64, unique=True, db_index=True)
    criado_em = models.DateTimeField(default=timezone.now, editable=False)
    expira_em = models.DateTimeField()

    @staticmethod
    def gerar_token():
        return secrets.token_urlsafe(36)

    def __str__(self):
        return f"Token do usuário {self.usuario_id}"


class LogAcao(models.Model):
    usuario = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True, related_name="logs_acoes"
    )
    acao = models.CharField(max_length=30)
    entidade = models.CharField(max_length=80)
    entidade_id = models.CharField(max_length=80, blank=True)
    detalhes = models.JSONField(default=dict, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    criado_em = models.DateTimeField(default=timezone.now, editable=False, db_index=True)

    class Meta:
        ordering = ["-criado_em"]
        verbose_name = "Log de ação"
        verbose_name_plural = "Logs de ações"

    def __str__(self):
        return f"{self.acao} - {self.entidade}#{self.entidade_id}"
