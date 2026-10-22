# Modelo de dados simplificado --- PoC de Ativos e Marcadores

Para a Prova de Conceito (PoC), o modelo de dados será limitado às
entidades **Ativo** e **Marcador**, conforme o diagrama de classes
apresentado e os diagramas lógico e conceitual do sistema. O objetivo é
demonstrar o cadastro e a identificação de ativos por meio de
marcadores, sem a necessidade de implementar um banco de dados
definitivo.

## 1. Entidades e atributos

### Entidade: Ativo

Representa um equipamento ou bem que precisa ser identificado e
localizado no sistema.

 
  Campo                   Tipo                    Descrição

  `id`                    Integer                 **Chave primária
                                                  (PK)**. Identificador
                                                  único do ativo.

  `patrimonio`            String                  Número de patrimônio do
                                                  ativo.

  `nome`                  String                  Nome ou identificação
                                                  do ativo.

  `localizacao`           String                  Local onde o ativo está
                                                  situado.


### Entidade: Marcador

Representa o marcador utilizado para identificar um ativo, por exemplo,
por meio de um código QR.


  Campo                   Tipo                    Descrição
  
  `id`                    Integer                 **Chave primária
                                                  (PK)**. Identificador
                                                  único do marcador.

  `codigo`                String                  Código de identificação
                                                  do marcador.

  `ativoId`               Integer                 **Chave estrangeira
                                                  (FK)** que referencia o
                                                  `id` do ativo
                                                  associado.


## 2. Relacionamento entre as entidades

O relacionamento entre `Ativo` e `Marcador` permite identificar qual
ativo está associado a determinado marcador.

-   Um **Ativo** pode possuir zero ou vários marcadores.
-   Cada **Marcador** está associado a exatamente um ativo.
-   O campo `ativoId` estabelece essa ligação entre as entidades.

``` text
Ativo (1) ───────── (0..N) Marcador

Ativo:
- id (PK)
- patrimonio
- nome
- localizacao

Marcador:
- id (PK)
- codigo
- ativoId (FK → Ativo.id)
```

## 3. Exemplo de representação em JSON

Para a PoC, os dados podem ser armazenados em um arquivo JSON, sem a
necessidade de configurar um banco de dados.

``` json
{
  "ativos": [
    {
      "id": 1,
      "patrimonio": "PAT-001",
      "nome": "Notebook",
      "localizacao": "Laboratorio 1"
    }
  ],
  "marcadores": [
    {
      "id": 1,
      "codigo": "QR-001",
      "ativoId": 1
    }
  ]
}
```

Nesse exemplo, o marcador `QR-001` está associado ao ativo de
identificador `1`, que corresponde ao notebook localizado no Laboratório
