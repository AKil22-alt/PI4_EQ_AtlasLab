from django import forms
from django.contrib import admin, messages
from django.contrib.auth.hashers import make_password

from .models import (
    Ativo,
    DenunciaF,
    GrupoA,
    LogAcao,
    ManutencaoA,
    MovimentacoesA,
    OrdemServico,
    OSAtivo,
    OSManutencao,
    OSSalaLab,
    OSUser,
    SalaLab,
    Usuario,
)


admin.site.site_header = "AtlasLab — Gestão de Laboratórios e Ativos"
admin.site.site_title = "AtlasLab"
admin.site.index_title = "Administração do sistema"


class UsuarioAdminForm(forms.ModelForm):
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

    def save_model(self, request, obj, form, change):
        senha = form.cleaned_data.get("senha")
        if senha:
            obj.senha = make_password(senha)
        elif change:
            obj.senha = Usuario.objects.get(pk=obj.pk).senha
        super().save_model(request, obj, form, change)


@admin.register(GrupoA)
class GrupoAAdmin(admin.ModelAdmin):
    list_display = ("id_grupo_a", "nome", "tipo", "setor", "numero_ta")
    list_display_links = ("id_grupo_a", "nome")
    list_filter = ("tipo", "setor")
    search_fields = ("nome", "tipo", "setor")
    ordering = ("nome",)


@admin.register(SalaLab)
class SalaLabAdmin(admin.ModelAdmin):
    list_display = ("id_sala", "nome", "numero_ta", "localizacao", "responsavel")
    list_display_links = ("id_sala", "nome")
    list_filter = ("localizacao",)
    search_fields = ("nome", "numero_ta", "localizacao")
    list_select_related = ("responsavel",)
    autocomplete_fields = ("responsavel",)
    ordering = ("nome",)


class MovimentacoesInline(admin.TabularInline):
    model = MovimentacoesA
    fields = ("data_hora", "local_m", "justificativa", "usuario")
    readonly_fields = fields
    extra = 0
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Ativo)
class AtivoAdmin(admin.ModelAdmin):
    list_display = ("id_ativos", "nome", "qr_code", "status", "local_atual", "grupo", "sala")
    list_display_links = ("id_ativos", "nome")
    list_filter = ("status", "grupo", "sala")
    search_fields = ("nome", "qr_code", "local_atual", "local_origem")
    list_select_related = ("grupo", "sala")
    autocomplete_fields = ("grupo", "sala")
    ordering = ("nome",)
    inlines = (MovimentacoesInline,)
    actions = ("inativar_ativos", "reativar_ativos")

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


class OSUserInline(admin.TabularInline):
    model = OSUser
    extra = 0
    autocomplete_fields = ("usuario",)


class OSSalaLabInline(admin.TabularInline):
    model = OSSalaLab
    extra = 0
    autocomplete_fields = ("sala",)


class OSAtivoInline(admin.TabularInline):
    model = OSAtivo
    extra = 0
    autocomplete_fields = ("ativo",)


class OSManutencaoInline(admin.TabularInline):
    model = OSManutencao
    extra = 0
    autocomplete_fields = ("manutencao",)


@admin.register(OrdemServico)
class OrdemServicoAdmin(admin.ModelAdmin):
    list_display = ("id_ordem", "titulo", "status", "data_hora")
    list_display_links = ("id_ordem", "titulo")
    list_filter = ("status", "data_hora")
    search_fields = ("titulo", "descricao")
    date_hierarchy = "data_hora"
    ordering = ("-data_hora",)
    inlines = (OSUserInline, OSSalaLabInline, OSAtivoInline, OSManutencaoInline)


@admin.register(ManutencaoA)
class ManutencaoAAdmin(admin.ModelAdmin):
    list_display = (
        "id_man", "tipo", "prioridade", "gravidade",
        "data_hora_entrada", "data_hora_saida",
    )
    list_display_links = ("id_man", "tipo")
    list_filter = ("tipo", "prioridade", "gravidade")
    search_fields = ("tipo", "descricao", "numero_tag")
    date_hierarchy = "data_hora_entrada"
    ordering = ("-data_hora_entrada",)


@admin.register(MovimentacoesA)
class MovimentacoesAAdmin(admin.ModelAdmin):
    list_display = (
        "id_mov", "ativo", "local_m", "usuario", "data_hora",
        "data_hora_entrada", "data_hora_saida",
    )
    list_display_links = ("id_mov",)
    list_filter = ("local_m", "data_hora")
    search_fields = ("ativo__nome", "ativo__qr_code", "local_m", "justificativa")
    list_select_related = ("ativo", "usuario")
    autocomplete_fields = ("ativo", "usuario", "manutencao")
    date_hierarchy = "data_hora"
    ordering = ("-data_hora",)
    readonly_fields = (
        "id_mov", "justificativa", "previsao_data_hora", "contagem_mov_a",
        "local_m", "data_hora", "data_hora_entrada", "data_hora_saida",
        "usuario", "ativo", "manutencao",
    )

    def has_change_permission(self, request, obj=None):
        return obj is None

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(DenunciaF)
class DenunciaFAdmin(admin.ModelAdmin):
    list_display = ("id_denuncia", "classificacao", "usuario", "criado_em")
    list_display_links = ("id_denuncia",)
    list_filter = ("classificacao", "criado_em")
    search_fields = ("descricao", "classificacao", "usuario__nome", "usuario__email")
    list_select_related = ("usuario",)
    readonly_fields = ("id_denuncia", "usuario", "criado_em")


@admin.register(LogAcao)
class LogAcaoAdmin(admin.ModelAdmin):
    list_display = ("id", "usuario", "acao", "entidade", "entidade_id", "criado_em")
    list_filter = ("acao", "entidade")
    search_fields = ("entidade", "entidade_id", "usuario__email")
    readonly_fields = (
        "usuario", "acao", "entidade", "entidade_id", "detalhes", "ip", "criado_em",
    )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_view_permission(self, request, obj=None):
        return request.user.is_superuser or request.user.has_perm("ativos.view_logacao")

    def has_delete_permission(self, request, obj=None):
        return False
