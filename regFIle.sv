module regfile(ReadData1,ReadData2,WriteData, ReadRegister1, ReadRegister2, WriteRegister, RegWrite, clk,reset);

	input logic [4:0] ReadRegister1,ReadRegister2,WriteRegister;
	input logic reset;
	input logic [63:0] WriteData;
	input logic RegWrite,clk;
	output [63:0] ReadData1,ReadData2;
	


	


	wire[31:0] decodeOut;
	decode32_1 writeDecoder(RegWrite,WriteRegister,decodeOut);
	//creates decoder and wires it up to array with each place in array coresponding to a register to enable
	
	logic [31:0][63:0] registerOut;//creates output for register file
	RegisterArray regbank(WriteData,registerOut,decodeOut,reset,clk);
	//creates register file with 32 64 bit registers
	//register 31 is always 0
	
	logic [63:0][31:0]muxin;
	//creates a logic type to allow for matrix transpose
	
	
	always_comb begin //preforms a matrix transpose with wires to order wires correctly for muxltiplexer
		for(int i = 0; i < 64; i++)begin
			for(int j = 0; j < 32;j++)begin
				muxin[i][j] = registerOut[j][i];
				//swaps rows and collumns
			end
		end
	
	end
	
	

	mux32_64 read1(ReadData1,muxin,ReadRegister1);
	//creates 2 multiplexers that view all register outputs and then output only the selected data
	mux32_64 read2(ReadData2,muxin,ReadRegister2);




endmodule
