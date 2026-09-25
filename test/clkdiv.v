`include "clkdiv.v"

`timescale 1ns/1ns

module test;

	// Test 25MHz clock
	reg clock = 1'b0;
	always #20 clock = ~clock;

	// Clock Divider
	ClockDivider #(
		.DIVISOR(5),
		.BIT_WIDTH(3)
	) clkdiv (
		.i_clock(clock)
	);

	// Save output
	initial begin
		$dumpfile("clkdiv.vcd");
		$dumpvars(0, clkdiv);
		#10000 $finish;
	end

endmodule

