`include "spi.v"

`timescale 1ns/1ns

module test;

	// Test 25MHz clock
	reg clock = 1'b0;
	always #20 clock = ~clock;

	// SPI
	reg [1:0] command = 0;
	reg [7:0] data = 8'hCA;
	reg [2:0] counter = 0;
	reg [7:0] byte = 8'hCA;
	wire spiclk;
	reg di;
	SPI spi (
		.i_clock(clock),
		.i_command(command),
		.i_byte(data),
		.i_dataIn(di),
		.o_clockSPI(spiclk)
	);
	always @(negedge spiclk) begin
		counter <= counter + 1;
		di <= byte[7-counter];
	end

	// Save output
	initial begin
		$dumpfile("spi.vcd");
		$dumpvars(0, spi);

		#10 command = spi.s_SEND;
		#410 command = spi.s_IDLE;
		#800 command = spi.s_READ;
		#2000 command = spi.s_HOLD;

		#10000 $finish;
	end

endmodule

