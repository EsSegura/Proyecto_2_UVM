`include "uvm_macros.svh"
import uvm_pkg::*;
import aligner_apb_registerfile_model::*;

class aligner__CTRL_cov extends aligner__CTRL;//clase que hereda los fields del modelo del registro de control generado por RAL, para generar cobertura
  `uvm_object_utils(aligner__CTRL_cov)
  covergroup ctrl_cg;
    cp_size: coverpoint SIZE.value { //cover group de posibles valores de size, solo se incluyen los size legales
      bins size_1={3'b001};
      bins size_2={3'b010};
      bins size_4={3'b100};
      bins size_invalid = {3'b000, 3'b011, 3'b101, 3'b110, 3'b111}; // casos ilegales
    } // solo 3 size legales segun el datasheet (solo sizes que son potencias de 2)
  
  cp_offset: coverpoint OFFSET.value {// covergroup de posibles valores de offset
    bins offset_0= {2'b00};  
    bins offset_1= {2'b01};  
    bins offset_2= {2'b10};  
    bins offset_3= {2'b11};  

  }
  
    cp_clr: coverpoint CLR.value { // ver si se probo la activacion de CLR
    bins clear = {1'b1};
  
  }
      // aca se comprueba que se probaron todas las combinaciones de los coverpoints
  cx_legales: cross cp_size, cp_offset {
    bins legal_s1_o0 = binsof(cp_size.size_1) && binsof(cp_offset.offset_0);
    bins legal_s1_o1 = binsof(cp_size.size_1) && binsof(cp_offset.offset_1);
    bins legal_s1_o2 = binsof(cp_size.size_1) && binsof(cp_offset.offset_2);
    bins legal_s1_o3 = binsof(cp_size.size_1) && binsof(cp_offset.offset_3);
    bins legal_s2_o0 = binsof(cp_size.size_2) && binsof(cp_offset.offset_0);
    bins legal_s2_o2 = binsof(cp_size.size_2) && binsof(cp_offset.offset_2);
    bins legal_s4_o0 = binsof(cp_size.size_4) && binsof(cp_offset.offset_0);
  } //estos son las combinaciones legales
  
  cx_ilegales: cross cp_size, cp_offset {
    bins ilegal_s2_o1 = binsof(cp_size.size_2) && binsof(cp_offset.offset_1);
    bins ilegal_s2_o3 = binsof(cp_size.size_2) && binsof(cp_offset.offset_3);
    bins ilegal_s4_o1 = binsof(cp_size.size_4) && binsof(cp_offset.offset_1);
    bins ilegal_s4_o2 = binsof(cp_size.size_4) && binsof(cp_offset.offset_2);
    bins ilegal_s4_o3 = binsof(cp_size.size_4) && binsof(cp_offset.offset_3);
    bins ilegal_sinv_o0 = binsof(cp_size.size_invalid) && binsof(cp_offset.offset_0);
	bins ilegal_sinv_o1 = binsof(cp_size.size_invalid) && binsof(cp_offset.offset_1);
	bins ilegal_sinv_o2 = binsof(cp_size.size_invalid) && binsof(cp_offset.offset_2);
	bins ilegal_sinv_o3 = binsof(cp_size.size_invalid) && binsof(cp_offset.offset_3);
  }// estas son las combinaciones ilegales
    
  endgroup
  
   function new(string name="aligner__CTRL_cov");
     super.new(name); // declarar al registro padre con cobertura
     ctrl_cg = new();
  endfunction
  
  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en, bit is_read, uvm_reg_map    map);
    if (!is_read) // solo samplear si es escritura, ya que para este registro solo tiene sentido samplear si se asertaron ciertos valores, no si se leyeron
            ctrl_cg.sample();
    endfunction



  
endclass


class aligner__STATUS_cov extends aligner__STATUS; // clase para generar cobertura del registro de estado, herada los campos del modelos de registros del registro de estados
	`uvm_object_utils(aligner__STATUS_cov)    
    covergroup status_cg;
      
      cp_cnt_drop: coverpoint CNT_DROP.value { // ver si se ejercitaron todos los estados de numero de rechazos
        bins no_drop    = {8'h00}; 
        bins dropping   = {[8'h01:8'hFE]};
        bins max_drop   = {8'hFF}; // maximo de rechazos segun datasheet
    }
      
      cp_rx_lvl: coverpoint RX_LVL.value { // ver si se ejercitaron todos los niveles de llenado de la fifo de recepcion
        bins empty = {4'h0};
        bins partial = {[4'h1:4'h7]};
        bins full = {4'h8}; // maxima capacidad de la fifo segun datasheet
    }
      
      cp_tx_lvl: coverpoint TX_LVL.value {// ver si se ejercitaron todos los niveles de llenado de la fifo de transmision
        bins empty   = {4'h0};
        bins partial = {[4'h1:4'h7]};
        bins full    = {4'h8}; //maxima capacidad de la fifo segun datasheet
    }
      

    endgroup

    function new(string name = "aligner__STATUS_cov");
     	super.new(name); // declarar al registro padre con cobertura
      	status_cg = new();   
    endfunction
  
  virtual function void sample(uvm_reg_data_t data,
                                 uvm_reg_data_t byte_en,
                                 bit            is_read,
                                 uvm_reg_map    map);
    if (is_read) // registro es read only asi que solo se samplea si hay lectura, se debe hacer que el test lea para que se llene esta cobertura
            status_cg.sample();
    endfunction


endclass



class aligner__IRQEN_cov extends aligner__IRQEN;// clase para generar cobertura del registro de habilitacion de interrupciones, herada los campos del modelos de registros del registro de ral
    `uvm_object_utils(aligner__IRQEN_cov)

  covergroup irqen_cg; // se verifica que se hayan acertado todos los campos (5 bits para habilitacion de interrupciones)
      cp_rx_fifo_empty: coverpoint RX_FIFO_EMPTY.value {
        bins disabled = {1'b0};
        bins enabled  = {1'b1};
    }

    cp_rx_fifo_full: coverpoint RX_FIFO_FULL.value {
        bins disabled = {1'b0};
        bins enabled  = {1'b1};
    }

    cp_tx_fifo_empty: coverpoint TX_FIFO_EMPTY.value {
        bins disabled = {1'b0};
        bins enabled  = {1'b1};
    }

    cp_tx_fifo_full: coverpoint TX_FIFO_FULL.value {
        bins disabled = {1'b0};
        bins enabled  = {1'b1};
    }

    cp_max_drop: coverpoint MAX_DROP.value {
        bins disabled = {1'b0};
        bins enabled  = {1'b1};
    }

    endgroup

    function new(string name = "aligner__IRQEN_cov");
     	super.new(name); // declarar al registro padre con cobertura
        irqen_cg = new();
    endfunction
  
  virtual function void sample(uvm_reg_data_t data,
                                 uvm_reg_data_t byte_en,
                                 bit            is_read,
                                 uvm_reg_map    map);
    if (!is_read) // solo se samplea en escrituras, ahi es donde se habilitan las interrupciones
            irqen_cg.sample();
    endfunction



endclass

class aligner__IRQ_cov extends aligner__IRQ;// clase para generar cobertura del registro de interrupciones, herada los campos del modelos de registros del registro de ral
    `uvm_object_utils(aligner__IRQ_cov)

    covergroup irq_cg; // aca nada mas se verifica que se hayan acertado todas las interrupciones
      cp_rx_fifo_empty: coverpoint RX_FIFO_EMPTY.value {
        bins inactive = {1'b0};
        bins active   = {1'b1};
    }

    cp_rx_fifo_full: coverpoint RX_FIFO_FULL.value {
        bins inactive = {1'b0};
        bins active   = {1'b1};
    }

    cp_tx_fifo_empty: coverpoint TX_FIFO_EMPTY.value {
        bins inactive = {1'b0};
        bins active   = {1'b1};
    }

    cp_tx_fifo_full: coverpoint TX_FIFO_FULL.value {
        bins inactive = {1'b0};
        bins active   = {1'b1};
    }

    cp_max_drop: coverpoint MAX_DROP.value {
        bins inactive = {1'b0};
        bins active   = {1'b1};
    }

    endgroup

    function new(string name = "aligner__IRQ_cov");
     	super.new(name); // declarar al registro padre con cobertura
        irq_cg = new();
    endfunction
  
  virtual function void sample(uvm_reg_data_t data,
                                 uvm_reg_data_t byte_en,
                                 bit            is_read,
                                 uvm_reg_map    map);
    irq_cg.sample(); // samplear en ambas direcciones, escritura y lectura ya que los campos son w1c (hardare las aserta en 1, agente externo las limpia)
    endfunction


endclass

class aligner_reg_cov extends aligner_apb_registerfile_model::aligner; // clase para poder usar las clases de cobertura y el modelo de registros
  `uvm_object_utils(aligner_reg_cov)

  function new(string name = "aligner_reg_cov");
        super.new(name);
    endfunction

    virtual function void build();
        this.default_map = create_map("reg_map", 0, 4, UVM_LITTLE_ENDIAN);

        this.CTRL = aligner__CTRL_cov::type_id::create("CTRL");
        this.CTRL.configure(this);
        this.CTRL.build();
        this.default_map.add_reg(this.CTRL, 'h0);

        this.STATUS = aligner__STATUS_cov::type_id::create("STATUS");
        this.STATUS.configure(this);
        this.STATUS.build();
        this.default_map.add_reg(this.STATUS, 'hc);

        this.IRQEN = aligner__IRQEN_cov::type_id::create("IRQEN");
        this.IRQEN.configure(this);
        this.IRQEN.build();
        this.default_map.add_reg(this.IRQEN, 'hf0);

        this.IRQ = aligner__IRQ_cov::type_id::create("IRQ");
        this.IRQ.configure(this);
        this.IRQ.build();
        this.default_map.add_reg(this.IRQ, 'hf4);

    endfunction

endclass