# Proyecto_2_UVM
Aligner Verification using UVM

## Test plan:

### Test base:
#### Aleatorizar:

Detectar transaccion invalida
Detectar que datos de salida sean validos cuando se detectar PREADY
Interrupciones detienen la simulacion y dicen que paso
1.Tamano del paquete
2.offset 
3.datos
4. eventos de clear

#### Casos esquina:
Caso esquina1:
Chekear registro de estado para underflow y overflow de fifos

Caso esquina2:
Mandar solo transacciones invalidas y chekear interrupcion con maxdrop

Caso esquina 3:
Chekear que se ponga en 1 md_rx_ready cuando fifo de recepcion esta llena


Caso esquina 4:
Chekear que todas las interrupciones se aserten correctamente (W1C) en registro de de interrupcion

Caso esquina 5:
Chekear que no se pueda escribir en registro de solo lectura y viceversa

Caso esquina 6:
Solo mandar tamanos y offset validos intercalados


#### Estructura:
3 agentes:
1 para entrada
otro para salida
uno para interfaz de registros controlada por systemRDL

1 scoreboard

Cobertura

Testbench
Ambiente
RAL

## Posibles Constraints:
1. RX — combinaciones legales e ilegales

c_legal_combo:    ((4 + rx_offset) % rx_size) == 0
c_illegal_combo:  ((4 + rx_offset) % rx_size) != 0

2. RX — combinaciones legales esp

c_size1_off0:     rx_size == 1 && rx_offset == 0
c_size1_off1:     rx_size == 1 && rx_offset == 1
c_size1_off2:     rx_size == 1 && rx_offset == 2
c_size1_off3:     rx_size == 1 && rx_offset == 3
c_size2_off0:     rx_size == 2 && rx_offset == 0
c_size2_off2:     rx_size == 2 && rx_offset == 2
c_size4_off0:     rx_size == 4 && rx_offset == 0

3. RX — combinaciones ilegales esp (debe disparar md_rx_err=1 e incrementar STATUS.CNT_DROP)

c_size2_off1:     rx_size == 2 && rx_offset == 1
c_size2_off3:     rx_size == 2 && rx_offset == 3
c_size4_off1:     rx_size == 4 && rx_offset == 1
c_size4_off2:     rx_size == 4 && rx_offset == 2
c_size4_off3:     rx_size == 4 && rx_offset == 3
c_size0:          rx_size == 0                        

4. RX — fijo

c_size_q1:        rx_size == 1
c_size_q2:        rx_size == 2
c_size_q4:        rx_size == 4
c_offset0:        rx_offset == 0
c_offset1:        rx_offset == 1
c_offset2:        rx_offset == 2
c_offset3:        rx_offset == 3

5. RX — por distribución

c_uniform_offset: rx_offset dist { 0 := 25, 1 := 25, 2 := 25, 3 := 25 }
c_uniform_size:   rx_size   dist { 1 := 33, 2 := 33, 4 := 34 }


6. RX — datos

// Patrones fijos 
c_data:           rx_data inside { 32'hAAAAAAAA, 32'h55555555,
                                   32'hFFFFFFFF, 32'h00000000 }
// Walking 1s
c_data_walking1:  rx_data inside { 32'h00000001, 32'h00000002,
                                   32'h00000004, 32'h00000008,
                                   32'h00000010, 32'h00000100,
                                   32'h00010000, 32'h01000000,
                                   32'h80000000 }

// Walking 0s
c_data_walking0:  rx_data inside { 32'hFFFFFFFE, 32'hFFFFFFFD,
                                   32'hFFFFFFFB, 32'hFEFFFFFF,
                                   32'h7FFFFFFF }

// Totalmente aleatorio 
c_data_random:   

7. APB — direcciones

c_valid_addr:     addr inside { 16'h0000, 16'h000C, 16'h00F0, 16'h00F4 }
c_invalid_addr:   !(addr inside { 16'h0000, 16'h000C, 16'h00F0, 16'h00F4 })
c_read_only:      write == 0
c_write_only:     write == 1


8. APB — alineamiento de palabra

c_addr_unaligned_ctrl:    addr inside { 16'h0001, 16'h0002, 16'h0003 }
c_addr_unaligned_status:  addr inside { 16'h000D, 16'h000E, 16'h000F }
c_addr_unaligned_irqen:   addr inside { 16'h00F1, 16'h00F2, 16'h00F3 }
c_addr_unaligned_irq:     addr inside { 16'h00F5, 16'h00F6, 16'h00F7 }

// Dirección inválida con bits bajos variables
c_invalid_addr_unaligned: !(addr[15:2] inside { 14'h0000, 14'h0003,
                                                14'h003C, 14'h003D })


9. APB — escrituras al ctrl register

// Escritura legal: SIZE != 0 y combinación (SIZE, OFFSET) válida
c_ctrl_legal_write:   write == 1 && addr == 16'h0000 &&
                      (wdata[2:0] != 0) &&
                      (((4 + wdata[9:8]) % wdata[2:0]) == 0)

// Escritura ilegal: SIZE = 0, debe retornar APB error
c_ctrl_size_zero:     write == 1 && addr == 16'h0000 &&
                      wdata[2:0] == 3'd0

// Escritura ilegal: combinación (SIZE, OFFSET) inválida,  APB error
c_ctrl_illegal_combo: write == 1 && addr == 16'h0000 &&
                      wdata[2:0] != 0 &&
                      ((4 + wdata[9:8]) % wdata[2:0]) != 0

// Escritura al STATUS (read-only),  siempre debe retornar APB error
c_status_write:       write == 1 && addr == 16'h000C

// Forzar escritura del bit CLR (bit 16 del CTRL),  resetea CNT_DROP
c_ctrl_clr:           write == 1 && addr == 16'h0000 && wdata[16] == 1


10. INTERRUPCIONES — IRQEN 
// Un solo enable activo a la vez
c_irqen_only_rx_empty: irqen == 5'b00001
c_irqen_only_rx_full:  irqen == 5'b00010
c_irqen_only_tx_empty: irqen == 5'b00100
c_irqen_only_tx_full:  irqen == 5'b01000
c_irqen_only_drop:     irqen == 5'b10000

// Todos habilitados / todos deshabilitados
c_irqen_all:           irqen == 5'b11111
c_irqen_none:          irqen == 5'b00000

// Distribución aleatoria con extremos forzados
c_irqen_random:        irqen dist { 5'b00000 := 10,
                                    [5'b00001:5'b11110] := 80,
                                    5'b11111 := 10 }

11. backpressure al TX — md_tx_ready

// TX lento implica estresa TX FIFO FULL e IRQ.TX_FIFO_FULL
c_tx_slow:     md_tx_ready dist { 0 := 80, 1 := 20 }

// TX rápido implica estresa TX FIFO EMPTY e IRQ.TX_FIFO_EMPTY
c_tx_fast:     md_tx_ready dist { 0 := 10, 1 := 90 }

// Balanceado
c_backpressure_tx: md_tx_ready dist { 0 := 50, 1 := 50 }


12. estres para la FIFO 

c_transactions: num_transfers inside { [100:1000] }

13. CNT_DROP — saturarlo

// Forzar suficientes ilegales para alcanzar y superar el máximo
c_stress_drop:    num_illegal_transfers inside { [250:300] }

// Tráfico mixto con proporción controlada de ilegales
c_mixed_traffic:  illegal_ratio dist { 0 := 20, [1:49] := 60, 50 := 20 }

