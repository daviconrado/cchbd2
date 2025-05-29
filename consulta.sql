--configurações para o teste
SET enable_seqscan = on;
SET enable_indexscan = on;
SET enable_bitmapscan= on;
SET enable_indexonlyscan = on;

--consulta 1
CREATE OR REPLACE VIEW consulta1 AS
SELECT cli.Nome 
FROM Corrida corrida -- seleciona o nome dos clientes que solicitaram corridas no taxi da marca Toyota
JOIN Cliente cli ON cli.CliId = corrida.CliId 
JOIN Taxi taxi ON corrida.Placa = taxi.Placa
WHERE taxi.Marca = 'Toyota';
--consulta 2
CREATE OR REPLACE VIEW consulta2 AS --filtra apenas as corridas feitas entre 16 de fevereiro de 2024 e 18 de fevereiro de 2025
SELECT c.Nome AS Cliente,t.Placa,t.Marca,co.DataPedido
FROM Corrida co
JOIN Cliente c ON co.CliId = c.CliId
JOIN Taxi t ON co.Placa = t.Placa
WHERE co.DataPedido BETWEEN '2024-02-16' AND '2025-02-18';

--consulta 3
CREATE OR REPLACE VIEW consulta3 AS
SELECT c.Nome
FROM Cliente c
WHERE (
  	SELECT COUNT(*) -- conta quantas corridas cada cliente realizou
    FROM Corrida co
    WHERE co.CliId = c.CliId
) > (
    SELECT AVG(qtd) -- calcula a média de corridas por cliente
    FROM (
        SELECT COUNT(*) AS qtd -- subconsulta que agrupa as corridas por cliente e conta quantas cada um teve
        FROM Corrida
        GROUP BY CliId
    ) AS sub
);

--consulta 4
CREATE OR REPLACE VIEW consulta4 AS
SELECT t.Marca AS Modelo, COUNT(DISTINCT c.CliId) AS TotalClientes -- para cada marca de táxi, mostra o número de clientes distintos que a utilizaram
FROM Corrida   co
JOIN Taxi t ON co.Placa = t.Placa
JOIN Cliente   c  ON co.CliId  = c.CliId
GROUP BY t.Marca;

--consulta 5
CREATE OR REPLACE VIEW consulta5 AS
SELECT t.Marca,-- seleciona a marca do táxi, o total de corridas, o total de clientes únicos 
                -- e a média de corridas por cliente (arredondada para 2 casas decimais)
COUNT(*)                         AS TotalCorridas,
COUNT(DISTINCT c.CliId)          AS ClientesUnicos,
ROUND(
    (COUNT(*)::numeric
     /
     COUNT(DISTINCT c.CliId)::numeric)
    , 2
  )                                 AS MediaCorridasPorCliente
FROM Corrida co
JOIN Taxi   t  ON co.Placa = t.Placa
JOIN Cliente c  ON co.CliId = c.CliId
GROUP BY t.Marca
HAVING COUNT(*) > 1; -- inclui apenas marcas com mais de uma corrida registrada


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
CREATE INDEX idx_corrida_date ON Corrida USING brin(DataPedido);
DROP INDEX idx_corrida_date;
--indices consulta 3
CREATE INDEX idx_corrida_cliid ON Corrida (CliId);
DROP INDEX idx_corrida_cliid;
--indices consulta 4
CREATE INDEX idx_taxi_marca_placa ON Taxi (Marca, Placa);
DROP INDEX idx_taxi_marca_placa;
--indices consulta 5
CREATE INDEX idx_taxi_marca ON Taxi(Marca);
DROP INDEX idx_taxi_marca_2;

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

        PERFORM * FROM consulta2; 

        fim := clock_timestamp();

        total_ms := total_ms + EXTRACT(EPOCH FROM (fim - inicio)) * 1000;
        i := i + 1;
    END LOOP;

    RETURN total_ms / 30;
END;
$$ LANGUAGE plpgsql;

SELECT tempo_medio_select_ms();