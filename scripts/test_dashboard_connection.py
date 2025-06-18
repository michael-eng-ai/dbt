#!/usr/bin/env python3
"""
Script de Teste - Conexão Dashboard
Verifica se o dashboard consegue conectar ao banco e acessar as tabelas DBT
"""

import psycopg2
import pandas as pd
from datetime import datetime

# Configurações de conexão (mesmas do dashboard)
DB_CONFIG = {
    'host': 'localhost',
    'port': 5430,
    'database': 'db_source',
    'user': 'admin',
    'password': 'admin'
}

def test_connection():
    """Testa a conexão básica com o banco"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        print("✅ Conexão com banco estabelecida com sucesso")
        
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"📊 Versão PostgreSQL: {version}")
        
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Erro ao conectar: {e}")
        return False

def test_source_tables():
    """Testa acesso às tabelas de origem"""
    print("\n🔍 Testando tabelas de origem...")
    
    tables_to_test = [
        ('public.clientes', 'Clientes'),
        ('public.pedidos', 'Pedidos'),
        ('public.produtos', 'Produtos')
    ]
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        
        for table, name in tables_to_test:
            try:
                query = f"SELECT COUNT(*) FROM {table}"
                df = pd.read_sql_query(query, conn)
                count = df.iloc[0, 0]
                print(f"  ✅ {name}: {count} registros")
            except Exception as e:
                print(f"  ❌ {name}: Erro - {e}")
        
        conn.close()
    except Exception as e:
        print(f"❌ Erro geral: {e}")

def test_dbt_tables():
    """Testa acesso às tabelas DBT"""
    print("\n🏗️ Testando tabelas DBT...")
    
    dbt_tables = [
        ('public_bronze.bronze_clientes', 'Bronze - Clientes'),
        ('public_bronze.bronze_pedidos', 'Bronze - Pedidos'),
        ('public_silver.dim_clientes', 'Silver - Dim Clientes'),
        ('public_silver.fct_pedidos', 'Silver - Fct Pedidos'),
        ('public_gold.gold_analise_coorte', 'Gold - Análise Coorte'),
        ('public_gold.gold_deteccao_anomalias', 'Gold - Detecção Anomalias')
    ]
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        
        for table, name in dbt_tables:
            try:
                query = f"SELECT COUNT(*) FROM {table}"
                df = pd.read_sql_query(query, conn)
                count = df.iloc[0, 0]
                print(f"  ✅ {name}: {count} registros")
            except Exception as e:
                print(f"  ❌ {name}: Erro - {e}")
        
        conn.close()
    except Exception as e:
        print(f"❌ Erro geral: {e}")

def test_dashboard_queries():
    """Testa as principais consultas do dashboard"""
    print("\n📊 Testando consultas do dashboard...")
    
    queries = [
        (
            "Métricas Principais",
            """
            SELECT 
                (SELECT COUNT(*) FROM public.clientes) as total_clientes,
                (SELECT COUNT(*) FROM public.pedidos) as total_pedidos,
                (SELECT COALESCE(SUM(valor_bruto), 0) FROM public.pedidos) as receita_total,
                (SELECT COALESCE(AVG(valor_bruto), 0) FROM public.pedidos) as ticket_medio
            """
        ),
        (
            "Top Clientes",
            """
            SELECT 
                c.nome,
                COUNT(p.id) as total_pedidos,
                SUM(p.valor_bruto) as receita_total
            FROM public.clientes c
            LEFT JOIN public.pedidos p ON c.id = p.cliente_id
            GROUP BY c.id, c.nome
            HAVING SUM(p.valor_bruto) IS NOT NULL
            ORDER BY receita_total DESC
            LIMIT 5
            """
        )
    ]
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        
        for name, query in queries:
            try:
                df = pd.read_sql_query(query, conn)
                print(f"  ✅ {name}: {len(df)} linhas retornadas")
                if not df.empty:
                    print(f"    📋 Amostra: {df.iloc[0].to_dict()}")
            except Exception as e:
                print(f"  ❌ {name}: Erro - {e}")
        
        conn.close()
    except Exception as e:
        print(f"❌ Erro geral: {e}")

def main():
    print("🧪 TESTE DE CONEXÃO DO DASHBOARD")
    print("=" * 50)
    print(f"⏰ Executado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🔗 Conectando em: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")
    print("=" * 50)
    
    # Executa todos os testes
    if test_connection():
        test_source_tables()
        test_dbt_tables()
        test_dashboard_queries()
        
        print("\n" + "=" * 50)
        print("✅ TESTE CONCLUÍDO")
        print("💡 Se todos os testes passaram, o dashboard deve funcionar corretamente")
        print("🚀 Execute: streamlit run dashboard.py")
    else:
        print("\n❌ FALHA NA CONEXÃO - Verifique se o PostgreSQL está rodando")

if __name__ == "__main__":
    main()