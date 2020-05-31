/* RNS to binary converter module
input: R1, R2, R3, R4, n, p
where R* are RNS residues, n and p are a positive integers and 0≤p≤n-2 from which moduli set will be generated in following way {2^n-1, 2^n+1, 2^(2n)+1, 2^(2n+p)}
output: X
where X is a binary format of converted number

compiled via iverilog -o converter converter.v
*/

module concate4(
    input a, b, c, d,
	output result
	);

	assign result = {a,b,c,d};
endmodule

module concate3(
	input a, b, c,
	output result
	);

	assign result = {a,b,c};
endmodule

module concate2(
	input a, b,
	output result
	);

	assign result = {a,b};
endmodule

module csa(
	input a, b, c,
	output ps, sc
	);

	assign sum = a + b + c;
	assign ps = sum >> 1;
	assign sc = sum - ps;
endmodule

module modulo_adder(
	input a, b, m,
	output result
	);

	assign result = (a+b)%m;
endmodule

module most_sign_bit(
	input a, length,
	output result
	);
	assign result = a >> (length-1);
endmodule

module ones(
	input number,
	output result
	);

	assign result = number;
	assign number = '1;
endmodule

module zeros(
	input number,
	output result
	);

	assign result = number;
	assign number = '0;
endmodule

module converter(
	input R1, R2, R3, R4, n, p,
	output X
	);
	wire X;
	wire m;
	assign m = 2**(4*n - 1);

//calc ~R1
	wire tR1;
	concate4 cnt1(R1, R1, R1, R1, tR1);
//calc ~R2
	wire tR2, dR2, msbR2, k2, R2_length;
	assign dR = R2 >> 1;
	assign R2_length = n + 1;
	concate4 cnt2(dR2, ~dR2, dR2, ~dR2, tR2);
	most_sign_bit msb1(R2, R2_length, msbR2);
	assign k2 = ((-2**(3*n)+2**(2*n)-2**n+1)*(1+msbR2))%m;
//calc ~R3
	wire tR3, dR3, k3, cntR3;
	assign dR3 = R3 >> 1;
	concate2 cnt3(~dR3, dR3, cntR3);
	assign tR3 = ((2**(n+1))*cntR3)%m;
	assign k3 = ((2**(n+1))*(2**(2*n)-1))%m;
//calc ~R4
	wire tR4, dR4, k4, element1, element2;
	assign element1 = 2**(n-p-2);
	zeros zrs1(element1, element1);
	assign element2 = 2**(n+2);
	ones ons1(element2, element2);
	concate3 cnt4(element1, ~R4, element2, tR4);
	assign k4 = 2**(n+2) - 1;

	assign k = k2+k3+k4;

	csa csa1(tR1, tR2, tR3, ps, sc);
	csa csa2(ps, sc, tR4, ps2, sc2);
	csa csa3(ps2, sc2, k, ps3, sc3);

	modulo_adder mod_add1(ps3, sc3, ((2**(4 * n)) - 1), X);
	assign X = X*2^(2*n+p) + R4;
endmodule



module testbench();
	reg R1, R2, R3, R4, n, p;
	wire X;
	localparam delay = 10;
	converter test_converter(.R1(R1), .R2(R2), .R3(R3), .R4(R4), .n(n), .p(p), .X(X));

	initial
		begin
		//test #1
			R1 = 1; R2 = 0; R3 = 15; R4 = 4; n = 2; p = 0;
			#delay;
			if ( X != 100)
			begin
				$display("Results: %b", X);
				$display("test failed");
			end
			else
				$display("test succeeded");

		//test #2
			// R1 = 1; R2 = 0; R3 = 15; R4 = 4; n = 2; p = 0;
			// #delay;
			// if ( X != expected)
			// begin
			// 	$display("Results: %b", X);
			// 	$display("test failed");
			// end
			// else
			// 	$display("test succeeded");
		end
endmodule