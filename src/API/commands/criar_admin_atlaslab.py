from getpass import getpass

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError

from ativos.models import Cargo, Usuario


class Command(BaseCommand):
    help = "Cria o primeiro usuário administrador da API AtlasLab."

    def handle(self, *args, **options):
        nome = input("Nome do administrador: ").strip()
        email = input("E-mail do administrador: ").strip().lower()
        senha = getpass("Senha (mínimo de 8 caracteres): ")
        confirmacao = getpass("Confirme a senha: ")
        if len(nome) < 3:
            raise CommandError("O nome precisa ter pelo menos 3 caracteres.")
        if len(senha) < 8:
            raise CommandError("A senha precisa ter pelo menos 8 caracteres.")
        if senha != confirmacao:
            raise CommandError("As senhas não conferem.")
        if Usuario.objects.filter(email__iexact=email).exists():
            raise CommandError("Já existe um usuário com esse e-mail.")
        usuario = Usuario.objects.create(
            nome=nome, email=email, cargo=Cargo.ADMINISTRADOR, senha=make_password(senha)
        )
        self.stdout.write(self.style.SUCCESS(f"Administrador criado: {usuario.email}"))
