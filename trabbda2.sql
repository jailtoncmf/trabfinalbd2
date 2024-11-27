CREATE TABLE Usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    cargo VARCHAR(50) NOT NULL
);

CREATE TABLE Espaco (
    id_espaco SERIAL  PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    equipamentos TEXT
);

CREATE TABLE Solicitacao (
    id_solicitacao SERIAL PRIMARY KEY,
    id_usuario SERIAL NOT NULL,
    id_espaco SERIAL NOT NULL,
    data_solicitacao TIMESTAMP NOT NULL DEFAULT,
    data_inicio TIMESTAMP NOT NULL,
    data_fim TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDENTE',
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario),
    FOREIGN KEY (id_espaco) REFERENCES Espaco(id_espaco)
);

CREATE TABLE Avaliacao (
    id_avaliacao SERIAL PRIMARY KEY,
    id_solicitacao SERIAL NOT NULL,
    id_usuario SERIAL NOT NULL,
    data_avaliacao TIMESTAMP NOT NULL,
    resultado VARCHAR(50) NOT NULL,
    comentario TEXT,
    FOREIGN KEY (id_solicitacao) REFERENCES Solicitacao(id_solicitacao),
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);

CREATE TABLE Auditoria (
    id_auditoria SERIAL PRIMARY KEY,
    id_usuario SERIAL NOT NULL,
    acao VARCHAR(255) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);

CREATE TABLE Feriados (
    id_feriado SERIAL PRIMARY KEY,
    data DATE NOT NULL UNIQUE,
    descricao VARCHAR(255)
);

--
CREATE OR REPLACE FUNCTION valida_cargo_avaliador()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Usuario
        WHERE id_usuario = NEW.id_usuario
          AND cargo IN ('ADMINISTRADOR', 'GESTOR')
    ) THEN
        RAISE EXCEPTION 'Somente ADMINISTRADOR ou GESTOR podem avaliar solicitações.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--
CREATE OR REPLACE FUNCTION valida_horario_reserva()
RETURNS TRIGGER AS $$
BEGIN
    IF EXTRACT(HOUR FROM NEW.data_inicio) < 7 OR EXTRACT(HOUR FROM NEW.data_fim) > 22 THEN
        RAISE EXCEPTION 'Reservas só podem ser feitas entre 07:00 e 22:00.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valida_horario_reserva
BEFORE INSERT ON Solicitacao
FOR EACH ROW
EXECUTE FUNCTION valida_horario_reserva();

--

CREATE OR REPLACE FUNCTION valida_sobreposicao_reserva()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Solicitacao
        WHERE id_espaco = NEW.id_espaco
        AND status = 'APROVADO'
        AND NEW.data_inicio < data_fim
        AND NEW.data_fim > data_inicio
    ) THEN
        RAISE EXCEPTION 'Conflito de horários na reserva.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valida_sobreposicao_reserva
BEFORE INSERT ON Solicitacao
FOR EACH ROW
EXECUTE FUNCTION valida_sobreposicao_reserva();

--

CREATE OR REPLACE FUNCTION verifica_dia_util(data DATE) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        EXTRACT(DOW FROM data) != 0 AND  -- 0 é domingo
        NOT EXISTS (SELECT 1 FROM Feriados WHERE data = data)
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION valida_dia_util()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT verifica_dia_util(NEW.data_inicio) THEN
        RAISE EXCEPTION 'Não é permitido reservas em domingos ou feriados.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valida_dia_util
BEFORE INSERT ON Solicitacao
FOR EACH ROW
EXECUTE FUNCTION valida_dia_util();

-- 

INSERT INTO Usuario (nome, email, senha, cargo) 
VALUES 
('Ana Silva', 'ana.silva@email.com', 'senha123', 'PROFESSOR'),
('Carlos Mendes', 'carlos.mendes@email.com', 'senha123', 'GESTOR'),
('Maria Oliveira', 'maria.oliveira@email.com', 'senha123', 'ADMINISTRADOR');

