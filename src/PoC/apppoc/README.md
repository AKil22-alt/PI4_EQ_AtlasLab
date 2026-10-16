# PoC Integrador

Repositório contendo a Prova de Conceito (PoC) do projeto Integrador. 

## 📦 Instalação de Dependências

Caso seja a sua primeira vez rodando o projeto ou as bibliotecas tenham sido desinstaladas, abra o terminal na pasta raiz do projeto e instale as dependências executando:

```bash
flutter pub get
```
# 📱 Como testar em um dispositivo físico (Android)
Para rodar e depurar o aplicativo diretamente no seu smartphone, é necessário preparar o dispositivo seguindo os passos abaixo:

## Habilitar o Modo de Desenvolvedor
Acesse as Configurações do seu celular.

Vá em Sobre o telefone > Informações do software.

Toque 7 vezes na opção Número de compilação (ou Versão da interface, dependendo da fabricante) até aparecer a mensagem informando que você agora é um desenvolvedor.

## Ativar a Depuração USB
Volte ao menu principal de Configurações e role até o final para encontrar as Opções do desenvolvedor.

Procure e ative a opção Depuração USB.

No menu de Segurança e Privacidade, certifique-se de remover o bloqueador automático (se o seu aparelho possuir essa função).

Conecte o celular ao computador via cabo USB. Um aviso aparecerá na tela do celular; toque em Permitir depuração USB.

## Rodar o Aplicativo
Com o celular conectado e reconhecido pelo computador, execute o comando abaixo no terminal para iniciar o app:

```bash
flutter run
```