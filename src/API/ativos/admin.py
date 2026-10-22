import bcrypt
from django import forms
from django.contrib import admin, messages

from .models import (
<<<<<<< Updated upstream
    Ativo,
    DenunciaF,
    DenunciaFaz,
    GrupoA,
    ManutencaoA,
    MovimentacoesA,
    OrdemServico,
    SalaLab,
    Usuario,
)

admin.site.site_header = "AtlasLab — Gestão de Laboratórios e Ativos"
admin.site.site_title = "AtlasLab"
admin.site.index_title = "Administração do sistema"


# ---------------------------------------------------------------------------
# Usuários
# ---------------------------------------------------------------------------
def _ja_e_hash_bcrypt(valor: str) -> bool:
    return valor.startswith(("$2a$", "$2b$", "$2y$")) and len(valor) == 60


class UsuarioAdminForm(forms.ModelForm):
    """Campo de senha em texto puro só na digitação; o banco recebe o hash."""

    senha = forms.CharField(
        label="Senha",
        widget=forms.PasswordInput(render_value=False),
        required=False,
        help_text="Obrigatória ao criar. Ao editar, deixe em branco para manter a atual.",
    )

    class Meta:
        model = Usuario
        fields = "__all__"

    def clean_senha(self):
        senha = self.cleaned_data.get("senha", "")
        if not self.instance.pk and not senha:
            raise forms.ValidationError("Informe uma senha para o novo usuário.")
        if senha and len(senha) < 8:
            raise forms.ValidationError("A senha deve ter pelo menos 8 caracteres.")
        return senha


@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    form = UsuarioAdminForm
    list_display = ("id_user", "nome", "email", "cargo")
    list_display_links = ("id_user", "nome")
    list_filter = ("cargo",)
    search_fields = ("nome", "email")
    ordering = ("nome",)
    filter_horizontal = ("salas_responsaveis",)

    def save_model(self, request, obj, form, change):
        nova_senha = form.cleaned_data.get("senha")
        if nova_senha:
            obj.senha = bcrypt.hashpw(nova_senha.encode(), bcrypt.gensalt()).decode()
        elif change:
            # Mantém o hash que já estava salvo.
            obj.senha = Usuario.objects.get(pk=obj.pk).senha
        elif not _ja_e_hash_bcrypt(obj.senha):
            raise ValueError("Usuário novo sem senha válida.")
        super().save_model(request, obj, form, change)


# ---------------------------------------------------------------------------
# Grupos de ativos e Salas/Laboratórios
# ---------------------------------------------------------------------------
@admin.register(GrupoA)
class GrupoAAdmin(admin.ModelAdmin):
    list_display = ("id_grupo_a", "nome", "tipo", "setor", "numero_ta")
    list_display_links = ("id_grupo_a", "nome")
    list_filter = ("tipo", "setor")
    search_fields = ("nome", "tipo", "setor")
    ordering = ("nome",)


@admin.register(SalaLab)
class SalaLabAdmin(admin.ModelAdmin):
    list_display = ("id_sala", "nome", "numero_ta", "localizacao", "sala_pai")
    list_display_links = ("id_sala", "nome")
    list_filter = ("localizacao",)
    search_fields = ("nome", "numero_ta", "localizacao")
    list_select_related = ("sala_pai",)
    autocomplete_fields = ("sala_pai",)
    ordering = ("nome",)


# ---------------------------------------------------------------------------
# Ativos
# ---------------------------------------------------------------------------
class MovimentacoesInline(admin.TabularInline):
    """Histórico do ativo, somente leitura."""

    model = MovimentacoesA
    fields = ("data_hora", "local_m", "justificativa", "data_hora_entrada", "data_hora_saida")
    readonly_fields = fields
    extra = 0
    can_delete = False
    show_change_link = True
    ordering = ("-data_hora",)

    def has_add_permission(self, request, obj=None):
=======
    Ativo, DenunciaF, GrupoA, LogAcao, ManutencaoA, MovimentacoesA,
    OrdemServico, SalaLab, Usuario,
)


@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    list_display = ("id_user", "nome", "email", "cargo")
    search_fields = ("nome", "email")
    list_filter = ("cargo",)
    exclude = ("senha",)

    def has_add_permission(self, request):
>>>>>>> Stashed changes
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Ativo)
class AtivoAdmin(admin.ModelAdmin):
<<<<<<< Updated upstream
    list_display = ("id_ativos", "nome", "qr_code", "situacao", "local_atual", "grupo", "sala")
    list_display_links = ("id_ativos", "nome")
    list_filter = ("status", "grupo", "sala")
    search_fields = ("nome", "qr_code", "local_atual", "local_origem")
    list_select_related = ("grupo", "sala")
    autocomplete_fields = ("sala",)
    ordering = ("nome",)
    inlines = [MovimentacoesInline]
    actions = ["inativar_ativos", "reativar_ativos"]

    @admin.display(description="Situação", boolean=True, ordering="status")
    def situacao(self, obj):
        return obj.status

    # Sem exclusão física: preserva a rastreabilidade (use a ação "Inativar").
    def has_delete_permission(self, request, obj=None):
        return False

    @admin.action(description="Inativar ativos selecionados")
    def inativar_ativos(self, request, queryset):
        total = queryset.filter(status=True).update(status=False)
        self.message_user(request, f"{total} ativo(s) inativado(s).", messages.SUCCESS)

    @admin.action(description="Reativar ativos selecionados")
    def reativar_ativos(self, request, queryset):
        total = queryset.filter(status=False).update(status=True)
        self.message_user(request, f"{total} ativo(s) reativado(s).", messages.SUCCESS)


