// Top Level Module

`include "sdhc.v"

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
	// 7-Segment Display
	output o_Segment1_A,
	output o_Segment1_B,
	output o_Segment1_C,
	output o_Segment1_D,
	output o_Segment1_E,
	output o_Segment1_F,
	output o_Segment1_G,
	output o_Segment2_A,
	output o_Segment2_B,
	output o_Segment2_C,
	output o_Segment2_D,
	output o_Segment2_E,
	output o_Segment2_F,
	output o_Segment2_G
);

	SDHC card (
		.i_clock25MHz(i_Clk),
		.o_CS(io_PMOD_1),
		.o_DO(io_PMOD_2),
		.i_DI(io_PMOD_3),
		.o_SCLK(io_PMOD_4)
	);

endmodule
