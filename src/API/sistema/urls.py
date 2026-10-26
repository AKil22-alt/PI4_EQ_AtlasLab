from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from ativos import views

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
