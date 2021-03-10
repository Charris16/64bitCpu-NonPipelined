parameter delay = 0.05;
`timescale 1ns/10ps




//module for a 64 bit ALU
// 000:			result = B						
// 010:			result = A + B
// 011:			result = A - B
// 100:			result = bitwise A & B		
// 101:			result = bitwise A | B		
// 110:			result = bitwise A XOR B	
module alu_64b(A,B,OP,result,negative, zero, overflow, carry_out);
	input logic [63:0] A,B;
	input logic [2:0] OP;
	output logic [63:0] result;
	output logic negative, zero, overflow, carry_out;
	wire sub;
	
	logic[63:0] carrys;
	logic notOP;
	
	not#delay NotOp(notOP,OP[2]);
	and#delay subSignal(sub,OP[1],OP[0],notOP);
	//checks to see if the operation is a subtract
	
	
	
	
	
	aluSlice edgecaseALU0(A[0],B[0],OP,sub,carrys[0],result[0]);
	//creates edgecase ALu slice that takes in the +1 signal to add 1 for subtracting
	
	
	genvar i;

	generate	
			
			for(i = 1; i < 64;i++) begin: ALU
				aluSlice ALUgen(A[i],B[i],OP,carrys[i-1],carrys[i],result[i]);
			end
	endgenerate
	//generates remaining 63 ALUs slices and wires the carrys up together
	//creates carry bus uses for wiring up overflow flag

	
	
	assign negative = result[63];
	assign carry_out = carrys[63];
	//creates carry and negative flags from the carry bus and result bus
	
	
	logic zFlag;
	isZero zeroFlag(result,zFlag);
	assign zero = zFlag;
	//uses isZero module to check if output is 0
	//assigns that check to zero flag
	
	logic ovrFlag;
	xor#delay OverflowFlag(ovrFlag,carrys[63],carrys[62]);
	assign overflow = ovrFlag;
	//checks sign on the last two carrys 
	//if differnt overflow == 1
	

endmodule
//module to check is Input is 0
module isZero(A,foo);
	
	input logic [63:0] A;
	output logic foo;
	//output foo == 1 if A == 0 
	//output foo == 0 if A != 0
	
	logic [15:0] stage1;
	logic [3:0] stage2;
	
	//NOR STAGE
	genvar i;
	generate		
			for(i = 0; i < 16;i++) begin: norStage1
				nor norGenStage1(stage1[i],A[(4*i)],A[(4*i)+1],A[(4*i)+2],A[(4*i)+3]);
			end
	endgenerate
	//generates a bunch of 4 input nor gates and wire them up instages
	//need generate statement to avoid using more than 4 input gates
	
	//AND STAGES
	genvar j;
	generate		
			for(j = 0; j < 4;j++) begin: norStage2
				
				and andGenStage2(stage2[j],stage1[(4*j)],stage1[(4*j)+1],stage1[(4*j)+2],stage1[(4*j)+3]);
			end
	endgenerate
	//wires outputs of previous stage together with and gates to create a large nor gate
	and#delay finalStage(foo,stage2[3],stage2[2],stage2[1],stage2[0]);
	//final stage that ANDS the previous AND stage together 
	//to many gates to have 1 singluar Stage with reasonable delays

endmodule








module adder_64b(A,B,result,carry_out);
	input logic [63:0] A,B;
	output logic [63:0] result;
	output logic carry_out;
	
	logic[63:0] carrys;

	
	
	adder edgecaseAdder0(A[0],B[0],1'b0,result[0],carrys[0]);
	
	
	genvar i;

	generate	
			
			for(i = 1; i < 64;i++) begin: ALU
				adder Addergen(A[i],B[i],carrys[i-1],result[i],carrys[i]);
			end
	endgenerate
	assign carry_out = carrys[63];

endmodule







module aluSlice(A,B,OP,cin,cout,sum);
	
	input logic A,B,cin;
	input logic [2:0]OP;
	output logic sum,cout;
	
	wire Bmux,notB,adderOut,andOut,OrOut,XorOut,sub,notOP;
	wire [7:0] outMuxin;
	
//	and#delay LogicAnd(andOut,A,B);
//	or#delay LogicOr(OrOut,A,B);
//	xor#delay LogicXOR(XorOut,A,B);
	

	assign outMuxin[0] = B;
	assign outMuxin[1] = 1'b0;//don't care
	//OutMuxin[2] is assigned dirrectly in Adder unit
	assign outMuxin[3] = outMuxin[2];//Both add and sub share data path
	
	and#delay LogicAnd(outMuxin[4],A,B);
	or#delay LogicOr(outMuxin[5],A,B);	//
	xor#delay LogicXOR(outMuxin[6],A,B);
	//Puts A,B through there respective logic units 
	//Wires the output of each gate to its location in the mux based on the op code
	
	assign outMuxin[7] = 1'b0;//dont care

	

	
	
	

	not#delay NOTOP(notOP,OP[2]);
	and#delay and1(sub,notOP,OP[1],OP[0]);
	not#delay not1(notB,B);
	mux2_1 subMux(Bmux, B, notB, sub);
	//checks for a subtract OP
	//If sub == 0; ALU receives A,  B
	//If sub == 1; ALU receives A, ~B
	
	
	adder Addern(A,Bmux,cin,outMuxin[2],cout);
	//creates adder that takes in A and Bmux and sums them
	
	//output mux
	//controled by OP code
	mux8_1 outputMUx(sum, outMuxin, OP);

endmodule





//Basic 1bit full adder module
// inputs A,B,cin 
//computes A+B+cin
//outputs to Sum and Cout

module adder(A,B,Cin,Sum,Cout);
	input logic A,B,Cin;
	output logic Sum,Cout;
	
	wire xOut1,AandB,Candx2;
	xor#delay xor1(xOut1,A,B);
	xor#delay xor2(Sum,xOut1,Cin);
	
	and#delay and1(AandB,A,B);
	and#delay and2(Candx2,xOut1,Cin);
	
	or#delay or1(Cout,AandB,Candx2);

endmodule


module b64_adder_test();

	logic [63:0] A,B;
	logic [63:0] result;
	logic carry_out;
	
	adder_64b dut(A,B,result, carry_out);
	initial begin
		A=64'h0;B=64'hFFFF;#14000;
		A=64'h0;B=64'hFFFF;#14000;
		A=64'hFFFF;B=64'hFFFF;#14000;
		

	
	
	end


endmodule


module ALU_testbench();
	logic [63:0] A,B;
	logic [2:0] OP;
	logic [63:0] result;
	logic negative, zero, overflow, carry_out;
	
	alu_64b dut(A,B,OP,result,negative, zero, overflow, carry_out);
	initial begin
		A=64'h0;B=64'hFFFF;OP=3'b000;#14000;
		A=64'h0;B=64'hFFFF;OP=3'b000;#14000;
		A=64'hFFFF;B=64'hFFFF;OP=3'b010;#14000;
		#14000;
		#14000;
		#14000;
		#14000;
		#14000;
		#14000;
		A=64'hFFFFFFFFFFFFFFFF;B=64'hFFFF;OP=3'b011;#14000;
		#14000;
		#14000;
		#14000;
		A=64'h0;B=64'h0;OP=3'b010;#14000;
		A=64'h1;B=64'h1;OP=3'b010;#14000;
		A=64'h0;B=64'h1;OP=3'b010;#14000;
		A=64'h1;B=64'h1;OP=3'b010;#14000;
		A=64'h2;B=64'h1;OP=3'b010;#14000;
		A=64'h1;B=64'h2;OP=3'b010;#14000;
		A=64'h5;B=64'h3;OP=3'b010;#14000;
		#14000;
		A=64'h0;B=64'hFFFF;OP=3'b010;#14000;
		#14000;
		#14000;
		#14000;
		#14000;
		A=64'hFF;B=64'hFFFF;OP=3'b100;#14000;
	
	
	end


endmodule




module isZero_testbench();

	logic [63:0] A;
	logic foo;
	
	
	isZero dut(A,foo);
	initial begin
		A=64'hFFFFFFFFFFFFFFFF;#1000;
		A=64'b0;#1000;
		A=64'hFFFFFF4FFFF2FFFF;#1000;
		A=64'hCCCCCCCCCCCCCCCC;#1000;
		A=64'hFFFF;#1000;
		A=64'h7FFF;#1000;
		A=64'h3FFF;#1000;
		A=64'h1FFF;#1000;
		A=64'h0FFF;#1000;
		
		A=64'h0FFF;#1000;
		A=64'h07FF;#1000;
		A=64'h03FF;#1000;
		A=64'h01FF;#1000;
		A=64'h00FF;#1000;

		A=64'h00FF;#1000;
		A=64'h007F;#1000;
		A=64'h003F;#1000;
		A=64'h001F;#1000;
		A=64'h000F;#1000;
		
		A=64'h000F;#1000;
		A=64'h0007;#1000;
		A=64'h0003;#1000;
		A=64'h0001;#1000;
		A=64'h0000;#1000;
	
	
	end

endmodule


module aluSlice_TestBench();
	logic A,B,cin,sum,cout;
	logic [2:0]OP;
	
	aluSlice dut(A,B,OP,cin,cout,sum);
	initial begin
		
		
		
			OP=000;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;

			OP=001;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;
		
			OP=010;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;

			OP=011;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;		
		

			OP=100;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;
		
			OP=101;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;

			OP=110;A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=0;#1000;
			A=0;B=0;cin=1;#1000;
			A=0;B=1;cin=0;#1000;
			A=0;B=1;cin=1;#1000;
			A=1;B=0;cin=0;#1000;
			A=1;B=0;cin=1;#1000;
			A=1;B=1;cin=0;#1000;
			A=1;B=1;cin=1;#1000;		
				
		
		
		
	
	
	end



endmodule



module adder_testBench();
	logic A,B,Cin,Sum,Cout;
	
	adder dut(A,B,Cin,Sum,Cout);
	initial begin
		A=0;B=0;Cin=0;#1000;
		A=0;B=0;Cin=0;#1000;
		A=0;B=0;Cin=1;#1000;
		A=0;B=1;Cin=0;#1000;
		A=0;B=1;Cin=1;#1000;
		A=1;B=0;Cin=0;#1000;
		A=1;B=0;Cin=1;#1000;
		A=1;B=1;Cin=0;#1000;
		A=1;B=1;Cin=1;#1000;
		
	
	
	end
	

endmodule




