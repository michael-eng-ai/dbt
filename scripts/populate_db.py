#!/usr/bin/env python3
"""
Script para popular banco de dados com dados fictícios
Usado pelo Airflow para simular dados em produção
"""

import psycopg2
import random
from datetime import datetime, timedelta

# Configurações de conexão
DB_CONFIG = {
    'host': 'localhost',  # Conecta via porta mapeada
    'port': 5430,
    'database': 'db_source',
    'user': 'admin',
    'password': 'admin'
}

def conectar_db():
    """Conecta ao banco PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        return conn
    except Exception as e:
        print(f"❌ Erro ao conectar ao banco: {e}")
        return None

def inserir_dados_ficticios():
    """Insere dados fictícios no banco"""
    conn = conectar_db()
    if not conn:
        return False
    
    try:
        cur = conn.cursor()
        
        # Inserir alguns clientes
        clientes = [
            ('João Silva', 'joao@email.com'),
            ('Maria Santos', 'maria@email.com'),
            ('Pedro Costa', 'pedro@email.com')
        ]
        
        for nome, email in clientes:
            cur.execute("""
                INSERT INTO public.clientes (nome, email, data_cadastro)
                VALUES (%s, %s, %s)
                ON CONFLICT (email) DO NOTHING
            """, (nome, email, datetime.now()))
        
        # Primeiro inserir alguns produtos
        produtos_data = [
            ('NB001', 'Notebook Dell', 'Eletrônicos', 1200.00),
            ('MS001', 'Mouse Logitech', 'Periféricos', 50.00),
            ('TC001', 'Teclado Mecânico', 'Periféricos', 150.00),
            ('MN001', 'Monitor 24"', 'Eletrônicos', 300.00)
        ]
        
        for codigo, nome, categoria, preco in produtos_data:
            cur.execute("""
                INSERT INTO public.produtos (codigo_produto, nome, categoria, preco_venda)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (codigo_produto) DO NOTHING
            """, (codigo, nome, categoria, preco))
        
        # Inserir alguns pedidos
        for i in range(5):
            numero_pedido = f"PED{datetime.now().strftime('%Y%m%d')}{i+1:03d}"
            cur.execute("""
                INSERT INTO public.pedidos (cliente_id, numero_pedido, valor_bruto, status, data_pedido)
                SELECT id, %s, %s, %s, %s
                FROM public.clientes
                ORDER BY RANDOM()
                LIMIT 1
            """, (
                numero_pedido,
                round(random.uniform(100, 1000), 2),
                'concluido',
                datetime.now() - timedelta(days=random.randint(0, 30))
            ))
            
        # Inserir itens dos pedidos
        cur.execute("""
            INSERT INTO public.itens_pedido (pedido_id, produto_id, quantidade, preco_unitario)
            SELECT p.id, pr.id, %s, pr.preco_venda
            FROM public.pedidos p
            CROSS JOIN public.produtos pr
            ORDER BY RANDOM()
            LIMIT 10
        """, (random.randint(1, 3),))
        
        print("✅ Dados fictícios inseridos com sucesso")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao inserir dados: {e}")
        return False
    finally:
        conn.close()

if __name__ == "__main__":
    print("🔄 Populando banco com dados fictícios...")
    if inserir_dados_ficticios():
        print("✅ Processo concluído")
    else:
        print("❌ Processo falhou")