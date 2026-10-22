from .models import LogAcao


def registrar_acao(request, acao, entidade, entidade_id="", detalhes=None):
    user = getattr(request, "user", None)
    usuario = user if getattr(user, "is_authenticated", False) else None
    ip = None
    if request is not None:
        forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip()
        candidato = forwarded or request.META.get("REMOTE_ADDR")
        # GenericIPAddressField valida o valor; não gravar valores arbitrários do header.
        import ipaddress
        try:
            ip = str(ipaddress.ip_address(candidato)) if candidato else None
        except ValueError:
            ip = None
    LogAcao.objects.create(
        usuario=usuario,
        acao=acao[:30],
        entidade=entidade[:80],
        entidade_id=str(entidade_id)[:80],
        detalhes=detalhes or {},
        ip=ip,
    )
