parameter delay = 0.05;
`timescale 1ns/10ps

module decode2_1(enable,sel,out); //2 input decoder
			output logic [1:0] out;
			input logic enable,sel;
			
			wire notSel;
			not#delay not1(notSel,sel);
			
			and#delay and1(out[0],enable,notSel);
			and#delay and2(out[1],enable,sel);

			
endmodule

module decode4_1(enable,sel,out); //4 input decoder
			output logic [3:0] out;
			input logic enable;
			input logic [1:0] sel;
			
			wire [1:0] control;
			decode2_1 d3(enable,sel[1],control);
			//uses 2 2_1 decodes for output while a seperate 2_1 to control which one is one
			decode2_1 d1(control[0],sel[0],out[1:0]);
			decode2_1 d2(control[1],sel[0],out[3:2]);
			


endmodule


module decode8_1(enable,sel,out);//8 by 1 decoder
			output logic [7:0] out;
			input logic enable;
			input logic [2:0] sel;
			
			wire [1:0] control;
			decode2_1 d3(enable,sel[2],control);
			//controlls the two 4 output decoders with a 2 output decoder
			decode4_1 d1(control[0],sel[1:0],out[3:0]);
			decode4_1 d2(control[1],sel[1:0],out[7:4]);
			


endmodule

module decode16_1(enable,sel,out);// 16b by 1 decoder
			output logic [15:0] out;
			input logic enable;
			input logic [3:0] sel;
			
			
			wire [1:0] control;
			decode8_1 d1(control[0],sel[2:0],out[7:0]);
			decode8_1 d2(control[1],sel[2:0],out[15:8]);
			decode2_1 d3(enable,sel[3],control);
			//creates from two 8 output decoders with a 2 output decoder controlling enables


endmodule

module decode32_1(enable,sel,out); //32 by 1 decoder
			output logic [31:0] out;
			input logic enable;
			input logic [4:0] sel;
			//creates from two 16 output decoders with a 2 output decoder controlling enables
			wire [1:0] control;
			decode16_1 d1(control[0],sel[3:0],out[15:0]);
			decode16_1 d2(control[1],sel[3:0],out[31:16]);
			decode2_1 d3(enable,sel[4],control);


endmodule




  module decode_testbench();
			logic enable;

			logic [31:0] out;
			logic [4:0] sel;
			
			
			decode32_1 dut(enable,sel,out);
			initial begin	
				for (int i=0; i< 32; i++) begin
            enable = 1;sel = i; #50;
            
				end
			end
	endmodule
	