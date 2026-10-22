from pathlib import Path
import sqlite3

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Restaura um backup SQLite após confirmação explícita."

    def add_arguments(self, parser):
        parser.add_argument("arquivo", help="Caminho do arquivo .sqlite3 validado")
        parser.add_argument("--confirmar", action="store_true", help="Confirma a substituição do banco atual")

    def handle(self, *args, **options):
        db = settings.DATABASES["default"]
        if db["ENGINE"] != "django.db.backends.sqlite3":
            raise CommandError("Este comando atende SQLite. Para MySQL, use o procedimento de restauração do servidor.")
        backup = Path(options["arquivo"]).resolve()
        banco = Path(db["NAME"]).resolve()
        if not options["confirmar"]:
            raise CommandError("Confirme a substituição usando --confirmar. Faça um backup antes de restaurar.")
        if not backup.is_file() or backup == banco:
            raise CommandError("Informe um arquivo de backup válido diferente do banco atual.")
        with sqlite3.connect(backup) as con:
            resultado = con.execute("PRAGMA integrity_check").fetchone()[0]
        if resultado != "ok":
            raise CommandError(f"Backup inválido: {resultado}")
        banco.parent.mkdir(parents=True, exist_ok=True)
        with sqlite3.connect(backup) as source, sqlite3.connect(banco) as target:
            source.backup(target)
            resultado_final = target.execute("PRAGMA integrity_check").fetchone()[0]
        if resultado_final != "ok":
            raise CommandError(f"Falha após restauração: {resultado_final}")
        self.stdout.write(self.style.SUCCESS(f"Banco restaurado e validado de: {backup}"))
