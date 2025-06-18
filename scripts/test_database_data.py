#!/usr/bin/env python3
"""
Script de teste para verificar os dados no banco PostgreSQL
"""

import psycopg2
import pandas as pd
from datetime import datetime
import sys
import os

# Configurações do banco
DB_CONFIG = {
    'host': 'localhost',
    'port': '5430',  # Porta correta do container Docker
    'database': 'db_source',  # Banco correto onde estão os dados
    'user': 'admin',
    'password': 'admin123'
}

def connect_to_db():
    """Conecta ao banco PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"❌ Erro ao conectar ao banco: {e}")
        return None

def test_connection():
    """Testa a conexão com o banco"""
    print("🔍 Testando conexão com o banco PostgreSQL...")
    conn = connect_to_db()
    if conn:
        print("✅ Conexão estabelecida com sucesso!")
        conn.close()
        return True
    else:
        print("❌ Falha na conexão com o banco")
        return False

def check_databases():
    """Verifica os bancos disponíveis"""
    print("\n🗄️ Verificando bancos disponíveis...")
    conn = connect_to_db()
    if not conn:
        return
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
            FROM pg_database 
            WHERE datistemplate = false
            ORDER BY datname;
        """)
        databases = cursor.fetchall()
        
        print("Bancos encontrados:")
        for db_name, size in databases:
            print(f"  - {db_name} ({size})")
            
    except Exception as e:
        print(f"❌ Erro ao verificar bancos: {e}")
    finally:
        conn.close()

def check_schemas():
    """Verifica os schemas disponíveis"""
    print("\n📋 Verificando schemas disponíveis...")
    conn = connect_to_db()
    if not conn:
        return
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT schema_name 
            FROM information_schema.schemata 
            WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
            ORDER BY schema_name;
        """)
        schemas = cursor.fetchall()
        
        print("Schemas encontrados:")
        for schema in schemas:
            print(f"  - {schema[0]}")
            
    except Exception as e:
        print(f"❌ Erro ao verificar schemas: {e}")
    finally:
        conn.close()

def check_tables_in_schema(schema_name):
    """Verifica as tabelas em um schema específico"""
    print(f"\n📊 Verificando tabelas no schema '{schema_name}'...")
    conn = connect_to_db()
    if not conn:
        return
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT table_name, 
                   (SELECT COUNT(*) FROM information_schema.columns 
                    WHERE table_schema = %s AND table_name = t.table_name) as column_count
            FROM information_schema.tables t
            WHERE table_schema = %s
            ORDER BY table_name;
        """, (schema_name, schema_name))
        tables = cursor.fetchall()
        
        if tables:
            print(f"Tabelas encontradas no schema '{schema_name}':")
            for table_name, column_count in tables:
                print(f"  - {table_name} ({column_count} colunas)")
        else:
            print(f"❌ Nenhuma tabela encontrada no schema '{schema_name}'")
            
    except Exception as e:
        print(f"❌ Erro ao verificar tabelas: {e}")
    finally:
        conn.close()

def count_records_in_table(schema_name, table_name):
    """Conta registros em uma tabela específica"""
    conn = connect_to_db()
    if not conn:
        return 0
    
    try:
        cursor = conn.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM {schema_name}.{table_name}")
        count = cursor.fetchone()[0]
        return count
    except Exception as e:
        print(f"❌ Erro ao contar registros em {schema_name}.{table_name}: {e}")
        return 0
    finally:
        conn.close()

def show_sample_data(schema_name, table_name, limit=5):
    """Mostra dados de exemplo de uma tabela"""
    print(f"\n📄 Amostra de dados da tabela {schema_name}.{table_name}:")
    conn = connect_to_db()
    if not conn:
        return
    
    try:
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM {schema_name}.{table_name} LIMIT {limit}")
        records = cursor.fetchall()
        
        # Pega os nomes das colunas
        cursor.execute(f"""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = %s AND table_name = %s 
            ORDER BY ordinal_position
        """, (schema_name, table_name))
        columns = [col[0] for col in cursor.fetchall()]
        
        if records:
            # Cria DataFrame para melhor visualização
            df = pd.DataFrame(records, columns=columns)
            print(df.to_string(index=False))
        else:
            print("❌ Nenhum registro encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao buscar dados: {e}")
    finally:
        conn.close()

def check_recent_data():
    """Verifica dados recentes nas tabelas principais"""
    print("\n🕒 Verificando dados recentes...")
    
    # Tabelas principais para verificar
    main_tables = [
        ('public', 'clientes'),
        ('public', 'produtos'),
        ('public', 'vendas'),
        ('public', 'itens_venda'),
        ('transacional', 'vendas'),
        ('transacional', 'clientes'),
        ('staging', 'vendas'),
        ('staging', 'clientes')
    ]
    
    for schema, table in main_tables:
        try:
            count = count_records_in_table(schema, table)
            print(f"  {schema}.{table}: {count} registros")
            
            if count > 0:
                show_sample_data(schema, table, 3)
                print("-" * 50)
        except:
            print(f"  {schema}.{table}: Tabela não existe ou erro ao acessar")

def check_dbt_models():
    """Verifica se os modelos DBT foram executados"""
    print("\n🔧 Verificando modelos DBT...")
    
    # Verifica tabelas/views criadas pelo DBT nos schemas corretos
    dbt_schemas = ['public_bronze', 'public_silver', 'public_gold']
    
    for schema in dbt_schemas:
        check_tables_in_schema(schema)

def main():
    """Função principal"""
    print("🚀 TESTE DE DADOS NO BANCO POSTGRESQL")
    print("=" * 50)
    print(f"Timestamp: {datetime.now()}")
    
    # Testa conexão
    if not test_connection():
        sys.exit(1)
    
    # Verifica bancos disponíveis
    check_databases()
    
    # Verifica schemas
    check_schemas()
    
    # Verifica tabelas em cada schema
    schemas_to_check = ['public', 'transacional', 'staging', 'public_bronze', 'public_silver', 'public_gold']
    for schema in schemas_to_check:
        check_tables_in_schema(schema)
    
    # Verifica dados recentes
    check_recent_data()
    
    # Verifica modelos DBT
    check_dbt_models()
    
    print("\n✅ Teste concluído!")

if __name__ == "__main__":
    main()