# ---------------------------------------------------------------------------
# Ordens de serviço e manutenções
# ---------------------------------------------------------------------------
class ManutencaoInline(admin.TabularInline):
    model = ManutencaoA
    extra = 0
    fields = ("tipo", "prioridade", "gravidade", "data_hora_prev", "data_hora_entrada", "data_hora_saida")


@admin.register(OrdemServico)
class OrdemServicoAdmin(admin.ModelAdmin):
    list_display = ("id_ordem", "titulo", "ativo", "sala", "usuario", "data_hora")
    list_display_links = ("id_ordem", "titulo")
    list_filter = ("data_hora", "sala")
    search_fields = ("titulo", "descricao", "ativo__nome", "ativo__qr_code", "usuario__nome")
    list_select_related = ("ativo", "sala", "usuario")
    autocomplete_fields = ("usuario", "ativo", "sala")
    date_hierarchy = "data_hora"
    ordering = ("-data_hora",)
    inlines = [ManutencaoInline]


@admin.register(ManutencaoA)
class ManutencaoAAdmin(admin.ModelAdmin):
    list_display = ("id_man", "tipo", "prioridade", "gravidade", "ordem_servico", "data_hora_entrada", "data_hora_saida")
    list_display_links = ("id_man", "tipo")
    list_filter = ("tipo", "prioridade", "gravidade")
    search_fields = ("tipo", "descricao", "numero_tag", "ordem_servico__titulo")
    list_select_related = ("ordem_servico",)
    autocomplete_fields = ("ordem_servico",)
    date_hierarchy = "data_hora_entrada"
    ordering = ("-data_hora_entrada",)


# ---------------------------------------------------------------------------
# Movimentações (histórico append-only)
# ---------------------------------------------------------------------------
@admin.register(MovimentacoesA)
class MovimentacoesAAdmin(admin.ModelAdmin):
    list_display = ("id_mov", "ativo", "local_m", "data_hora", "data_hora_entrada", "data_hora_saida")
    list_display_links = ("id_mov",)
    list_filter = ("local_m", "data_hora")
    search_fields = ("ativo__nome", "ativo__qr_code", "local_m", "justificativa")
    list_select_related = ("ativo",)
    autocomplete_fields = ("ativo", "manutencao")
    date_hierarchy = "data_hora"
    ordering = ("-data_hora",)

    # Pode registrar e consultar; não pode alterar nem apagar o histórico.
    def has_change_permission(self, request, obj=None):
        return obj is None  # mantém a listagem acessível; edição de registro bloqueada
=======
    list_display = ("id_ativos", "nome", "qr_code", "status", "local_atual", "grupo", "sala")
    list_filter = ("status", "grupo", "sala")
    search_fields = ("nome", "qr_code", "local_atual", "local_origem")


@admin.register(LogAcao)
class LogAcaoAdmin(admin.ModelAdmin):
    list_display = ("id", "usuario", "acao", "entidade", "entidade_id", "criado_em")
    list_filter = ("acao", "entidade")
    search_fields = ("entidade", "entidade_id", "usuario__email")
    readonly_fields = ("usuario", "acao", "entidade", "entidade_id", "detalhes", "ip", "criado_em")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
>>>>>>> Stashed changes

    def has_delete_permission(self, request, obj=None):
        return False


<<<<<<< Updated upstream
# ---------------------------------------------------------------------------
# Denúncias
# ---------------------------------------------------------------------------
class DenunciaFazInline(admin.TabularInline):
    model = DenunciaFaz
    extra = 0
    autocomplete_fields = ("usuario",)


@admin.register(DenunciaF)
class DenunciaFAdmin(admin.ModelAdmin):
    list_display = ("id_denuncia", "classificacao", "resumo")
    list_display_links = ("id_denuncia",)
    list_filter = ("classificacao",)
    search_fields = ("descricao", "classificacao")
    inlines = [DenunciaFazInline]

    @admin.display(description="Descrição")
    def resumo(self, obj):
        return (obj.descricao[:60] + "…") if len(obj.descricao) > 60 else obj.descricao


@admin.register(DenunciaFaz)
class DenunciaFazAdmin(admin.ModelAdmin):
    list_display = ("id", "denuncia", "usuario")
    autocomplete_fields = ("usuario",)
    list_select_related = ("denuncia", "usuario")
=======
admin.site.register([DenunciaF, GrupoA, SalaLab, OrdemServico, ManutencaoA, MovimentacoesA])
>>>>>>> Stashed changes
