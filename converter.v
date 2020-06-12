/* RNS to binary converter module
input: R1, R2, R3, R4, n, p
where R* are RNS residues, n and p are a positive integers and 0≤p≤n-2 from which moduli set will be generated in following way {2^n-1, 2^n+1, 2^(2n)+1, 2^(2n+p)}
output: X
where X is a binary format of converted number

compiled via iverilog -o converter converter.v
*/
//edit: reworked to be bit length specified ->

//8bit csa adder
module csa(
	input [0:7]a,
	input [0:7]b,
	input [0:7]c,
	output [0:7]ps,
	output [0:1]sc
	);
	wire [0:9]sum;

	assign sum = a + b + c;
	assign ps[0] = sum[2];
	assign ps[1] = sum[3];
	assign ps[2] = sum[4];
	assign ps[3] = sum[5];
	assign ps[4] = sum[6];
	assign ps[5] = sum[7];
	assign ps[6] = sum[8];
	assign ps[7] = sum[9];

	assign sc[0] = sum[0];
	assign sc[1] = sum[1];
endmodule

//8bit modulo adder with defined m
module modulo_adder(
	input [0:7]a,
	input [0:7]b,
	input [0:7]m,
	output [0:7]result
	);

	assign result = (a+b)%m;
endmodule


module converter( 
	input [0:1]R1,
	input [0:2]R2,
	input [0:4]R3,
	input [0:3]R4,
	input [0:1]n,
	input [0:1]p,
	output [0:10]X
	);
	wire [0:7]m;
	assign m = 2**(4*n) - 1;

//calc ~R1
	wire [0:7]tR1;
	assign tR1 = {R1, R1, R1, R1};

//calc ~R2
	wire [0:1]dR2;
	wire [0:7]tR2;
	wire msbR2;
	wire [0:7]k2;

	assign dR2[0] = R2[1];
	assign dR2[1] = R2[2];
	assign tR2 = {dR2, ~dR2, dR2, ~dR2};
	assign msbR2 = R2[0];
	assign k2 = (( 1 - (2**n) + (2**(2*n)) - (2**(3*n)) ) * (1 + msbR2))%m - 1;
//"-1" at the end of above line is a hack - verilog does not quite support modulo operation for negative numbers which is required in above set of numbers(always equals (-51 or -102)%255 ). What it means is that while passing "0" barrier it does not count zero as number and adds additional bit.

//calc ~R3
	wire [0:3]dR3;
	wire [0:7]cntR3;
	wire [0:7]tR3;
	wire [0:7]k3;
	assign dR3[0] = R3[1];
	assign dR3[1] = R3[2];
	assign dR3[2] = R3[3];
	assign dR3[3] = R3[4];
	assign cntR3 = {~dR3, dR3};
	assign tR3 = ((2**(n+1)) * cntR3)%m;
	assign k3 = ((2**(n+1)) * ((2**(2*n) - 1) * (1 + R3[0])))%m;

//calc ~R4
	// wire []ones; //-> length = n-p-2 = 2-0-2 = 0
	wire [0:3]zeros;
	wire [0:7]tR4;
	wire [0:7]k4;
	// assign ones = {(0){1'b0}}; //-> length = 0
	assign zeros = {(4){1'b0}};
	// assign tR4 = {ones, ~R4, zeros};
	assign tR4 = {~R4, zeros};
	assign k4 = 2**(n+2) - 1;

//calc X
	wire [0:7]ps;
	wire [0:7]ps2;
	wire [0:7]ps3;
	wire [0:1]sc;
	wire [0:1]sc2;
	wire [0:1]sc3;
	wire [0:7]k;

	assign k = k2 + k3 + k4;

	csa csa1(tR1, tR2, tR3, ps, sc);
	csa csa2(ps, sc, tR4, ps2, sc2);
	csa csa3(ps2, sc2, k, ps3, sc3);

	wire [0:7]tempX;
	modulo_adder mod_add1(ps3, sc3, ((2**(4 * n)) - 1), tempX);

	assign X = (tempX*2^(2*n+p)) + R4;
endmodule



module testbench();
	reg [0:1]R1;
	reg [0:2]R2;
	reg [0:4]R3;
	reg [0:3]R4;
	reg [0:1]n, p;
	wire [0:7]X;
	localparam delay = 10;
	converter test_converter(.R1(R1), .R2(R2), .R3(R3), .R4(R4), .n(n), .p(p), .X(X));

	initial begin //: R1 R2 R3 R4 n p
		$monitor("R1=%b R2=%b R3=%b R4=%b n=%d p=%d => X=%bb=%dd", R1, R2, R3, R4, n, p, X, X);
		R1 = 1; R2 = 0; R3 = 15; R4 = 4; n = 2; p = 0;		//100
		#delay;
		R1 = 0; R2 = 3; R3 = 10; R4 = 14; n = 2; p = 0;		//78
	end
endmodule
