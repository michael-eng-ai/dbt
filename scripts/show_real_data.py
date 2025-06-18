#!/usr/bin/env python3
"""
Script para mostrar dados reais das tabelas que existem no banco
"""

import psycopg2
import pandas as pd
from datetime import datetime

# Configurações do banco
DB_CONFIG = {
    'host': 'localhost',
    'port': '5430',
    'database': 'db_source',
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

def show_table_data(schema, table, limit=10):
    """Mostra dados de uma tabela específica"""
    print(f"\n📊 DADOS DA TABELA {schema}.{table}")
    print("=" * 60)
    
    conn = connect_to_db()
    if not conn:
        return
    
    try:
        cursor = conn.cursor()
        
        # Conta total de registros
        cursor.execute(f"SELECT COUNT(*) FROM {schema}.{table}")
        total_count = cursor.fetchone()[0]
        print(f"📈 Total de registros: {total_count}")
        
        if total_count == 0:
            print("❌ Tabela vazia")
            return
        
        # Pega os nomes das colunas
        cursor.execute(f"""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_schema = %s AND table_name = %s 
            ORDER BY ordinal_position
        """, (schema, table))
        columns_info = cursor.fetchall()
        
        print(f"📋 Colunas ({len(columns_info)}):")
        for col_name, col_type in columns_info:
            print(f"  - {col_name} ({col_type})")
        
        # Mostra dados de exemplo
        cursor.execute(f"SELECT * FROM {schema}.{table} LIMIT {limit}")
        records = cursor.fetchall()
        
        if records:
            columns = [col[0] for col in columns_info]
            df = pd.DataFrame(records, columns=columns)
            print(f"\n📄 Primeiros {len(records)} registros:")
            print(df.to_string(index=False, max_colwidth=50))
        
    except Exception as e:
        print(f"❌ Erro ao buscar dados: {e}")
    finally:
        conn.close()

def main():
    """Função principal"""
    print("🔍 ANÁLISE DETALHADA DOS DADOS REAIS")
    print("=" * 50)
    print(f"Timestamp: {datetime.now()}")
    
    # Tabelas principais que existem
    tables_to_check = [
        # Dados originais
        ('public', 'clientes'),
        ('public', 'produtos'),
        ('public', 'pedidos'),
        ('public', 'itens_pedido'),
        ('public', 'leads'),
        ('public', 'campanhas_marketing'),
        
        # Camada Bronze
        ('public_bronze', 'bronze_clientes'),
        ('public_bronze', 'bronze_produtos'),
        ('public_bronze', 'bronze_pedidos'),
        ('public_bronze', 'bronze_leads'),
        
        # Camada Silver
        ('public_silver', 'silver_clientes'),
        ('public_silver', 'silver_produtos'),
        ('public_silver', 'silver_pedidos'),
        ('public_silver', 'dim_clientes'),
        ('public_silver', 'fct_pedidos'),
        
        # Camada Gold
        ('public_gold', 'gold_visao_geral_clientes'),
        ('public_gold', 'gold_metricas_avancadas_clientes'),
        ('public_gold', 'agg_valor_pedidos_por_cliente_mensal'),
        ('public_gold', 'gold_analise_coorte'),
        ('public_gold', 'gold_deteccao_anomalias')
    ]
    
    for schema, table in tables_to_check:
        try:
            show_table_data(schema, table, 5)
            print("\n" + "-" * 80)
        except Exception as e:
            print(f"❌ Erro ao processar {schema}.{table}: {e}")
    
    print("\n✅ Análise concluída!")

if __name__ == "__main__":
    main()