module TRI_State (
	inout port,
	input dir,
	input send,
	output read
	);
	
	
	assign port = dir ? send : 1'bz;  // Se dir for 1, entra no modo de enviar dados.
	assign read = dir ? 1'bz : port;  // Se dir for 0, entra no modo de ler dados.
	
	
endmodule 