from django.db import models
from django.utils.translation import gettext_lazy as _

# 1. Denuncias_F
class DenunciaF(models.Model):
    id_denuncia = models.AutoField(primary_key=True)
    descricao = models.TextField(max_length=1000)
    imagem = models.ImageField(upload_to='DenunciasFoto/', blank=True, null=True)
    classificacao = models.CharField(max_length=100)

    def __str__(self):
        return f"Denúncia {self.id_denuncia}"

# 2. Grupo_A A = ativos
class GrupoA(models.Model):
    id_grupo_a = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    numero_ta = models.SmallIntegerField(max_length=50)
    tipo = models.CharField(max_length=50)
    setor = models.CharField(max_length=100)

    def __str__(self):
        return self.nome

# 3. Salas/Labs
class SalaLab(models.Model):
    id_sala = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    numero_ta = models.CharField(max_length=50)
    localizacao = models.CharField(max_length=150)
    descricao = models.TextField(blank=True, null=True)
    
    # Relacionamento 0,1 
    sala_pai = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='sub_salas')

    def __str__(self):
        return self.nome

# 4. Usuarios
class Usuario(models.Model):
    id_user = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    email = models.EmailField(_("endereço de e-mail"), max_length=254, unique=True)
    
    class CargoChoices(models.TextChoices):
        ADMINISTRADOR = "ADM", "Administrador"
        TECNICO = "TEC", "Tecnico"
        COLABORADOR = "CLB", "Colaborador"
        
    cargo = models.CharField(max_length=3, choices=CargoChoices.choices)
    foto = models.ImageField(upload_to='UserFoto/', blank=True, null=True)
    senha = models.CharField(max_length=128)
    
    # Relação Responsavel (0,n) com Salas/Labs
    salas_responsaveis = models.ManyToManyField(SalaLab, related_name='responsaveis', blank=True)

    def __str__(self):
        return self.nome

# Relacionamento 'Faz' entre Denuncias_F (1,n) e Usuarios (0,1)
class DenunciaFaz(models.Model):
    denuncia = models.ForeignKey(DenunciaF, on_delete=models.CASCADE)
    usuario = models.ForeignKey(Usuario, on_delete=models.SET_NULL, null=True, blank=True)

# 5. Ativo
class Ativo(models.Model):
    id_ativos = models.AutoField(primary_key=True)
    nome = models.CharField(max_length=100)
    qr_code = models.CharField(max_length=150, unique=True)
    status = models.BooleanField(default=True)
    local_origem = models.CharField(max_length=100)
    local_atual = models.CharField(max_length=100)
    descricao = models.TextField(blank=True, null=True)
    
    # Relações (1,1 com Grupo_A e 0,n com Salas/Labs)
    grupo = models.ForeignKey(GrupoA, on_delete=models.CASCADE, related_name='ativos')
    sala = models.ForeignKey(SalaLab, on_delete=models.SET_NULL, null=True, blank=True, related_name='ativos')

    def __str__(self):
        return self.nome

# 6. Ordem_servico
class OrdemServico(models.Model):
    id_ordem = models.AutoField(primary_key=True)
    titulo = models.CharField(max_length=100)
    descricao = models.TextField()
    data_hora = models.DateTimeField()
    
    # Relações 'contem' (1,n com Usuarios, Ativos, etc.)
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='ordens_servico')
    ativo = models.ForeignKey(Ativo, on_delete=models.CASCADE, related_name='ordens_servico', null=True, blank=True)
    sala = models.ForeignKey(SalaLab, on_delete=models.CASCADE, related_name='ordens_servico', null=True, blank=True)

    def __str__(self):
        return f"OS {self.id_ordem} - {self.titulo}"

# 7. Manutenção_A
class ManutencaoA(models.Model):
    id_man = models.AutoField(primary_key=True)
    tipo = models.CharField(max_length=50)
    descricao = models.TextField()
    data_hora_prev = models.DateTimeField()
    data_hora_entrada = models.DateTimeField()
    data_hora_saida = models.DateTimeField(blank=True, null=True)
    prioridade = models.CharField(max_length=50)
    gravidade = models.CharField(max_length=50)
    numero_tag = models.CharField(max_length=50)
    utima_manutencao = models.DateField()
    
    # Relação com Ordem de Serviço
    ordem_servico = models.ForeignKey(OrdemServico, on_delete=models.CASCADE, related_name='manutencoes')

    def __str__(self):
        return f"Manutenção {self.id_man} - {self.tipo}"

# 8. Movimentações_A
class MovimentacoesA(models.Model):
    id_mov = models.AutoField(primary_key=True)
    justificativa = models.TextField()
    previsao_data_hora = models.DateTimeField()
    contagem_mov_a = models.IntegerField()
    local_m = models.CharField(max_length=100)
    data_hora = models.DateTimeField()
    data_hora_entrada = models.DateTimeField()
    data_hora_saida = models.DateTimeField(blank=True, null=True)
    
    # mapeamento
    ativo = models.ForeignKey(Ativo, on_delete=models.CASCADE, related_name='movimentacoes')
    manutencao = models.ForeignKey(ManutencaoA, on_delete=models.SET_NULL, null=True, blank=True, related_name='movimentacoes')

    def __str__(self):
        return f"Movimentação {self.id_mov}"