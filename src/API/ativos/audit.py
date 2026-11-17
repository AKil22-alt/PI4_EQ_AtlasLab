from .models import Cargo, LogAcao, Notificacao, Usuario


_ENTITY_LABELS = {
    "Ativo": "Ativo",
    "OrdemServico": "Ordem de Serviço",
    "SalaLab": "Laboratório",
    "Usuario": "Usuário",
    "GrupoA": "Grupo de Ativos",
    "ManutencaoA": "Manutenção",
    "MovimentacoesA": "Movimentação",
    "DenunciaF": "Denúncia",
    "SolicitacaoCadastro": "Solicitação de Cadastro",
}
_ACTION_VERBS = {
    "CRIAR": "criou",
    "ATUALIZAR": "atualizou",
    "EXCLUIR": "removeu",
    "MOVIMENTAR": "movimentou",
    "ATIVAR": "ativou",
    "INATIVAR": "inativou",
    "APROVAR": "aprovou",
    "LIMPAR_HISTORICO": "limpou",
}


def _notification_destination(acao, entidade, entidade_id, detalhes):
    item_id = str(entidade_id)
    include_item = acao != "EXCLUIR"

    if entidade == "Ativo":
        query = {"tab": "assets"}
        if include_item:
            query["assetId"] = item_id
        return {"name": "Labs", "query": query}
    if entidade == "OrdemServico":
        query = {"orderId": item_id} if include_item else {}
        return {"name": "Orders", "query": query}
    if entidade == "SalaLab":
        query = {"tab": "labs"}
        if include_item:
            query["labId"] = item_id
        return {"name": "Labs", "query": query}
    if entidade == "Usuario":
        query = {"userId": item_id} if include_item else {}
        return {"name": "Users", "query": query}
    if entidade == "MovimentacoesA":
        query = {"tab": "movements"}
        if include_item:
            query["movementId"] = item_id
        return {"name": "Labs", "query": query}
    if entidade == "SolicitacaoCadastro":
        usuario_id = detalhes.get("usuario_id") if acao == "APROVAR" else None
        if usuario_id:
            return {"name": "Users", "query": {"userId": str(usuario_id)}}
        query = {"tab": "requests"}
        if include_item:
            query["requestId"] = item_id
        return {"name": "Users", "query": query}
    if entidade == "GrupoA":
        return {"name": "Labs", "query": {"tab": "assets"}}
    return {"name": "Dashboard", "query": {}}


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
    log = LogAcao.objects.create(
        usuario=usuario,
        acao=acao[:30],
        entidade=entidade[:80],
        entidade_id=str(entidade_id)[:80],
        detalhes=detalhes or {},
        ip=ip,
    )

    if acao in {"LOGIN", "LOGOUT"}:
        return log

    actor = usuario.nome if usuario else "Usuário"
    entity_label = _ENTITY_LABELS.get(entidade, entidade)
    verb = _ACTION_VERBS.get(acao, "registrou uma ação em")
    suffix = f" #{entidade_id}" if entidade_id else ""
    mensagem = f"{actor} {verb} {entity_label}{suffix}"
    detalhes_notificacao = detalhes or {}
    Notificacao.objects.bulk_create([
        Notificacao(
            usuario=admin,
            mensagem=mensagem[:255],
            acao=acao[:30],
            entidade=entidade[:80],
            entidade_id=str(entidade_id)[:80],
            destino=_notification_destination(
                acao, entidade, entidade_id, detalhes_notificacao
            ),
        )
        for admin in Usuario.objects.filter(cargo=Cargo.ADMINISTRADOR).only("id_user")
    ])
    return log
