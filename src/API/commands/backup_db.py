from datetime import datetime
from pathlib import Path
import sqlite3

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Gera um backup consistente do banco SQLite da API."

    def add_arguments(self, parser):
        parser.add_argument("--destino", default=str(settings.BASE_DIR / "backups"))

    def handle(self, *args, **options):
        db = settings.DATABASES["default"]
        if db["ENGINE"] != "django.db.backends.sqlite3":
            raise CommandError("Este comando atende SQLite. Para MySQL, use mysqldump e valide a restauração.")
        origem = Path(db["NAME"])
        if not origem.exists():
            raise CommandError(f"Banco não encontrado: {origem}. Execute migrate primeiro.")
        destino_dir = Path(options["destino"])
        destino_dir.mkdir(parents=True, exist_ok=True)
        destino = destino_dir / f"atlaslab_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sqlite3"
        with sqlite3.connect(origem) as source, sqlite3.connect(destino) as target:
            source.backup(target)
            resultado = target.execute("PRAGMA integrity_check").fetchone()[0]
        if resultado != "ok":
            destino.unlink(missing_ok=True)
            raise CommandError(f"Falha na integridade do backup: {resultado}")
        self.stdout.write(self.style.SUCCESS(f"Backup validado: {destino}"))
