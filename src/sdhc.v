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
	input [2:0] i_command,
	input [47:0] i_frame,
	output o_busy,
	// Data packet transfer
	input [7:0] i_byte,
	output reg [7:0] o_byte,
	output reg [8:0] o_index,
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
	parameter s_IDLE = 4'h0;	// Accept new commands
	parameter s_WAIT = 4'h1;	// Wait for 512 clock cycles
	parameter s_HOLD = 4'h2;	// Hold chipSelect and dataOut high
	parameter s_CMD_SEND = 4'h3;	// Send the command
	parameter s_CMD_WAIT = 4'h4;	// Wait for the command response
	parameter s_CMD_RESP = 4'h5;	// Read the command response
	parameter s_SEND_WAIT = 4'h6;	// Wait for one byte before sending the data packet
	parameter s_SEND_TK24 = 4'h7;	// Send the data packet token for CMD24
	parameter s_SEND_DATA = 4'h8;	// Input and send the 512 byte sector
	parameter s_SEND_CRC0 = 4'h9;	// Send a blank CRC to finish up the data packet
	parameter s_SEND_RESP = 4'hA;	// Read the data response to verify everything went smoothly
	parameter s_SEND_BUSY = 4'hB;	// Wait for the SD card to finish the write
	parameter s_RECV_WAIT = 4'hC;	// Wait for as many bytes as it takes for the card to be ready
	parameter s_RECV_TK17 = 4'hD;	// Receive data packet token, should be the CMD17 token
	parameter s_RECV_DATA = 4'hE;	// Receive the data for the 512 byte sector and output it
	parameter s_RECV_CRC0 = 4'hF;	// Receive CRC for data packet, and ignore it
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
				s_HOLD
			endcase
		end
	end

endmodule
