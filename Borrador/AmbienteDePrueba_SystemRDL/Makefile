UVM_HOME = $(HOME)/intelFPGA/modelsim_ase/verilog_src/uvm-1.2

all: clean compile sim

clean:
	rm -rf work transcript vsim.wlf

compile:
	vlib work
	vlog -sv +incdir+$(UVM_HOME)/src +incdir+$(PWD) $(UVM_HOME)/src/uvm_pkg.sv MI_PERIFERICO_pkg.sv mi_periferico_ral_pkg.sv apb3_intf.sv my_testbench_pkg.sv MI_PERIFERICO.sv TB_top.sv
sim:
	vsim -c tb_top +UVM_TESTNAME=base_test +UVM_VERBOSITY=UVM_MEDIUM -sv_lib uvm_dpi -do "run -all; quit"
