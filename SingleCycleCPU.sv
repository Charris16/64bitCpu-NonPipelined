`timescale 1ns/10ps

module SingleCycleCPU(clk,reset);
	input logic clk,reset;
//	
	wire [63:0] Addr;
	wire [31:0] Instruction;
//
	wire UncondBr,BrTaken,MemToReg,ALUSrc,Reg2Loc,SetFlags,RegWrite,ALU_Interm,MemWrite,Byte,movk,movz;

	wire [8:0] DAddr9;
	wire [25:0] BrAddr26;
	wire [18:0] CondAddr19;
	wire [5:0] SHAMT;
	wire [2:0] ALUOP;
	wire [3:0] xfer_size;
	wire [11:0] ALU_Imm12;
	wire [15:0] Imm16;
	
	wire [4:0] Rd,Rn,Rm;
	wire [63:0] inputB,ALUout,MemoryOut,MemToRegister,extendedDAddr9,extendedALU_Imm12,ALUConstant,ReadData1,ReadData2;
	wire [4:0] readRegB;
	
	wire [3:0] flagALU;
	wire [3:0] flagReg;
	wire [1:0] movShamt;
	
	controlDataPath controlLogic(Instruction,UncondBr,BrTaken,MemToReg,ALUSrc,RegWrite,Reg2Loc,SetFlags,ALUOP,xfer_size,ALU_Interm,MemWrite,Rd,Rn,Rm,flagReg,flagALU,Byte,movk,movz);
	
	ProgramCounterDataPath CPUProgramCounter(UncondBr,BrTaken,Addr,CondAddr19,BrAddr26,reset,clk);
	instructmem Instruction_Memory(Addr,Instruction,clk);
	
	
	
//	
//	
//	
//	
//	
//	// Control Logic Start
//	

//	
//	
//	

	assign movShamt = Instruction[22:21];
	assign ALU_Imm12 = Instruction[21:10];
	assign DAddr9 = Instruction[20:12];
	assign BrAddr26 = Instruction[25:0];
	assign CondAddr19 = Instruction[23:5];
	assign SHAMT = Instruction[15:10];
	assign Imm16 = Instruction[20:5];
//	
//	
//	

//	
//	
//	//Control Logic End
//	
//	
//	//END PC
//	
//	
//	
//	
//	//FLAGS START

//
//	// flag 0 -> Zero Flag
//	// flag 1 -> Neg
//	// flag 2 -> Overflow
//	// flag 3 -> Carry
//	
	register ZeroFlagReg(flagALU[0], flagReg[0],SetFlags,reset,clk);
	register NegFlagReg(flagALU[1], flagReg[1],SetFlags,reset,clk);
	register OvrFlowFlagReg(flagALU[2], flagReg[2],SetFlags,reset,clk);
	register CarryFlagReg(flagALU[3], flagReg[3],SetFlags,reset,clk);
//	
//	//FLAGS END
//	
//	
//	
//	//ALU Data Path

		mux2_5 Reg2LocMux(readRegB,Rd, Rm, Reg2Loc);
		regfile registers(ReadData1,ReadData2,MemToRegister, Rn, readRegB, Rd, RegWrite, clk,reset);
		
		
		SignExtendImm9 extendDaddr9(DAddr9,extendedDAddr9);
		
		ZeroExtend12 zeroExtender(ALU_Imm12, extendedALU_Imm12);
		
		mux2_64 ADDI(ALUConstant,extendedDAddr9,extendedALU_Imm12,ALU_Interm);
		
		mux2_64 ALUSrcMux(inputB,ReadData2,ALUConstant,ALUSrc);
		
		alu_64b ALU(ReadData1,inputB,ALUOP,ALUout,flagALU[1], flagALU[0], flagALU[2], flagALU[3]);
		
		
		
		wire [63:0] Mem,movkOut,movZout,toReg,movKmuxOut,MemToRegMuxOut;
		datamem MainMemory(ALUout,MemWrite,MemToReg,ReadData2,clk,xfer_size,Mem);
		ZeroExtend8 extendByte(Mem,Byte,MemoryOut);
		
		
		movK movKControl(ReadData2,Imm16,movShamt,movkOut);
		movZ movZcontrol(Imm16,movShamt,movZout);
//		
		mux2_64 MemToRegMux(MemToRegMuxOut,ALUout,MemoryOut,MemToReg);
		mux2_64 movkMux(movKmuxOut,MemToRegMuxOut,movkOut,movk);
		mux2_64 movzMux(MemToRegister,movKmuxOut,movZout,movz);
//		
//	//ALU DATA PATH END
	
endmodule




module CPU_Testbench();
	logic reset,clk;
	SingleCycleCPU dut(clk,reset);

	parameter clk_PERIOD = 10000000;	
	initial begin	
		clk <= 0;	
		forever #(clk_PERIOD/2) clk <= ~clk;	
	end
	
	initial begin
		reset <= 1;@(posedge clk);
		reset <= 0;@(posedge clk);
		
		for(int i = 0 ; i < 1500; i++)begin
			@(posedge clk);
		end
		
		$stop;
	end

endmodule

module movK(in,Imm16,movShamt,out);
	input logic [63:0] in;
	input logic [1:0] movShamt;
	input logic [15:0] Imm16;
	logic [63:0] shiftout,mask;
	output logic [63:0] out;
	//new code
	wire [63:0] mask0,mask1,mask2,mask3;
	assign mask0 = 64'hFFFFFFFFFFFF0000;
	assign mask1 = 64'hFFFFFFFF0000FFFF;
	assign mask2 = 64'hFFFF0000FFFFFFFF;
	assign mask3 = 64'h0000FFFFFFFFFFFF;
	mux4_64 maskSel(mask,mask0,mask1,mask2,mask3,movShamt);
	
	wire [63:0] shift0,shift1,shift2,shift3;
	assign shift0 = {{48'b0},Imm16};
	assign shift1 = {{32'b0},Imm16,{16'b0}};
	assign shift2 = {{16'b0},Imm16,{32'b0}};
	assign shift3 = {Imm16,{48'b0}};
	mux4_64 shiftSel(shiftout,shift0,shift1,shift2,shift3,movShamt);
	
	assign out = ((in & mask)|shiftout);//replace with logic gates
	
//	always_comb begin
//		if(movShamt == 2'b00)begin
//			mask = 64'hFFFFFFFFFFFF0000;
//			shift = 6'b0;
//			//in[15:0] = Imm16;
//		end
//		else if (movShamt == 2'b01)begin
//			mask = 64'hFFFFFFFF0000FFFF;
//			shift =6'b10000;
//			//in[31:16] = Imm16;
//		end
//		else if(movShamt == 2'b10)begin
//			mask = 64'hFFFF0000FFFFFFFF;
//			shift =6'b100000;
//			//in[47:32] = Imm16;
//		end
//		else if(movShamt == 2'b11)begin
//			mask = 64'h0000FFFFFFFFFFFF;
//			shift = 6'b110000;
//			//in[63:48] = Imm16;
//		end
//	end
//	shifter movzSHifT({{48'b0},Imm16},1'b0,shift,shiftout);

	


endmodule

module movZ(Imm16,movShamt,out);
	input logic [1:0] movShamt;
	input logic [15:0] Imm16;
	output logic [63:0] out;
	
	wire [63:0] shift0,shift1,shift2,shift3;
	assign shift0 = {{48'b0},Imm16};
	assign shift1 = {{32'b0},Imm16,{16'b0}};
	assign shift2 = {{16'b0},Imm16,{32'b0}};
	assign shift3 = {Imm16,{48'b0}};
	mux4_64 shiftSel(out,shift0,shift1,shift2,shift3,movShamt);
	
	

//	always_comb begin
//		if(movShamt == 2'b00)begin
//			shift = 6'b0;
//		end
//		else if (movShamt == 2'b01)begin
//			shift =6'b10000;
//		end
//		else if(movShamt == 2'b10)begin
//			shift =6'b100000;
//		end
//		else if(movShamt == 2'b11)begin
//			shift = 6'b110000;
//		end
//	end
//	shifter movzSHifT({{48'b0},Imm16},1'b0,shift,out);
//	
	


endmodule


module control_Testbench();
	logic [31:0] Instruction;
	logic [3:0] flagReg,flagALU;
	logic UncondBr,BrTaken,MemToReg,ALUSrc,Reg2Loc,SetFlags,RegWrite,ALUConstant,MemWrite,Byte,movk,movz;
	logic [4:0] Rd,Rn,Rm;
	logic [2:0] ALUOP;
	logic [3:0] xfer_size;
	
	controlDataPath dut(Instruction,UncondBr,BrTaken,MemToReg,ALUSrc,RegWrite,Reg2Loc,SetFlags,ALUOP,xfer_size,ALUConstant,MemWrite,Rd,Rn,Rm,flagReg,flagALU,Byte,movk,movz);
	
	initial begin
		Instruction = 32'b1001000100_110011001100_11111_00010; flagReg = 4'hF;flagALU = 4'hF;#1000;
		Instruction = 32'b110100101_00_1101111010101101_00000; flagReg = 4'hF;flagALU = 4'hF;#1000;

		Instruction = 32'b110100101_01_1011111011101111_00000; flagReg = 4'hF;flagALU = 4'hF;#1000;
	
	end
	


endmodule 

module controlDataPath(Instruction,UncondBr,BrTaken,MemToReg,ALUSrc,RegWrite,Reg2Loc,SetFlags,ALUOP,xfer_size,ALUConstant,MemWrite,Rd,Rn,Rm,flagReg,flagALU,Byte,movk,movz);
	input logic [31:0] Instruction;
	input logic [3:0] flagReg,flagALU;
	output logic UncondBr,BrTaken,MemToReg,ALUSrc,RegWrite,Reg2Loc,SetFlags,ALUConstant,MemWrite,Byte,movk,movz;
	output logic [4:0] Rd,Rn,Rm;
	output logic [2:0] ALUOP;
	output logic [3:0] xfer_size;
	
	


	
	wire [5:0] BType;
	wire [7:0]CBType;
	wire [10:0]RType;
	wire [9:0]IType;
	wire [8:0]MovType;
	
	

	

	
	assign BType = Instruction[31:26];
	assign CBType = Instruction[31:24];
	assign RType = Instruction[31:21];
	assign IType = Instruction[31:22];
	assign MovType = Instruction[31:23];
	
	
	always_comb begin
		
		if(MovType == 9'b111100101)begin //MOVK
			UncondBr = 1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b000;
			xfer_size  = 4'b0;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b1;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
			 
			 
		end
		
		if(MovType == 9'b110100101)begin //MOVZ
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b000;
			xfer_size  = 4'b0;
			ALUConstant = 1'b1;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b1;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
			 
			 
		end
	
		
		if(BType == 6'b000101)begin //B
			UncondBr =1'b1;
			BrTaken =  1'b1;
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b0;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP =  3'b0;
			xfer_size  = 4'b0;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
		end
		
		if(RType == 11'b11101011000)begin //SUBS
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b1;
			SetFlags = 1'b1;
			ALUOP  = 3'b011;
			xfer_size  = 4'b0;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;
		
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
			
		
		end
		
		if(RType == 11'b10101011000)begin //ADDS
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b1;
			SetFlags = 1'b1;
			ALUOP  = 3'b010;
			xfer_size  = 4'b0;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
		end
		
		if(IType == 10'b1001000100)begin //ADDI
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b1;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b1;
			SetFlags = 1'b0;
			ALUOP  = 3'b010;
			xfer_size  = 4'b0;
			ALUConstant = 1'b1;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
			 
			 
		end
		
		if(RType == 11'b11111000010)begin //LDUR
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b1;
			ALUSrc = 1'b1;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b010;
			xfer_size  = 4'd8;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
		end
		
		if(RType == 11'b00111000010)begin //LDURB
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b1;
			ALUSrc = 1'b1;
			RegWrite = 1'b1;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b010;
			xfer_size  = 4'd1;
			ALUConstant = 1'b0;
			Byte = 1'b1;
			
						
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
		end
		
		
		if(RType == 11'b11111000000)begin //STUR
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b1;
			RegWrite = 1'b0;
			MemWrite = 1'b1;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b010;
			xfer_size  = 4'd8;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;
			 
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
		end
		
		if(RType == 11'b00111000000)begin //STURB
			UncondBr =1'b0;
			BrTaken =  1'b0;
			MemToReg = 1'b0;
			ALUSrc = 1'b1;
			RegWrite = 1'b0;
			MemWrite = 1'b1;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b010;
			xfer_size  = 4'd1;
			ALUConstant = 1'b0;
			Byte = 1'b1;
			
						
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
		end
		
		if((CBType == 8'b01010100) & (Instruction[4:0] == 5'b01011))begin //B.LT
			
			
			
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b0;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b0;
			xfer_size  = 4'b0;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;
			
			Rd = Instruction[4:0];
			Rn = Instruction[9:5];
			Rm = Instruction[20:16];
			
			
			if(flagReg[1] != flagReg[2])begin //if neg != overflow
				UncondBr =1'b0;
				BrTaken =  1'b1;
			end
			else begin
				UncondBr =1'b0;
				BrTaken =  1'b0;
			
			end
		
		
		end
		
		
		
		if((CBType == 8'b10110100))begin //CBZ
			
			Rd = Instruction[4:0];
			Rn = 5'b11111;
			Rm = 5'b11111;
			
			
			
			MemToReg = 1'b0;
			ALUSrc = 1'b0;
			RegWrite = 1'b0;
			MemWrite = 1'b0;
			Reg2Loc = 1'b0;
			SetFlags = 1'b0;
			ALUOP  = 3'b011;
			xfer_size  = 4'b0;
			ALUConstant = 1'b0;
			Byte = 1'b0;
			
						
			movk = 1'b0;
			movz = 1'b0;

			
			
			if(flagALU[0])begin //if zero flag == 0
				UncondBr =1'b0;
				BrTaken =  1'b1;
			end
			else begin
				UncondBr =1'b0;
				BrTaken =  1'b0;
			
			end
		
		
		end
		
		
	
	end

endmodule 



module ProgramCounter(nextAddr,Addr,reset,clk);
	input logic[63:0]nextAddr;
	input logic clk,reset;
	output logic[63:0]Addr;
	
	Register64b PCReg(nextAddr,Addr,1'b1,reset,clk);
	
endmodule

module ProgramCounterDataPath(UncondBr,BrTaken,Addr,CondAddr19,BrAddr26,reset,clk);
	input logic UncondBr,BrTaken,reset,clk;
	input logic [18:0] CondAddr19;
	input logic [25:0] BrAddr26;
	output logic [63:0] Addr;
	wire [63:0] CondAddr_ex,BrAddr26_ex,BranchAddr;
	SignExtendImm19 extend19(CondAddr19,CondAddr_ex);
	SignExtendImm26 extend26(BrAddr26,BrAddr26_ex);


	
	wire [63:0] Instruction,nextAddr,PCinc4,PCincBr;
	wire [63:0] PC_Uncond;
	mux2_64 UncondBrMux(PC_Uncond, CondAddr_ex, BrAddr26_ex, UncondBr);
	//shifter UncondBrShifter(PC_Uncond,1'b0,6'd2,BranchAddr);
	assign BranchAddr = {{PC_Uncond[61:0]},2'b0};
	
	wire c1,c2;
	adder_64b PCINC(Addr,64'd4,PCinc4,c1);
	
	
	adder_64b UncondBrINC(Addr,BranchAddr,PCincBr,c2);
	
	
	mux2_64 BrTakenMux(nextAddr,PCinc4, PCincBr, BrTaken);
	
	ProgramCounter PC(nextAddr,Addr,reset,clk);


endmodule

module PC_Testbench();
	logic UncondBr,BrTaken,clk,reset;
	logic [18:0] CondAddr19;
	logic [25:0] BrAddr26;
	logic [63:0] Addr;
	ProgramCounterDataPath dut(UncondBr,BrTaken,Addr,CondAddr19,BrAddr26,reset,clk);
	parameter clk_PERIOD = 100000;	
	initial begin	
		clk <= 0;	
		forever #(clk_PERIOD/2) clk <= ~clk;	
	end
	initial begin	
		UncondBr <= 1'b0;BrTaken<=1'b0;CondAddr19 <= 19'd0;reset <= 1;BrAddr26 <= 26'd0;@(posedge clk);
		UncondBr <= 1'b0;BrTaken<=1'b0;CondAddr19 <= 19'd0;reset <= 1;BrAddr26 <= 26'd0;@(posedge clk);
		UncondBr <= 1'b0;BrTaken<=1'b0;CondAddr19 <= 19'd0;reset <= 0;BrAddr26 <= 26'd0;@(posedge clk);
		UncondBr <= 1'b0;BrTaken<=1'b0;CondAddr19 <= 19'd0;reset <= 0;BrAddr26 <= 26'd0;@(posedge clk);
		UncondBr <= 1'b0;BrTaken<=1'b0;CondAddr19 <= 19'd0;reset <= 0;BrAddr26 <= 26'd0;@(posedge clk);


		$stop;
	end
	
	


endmodule




module SignExtendImm26(in,out);
	input logic [25:0] in;
	output logic [63:0] out;
	
	assign out = {{38{in[25]}},in[25:0]};

endmodule

module ZeroExtend8(in,ByteLOAD,out);
	input logic [63:0] in;
	input logic ByteLOAD;
	output logic [63:0] out;
	
	mux2_64 Byte(out,in,{{56'b0,in[7:0]}},ByteLOAD);



endmodule

module ZeroExtend12(in, out);
	input logic [11:0] in;
	output logic [63:0] out;
	
	assign out = {{52'b0,in[11:0]}};

endmodule

module SignExtendImm19(in,out);
	input logic [18:0] in;
	output logic [63:0] out;
	
	assign out = {{45{in[18]}},in[18:0]};


endmodule

module SignExtendImm9(in,out);
	input logic [8:0] in;
	output logic [63:0] out;
	
	assign out = {{55{in[8]}},in[8:0]};

endmodule





