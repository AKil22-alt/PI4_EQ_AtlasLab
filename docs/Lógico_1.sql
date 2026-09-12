/* Lógico_1: */

CREATE TABLE Usuarios (
    Id_user INTEGER PRIMARY KEY,
    Nome VARCHAR,
    Email VARCHAR,
    Cargo VARCHAR,
    Foto BLOB,
    Senha VARCHAR,
    UNIQUE (Id_user, Email)
);

CREATE TABLE Ativo (
    Id_Ativos INTEGER PRIMARY KEY UNIQUE,
    Nome  VARCHAR,
    QR_Code BLOB,
    Status VARCHAR,
    Local_origem VARCHAR,
    Local_atual VARCHAR,
    Descrição VARCHAR,
    fk_Salas/Labs_Id_Sala VARCHAR,
    fk_Grupo_A_Id_Grupo_A INTEGER
);

CREATE TABLE Salas/Labs (
    Id_Sala VARCHAR PRIMARY KEY UNIQUE,
    Nome VARCHAR,
    Numero_TA INTEGER,
    Localização VARCHAR,
    Descrição VARCHAR,
    Id_user INTEGER
);

CREATE TABLE Manutenção_A (
    Id_Man INTEGER PRIMARY KEY UNIQUE,
    Tipo VARCHAR,
    Descrição VARCHAR,
    Prioridade VARCHAR,
    Gravidade VARCHAR,
    Numero_TAG INTEGER,
    Utima_manutenção VARCHAR,
    Data_Hora_entrada TIMESTAMP,
    Data_Hora_Saida TIMESTAMP
);

CREATE TABLE Movimentações (
    Justificativa VARCHAR,
    Previsao_Data_hora VARCHAR,
    Id_Mov INTEGER PRIMARY KEY UNIQUE,
    Contagem_mov_A INTEGER,
    Data_Hora_entrada TIMESTAMP,
    Data_Hora_Saida TIMESTAMP,
    Local_M VARCHAR,
    fk_Usuarios_Id_user INTEGER,
    fk_Ativo_Id_Ativos INTEGER,
    fk_Manutenção_A_Id_Man INTEGER
);

CREATE TABLE Grupo_A (
    Id_Grupo_A INTEGER PRIMARY KEY UNIQUE,
    Nome VARCHAR,
    Numero_TA INTEGER,
    Tipo VARCHAR,
    Setor VARCHAR
);

CREATE TABLE Ordem_serviço (
    Id_Ordem INTEGER PRIMARY KEY UNIQUE,
    Descrição VARCHAR,
    Titulo VARCHAR,
    Data_hora VARCHAR
);

CREATE TABLE Denuncias_F (
    Id_denuncia INTEGER PRIMARY KEY UNIQUE,
    Descrição VARCHAR,
    Imagem BLOB,
    Classificação VARCHAR,
    fk_Usuarios_Id_user INTEGER
);

CREATE TABLE OS_User (
    fk_Ordem_serviço_Id_Ordem INTEGER,
    fk_Usuarios_Id_user INTEGER,
    Data_hora_OP VARCHAR
);

CREATE TABLE OS_Salas/Labs (
    fk_Ordem_serviço_Id_Ordem INTEGER,
    fk_Salas/Labs_Id_Sala VARCHAR,
    Data_hora VARCHAR
);

CREATE TABLE OS_Ativo (
    fk_Ordem_serviço_Id_Ordem INTEGER,
    fk_Ativo_Id_Ativos INTEGER,
    Data_hora VARCHAR
);

CREATE TABLE OS_Manutenção (
    fk_Manutenção_A_Id_Man INTEGER,
    fk_Ordem_serviço_Id_Ordem INTEGER,
    Data_hora VARCHAR
);
 
ALTER TABLE Ativo ADD CONSTRAINT FK_Ativo_2
    FOREIGN KEY (fk_Salas/Labs_Id_Sala)
    REFERENCES Salas/Labs (Id_Sala)
    ON DELETE SET NULL;
 
ALTER TABLE Ativo ADD CONSTRAINT FK_Ativo_3
    FOREIGN KEY (fk_Grupo_A_Id_Grupo_A)
    REFERENCES Grupo_A (Id_Grupo_A)
    ON DELETE CASCADE;
 
ALTER TABLE Salas/Labs ADD CONSTRAINT Id_user
    FOREIGN KEY (Id_user???, Id_user)
    REFERENCES Usuarios (???, Id_user);
 
ALTER TABLE Movimentações ADD CONSTRAINT FK_Movimentações_2
    FOREIGN KEY (fk_Usuarios_Id_user)
    REFERENCES Usuarios (Id_user);
 
ALTER TABLE Movimentações ADD CONSTRAINT FK_Movimentações_3
    FOREIGN KEY (fk_Ativo_Id_Ativos)
    REFERENCES Ativo (Id_Ativos);
 
ALTER TABLE Movimentações ADD CONSTRAINT FK_Movimentações_4
    FOREIGN KEY (fk_Manutenção_A_Id_Man)
    REFERENCES Manutenção_A (Id_Man);
 
ALTER TABLE Denuncias_F ADD CONSTRAINT FK_Denuncias_F_2
    FOREIGN KEY (fk_Usuarios_Id_user)
    REFERENCES Usuarios (Id_user)
    ON DELETE CASCADE;
 
ALTER TABLE OS_User ADD CONSTRAINT FK_OS_User_1
    FOREIGN KEY (fk_Ordem_serviço_Id_Ordem)
    REFERENCES Ordem_serviço (Id_Ordem)
    ON DELETE RESTRICT;
 
ALTER TABLE OS_User ADD CONSTRAINT FK_OS_User_2
    FOREIGN KEY (fk_Usuarios_Id_user)
    REFERENCES Usuarios (Id_user)
    ON DELETE SET NULL;
 
ALTER TABLE OS_Salas/Labs ADD CONSTRAINT FK_OS_Salas/Labs_1
    FOREIGN KEY (fk_Ordem_serviço_Id_Ordem)
    REFERENCES Ordem_serviço (Id_Ordem)
    ON DELETE SET NULL;
 
ALTER TABLE OS_Salas/Labs ADD CONSTRAINT FK_OS_Salas/Labs_2
    FOREIGN KEY (fk_Salas/Labs_Id_Sala)
    REFERENCES Salas/Labs (Id_Sala)
    ON DELETE SET NULL;
 
ALTER TABLE OS_Ativo ADD CONSTRAINT FK_OS_Ativo_1
    FOREIGN KEY (fk_Ordem_serviço_Id_Ordem)
    REFERENCES Ordem_serviço (Id_Ordem)
    ON DELETE RESTRICT;
 
ALTER TABLE OS_Ativo ADD CONSTRAINT FK_OS_Ativo_2
    FOREIGN KEY (fk_Ativo_Id_Ativos)
    REFERENCES Ativo (Id_Ativos)
    ON DELETE SET NULL;
 
ALTER TABLE OS_Manutenção ADD CONSTRAINT FK_OS_Manutenção_1
    FOREIGN KEY (fk_Manutenção_A_Id_Man)
    REFERENCES Manutenção_A (Id_Man)
    ON DELETE RESTRICT;
 
ALTER TABLE OS_Manutenção ADD CONSTRAINT FK_OS_Manutenção_2
    FOREIGN KEY (fk_Ordem_serviço_Id_Ordem)
    REFERENCES Ordem_serviço (Id_Ordem)
    ON DELETE SET NULL;