// Top Level Module

`include "clkdiv.v"
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
	output o_LED_4
);
	
	SDHC card (
		.i_clock25MHz(i_Clk),
		.o_chipSelect(io_PMOD_1),
		.o_dataOut(io_PMOD_2),
		.i_dataIn(io_PMOD_3),
		.o_clock(io_PMOD_4),
		.o_initStatus(o_LED_1),
		.o_cardBusy(o_LED_2),
		.o_debug(o_LED_3)
	);

endmodule
