#!/usr/bin/env python3
"""
Script para inserir dados continuamente no PostgreSQL
Simula um ambiente real para demonstrar CDC e pipeline em tempo real
"""

import psycopg2
import random
import time
from datetime import datetime, timedelta
import sys

# Configurações de conexão
DB_CONFIG = {
    'host': 'localhost',
    'port': 5430,
    'database': 'db_source',
    'user': 'admin',
    'password': 'admin'
}

# Dados para geração aleatória
NOMES = [
    'Ana Silva', 'Bruno Costa', 'Carla Santos', 'Diego Almeida', 'Elena Ferreira',
    'Felipe Lima', 'Gabriela Rocha', 'Henrique Souza', 'Isabela Martins', 'João Oliveira',
    'Kamila Pereira', 'Lucas Barbosa', 'Marina Gomes', 'Nicolas Cardoso', 'Olívia Mendes',
    'Pedro Ribeiro', 'Quintina Araújo', 'Rafael Torres', 'Sofia Nascimento', 'Thiago Ramos'
]

PRODUTOS = [
    {'nome': 'Notebook Dell', 'categoria': 'Informática', 'preco': 2500.00, 'codigo': 'NB001'},
    {'nome': 'Mouse Logitech', 'categoria': 'Periféricos', 'preco': 89.90, 'codigo': 'MS002'},
    {'nome': 'Teclado Mecânico', 'categoria': 'Periféricos', 'preco': 299.99, 'codigo': 'KB003'},
    {'nome': 'Monitor 24"', 'categoria': 'Monitores', 'preco': 899.00, 'codigo': 'MN004'},
    {'nome': 'Webcam HD', 'categoria': 'Periféricos', 'preco': 199.90, 'codigo': 'WC005'},
    {'nome': 'Smartphone Samsung', 'categoria': 'Celulares', 'preco': 1299.00, 'codigo': 'SP006'},
    {'nome': 'Tablet iPad', 'categoria': 'Tablets', 'preco': 2199.00, 'codigo': 'TB007'},
    {'nome': 'Fone Bluetooth', 'categoria': 'Audio', 'preco': 149.90, 'codigo': 'FN008'},
    {'nome': 'Carregador Wireless', 'categoria': 'Acessórios', 'preco': 79.90, 'codigo': 'CW009'},
    {'nome': 'Cabo USB-C', 'categoria': 'Cabos', 'preco': 29.90, 'codigo': 'CB010'},
    {'nome': 'SSD 1TB', 'categoria': 'Armazenamento', 'preco': 399.00, 'codigo': 'SD011'},
    {'nome': 'Memória RAM 16GB', 'categoria': 'Memória', 'preco': 299.00, 'codigo': 'RM012'},
    {'nome': 'Placa de Vídeo', 'categoria': 'Hardware', 'preco': 1899.00, 'codigo': 'VG013'},
    {'nome': 'Processador Intel', 'categoria': 'Hardware', 'preco': 899.00, 'codigo': 'PR014'},
    {'nome': 'Motherboard ASUS', 'categoria': 'Hardware', 'preco': 599.00, 'codigo': 'MB015'}
]

CAMPANHAS = [
    {'nome': 'Black Friday 2024', 'tipo': 'promocional', 'canal': 'email'},
    {'nome': 'Volta às Aulas', 'tipo': 'sazonal', 'canal': 'social_media'},
    {'nome': 'Lançamento Produtos', 'tipo': 'produto', 'canal': 'google_ads'},
    {'nome': 'Fidelização Clientes', 'tipo': 'relacionamento', 'canal': 'whatsapp'},
    {'nome': 'Cyber Monday', 'tipo': 'promocional', 'canal': 'email'}
]

FONTES_LEAD = ['website', 'google_ads', 'facebook', 'instagram', 'indicacao', 'evento', 'cold_call']
EMPRESAS = ['TechCorp', 'InnovaSoft', 'DataSolutions', 'CloudTech', 'StartupXYZ', 'MegaCorp', 'SmallBiz']
CARGOS = ['CEO', 'CTO', 'Gerente TI', 'Analista', 'Desenvolvedor', 'Coordenador', 'Diretor']

DOMINIOS_EMAIL = ['gmail.com', 'hotmail.com', 'yahoo.com.br', 'empresa.com', 'outlook.com']

