// SDHC Implementation
`include "spi.v"
`include "clkdiv.v"

module SDHC (
	// Base 25MHz clock
	input i_clock25MHz,
	// SDHC SPI lines
	output o_chipSelect,
	output o_dataOut,
	input i_dataIn,
	output o_clockSDHC,
	// SDHC commands
	input i_command,
	output o_busy,
	input [7:0] i_byte,
	output reg o_address,
);

	// 100 kHz clock for SDHC card initialization, updates on negedge
	wire w_clock100kHz;
	ClockDivider initClock (
		.i_clock(i_clock25MHz),
		.o_clock(w_clock100kHz)
	);

	// SPI logic clock, should be updated on posedge to avoid glitchyness
	reg initMode = 1'b1;
	wire w_clock;
	assign w_clock = initMode ? w_clock100kHz : i_clock;
	
	// SPI interface, logic updates on negedge
	wire w_busySPI;
	reg r_commandSPI = 2'b0;
	SPI card (
		.i_clock(w_clock),
		.o_chipSelect(o_chipSelect),
		.o_dataOut(o_dataOut),
		.i_dataIn(i_dataIn),
		.o_clockSPI(o_clockSDHC)
	);

	// SDHC command states
	parameter s_IDLE = 4'h0;
	parameter s_HOLD = 4'h1;
	reg r_state = s_IDLE;
	// SDHC state machine, updates on posedge
	always @(posedge i_clock)
	begin
		// Only update when SPI is not busy
		if (w_busySPI == 1'b0) begin
			case (r_state)
				// Idle: Accept new commands
				s_IDLE : begin
				end
				// Hold
			endcase
		end
	end

endmodule
