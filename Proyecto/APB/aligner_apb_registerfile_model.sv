//Este archivo fue autogenerado por PeakRDL-uvm
package aligner_apb_registerfile_model;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    //reg - aligner::CTRL (registro de control del alineador)
    class aligner__CTRL extends uvm_reg;
        rand uvm_reg_field SIZE;      //cuantos bytes se extraen por transferencia
        rand uvm_reg_field reserved1; //bits reservados
        rand uvm_reg_field OFFSET;    //byte de inicio de la transferencia
        rand uvm_reg_field reserved2; //bits reservados
        rand uvm_reg_field CLR;       //limpia el contador de drops al escribir 1
        rand uvm_reg_field reserved3; //bits reservados

        function new(string name = "aligner__CTRL");
            super.new(name, 32, UVM_NO_COVERAGE); //registro de 32 bits sin cobertura propia
        endfunction : new

        //build: arma cada campo del registro con su ancho, posicion y tipo de acceso
        virtual function void build();
            this.SIZE = new("SIZE");
            this.SIZE.configure(this, 3, 0, "RW", 0, 'h1, 1, 1, 0);
            this.reserved1 = new("reserved1");
            this.reserved1.configure(this, 5, 3, "RO", 0, 'h0, 1, 1, 0);
            this.OFFSET = new("OFFSET");
            this.OFFSET.configure(this, 2, 8, "RW", 0, 'h0, 1, 1, 0);
            this.reserved2 = new("reserved2");
            this.reserved2.configure(this, 6, 10, "RO", 0, 'h0, 1, 1, 0);
            this.CLR = new("CLR");
            this.CLR.configure(this, 1, 16, "WO", 0, 'h0, 1, 1, 0);
            this.reserved3 = new("reserved3");
            this.reserved3.configure(this, 15, 17, "RO", 0, 'h0, 1, 1, 0);
        endfunction : build
    endclass : aligner__CTRL

    //reg - aligner::STATUS (registro de estado, solo lectura)
    class aligner__STATUS extends uvm_reg;
        rand uvm_reg_field CNT_DROP;  //contador de transferencias rechazadas
        rand uvm_reg_field RX_LVL;    //nivel de llenado de la fifo de recepcion
        rand uvm_reg_field reserved1; //bits reservados
        rand uvm_reg_field TX_LVL;    //nivel de llenado de la fifo de transmision
        rand uvm_reg_field reserved2; //bits reservados

        function new(string name = "aligner__STATUS");
            super.new(name, 32, UVM_NO_COVERAGE); //registro de 32 bits sin cobertura propia
        endfunction : new

        //build: arma cada campo del registro con su ancho, posicion y tipo de acceso
        virtual function void build();
            this.CNT_DROP = new("CNT_DROP");
            this.CNT_DROP.configure(this, 8, 0, "RO", 1, 'h0, 1, 1, 0);
            //Datasheet (Tabla 6): RX_LVL ocupa 4 bits desde el bit 8
            //(con 3 bits no se podria representar el nivel maximo de 8)
            this.RX_LVL = new("RX_LVL");
            this.RX_LVL.configure(this, 4, 8, "RO", 1, 'h0, 1, 1, 0);
            this.reserved1 = new("reserved1");
            this.reserved1.configure(this, 4, 12, "RO", 0, 'h0, 1, 1, 0);
            this.TX_LVL = new("TX_LVL");
            this.TX_LVL.configure(this, 4, 16, "RO", 1, 'h0, 1, 1, 0);
            this.reserved2 = new("reserved2");
            this.reserved2.configure(this, 12, 20, "RO", 0, 'h0, 1, 1, 0);
        endfunction : build
    endclass : aligner__STATUS

    //reg - aligner::IRQEN (habilitacion de interrupciones)
    class aligner__IRQEN extends uvm_reg;
        rand uvm_reg_field RX_FIFO_EMPTY; //habilita irq por fifo RX vacia
        rand uvm_reg_field RX_FIFO_FULL;  //habilita irq por fifo RX llena
        rand uvm_reg_field TX_FIFO_EMPTY; //habilita irq por fifo TX vacia
        rand uvm_reg_field TX_FIFO_FULL;  //habilita irq por fifo TX llena
        rand uvm_reg_field MAX_DROP;      //habilita irq por maximo de drops
        rand uvm_reg_field reserved;      //bits reservados

        function new(string name = "aligner__IRQEN");
            super.new(name, 32, UVM_NO_COVERAGE); //registro de 32 bits sin cobertura propia
        endfunction : new

        //build: arma cada campo del registro con su ancho, posicion y tipo de acceso
        virtual function void build();
            //Datasheet (Tabla 7): todos los campos de IRQEN son RW con reset 0.
            //El modelo autogenerado los traia como W1C reset 1, lo que hacia
            //que update() nunca generara la escritura en el bus
            this.RX_FIFO_EMPTY = new("RX_FIFO_EMPTY");
            this.RX_FIFO_EMPTY.configure(this, 1, 0, "RW", 0, 'h0, 1, 1, 0);
            this.RX_FIFO_FULL = new("RX_FIFO_FULL");
            this.RX_FIFO_FULL.configure(this, 1, 1, "RW", 0, 'h0, 1, 1, 0);
            this.TX_FIFO_EMPTY = new("TX_FIFO_EMPTY");
            this.TX_FIFO_EMPTY.configure(this, 1, 2, "RW", 0, 'h0, 1, 1, 0);
            this.TX_FIFO_FULL = new("TX_FIFO_FULL");
            this.TX_FIFO_FULL.configure(this, 1, 3, "RW", 0, 'h0, 1, 1, 0);
            this.MAX_DROP = new("MAX_DROP");
            this.MAX_DROP.configure(this, 1, 4, "RW", 0, 'h0, 1, 1, 0);
            this.reserved = new("reserved");
            this.reserved.configure(this, 27, 5, "RO", 0, 'h0, 1, 1, 0);
        endfunction : build
    endclass : aligner__IRQEN

    //reg - aligner::IRQ (estado de las interrupciones)
    class aligner__IRQ extends uvm_reg;
        rand uvm_reg_field RX_FIFO_EMPTY; //irq de fifo RX vacia
        rand uvm_reg_field RX_FIFO_FULL;  //irq de fifo RX llena
        rand uvm_reg_field TX_FIFO_EMPTY; //irq de fifo TX vacia
        rand uvm_reg_field TX_FIFO_FULL;  //irq de fifo TX llena
        rand uvm_reg_field MAX_DROP;      //irq de maximo de drops
        rand uvm_reg_field reserved;      //bits reservados

        function new(string name = "aligner__IRQ");
            super.new(name, 32, UVM_NO_COVERAGE); //registro de 32 bits sin cobertura propia
        endfunction : new

        //build: arma cada campo del registro con su ancho, posicion y tipo de acceso
        virtual function void build();
            //Datasheet (Tabla 8): todos los campos de IRQ son W1C con reset 0
            //(el hardware los pone en 1 y el software los limpia escribiendo 1)
            this.RX_FIFO_EMPTY = new("RX_FIFO_EMPTY");
            this.RX_FIFO_EMPTY.configure(this, 1, 0, "W1C", 0, 'h0, 1, 1, 0);
            this.RX_FIFO_FULL = new("RX_FIFO_FULL");
            this.RX_FIFO_FULL.configure(this, 1, 1, "W1C", 0, 'h0, 1, 1, 0);
            this.TX_FIFO_EMPTY = new("TX_FIFO_EMPTY");
            this.TX_FIFO_EMPTY.configure(this, 1, 2, "W1C", 0, 'h0, 1, 1, 0);
            this.TX_FIFO_FULL = new("TX_FIFO_FULL");
            this.TX_FIFO_FULL.configure(this, 1, 3, "W1C", 0, 'h0, 1, 1, 0);
            this.MAX_DROP = new("MAX_DROP");
            this.MAX_DROP.configure(this, 1, 4, "W1C", 0, 'h0, 1, 1, 0);
            this.reserved = new("reserved");
            this.reserved.configure(this, 27, 5, "RO", 0, 'h0, 1, 1, 0);
        endfunction : build
    endclass : aligner__IRQ

    //addrmap - aligner (bloque que agrupa los registros y su mapa de direcciones)
    class aligner extends uvm_reg_block;
        rand aligner__CTRL CTRL;
        rand aligner__STATUS STATUS;
        rand aligner__IRQEN IRQEN;
        rand aligner__IRQ IRQ;

        function new(string name = "aligner");
            super.new(name); //llama al constructor de la clase base uvm_reg_block
        endfunction : new

        //build: crea el mapa, construye cada registro y lo agrega en su direccion
        virtual function void build();
            this.default_map = create_map("reg_map", 0, 4, UVM_LITTLE_ENDIAN);
            this.CTRL = new("CTRL");
            this.CTRL.configure(this);

            this.CTRL.build();
            this.default_map.add_reg(this.CTRL, 'h0);
            this.STATUS = new("STATUS");
            this.STATUS.configure(this);

            this.STATUS.build();
            this.default_map.add_reg(this.STATUS, 'hc);
            this.IRQEN = new("IRQEN");
            this.IRQEN.configure(this);

            this.IRQEN.build();
            this.default_map.add_reg(this.IRQEN, 'hf0);
            this.IRQ = new("IRQ");
            this.IRQ.configure(this);

            this.IRQ.build();
            this.default_map.add_reg(this.IRQ, 'hf4);
        endfunction : build
    endclass : aligner

endpackage: aligner_apb_registerfile_model
