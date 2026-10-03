// Top Level Module

`include "clkdiv.v"
`include "spi.v"

module rx512 (
	input i_Clk,
	// PMOD SD Card Adapter
	output io_PMOD_1,
	output io_PMOD_2,
	input io_PMOD_3,
	output io_PMOD_4,
	// LEDs
	output o_LED_1,
	output o_LED_2,
	output o_LED_3,
	output o_LED_4,
	// Seven Seg
	output o_Segment1_A,
	output o_Segment2_A,
	// Switches
	input i_Switch_1,
	input i_Switch_2,
	input i_Switch_3,
	input i_Switch_4
);
	
	wire w_clock;
	ClockDivider #(
		.DIVISOR(25000000),
		.BIT_WIDTH(25)
	) clkdiv (
		.i_clock(i_Clk),
		.o_clock(w_clock)
	);

	reg [7:0] i_byte = 0;
	wire [7:0] o_byte;
	reg [1:0] i_command = 2'b10;
	wire o_busy;
	SPI spi (
		.i_clock(w_clock),
		.i_dataIn(i_Switch_1),
		.o_chipSelect(o_LED_1),
		.o_dataOut(o_LED_2),
		.o_clockSPI(o_LED_4),
		.i_command(i_command),
		.i_byte(i_byte),
		.o_byte(o_byte),
		.o_busy(o_busy)
	);
	always @(posedge w_clock) begin
		if (!o_busy) begin
			i_command <= ~i_command;
			i_byte <= o_byte;
		end
	end

	assign o_Segment1_A = ~o_busy;
	assign o_Segment2_A = ~w_clock;
	assign o_LED_3 = i_Switch_1;	

endmodule
