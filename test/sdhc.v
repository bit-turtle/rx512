`include "sdhc.v"

`timescale 1ns/1ns

module test;

	// Test 25MHz clock
	reg clock = 1'b0;
	always #20 clock = ~clock;

	// SDHC card
	reg r_dataIn = 1'b0;
	SDHC card (
		.i_clock25MHz(clock),
		.i_dataIn(r_dataIn)
	);

	// Save output
	initial begin
		$dumpfile("sdhc.vcd");
		$dumpvars(0, card);
		#100000000 $finish;
	end

endmodule

