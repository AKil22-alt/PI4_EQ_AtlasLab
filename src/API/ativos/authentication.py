import hashlib

from django.utils import timezone
from rest_framework import authentication, exceptions

from .models import ApiToken


class AtlasTokenAuthentication(authentication.BaseAuthentication):
    """Autentica tokens opacos enviados no cabeçalho Authorization: Token <token>."""

    keyword = "Token"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).split()
        if not header:
            return None
        if header[0].decode("utf-8").lower() != self.keyword.lower():
            return None
        if len(header) != 2:
            raise exceptions.AuthenticationFailed("Cabeçalho de autenticação inválido.")
        try:
            raw_token = header[1].decode("utf-8")
        except UnicodeError as exc:
            raise exceptions.AuthenticationFailed("Token inválido.") from exc

        digest = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
        try:
            token = ApiToken.objects.select_related("usuario").get(
                token_hash=digest, expira_em__gt=timezone.now()
            )
        except ApiToken.DoesNotExist as exc:
            raise exceptions.AuthenticationFailed("Token inválido ou expirado.") from exc
        return token.usuario, token

    def authenticate_header(self, request):
        return self.keyword
