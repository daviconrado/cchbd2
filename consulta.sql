--consulta 1
CREATE OR REPLACE VIEW consulta1 AS
SELECT cli.Nome 
FROM Corrida corrida -- seleciona o nome dos clientes que solicitaram corridas no taxi da marca Toyota
JOIN Cliente cli ON cli.CliId = corrida.CliId 
JOIN Taxi taxi ON corrida.Placa = taxi.Placa
WHERE taxi.Marca = 'Toyota';

--consulta 2
CREATE OR REPLACE VIEW consulta2 AS --filtra apenas as corridas feitas entre fevereiro e março de 2025
SELECT c.Nome AS Cliente,t.Placa,t.Marca,co.DataPedido
FROM Corrida co
JOIN Cliente c ON co.CliId = c.CliId
JOIN Taxi t ON co.Placa = t.Placa
WHERE co.DataPedido BETWEEN '2025-02-01' AND '2025-03-01';

--consulta 3
CREATE OR REPLACE VIEW consulta3 AS
SELECT Nome
FROM (
  SELECT
    c.Nome,
    COUNT(co.CliId) AS cnt,
    AVG(COUNT(co.CliId)) OVER () AS avg_cnt
  FROM
    Cliente c
    LEFT JOIN Corrida co
      ON co.CliId = c.CliId
  GROUP BY
    c.CliId, c.Nome
) sub
WHERE
  cnt > avg_cnt;


--consulta 4
CREATE OR REPLACE VIEW consulta4 AS
SELECT
  t.Marca  AS Modelo,
  COUNT(*) AS TotalClientes
FROM (
    SELECT DISTINCT 
      co.Placa,
      co.CliId
    FROM Corrida co
) AS sub
JOIN Taxi   t ON sub.Placa = t.Placa
GROUP BY t.Marca;


--consulta 5
CREATE OR REPLACE VIEW consulta5 AS
SELECT 
  c.CliId,
  c.Nome AS NomeCliente,
  c.CPF,
  t.Placa,
  t.Marca,
  t.Modelo,
  t.AnoFab,
  t.Licenca,
  co.DataPedido
FROM Corrida co
JOIN Cliente c ON co.CliId = c.CliId
JOIN Taxi t ON co.Placa = t.Placa
WHERE Nome ~ 'a$'


--executando consultas
EXPLAIN ANALYZE
SELECT * FROM consulta1;

EXPLAIN ANALYZE
SELECT * FROM consulta2;

EXPLAIN ANALYZE
SELECT * FROM consulta3;

EXPLAIN ANALYZE
SELECT * FROM consulta4;

EXPLAIN ANALYZE
SELECT * FROM consulta5;


--indices

--indices consulta 1
CREATE INDEX idx_taxi_marca ON Taxi USING hash(Marca);
DROP INDEX idx_taxi_marca;
--indices consulta 2
CREATE INDEX idx_corrida_date ON Corrida(DataPedido);
DROP INDEX idx_corrida_date;
--indices consulta 3
CREATE INDEX idx_corrida_cliid ON Corrida (CliId);
DROP INDEX idx_corrida_cliid;
--indices consulta 4
CREATE INDEX idx_corrida_placa_cliid ON Corrida (Placa, CliId);
DROP INDEX idx_corrida_placa_cliid;
--indices consulta 5
CREATE INDEX idx_cliente_nome ON Cliente(Nome);
DROP INDEX idx_cliente_nome;

--função que calcula o tempo médio com 30 consultas
CREATE OR REPLACE FUNCTION tempo_medio_select_ms()
RETURNS double precision AS $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
    total_ms DOUBLE PRECISION := 0;
    i INTEGER := 1;
BEGIN
    WHILE i <= 30 LOOP
        inicio := clock_timestamp();

        PERFORM * FROM consulta5; 

        fim := clock_timestamp();

        total_ms := total_ms + EXTRACT(EPOCH FROM (fim - inicio)) * 1000;
        i := i + 1;
    END LOOP;

    RETURN total_ms / 30;
END;
$$ LANGUAGE plpgsql;

SELECT tempo_medio_select_ms();