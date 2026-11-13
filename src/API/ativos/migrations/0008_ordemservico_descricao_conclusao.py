from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("ativos", "0007_notificacao"),
    ]

    operations = [
        migrations.AddField(
            model_name="ordemservico",
            name="descricao_conclusao",
            field=models.TextField(blank=True, null=True),
        ),
    ]