--
INSERT INTO Espaco (nome, equipamentos) 
VALUES 
('Laboratório de Informática', 'Computadores, Projetor'),
('Sala de Aula A', 'Quadro Branco, Projetor'),
('Auditório Principal', 'Palco, Som, Iluminação');
--
INSERT INTO Feriados (data, descricao) 
VALUES 
('2024-12-25', 'Natal'),
('2024-01-01', 'Ano Novo'),
('2024-11-15', 'Proclamação da República');
--

INSERT INTO Solicitacao (id_usuario, id_espaco, data_solicitacao, data_inicio, data_fim) 
VALUES 
(1, 1, '2024-10-25 10:00:00', '2024-10-28 09:00:00', '2024-10-28 11:00:00'),
(1, 2, '2024-11-25 11:00:00', '2024-11-29 14:00:00', '2024-11-29 16:00:00'),
(2, 3, '2024-11-30 08:00:00', '2024-11-30 13:00:00', '2024-11-30 15:00:00');

--

INSERT INTO Avaliacao (id_solicitacao, id_usuario, data_avaliacao, resultado, comentario) 
VALUES 
(1, 1, '2024-10-27 10:00:00', 'APROVADO', 'Solicitação aprovada para o horário solicitado.'),
(2, 1, '2024-11-27 11:00:00', 'APROVADO', 'Aprovado com ajustes mínimos.'),
(3, 2, '2024-11-27 12:00:00', 'REJEITADO', 'Conflito com outro evento no auditório.');


--

INSERT INTO Auditoria (id_usuario, acao, data_hora) 
VALUES 
(1, 'Inserção de nova solicitação (id_solicitacao=1)', '2024-11-25 10:00:00'),
(2, 'Avaliação de solicitação (id_solicitacao=1)', '2024-11-27 10:00:00'),
('Inserção de novo espaço físico (id_espaco=3)', '2024-11-25 12:00:00');

SELECT * FROM SOLICITACAO;

--1 Todos os espaços físicos cadastrados, com todas as informações lançadas
SELECT * FROM ESPACO;

--2 Todos os usuários solicitantes cadastrados
SELECT id_usuario, nome, email 
FROM Usuario
WHERE cargo = 'PROFESSOR';

--3 Todos os gestores cadastrados
SELECT id_usuario, nome, email 
FROM Usuario
WHERE cargo = 'GESTOR';

--4 Todas as solicitações feitas pelos usuários
SELECT S.id_solicitacao, S.id_usuario, U.nome AS solicitante, S.id_espaco, E.nome AS espaco, 
       S.data_solicitacao, S.data_inicio, S.data_fim, S.status
FROM Solicitacao S
JOIN Usuario U ON S.id_usuario = U.id_usuario
JOIN Espaco E ON S.id_espaco = E.id_espaco;

--5 A auditoria das ações no sistema (log de auditoria)
SELECT A.id_auditoria, A.id_usuario, U.nome AS usuario, A.acao, A.data_hora
FROM Auditoria A
JOIN Usuario U ON A.id_usuario = U.id_usuario;

--6 O histórico com todas as avaliações feitas pelo gestor, incluindo o status de cada solicitação
SELECT AV.id_avaliacao, AV.id_usuario AS id_gestor, G.nome AS gestor, 
       AV.id_solicitacao, S.id_usuario AS id_solicitante, U.nome AS solicitante, 
       S.status AS status_solicitacao, AV.resultado AS resultado_avaliacao, AV.comentario, AV.data_avaliacao
FROM Avaliacao AV
JOIN Solicitacao S ON AV.id_solicitacao = S.id_solicitacao
JOIN Usuario U ON S.id_usuario = U.id_usuario
JOIN Usuario G ON AV.id_usuario = G.id_usuario;

--7 Lista de todas as solicitações aprovadas, incluindo: o espaço reservado, a data e a hora da reserva
SELECT S.id_solicitacao, S.id_usuario AS id_solicitante, U.nome AS solicitante, 
       S.id_espaco, E.nome AS espaco, S.data_inicio, S.data_fim
FROM Solicitacao S
JOIN Espaco E ON S.id_espaco = E.id_espaco
JOIN Usuario U ON S.id_usuario = U.id_usuario
WHERE S.status = 'APROVADO';
