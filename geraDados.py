import random
import string
from datetime import date, timedelta
import psycopg2
from psycopg2 import IntegrityError
from faker import Faker

# Configurações de conexão
DB_CONFIG = {'dbname': 'cch bd2 teste','user': 'postgres','password': '748596123','host': 'localhost','port': 5432}

# Quantidades de registros a serem gerados
NUM_TAXIS = 1000000
NUM_CLIENTES = 1000000
NUM_CORRIDAS = 1000000

# Listas de exemplos para marca e modelo
MARCAS = ['Toyota', 'Honda', 'Ford', 'Chevrolet', 'Volkswagen', 'Fiat', 'Renault']
MODELOS = ['Sedan', 'Hatch', 'SUV', 'Compacto', 'Luxo']

fake = Faker('pt_BR')


def gera_placa():
    letras = ''.join(random.choices(string.ascii_uppercase, k=3))
    numero_meio = random.randint(0, 9)
    letra_final = random.choice(string.ascii_uppercase)
    numeros_finais = ''.join(random.choices(string.digits, k=2))
    return f"{letras}{numero_meio}{letra_final}{numeros_finais}"


def gera_licenca():
    letras = ''.join(random.choices(string.ascii_uppercase, k=3))
    numeros = ''.join(random.choices(string.digits, k=4))
    return f"{letras}-{numeros}"


def conecta_db():
    return psycopg2.connect(**DB_CONFIG)


def popula_taxi(cursor):
    taxis = []
    while len(taxis) < NUM_TAXIS:
        placa = gera_placa()
        marca = random.choice(MARCAS)
        modelo = random.choice(MODELOS)
        ano = random.randint(2005, 2024)
        licenca = gera_licenca()
        try:
            cursor.execute(
                "INSERT INTO Taxi (Placa, Marca, Modelo, AnoFab, Licenca) VALUES (%s, %s, %s, %s, %s)",
                (placa, marca, modelo, ano, licenca)
            )
            taxis.append(placa)
        except IntegrityError:
            cursor.connection.rollback()
            # placa duplicada, gera outra
            continue
    return taxis


def popula_cliente(cursor):
    clientes = []
    cpfs_gerados = set()
    i = 1
    while len(clientes) < NUM_CLIENTES:
        cli_id = f"C{i:03d}"
        nome = fake.name()
        cpf = fake.cpf()
        while cpf in cpfs_gerados:  # Gera novo CPF se repetido
            cpf = fake.cpf()
        cpfs_gerados.add(cpf)
        try:
            cursor.execute(
                "INSERT INTO Cliente (CliId, Nome, CPF) VALUES (%s, %s, %s)",
                (cli_id, nome, cpf)
            )
            clientes.append(cli_id)
        except IntegrityError:
            cursor.connection.rollback()
            continue
        finally:
            i += 1
    return clientes


def popula_corrida(cursor, clientes, taxis):
    if not clientes or not taxis:
        raise ValueError("Listas de clientes ou taxis estão vazias")
    corridas = 0
    registros = set()
    while corridas < NUM_CORRIDAS:
        cli = random.choice(clientes)
        tx = random.choice(taxis)
        data_pedido = fake.date_between(start_date='-1y', end_date='today')
        chave = (cli, tx, data_pedido)
        if chave in registros:
            continue 
        registros.add(chave)
        try:
            cursor.execute(
                "INSERT INTO Corrida (CliId, Placa, DataPedido) VALUES (%s, %s, %s)",
                (cli, tx, data_pedido)
            )
            corridas += 1
        except IntegrityError:
            cursor.connection.rollback()
            continue


def main():
    conn = conecta_db()
    cur = conn.cursor()
    try:
        # Limpa tabelas antes de inserir novos dados
        cur.execute("DELETE FROM Corrida;")
        cur.execute("DELETE FROM Cliente;")
        cur.execute("DELETE FROM Taxi;")
        conn.commit()

        taxis = popula_taxi(cur)
        clientes = popula_cliente(cur)
        popula_corrida(cur, clientes, taxis)
        conn.commit()
        print("Dados populados com sucesso!")
    except Exception as e:
        conn.rollback()
        print("Erro ao popular dados:", e)
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
