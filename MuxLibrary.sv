  parameter delay = 0.05;
  `timescale 1ns/10ps

  
  module mux2_1(out, i0, i1, sel);
            output logic out;
            input  logic i0, i1, sel;
				
				wire m0,m1,notsel;
				not#delay inSel(notsel,sel);
				and#delay and1(m0,i1,sel);
				and#delay and2(m1,i0,notsel);
				
				or or1(out,m0,m1);
				//creates a 2 input multiplexer from gates
				
            //assign out  = (i1 & sel) | (i0 & ~sel); // Assigns the output to the Muliplexed input
  endmodule
  
  module mux2_5(out,i0,i1,sel);
		input logic sel;
		input logic [4:0] i0,i1;
		output logic [4:0] out;
		genvar i;
		
		generate
			for(i = 0; i < 5;i++) begin: mux
				
				mux2_1 mux_gen(out[i], i0[i], i1[i], sel);
				
			end
		endgenerate
  
  
  
  endmodule
  
    module mux_2_5_testbench();
		logic [5:0] out,i0,i1;
		logic sel;
		mux2_5 dut(out,i0,i1,sel);
		
		initial begin
				i0 = 5'h1F;i1 = 5'h12;sel = 1;#50;
				i0 = 5'h1F;i1 = 5'h12;sel = 0;#50;
		
		
		end
  endmodule 
  
  
  
    module mux2_64(out,i0,i1,sel);
		input logic sel;
		input logic [63:0] i0,i1;
		output logic [63:0] out;
		genvar i;
		
		generate
			for(i = 0; i < 64;i++) begin: mux
				
				mux2_1 mux_gen(out[i], i0[i], i1[i], sel);
				
			end
		
		
		endgenerate
  
  
  
  endmodule
  
  module mux_2_64_testbench();
		logic [63:0] out,i0,i1;
		logic sel;
		mux2_64 dut(out,i0,i1,sel);
		
		initial begin
				i0 = 64'd32;i1 = 64'hFFFF420;sel = 1;#50;
				i0 = 64'd32;i1 = 64'hFFFF420;sel = 0;#50;
		
		
		end
		
  
  
  endmodule 
  
  
  
  
  
   module mux4_1(out, in, sel);
				output logic out;
				input logic [3:0] in;
				input logic [1:0] sel;
				
				wire m0, m1;
					//uses multiple 2_1 multiplexers 
					// two control inputs
					// third one controls between those
				 mux2_1 mux0(m0,in[0],in[1],sel[0]);
				 mux2_1 mux1(m1,in[2],in[3],sel[0]);
				 mux2_1 mux2(out,m0,m1,sel[1]);
				
  endmodule
  
  module mux4_64(out,i0,i1,i2,i3,sel);
		input logic [1:0]sel;
		input logic [63:0] i0,i1,i2,i3;
		output logic [63:0] out;
		
		wire [63:0] m0,m1;
		mux2_64 mux0(m0,i0,i1,sel[0]);
		mux2_64 mux1(m1,i2,i3,sel[0]);
		mux2_64 mux2(out,m0,m1,sel[1]);
  
  
  endmodule
  
  
  
  
  
    module mux8_1(out, in, sel);
		output logic out;
		input logic [7:0] in;
		input logic [2:0] sel;
		wire m0, m1;
		
		//builds an 8 input plexer from 2 4 input multiplexer with a 2 input one to chose between halfs
		mux4_1 mux0(m0,in[3:0],sel[1:0]);
		mux4_1 mux1(m1,in[7:4],sel[1:0]);
		mux2_1 mux2(out,m0,m1,sel[2]);
		
  endmodule
  
    
  module mux16_1(out, in, sel);
		output logic out;
		input logic [15:0] in;
		input logic [3:0] sel;
		wire m0, m1;
		//continution of building bigger compents from smaller and switching between them with muxes
		mux8_1 mux0 (m0,in[7:0],sel[2:0]);
		mux8_1 mux1 (m1,in[15:8],sel[2:0]);
		mux2_1 mux2 (out,m0,m1,sel[3]);
  endmodule
 
  module mux32_1(out, in, sel);
		output logic out;
		input logic [31:0] in;
		input logic [4:0] sel;
		wire m0, m1;
		
		//creates 2 16bit multiplexers with an 2 bit mulplixer to switch between then creating  32 by 1 multiplexer
		mux16_1 mux0 (m0,in[15:0],sel[3:0]);
		mux16_1 mux1 (m1,in[31:16],sel[3:0]);
		mux2_1 mux2 (out,m0,m1,sel[4]);
  endmodule
  
  module mux32_64(out,in,sel);
		//parameter width = 32;
		output logic [63:0] out;
		input logic [63:0][31:0] in;
		input logic [4:0] sel;
		
		genvar i,j;
		//generates 64 32 input multiplexers
		//takes in the transpose of the register bit width vector
		generate	
			//for(i = 0; i < 32;i++) begin
				for(j =0; j < 64;j++) begin: mux
					mux32_1 muxGen(out[j],in[j],sel);
				end
			//end
		
		endgenerate
  
  endmodule
  
  
  
  
  module mux32_1_testbench();
			logic out;
			logic [31:0] in;
			logic [4:0] sel;
			
			
			mux32_1 dut(out,in,sel);
			initial begin	
				for (int i=0; i<32; i=i+1) begin
            in = 42405;sel = i; #50;
            
				end
			end
	endmodule
	
	  
	  module mux32_64_testbench();
			logic [63:0]out;
			logic [63:0][31:0] in;
			logic [4:0] sel;
			
			
			mux32_64 dut(out,in,sel);
			initial begin	
			for(int j = 0; j < 64;j++) begin	
				for(int i = 0; i < 32;i++)begin
					in[j][i] = 0;
					
				end
			end
			
			
			for(int i = 0; i < 64;i++)begin
				for(int j = 0; j < 32; j++)begin
					in[i][j] = 1;
						
				end
			
			
			end			
			
			
			for (int i=0; i<32; i++) begin
            sel = i; #50;
			end
			
			for(int i = 0; i < 64;i++)begin
				for(int j = 0; j < 32; j= j+2)begin
					in[i][j] = 1;
						
				end
			
			
			end
			for (int i=0; i<32; i++) begin
				sel = i; #50;
			end
				
			for(int i = 0; i < 64;i++)begin
				for(int j = 0; j < 32; j= j+4)begin
					in[i][j] = 1;
						
				end
			end
				
			for (int i=0; i<32; i++) begin
            sel = i; #50;
			end
			
			for(int i = 0; i < 64;i++)begin
				for(int j = 0; j < 32; j= j+8)begin
					in[i][j] = 1;
						
				end
			end
			
			for (int i=0; i<32; i++) begin
            sel = i; #50;
			end
			
			for(int i = 0; i < 64;i++)begin
				for(int j = 0; j < 32; j= j+16)begin
					in[i][j] = 1;
						
				end
			end			
			
			for (int i=0; i<32; i++) begin
            sel = i; #50;
			end
			
			for(int i = 0; i < 64;i++)begin
				for(int j = 0; j < 32; j= j+32)begin
					in[i][j] = 1;
						
				end
			end				
				
				
				
				
			end
	endmodule
	
	  module mux2_1_testbench();
       logic i0, i1, sel;
 		 logic out; 

           mux2_1 dut (.out, .i0, .i1, .sel);
           initial begin
                  sel=0; i0=0; i1=0; #50;
                  sel=0; i0=0; i1=1; #50;
                  sel=0; i0=1; i1=0; #50;
                  sel=0; i0=1; i1=1; #50;
                  sel=1; i0=0; i1=0; #50;
                  sel=1; i0=0; i1=1; #50;
                  sel=1; i0=1; i1=0; #50;
                  sel=1; i0=1; i1=1; #50;
           end
endmodule

module mux4_1_testbench();
		
		logic [3:0] in;
		logic [1:0] sel;
		logic out;
		//Tests the inputs at various times t


		
		mux4_1 dut(out, in, sel);
			initial begin
				sel = 2'b00;in =4'b0000; #50;
				sel = 2'b00;in =4'b0001; #50;
				sel = 2'b01;in =4'b0001; #50;
				sel = 2'b01;in =4'b0010; #50;
				sel = 2'b10;in =4'b0010; #50;
				sel = 2'b10;in =4'b0011; #50;
				sel = 2'b10;in =4'b0100; #50;
				sel = 2'b10;in =4'b1100; #50;
				sel = 2'b10;in =4'b1000; #50;
				sel = 2'b11;in =4'b0100; #50;
				sel = 2'b00;in =4'b1110; #50;
				
				
			end
endmodule
			

	