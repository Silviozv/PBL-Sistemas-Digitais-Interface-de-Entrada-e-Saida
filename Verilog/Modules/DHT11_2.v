module DHT11_2 ( 
	input clk_50MHz,          // Sinal de clock de 50 MHz
	input en,                  // Sinal de enable
	input rst,                 // Sinal de reset
	inout dht_data,            // Pino de dados
	output [7:0] hum_int,      // Parte inteira da humidade
	output [7:0] hum_float,    // Parte decimal da humidade
	output [7:0] temp_int,     // Parte inteira da temperatura
	output [7:0] temp_float,   // Parte inteira da temperatura
	output [7:0] cs,           // Check sum
	output wai,                // indica que o circuito está operando e aguarda retorno do DHT11
	output debug,              // Saída que copia os dados lidos do DHT11 para ser usado no osciloscópio
	output error               // Sinal que indica a ocorrência de erro na transmissão de dados
	);

	
	reg dir;                                // Usado para alterar o sentido do pino de entrada e saída do DHT11
	reg dht_out;                            // Dado enviado da FPGA para o DHT11
	reg wai_reg, debug_reg, error_reg;      // Registradores conectados com as saída
	reg [25:0] counter;                     // Contador para as divisões de clock
	reg [5:0] index;                        // Usado para indexação dos dados no barramento 	
	reg [39:0] data;                        // Barramento que armazena os dados retornados do DHT11
	wire dht_in;                            // Dado enviado do DHT11 para a FPGA             
	
	// Conectando os registradores com as saída
	assign wai = wai_reg;
	assign debug = debug_reg;
	assign error = error_reg;
	
	
	// Módulo para alterar o pino de ligação com o DHT11 para o modo de envio ou leitura.
	TRI_State TRIS0 (
		.port( dht_data),
		.dir( dir),
		.send( dht_out),
		.read( dht_in)
		);
		
	
	// Conectando o barramento geral de dados do DHT11 com seus barramentos específicos.
	// O DHT11 começa enviando do bit mais significativo.
		
	assign hum_int[7] = data[0];
	assign hum_int[6] = data[1];
	assign hum_int[5] = data[2];
	assign hum_int[4] = data[3];
	assign hum_int[3] = data[4];
	assign hum_int[2] = data[5];
	assign hum_int[1] = data[6];
	assign hum_int[0] = data[7];
	
	assign hum_float[7] = data[8];
	assign hum_float[6] = data[9];
	assign hum_float[5] = data[10];
	assign hum_float[4] = data[11];
	assign hum_float[3] = data[12];
	assign hum_float[2] = data[13];
	assign hum_float[1] = data[14];
	assign hum_float[0] = data[15];
	
	assign temp_int[7] = data[16];
	assign temp_int[6] = data[17];
	assign temp_int[5] = data[18];
	assign temp_int[4] = data[19];
	assign temp_int[3] = data[20];
	assign temp_int[2] = data[21];
	assign temp_int[1] = data[22];
	assign temp_int[0] = data[23];
	
	assign temp_float[7] = data[24];
	assign temp_float[6] = data[25];
	assign temp_float[5] = data[26];
	assign temp_float[4] = data[27];
	assign temp_float[3] = data[28];
	assign temp_float[2] = data[29];
	assign temp_float[1] = data[30];
	assign temp_float[0] = data[31];
	
	assign cs[7] = data[32];
	assign cs[6] = data[33];
	assign cs[5] = data[34];
	assign cs[4] = data[35];
	assign cs[3] = data[36];
	assign cs[2] = data[37];
	assign cs[1] = data[38];
	assign cs[0] = data[39];
	
	// Registradora com os estados
	reg [3:0] state;
	
	// Estados do circuito
	parameter S0 = 1, S1 = 2, S2 = 3, S3 = 4, S4 = 5, S5 = 6, 
				 S6 = 7, S7 = 8, S8 = 9, STOP = 0, START = 10;
	
	// Lógica da FSM (Finite State Machine)
	always @( posedge clk_50MHz)
		
		// Iniciando máquina de estados
		begin: FSM
			
			// Se enable for 1, a máquina de estados pode partir
			if (en == 1'b1)
				
				begin 
					
					// Verificando o reset
					if ( rst == 1'b1)
						
						begin
						
							dht_out <= 1'b1;    // Manda o sinal para que DHT11 fique pronto para operar
							wai_reg <= 1'b0;    // Indica que a passagem de dados ainda não iniciou
							counter <= 26'b00000000000000000000000000;
							data <= 40'b0000000000000000000000000000000000000000;
							dir <= 1'b1;       // Configurando a transmissão como uma saída (FPGA -> DHT11)
							error_reg <= 1'b0;
							state <= START;    // Mudando de estado
							
						end
						
					else begin
				
						case (state)
						
							// Inicialização da máquina de estados
							START:
							
								begin
								
									wai_reg <= 1'b1;   // Sinaliza que a estrutura está operando
									dir <= 1'b1;       // Configurando a transmissão como uma saída (FPGA -> DHT11)
									dht_out <= 1'b1;   // Manda o sinal para que DHT11 fique pronto para operar
									state <= S0;       // Mudando de estado
									
								end
							
							// Estado de mandar nível lógico alto para preparar para o sinal de start.
							// Permanecendo nele por 18 ms.
							S0:
							
								begin
								
									dir <= 1'b1;       // Configurando a transmissão como uma saída (FPGA -> DHT11)
									dht_out <= 1'b1;   // É mantido em nível lógico alto
								   wai_reg <= 1'b1;   // Sinaliza que a estrutura está operando
									error_reg <= 1'b0;
									
									if (counter >= 900000) begin     // Após a passagem do tempo, passa-se ao próximo estado
										
										counter <= 26'b00000000000000000000000000;
										state <= S1;
										
									end
									
									else begin       // É preciso aguardar um tempo de 18 ms
										
										counter <= counter + 1'b1;
										state <= S0;
										
									end
									
								end
							
							// Estado de mandar nível lógico baixo como forma de indicar que ocorrerá uma aquisição de dados.
							// Permanecendo nele por 19 ms.
							S1:
							
								begin
									dht_out <= 1'b0;   // Nível lógico baixo como procedimento de aquisição de dados
									wai_reg <= 1'b1;   // Sinaliza que a estrutura está operando
									
									if (counter >= 950000)  begin    // Após a passagem do tempo, passa-se ao próximo estado 
										
										counter <= 26'b00000000000000000000000000;
										state <= S2;
										
									end
									
									else begin       // É preciso aguardar um tempo de 18 ms
										
										counter <= counter + 1'b1;
										state <= S1;
										
									end
									
								end
							
							// Manda-se novamente nível lógico alto.
							// Permanecendo nesse estado por 20 us (a resposta do DHT11 deve ocorrer entre 20 a 40 us).
							S2: 
							
								begin 
									dht_out <= 1'b1;
									
									if ( counter >= 1000) begin
									
										dir <= 1'b0;    // Muda a direção do pino para receber dados do DHT11 (DHT11 -> FPGA)
										state <= S3;
									
									end
									
									else begin
									
										counter <= counter + 1'b1;
										state <= S2;
									
									end
								
								end
							
							// Estado de aguardo da resposta do DHT11. O nível lógico que se deve esperar do dht_in é o 0,
							// indicando que o DHT11 está sincronizando. O tempo de espera é de 60 us.
							S3:
							
								begin
									
									if ( dht_in == 1'b0) begin  
										
										counter <= 26'b00000000000000000000000000;
										state <= S4;
									
									end
									
									else begin      // O DHT11 ainda não deu o sinal de resposta
									
										counter <= counter + 1'b1;
										
										if ( counter >= 3000) begin
										
											error_reg <= 1'b1;     // Ocorreu um erro
											counter <= 26'b00000000000000000000000000;
											state <= STOP;
										
										end
									
									end
									
								end
							
							// Estado responsável por continuar detectando o pulso de sincronismo do DHT11.
							// O DHT11 deve enviar nível lógico alto antes do tempo limite de 88 us.
							S4:
							
								begin
								
									if ( dht_in == 1'b1) begin       
										
										state <= S5;
										counter <= 26'b00000000000000000000000000;
										
									end
									
									else begin
									
										counter <= counter + 1'b1;
										
										if ( counter >= 4400) begin
										
											error_reg <= 1'b1;          // Sinal de erro
											counter <= 26'b00000000000000000000000000;
											state <= STOP;
										
										end
									
									end
									
								end
							
							// Estado responsável por fazer a última checagem do processo de sincronismo com o DHT11.
							// O DHT11 deve enviar nível lógico baixo antes do tempo limite de 88 us.
							S5:
							
								begin
								 
									if ( dht_in == 1'b0) begin      
									
										state <= S6;
										counter <= 26'b00000000000000000000000000;
									
									end
									
									else begin
									
										counter <= counter + 1'b1;
										
										if ( counter >= 4400) begin
										
											error_reg <= 1'b1;     // Sinal de erro
											counter <= 26'b00000000000000000000000000;
											state <= STOP;
										
										end
									 
									end
									
								end
								
							// Inicio da leitura de dados
							S6:
								
								begin
									
									if ( dht_in == 1'b1) begin      
									
										state <= S7;
										error_reg <= 1'b0;
										index <= 6'b000000;       // Reseta o indexador
										counter <= 26'b00000000000000000000000000;
									
									end
									
									else begin
									
										counter <= counter + 1'b1;
										
										if ( counter >= 3275000) begin
										
											error_reg <= 1'b1;     // Sinal de erro
											counter <= 26'b00000000000000000000000000;
											state <= STOP;
										
										end
									 
									end
									
								end
								
							// Estado de leitura dos pulsos.
							// O nível baixo e alto é determinado pela largura do pulso de nível
							// lógico alto enviado. 
							S7:
								
								begin
									
									if ( dht_in == 1'b0) begin     // Não atingiu o tempo limite do else e comutou para 0
										
										// A largura do pulso de nível lógico alto foi lida corretamente
											
										if ( counter > 2500) begin  // Contador é maior que 50 us, então é nível lógico alto
											
											data[index] <= 1'b1;     // Armazena o dado no barramento de 40 bits
											debug_reg <= 1'b1;       // Copia dado para debug no osciloscópio
											
										end
											
										else begin                  // Contador é menor que 50 us, então é nível lógico baixo
											
											data[index] <= 1'b0;     // Armazena o dado no barramento de 40 bits
											debug_reg <= 1'b0;       // Copia dado para debug no osciloscópio
											
										end
											
										if ( index >= 39) begin      // Todos os bits foram lidos, o estado vai para o de STOP   
										
											error_reg <= 1'b0;    
											state <= STOP;
											
										end
											
										else begin           // Ainda não acabou a leitura de todos os bits
											
											counter <= 26'b00000000000000000000000000;
											state <= S8;
											
										end
										
									end
										
									else begin   // É contabilizada a largura do pulso de nível lógico alto
										
										counter <= counter + 1'b1;
											
										if ( counter > 1600000) begin   // Atingiu tempo limite de 32 ms
											
											error_reg <= 1'b1;         // Sinal de erro
											state <= STOP;
											
										end
										
									end
									
								end
								
							// O index é incrementado em um estado separado para ter certeza que o registrador
							// terá tempo de se estabilizar.
							// O circuito volta para o S6 e o processo ocorre novamente para cada bit.
							S8:
								
								begin 
									
									index <= index + 1'b1;
									state <= S6;
									
								end
									
							STOP:
								
								begin
									
									state <= STOP;
										
									if ( error_reg <= 1'b0) begin      // Não ocorreu nenhum erro
										
										dht_out <= 1'b1;
										wai_reg <= 1'b0;           // Sinaliza que a estrutura terminou o processamento
										counter <= 26'b00000000000000000000000000;
										dir <= 1'b1;               // Configurando conexão com o DHT11 como transmissão (FPGA -> DHT11)
										error_reg <= 1'b0;             // Erro é resetado
										index <= 6'b000000;
										
									end
										
									else begin      // Se ocorreu erro
										
										if ( counter < 1600000) begin    // Aguarda 32 ms
											
											data <= 40'b0000000000000000000000000000000000000000;    // Os dados são resetados
											counter <= counter + 1'b1;
											error_reg <= 1'b1;
											wai_reg <= 1'b1;      // Sinaliza que o sistema ainda está em execução
											dir <= 1'b0;          // Configura pino do DHT11 para receber dados (DHT11 -> FPGA)
											
										end
											
										else begin      // Após a passagem do tempo, o erro vai para 0
											
											error_reg <= 1'b0;
											
										end
										
									end
									
								end
		
						endcase
	
				end
				
			end		
			
		end					
		

endmodule 