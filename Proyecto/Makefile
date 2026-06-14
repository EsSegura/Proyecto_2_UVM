#  Makefile  Proyecto2 Veri


SHELL := /bin/bash

# Script de herramientas Synopsys
SYNOPSYS_TOOLS = /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh

# Fuente principal del testbench
TB_TOP   = Common_modules/aligner_tb_top.sv
SIM_OUT  = salida
LOG      = log_test
PLUSARGS = plusargs.txt
FSDB     = dump.fsdb
COV_DIR  = salida.vdb


#  Macros de verificacion


# Verifica que el binario compilado exista
define check_compiled
	@if [ ! -f $(SIM_OUT) ]; then \
		echo ""; \
		echo "  ERROR: El ambiente no ha sido compilado."; \
		echo "  Corre primero: make compile"; \
		echo ""; \
		exit 1; \
	fi
endef

# Verifica que el FSDB exista
define check_fsdb
	@if [ ! -f $(FSDB) ]; then \
		echo ""; \
		echo "  ERROR: No existe el archivo de formas de onda."; \
		echo "  Corre primero: make waves"; \
		echo ""; \
		exit 1; \
	fi
endef

# Verifica que el directorio de cobertura exista
define check_cov
	@if [ ! -d $(COV_DIR) ]; then \
		echo ""; \
		echo "  ERROR: No existe el directorio de cobertura."; \
		echo "  Corre primero: make run"; \
		echo ""; \
		exit 1; \
	fi
endef


#  Targets
.PHONY: all compile run waves verdi cov cov_report clean help

## Compilar + correr
all: compile run

## Solo compilar el ambiente
compile:
	@echo ">>> Compilando ambiente..."
	source $(SYNOPSYS_TOOLS) && vcs -Mupdate $(TB_TOP) \
	    -o $(SIM_OUT) \
	    -full64 \
	    -sverilog \
	    -kdb -lca \
	    -debug_acc+all \
	    -ntb_opts uvm-1.2 \
	    -timescale=1ns/1ps \
	    +incdir+Common_modules \
	    +incdir+APB \
	    +incdir+MD \
	    +incdir+DUT \
	    -cm line+cond+fsm+tgl+branch \
	    -debug_region+cell+encrypt \
	    -l $(LOG) \
	    +lint=TFIPC-L \
	    -P $${VERDI_HOME}/share/PLI/VCS/linux64/verdi.tab
	@echo ">>> Ambiente compilado."

## Solo correr simulacion (requiere compilar)
run:
	$(call check_compiled)
	@echo ">>> Corriendo simulacion..."
	source $(SYNOPSYS_TOOLS) && ./$(SIM_OUT) \
	    -f $(PLUSARGS) \
	    -cm line+cond+fsm+tgl+branch+assert \
	    2>&1 | tee $(LOG)
	@echo ">>> Simulacion lista. Log en: $(LOG)"

## Correr con formas de onda (requiere compilar)
waves:
	$(call check_compiled)
	@echo ">>> Corriendo simulacion con formas de onda..."
	source $(SYNOPSYS_TOOLS) && ./$(SIM_OUT) \
	    -f $(PLUSARGS) \
	    -cm line+cond+fsm+tgl+branch+assert \
	    +fsdbfile+$(FSDB) \
	    2>&1 | tee $(LOG)
	@echo ">>> FSDB generado: $(FSDB)"
	@echo ">>> Abriendo Verdi..."
	source $(SYNOPSYS_TOOLS) && verdi -dbdir salida.daidir -ssf $(FSDB) &

## Ver cobertura en Verdi (requiere compilar y haber corrido)
cov:
	$(call check_compiled)
	$(call check_cov)
	@echo ">>> Abriendo cobertura en Verdi..."
	source $(SYNOPSYS_TOOLS) && verdi -cov -covdir $(COV_DIR) &

## Limpiar todo
clean:
	@echo ">>> Limpiando..."
	rm -rfv $(shell ls | grep -v "^.*\.sv$$\|^.*\.sh$$\|^plusargs\.txt$$\|^Common_modules$$\|^DUT$$\|^APB$$\|^MD$$\|^Informe$$\|^Makefile$$")
	@echo ">>> Listo."

## Ayuda
help:
	@echo ""
	@echo "  Uso: make [target]"
	@echo ""
	@echo "  Targets disponibles:"
	@echo "    all        ? compilar + correr (default)"
	@echo "    compile    ? compilar el ambiente"
	@echo "    run        ? correr simulacion          (*requiere: compile)"
	@echo "    waves      ? correr + abrir Verdi       (*requiere: compile)"
	@echo "    cov        ? ver cobertura en Verdi     (*requiere: compile + run)"

	@echo "    clean      ? borrar archivos generados"
	@echo "    help       ? mostrar esta ayuda"
	 @echo ""

