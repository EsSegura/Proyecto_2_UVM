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

Division:
Seg:
Configuracion de 1 registro RAL
ambiente de UVM menos agente de registros

San:
Toda la estructura de RAL menos la configuracion de 1 registro
1 Agente de registro
