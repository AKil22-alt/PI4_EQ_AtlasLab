from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
<<<<<<< Updated upstream
from rest_framework.routers import DefaultRouter

from ativos import views

# --- CRUD via ViewSets -------------------------------------------------------
# Ações extras do Ativo (qr-code, movimentar, inativar, reativar, historico)
# são declaradas com @action dentro de AtivoViewSet e o router as expõe sozinho:
#   GET  /api/ativos/{id}/qr-code/     (url_path="qr-code")
#   POST /api/ativos/{id}/movimentar/
#   POST /api/ativos/{id}/inativar/
#   POST /api/ativos/{id}/reativar/
#   GET  /api/ativos/{id}/historico/
router = DefaultRouter()
router.register("usuarios", views.UsuarioViewSet, basename="usuario")
router.register("grupos", views.GrupoAViewSet, basename="grupo")
router.register("salas", views.SalaLabViewSet, basename="sala")
router.register("ativos", views.AtivoViewSet, basename="ativo")
router.register("ordens-servico", views.OrdemServicoViewSet, basename="ordem-servico")
router.register("manutencoes", views.ManutencaoAViewSet, basename="manutencao")
router.register("movimentacoes", views.MovimentacoesAViewSet, basename="movimentacao")
router.register("denuncias", views.DenunciaFViewSet, basename="denuncia")
router.register("logs", views.LogAuditoriaViewSet, basename="log")  # somente ADM

# --- Endpoints avulsos (saúde e autenticação) -----------------------------------
api_urlpatterns = [
    path("health/", views.HealthView.as_view(), name="health"),
    path("auth/login/", views.LoginView.as_view(), name="auth-login"),
    path("auth/logout/", views.LogoutView.as_view(), name="auth-logout"),
    path("auth/me/", views.MeView.as_view(), name="auth-me"),
    path("", include(router.urls)),
]

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include(api_urlpatterns)),
]

# Fotos de usuários e denúncias (ImageField) durante o desenvolvimento.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# ---------------------------------------------------------------------------
# Contrato esperado em ativos/views.py
#   ViewSets: UsuarioViewSet, GrupoAViewSet, SalaLabViewSet, AtivoViewSet,
#             OrdemServicoViewSet, ManutencaoAViewSet, MovimentacoesAViewSet,
#             DenunciaFViewSet, LogAuditoriaViewSet
#   APIViews: HealthView, LoginView, LogoutView, MeView
# ---------------------------------------------------------------------------
=======

from ativos.views import HealthView, LoginView, LogoutView, MeView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthView.as_view(), name="api-health"),
    path("api/auth/login/", LoginView.as_view(), name="api-login"),
    path("api/auth/logout/", LogoutView.as_view(), name="api-logout"),
    path("api/auth/me/", MeView.as_view(), name="api-me"),
    path("api/", include("ativos.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
>>>>>>> Stashed changes
