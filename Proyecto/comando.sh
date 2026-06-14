source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh;

rm -rfv `ls | grep -v ".*\.sv\|.*\.sh\|plusargs\.txt\|Common_modules\|DUT\|APB\|MD\|Informe"`
# ese comando destruye todos los archivos que no sean fuente, se debe descomentar al inicio y se debe comentar cada vez qeu se ejecute este archivo pq sino borra todo, solo se descomenta la primera vez que se usa el tb  

# Este comando compila el dut y el tb 
vcs -Mupdate Common_modules/aligner_tb_top.sv -o salida -full64 -sverilog -kdb -debug_acc+all -ntb_opts uvm-1.2  -timescale=1ns/1ps +incdir+Common_modules +incdir+APB +incdir+MD +incdir+DUT  -cm line+cond+fsm+tgl+branch -debug_region+cell+encrypt -l log_test +lint=TFIPC-L -P ${VERDI_HOME}/share/PLI/VCS/linux64/verdi.tab 







./salida -f plusargs.txt -cm line+cond+fsm+tgl+branch+assert  2>&1 | tee log_test ; # de aca se jalan los plusargs, se modifican en plusargs.txt 


#verdi -cov -covdir salida.vdb& # ; este comando se usa para abrir el archivo que tiene la cobertura, no se usa en este proyecto
