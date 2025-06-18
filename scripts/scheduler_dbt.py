#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scheduler DBT - POC Local sem Airbyte

Este script executa o DBT em intervalos regulares para simular
um pipeline de dados em tempo real, lendo diretamente do banco de origem.

Uso:
    python scheduler_dbt.py [--interval SECONDS] [--run-once]
"""

import os
import sys
import time
import argparse
import subprocess
import logging
from datetime import datetime
from pathlib import Path

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('dbt_scheduler.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class DBTScheduler:
    def __init__(self, dbt_project_dir=None, interval=300):
        """
        Inicializa o scheduler do DBT
        
        Args:
            dbt_project_dir: Diretório do projeto DBT
            interval: Intervalo em segundos entre execuções (padrão: 5 minutos)
        """
        self.interval = interval
        self.dbt_project_dir = dbt_project_dir or self._find_dbt_project()
        self.running = False
        
        logger.info(f"DBT Scheduler inicializado")
        logger.info(f"Projeto DBT: {self.dbt_project_dir}")
        logger.info(f"Intervalo: {self.interval} segundos")
    
    def _find_dbt_project(self):
        """Encontra o diretório do projeto DBT"""
        current_dir = Path(__file__).parent
        
        # Procura por dbt_project.yml no diretório atual e pais
        for path in [current_dir, current_dir.parent]:
            dbt_project_path = path / "dbt_project"
            if (dbt_project_path / "dbt_project.yml").exists():
                return str(dbt_project_path)
        
        # Se não encontrar, usa o diretório padrão
        default_path = current_dir.parent / "dbt_project"
        logger.warning(f"dbt_project.yml não encontrado. Usando: {default_path}")
        return str(default_path)
    
    def check_dbt_installation(self):
        """Verifica se o DBT está instalado"""
        try:
            result = subprocess.run(
                ["dbt", "--version"], 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            if result.returncode == 0:
                logger.info(f"DBT encontrado: {result.stdout.strip()}")
                return True
            else:
                logger.error(f"Erro ao verificar DBT: {result.stderr}")
                return False
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            logger.error(f"DBT não encontrado ou timeout: {e}")
            return False
    
    def run_dbt_command(self, command):
        """
        Executa um comando DBT
        
        Args:
            command: Lista com o comando DBT (ex: ['dbt', 'run'])
        
        Returns:
            bool: True se sucesso, False se erro
        """
        try:
            logger.info(f"Executando: {' '.join(command)}")
            
            result = subprocess.run(
                command,
                cwd=self.dbt_project_dir,
                capture_output=True,
                text=True,
                timeout=600  # 10 minutos timeout
            )
            
            if result.returncode == 0:
                logger.info(f"✅ Comando executado com sucesso")
                if result.stdout:
                    logger.debug(f"Output: {result.stdout}")
                return True
            else:
                logger.error(f"❌ Erro na execução: {result.stderr}")
                if result.stdout:
                    logger.error(f"Output: {result.stdout}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error(f"⏰ Timeout na execução do comando: {' '.join(command)}")
            return False
        except Exception as e:
            logger.error(f"💥 Erro inesperado: {e}")
            return False
    
    def run_dbt_pipeline(self):
        """
        Executa o pipeline completo do DBT
        
        Returns:
            bool: True se todo o pipeline foi executado com sucesso
        """
        logger.info("🚀 Iniciando execução do pipeline DBT")
        start_time = datetime.now()
        
        # Sequência de comandos DBT
        commands = [
            ["dbt", "deps"],           # Instala dependências
            ["dbt", "seed"],           # Carrega seeds (se houver)
            ["dbt", "run"],            # Executa modelos
            ["dbt", "test"]            # Executa testes
        ]
        
        success = True
        for command in commands:
            if not self.run_dbt_command(command):
                success = False
                break
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        if success:
            logger.info(f"✅ Pipeline executado com sucesso em {duration:.2f}s")
        else:
            logger.error(f"❌ Pipeline falhou após {duration:.2f}s")
        
        return success
    
    def run_once(self):
        """Executa o pipeline uma única vez"""
        if not self.check_dbt_installation():
            logger.error("DBT não está disponível. Instale com: pip install dbt-postgres")
            return False
        
        return self.run_dbt_pipeline()
    
    def start_scheduler(self):
        """Inicia o scheduler em loop contínuo"""
        if not self.check_dbt_installation():
            logger.error("DBT não está disponível. Instale com: pip install dbt-postgres")
            return
        
        self.running = True
        logger.info(f"📅 Scheduler iniciado. Executando a cada {self.interval} segundos")
        logger.info("Pressione Ctrl+C para parar")
        
        try:
            while self.running:
                self.run_dbt_pipeline()
                
                if self.running:  # Verifica se ainda está rodando
                    logger.info(f"⏳ Aguardando {self.interval} segundos até a próxima execução...")
                    time.sleep(self.interval)
                    
        except KeyboardInterrupt:
            logger.info("\n🛑 Scheduler interrompido pelo usuário")
        except Exception as e:
            logger.error(f"💥 Erro inesperado no scheduler: {e}")
        finally:
            self.running = False
            logger.info("📴 Scheduler finalizado")
    
    def stop(self):
        """Para o scheduler"""
        self.running = False
        logger.info("🛑 Parando scheduler...")

def main():
    parser = argparse.ArgumentParser(
        description="Scheduler para execução automática do DBT"
    )
    parser.add_argument(
        "--interval", 
        type=int, 
        default=300, 
        help="Intervalo em segundos entre execuções (padrão: 300 = 5 minutos)"
    )
    parser.add_argument(
        "--run-once", 
        action="store_true", 
        help="Executa apenas uma vez e sai"
    )
    parser.add_argument(
        "--project-dir", 
        type=str, 
        help="Diretório do projeto DBT (opcional)"
    )
    
    args = parser.parse_args()
    
    # Cria o scheduler
    scheduler = DBTScheduler(
        dbt_project_dir=args.project_dir,
        interval=args.interval
    )
    
    if args.run_once:
        # Executa uma vez e sai
        success = scheduler.run_once()
        sys.exit(0 if success else 1)
    else:
        # Executa em loop contínuo
        scheduler.start_scheduler()

if __name__ == "__main__":
    main()