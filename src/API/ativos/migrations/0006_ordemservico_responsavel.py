from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('ativos', '0005_ordemservico_data_termino'),
    ]

    operations = [
        migrations.AddField(
            model_name='ordemservico',
            name='responsavel',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='ordens_responsavel',
                to='ativos.usuario',
            ),
        ),
    ]
