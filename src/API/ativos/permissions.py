from rest_framework.permissions import BasePermission


ADMIN = {"ADM"}
TECNICO = {"ADM", "TEC"}
TODOS = {"ADM", "TEC", "CLB"}


class CargoPermission(BasePermission):
    """Controla as ações por cargo. O mapa action_roles tem precedência."""

    message = "Você não tem permissão para executar esta operação."

    def has_permission(self, request, view):
        user = getattr(request, "user", None)
        if not user or not getattr(user, "is_authenticated", False):
            return False

        cargo = getattr(user, "cargo", None)
        action = getattr(view, "action", None)
        action_roles = getattr(view, "action_roles", {})
        if action in action_roles:
            return cargo in action_roles[action]

        roles_read = getattr(view, "roles_read", TODOS)
        roles_create = getattr(view, "roles_create", TECNICO)
        roles_write = getattr(view, "roles_write", TECNICO)
        if request.method in ("GET", "HEAD", "OPTIONS"):
            return cargo in roles_read
        if request.method == "POST":
            return cargo in roles_create
        return cargo in roles_write

    def has_object_permission(self, request, view, obj):
        # As regras gerais de cargo já são aplicadas no nível da requisição.
        return True