def conectar_db():
    """Conecta ao banco PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        return conn
    except Exception as e:
        print(f"❌ Erro ao conectar ao banco: {e}")
        return None

def gerar_email(nome):
    """Gera um email baseado no nome"""
    nome_limpo = nome.lower().replace(' ', '.').replace('ã', 'a').replace('é', 'e').replace('í', 'i')
    dominio = random.choice(DOMINIOS_EMAIL)
    numero = random.randint(1, 999)
    return f"{nome_limpo}{numero}@{dominio}"

def inserir_cliente(conn):
    """Insere um novo cliente"""
    try:
        nome = random.choice(NOMES)
        email = gerar_email(nome)
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO public.clientes (nome, email, data_cadastro)
            VALUES (%s, %s, %s)
            RETURNING id;
        """, (nome, email, datetime.now()))
        
        cliente_id = cur.fetchone()[0]
        print(f"➕ Cliente inserido: ID {cliente_id} - {nome} ({email})")
        return cliente_id
        
    except Exception as e:
        print(f"❌ Erro ao inserir cliente: {e}")
        return None

def inserir_produto(conn):
    """Insere um novo produto"""
    try:
        produto = random.choice(PRODUTOS)
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO public.produtos (codigo_produto, nome, categoria, preco_venda, preco_custo, estoque_minimo, ativo)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            produto['codigo'], 
            produto['nome'], 
            produto['categoria'], 
            produto['preco'],
            produto['preco'] * 0.7,  # Custo = 70% do preço de venda
            random.randint(5, 50),
            True
        ))
        
        produto_id = cur.fetchone()[0]
        print(f"📦 Produto inserido: ID {produto_id} - {produto['nome']} ({produto['categoria']}) - R$ {produto['preco']:.2f}")
        return produto_id
        
    except Exception as e:
        print(f"❌ Erro ao inserir produto: {e}")
        return None

def inserir_pedido(conn, cliente_id=None):
    """Insere um novo pedido"""
    try:
        # Se não foi especificado cliente, pega um aleatório existente
        if cliente_id is None:
            cur = conn.cursor()
            cur.execute("SELECT id FROM public.clientes ORDER BY RANDOM() LIMIT 1")
            result = cur.fetchone()
            if not result:
                print("❌ Nenhum cliente disponível para pedido")
                return None
            cliente_id = result[0]
        
        # Data do pedido pode ser alguns dias atrás para variar
        dias_atras = random.randint(0, 7)
        data_pedido = datetime.now() - timedelta(days=dias_atras)
        
        # Gerar número do pedido único
        numero_pedido = f"PED-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
        
        # Criar pedido sem valor (será calculado pelos itens)
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO public.pedidos (cliente_id, numero_pedido, valor_bruto, data_pedido, status, metodo_pagamento, canal_venda)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            cliente_id, 
            numero_pedido, 
            0,  # Será atualizado depois
            data_pedido,
            random.choice(['pendente', 'processando', 'enviado', 'entregue']),
            random.choice(['cartao_credito', 'cartao_debito', 'pix', 'boleto']),
            random.choice(['loja_online', 'marketplace', 'loja_fisica', 'telefone'])
        ))
        
        pedido_id = cur.fetchone()[0]
        
        # Adicionar itens ao pedido
        valor_total_pedido = 0
        num_itens = random.randint(1, 4)  # 1 a 4 itens por pedido
        
        for _ in range(num_itens):
            # Pegar produto existente ou criar um novo
            cur.execute("SELECT id, nome, preco_venda FROM public.produtos ORDER BY RANDOM() LIMIT 1")
            produto_result = cur.fetchone()
            
            if not produto_result:
                # Se não há produtos, criar um
                produto_id = inserir_produto(conn)
                if produto_id:
                    cur.execute("SELECT id, nome, preco_venda FROM public.produtos WHERE id = %s", (produto_id,))
                    produto_result = cur.fetchone()
            
            if produto_result:
                produto_id, produto_nome, preco_unitario = produto_result
                quantidade = random.randint(1, 3)
                desconto_item = round(random.uniform(0, preco_unitario * 0.1), 2)  # Até 10% de desconto
                
                # Inserir item do pedido
                cur.execute("""
                    INSERT INTO public.itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, desconto_item)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING valor_total;
                """, (pedido_id, produto_id, quantidade, preco_unitario, desconto_item))
                
                valor_item = cur.fetchone()[0]
                valor_total_pedido += valor_item
                
                print(f"  📋 Item adicionado: {produto_nome} (Qtd: {quantidade}, Valor: R$ {valor_item:.2f})")
        
        # Atualizar valor total do pedido
        cur.execute("""
            UPDATE public.pedidos SET valor_bruto = %s WHERE id = %s
        """, (valor_total_pedido, pedido_id))
        
        print(f"🛒 Pedido inserido: ID {pedido_id} - Cliente {cliente_id} - Total: R$ {valor_total_pedido:.2f}")
        return pedido_id
        
    except Exception as e:
        print(f"❌ Erro ao inserir pedido: {e}")
        return None

