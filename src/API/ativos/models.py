from django.db import models

# Models

class User(models.Model):

    id = models.IntegerField(max_length = 100)
    nome = models.CharField(max_length= 100)
    email = models.EmailField(_("endereço de e-mail"), max_length=254, unique=True)
    cargo = models.Choices(
        ("ADM", "Administrador"),
        ("TEC", "Tecnico"),
        ("CLB", "Colaborador")
    )
    Foto = models.ImageField(upload_to='UserFoto/', blank=True, null=True)

class Ordem_servico(  )