def inserir_campanha(conn):
    """Insere uma nova campanha de marketing"""
    try:
        campanha = random.choice(CAMPANHAS)
        
        # Gerar datas da campanha
        data_inicio = datetime.now() - timedelta(days=random.randint(0, 30))
        data_fim = data_inicio + timedelta(days=random.randint(7, 60))
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO public.campanhas_marketing (nome, tipo, canal, orcamento, data_inicio, data_fim, status, meta_leads)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            campanha['nome'],
            campanha['tipo'],
            campanha['canal'],
            round(random.uniform(1000, 50000), 2),
            data_inicio.date(),
            data_fim.date(),
            random.choice(['planejada', 'ativa', 'pausada', 'finalizada']),
            random.randint(50, 1000)
        ))
        
        campanha_id = cur.fetchone()[0]
        print(f"📢 Campanha inserida: ID {campanha_id} - {campanha['nome']} ({campanha['tipo']})")
        return campanha_id
        
    except Exception as e:
        print(f"❌ Erro ao inserir campanha: {e}")
        return None

def inserir_lead(conn):
    """Insere um novo lead"""
    try:
        nome = random.choice(NOMES)
        email = gerar_email(nome)
        empresa = random.choice(EMPRESAS)
        cargo = random.choice(CARGOS)
        fonte = random.choice(FONTES_LEAD)
        
        # Pegar uma campanha existente ou criar uma nova
        cur = conn.cursor()
        cur.execute("SELECT id FROM public.campanhas_marketing ORDER BY RANDOM() LIMIT 1")
        campanha_result = cur.fetchone()
        
        campanha_id = None
        if campanha_result:
            campanha_id = campanha_result[0]
        elif random.random() < 0.3:  # 30% chance de criar nova campanha
            campanha_id = inserir_campanha(conn)
        
        cur.execute("""
            INSERT INTO public.leads (nome, email, telefone, empresa, cargo, fonte, campanha_id, score, status, interesse, orcamento_estimado)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            nome,
            email,
            f"({random.randint(11, 99)}) {random.randint(90000, 99999)}-{random.randint(1000, 9999)}",
            empresa,
            cargo,
            fonte,
            campanha_id,
            random.randint(0, 100),
            random.choice(['novo', 'contatado', 'qualificado', 'oportunidade', 'perdido', 'convertido']),
            random.choice(['baixo', 'medio', 'alto']),
            round(random.uniform(1000, 100000), 2)
        ))
        
        lead_id = cur.fetchone()[0]
        print(f"🎯 Lead inserido: ID {lead_id} - {nome} ({empresa}) - Fonte: {fonte}")
        return lead_id
        
    except Exception as e:
        print(f"❌ Erro ao inserir lead: {e}")
        return None

def atualizar_cliente(conn):
    """Atualiza um cliente existente (simula CDC)"""
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, nome, email FROM public.clientes ORDER BY RANDOM() LIMIT 1")
        result = cur.fetchone()
        if not result:
            return None
            
        cliente_id, nome_atual, email_atual = result
        
        # Simula atualização de email ou telefone
        if random.random() < 0.7:  # 70% chance de atualizar email
            novo_email = gerar_email(nome_atual)
            cur.execute("""
                UPDATE public.clientes 
                SET email = %s, updated_at = %s
                WHERE id = %s
            """, (novo_email, datetime.now(), cliente_id))
            print(f"🔄 Cliente atualizado: ID {cliente_id} - Email: {email_atual} → {novo_email}")
        else:  # 30% chance de atualizar telefone
            novo_telefone = f"({random.randint(11, 99)}) {random.randint(90000, 99999)}-{random.randint(1000, 9999)}"
            cur.execute("""
                UPDATE public.clientes 
                SET telefone = %s, updated_at = %s
                WHERE id = %s
            """, (novo_telefone, datetime.now(), cliente_id))
            print(f"🔄 Cliente atualizado: ID {cliente_id} - Telefone: {novo_telefone}")
        
        return cliente_id
        
    except Exception as e:
        print(f"❌ Erro ao atualizar cliente: {e}")
        return None

def mostrar_estatisticas(conn):
    """Mostra estatísticas atuais do banco"""
    try:
        cur = conn.cursor()
        
        # Contagem de clientes
        cur.execute("SELECT COUNT(*) FROM public.clientes")
        total_clientes = cur.fetchone()[0]
        
        # Contagem de pedidos
        cur.execute("SELECT COUNT(*) FROM public.pedidos")
        total_pedidos = cur.fetchone()[0]
        
        # Contagem de produtos
        cur.execute("SELECT COUNT(*) FROM public.produtos")
        total_produtos = cur.fetchone()[0]
        
        # Contagem de itens de pedido
        cur.execute("SELECT COUNT(*) FROM public.itens_pedido")
        total_itens = cur.fetchone()[0]
        
        # Contagem de campanhas
        cur.execute("SELECT COUNT(*) FROM public.campanhas_marketing")
        total_campanhas = cur.fetchone()[0]
        
        # Contagem de leads
        cur.execute("SELECT COUNT(*) FROM public.leads")
        total_leads = cur.fetchone()[0]
        
        # Receita total
        cur.execute("SELECT SUM(valor_bruto) FROM public.pedidos")
        receita_total = cur.fetchone()[0] or 0
        
        # Último pedido
        cur.execute("""
            SELECT p.id, c.nome, p.valor_bruto
            FROM public.pedidos p 
            JOIN public.clientes c ON p.cliente_id = c.id 
            ORDER BY p.id DESC LIMIT 1
        """)
        ultimo_pedido = cur.fetchone()
        
        print(f"\n📊 ESTATÍSTICAS ATUAIS:")
        print(f"   👥 Clientes: {total_clientes}")
        print(f"   🛒 Pedidos: {total_pedidos}")
        print(f"   📦 Produtos: {total_produtos}")
        print(f"   📋 Itens de Pedido: {total_itens}")
        print(f"   📢 Campanhas: {total_campanhas}")
        print(f"   🎯 Leads: {total_leads}")
        print(f"   💰 Receita Total: R$ {receita_total:.2f}")
        if ultimo_pedido:
            print(f"   🔥 Último Pedido: ID {ultimo_pedido[0]} - {ultimo_pedido[1]} (R$ {ultimo_pedido[2]:.2f})")
        print("-" * 60)
        
    except Exception as e:
        print(f"❌ Erro ao mostrar estatísticas: {e}")

def main():
    print("🎬 SIMULADOR DE DADOS EM TEMPO REAL")
    print("==================================")
    print("🎯 Objetivo: Demonstrar CDC e Pipeline funcionando")
    print("⏱️  Pressione Ctrl+C para parar\n")
    
    # Conectar ao banco
    conn = conectar_db()
    if not conn:
        sys.exit(1)
    
    try:
        ciclo = 0
        while True:
            ciclo += 1
            print(f"\n🔄 CICLO {ciclo} - {datetime.now().strftime('%H:%M:%S')}")
            
            # Decisão aleatória do que fazer
            acao = random.choices(
                ['novo_cliente', 'novo_pedido', 'atualizar_cliente', 'pedido_cliente_novo', 
                 'novo_produto', 'nova_campanha', 'novo_lead', 'lead_com_campanha'],
                weights=[15, 25, 10, 20, 10, 8, 10, 2],  # Probabilidades
                k=1
            )[0]
            
            if acao == 'novo_cliente':
                inserir_cliente(conn)
                
            elif acao == 'novo_pedido':
                inserir_pedido(conn)
                
            elif acao == 'atualizar_cliente':
                atualizar_cliente(conn)
                
            elif acao == 'pedido_cliente_novo':
                # Cria cliente e pedido na sequência
                cliente_id = inserir_cliente(conn)
                if cliente_id:
                    time.sleep(1)  # Pequena pausa
                    inserir_pedido(conn, cliente_id)
                    
            elif acao == 'novo_produto':
                inserir_produto(conn)
                
            elif acao == 'nova_campanha':
                inserir_campanha(conn)
                
            elif acao == 'novo_lead':
                inserir_lead(conn)
                
            elif acao == 'lead_com_campanha':
                # Cria campanha e lead na sequência
                campanha_id = inserir_campanha(conn)
                if campanha_id:
                    time.sleep(1)  # Pequena pausa
                    inserir_lead(conn)
            
            # Mostra estatísticas a cada 10 ciclos
            if ciclo % 10 == 0:
                mostrar_estatisticas(conn)
            
            # Pausa entre inserções (simula tempo real)
            intervalo = random.uniform(2, 8)  # Entre 2 e 8 segundos
            print(f"⏳ Aguardando {intervalo:.1f}s...")
            time.sleep(intervalo)
            
    except KeyboardInterrupt:
        print(f"\n\n⏹️  Simulação interrompida pelo usuário")
        print(f"📈 Total de ciclos executados: {ciclo}")
        mostrar_estatisticas(conn)
        
    except Exception as e:
        print(f"❌ Erro durante simulação: {e}")
        
    finally:
        conn.close()
        print("🔚 Conexão fechada. Obrigado!")

if __name__ == "__main__":
    main()