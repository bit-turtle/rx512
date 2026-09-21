// SPI SDHC Card Control

`include "clkdiv.v"

module SDHC (
	input i_clock25MHz,
	output reg o_chipSelect = 1'b0,
	output reg o_dataOut = 1'b0,
	input i_dataIn,
	output o_clock,
	output reg o_initStatus = 1'b1,
	output o_cardBusy,
	output o_debug
);
	// SPI Clock
	wire w_clock;
	reg r_fullSpeed = 1'b0;
	reg r_clockEnable = 1'b0;
	// 100kHz clock for initialization
	wire w_clock100kHz;
	ClockDivider #(
		.DIVISOR(250),
		.BIT_WIDTH(8)
	) clock100kHz (
		.i_clock(i_clock),
		.o_clock(w_clock100kHz)
	);
	// Uses 25MHz only after initialization
	assign w_clock = r_fullSpeed ? i_clock25MHz : w_clock100kHz;
	// Only outputs the clock when the clock is enabled
	assign o_clock = r_clockEnable ? w_clock : 1'b0;
	assign o_debug = w_clock;

	// Command State
	parameter c_CMD_IDLE = 2'b00;
	parameter c_CMD_SEND = 2'b01;
	parameter c_CMD_WAIT = 2'b10;
	parameter c_CMD_RESP = 2'b11;
	// Response Lengths
	parameter c_RESPONSE_R1 = 7;
	parameter c_RESPONSE_R3 = 39;
	parameter c_RESPONSE_R7 = 39;
	// Command Registers
	reg [1:0] r_cmdState = c_CMD_IDLE;
	reg [47:0] r_command = 0;	// 6 byte command to send
	reg [5:0] r_responseLength = 7;	// Expected response length -1
	reg [38:0] r_response = 0;
	reg [8:0] r_counter = 0;
	// Card Busy
	assign o_cardBusy = (r_cmdState == c_CMD_IDLE) ? 1'b0 : 1'b1;

	// Init State (Only active while o_initStatus = 1'b1)
	parameter c_INIT_WAIT = 3'b000;	// Wait at least 1 ms, then DCLK
	parameter c_INIT_DCLK = 3'b001;	// Clock at least 74 times, then CMD0
	parameter c_INIT_CMD0 = 3'b010;	// Send CMD0, then CMD8
	parameter c_INIT_CMD8 = 3'b011;	// Send CMD8, if there's a response SDHC, else SDSC
	parameter c_INIT_SDSC = 3'b100;	// ACMD41 with parameter 0x00000000 to initialize SDHC, then B512
	parameter c_INIT_SDHC = 3'b101;	// ACMD41 with parameter 0x40000000 to initialize SDHC, then V1V2
	parameter c_INIT_V1V2 = 3'b110;	// Send CMD58, if byte addressed B512, else done
	parameter c_INIT_B512 = 3'b111;	// CMD16 to set block size to 512 bytes, then done
	// Init Registers
	reg [2:0] r_initState = c_INIT_WAIT;
	reg [1:0] r_initFlag = 2'b00;

	// Command Update
	always @(posedge w_clock)
	begin
		case (r_cmdState)
			c_CMD_IDLE : begin
				// Initalization
				if (o_initStatus == 1'b1) begin case (r_initState)
					c_INIT_WAIT : begin
						// Wait for 512 clock cycles
						r_counter <= r_counter + 1;
						r_initState <= (r_counter == 511) ? c_INIT_DCLK : c_INIT_WAIT;
					end
					c_INIT_DCLK : begin
						// Dummy clock for 512 clock cycles
						r_counter <= r_counter + 1;
						r_initState <= (r_counter + 1 == 0) ? c_INIT_CMD0 : c_INIT_DCLK;
						o_dataOut <= (r_counter + 1 == 0) ? 1'b0 : 1'b1;
						r_clockEnable <= (r_counter + 1) ? 1'b0 : 1'b1;
					end
					c_INIT_CMD0 : begin
						// Keeps attemping CMD0 until there is no error
						r_command <= 48'h40_00_00_00_00_95;
						r_responseLength <= c_RESPONSE_R1;
						r_initFlag <= ~r_initFlag;
						r_cmdState <= (r_initFlag) ? c_CMD_IDLE : c_CMD_SEND;
						r_initState <= (r_initFlag && r_response == 0) ? c_INIT_CMD8 : c_INIT_CMD0;
					end
					c_INIT_CMD8 : begin
						// Attempt CMD8, then SDSC if failure, otherwise SDHC
						r_command <= 48'h48_00_00_01_AA_87;
						r_responseLength <= c_RESPONSE_R7;
						r_initFlag <= ~r_initFlag;
						r_cmdState <= (r_initFlag) ? c_CMD_IDLE : c_CMD_SEND;
						r_initState <= (r_initFlag) ? (
							(r_response == 0) ? c_INIT_SDHC : c_INIT_SDSC
						) : c_INIT_CMD8;
					end
					c_INIT_SDSC : begin
						// Keeps Attempting ACMD41 until there is no error
						r_command <= (r_initFlag == 0) ? 48'h77_00_00_00_00_65 : 48'h69_00_00_00_00_e5;
						r_responseLength <= c_RESPONSE_R1;
						r_initFlag <= (r_initFlag < 2) ? r_initFlag + 1 : ( (r_response == 0) ? 3 : 0);
						r_cmdState <= (r_initFlag < 2) ? c_CMD_SEND : c_CMD_IDLE;
						r_initState <= (r_initFlag == 3) ? c_INIT_B512 : c_INIT_SDSC;
					end
					c_INIT_SDHC : begin
						// Keeps Attempting ACMD41 until there is no error
						r_command <= (r_initFlag == 0) ? 48'h77_00_00_00_00_65 : 48'h69_00_00_00_00_77;
						r_responseLength <= c_RESPONSE_R1;
						r_initFlag <= (r_initFlag < 2) ? r_initFlag + 1 : ( (r_response == 0) ? 3 : 0);
						r_cmdState <= (r_initFlag < 2) ? c_CMD_SEND : c_CMD_IDLE;
						r_initState <= (r_initFlag == 3) ? c_INIT_V1V2 : c_INIT_SDSC;
					end
					c_INIT_V1V2 : begin
						// Attempt CMD58, then B512 if byte addressed, otherwise done
						r_command <= 48'h7A_00_00_00_00_FD;
						r_responseLength <= c_RESPONSE_R3;
						r_initFlag <= ~r_initFlag;
						r_cmdState <= (r_initFlag) ? c_CMD_IDLE : c_CMD_SEND;
						r_initState <= (r_initFlag) ? (
							(r_response[37] == 0) ? c_INIT_B512 : c_INIT_WAIT
						) : c_INIT_V1V2;
						o_initStatus <= (r_initFlag && r_response[37] == 1) ? 1'b0 : 1'b1;
					end
					c_INIT_B512 : begin
						// Attempt CMD16 to set block size to 512 bytes
						r_command <= 48'h50_00_00_03_00_15;
						r_responseLength <= c_RESPONSE_R1;
						r_initFlag <= 0;
						r_cmdState <= c_CMD_SEND;
						r_initState <= c_INIT_WAIT;
						o_initStatus <= 1'b0;
					end
				endcase end
			end
			c_CMD_SEND : begin
				r_counter <= (r_counter >= 47) ? 0 : r_counter + 1;
				r_cmdState <= (r_counter >= 47) ? c_CMD_WAIT : c_CMD_SEND;
				o_dataOut <= r_command[r_counter];
				r_clockEnable <= 1'b1;
			end
			c_CMD_WAIT : begin
				// Time out after 512 clock cycles, when r_counter wraps around
				r_counter <= r_counter + 1;
				r_cmdState <= (i_dataIn == 0) ? c_CMD_RESP : ( (r_counter + 1 == 0) ? c_CMD_IDLE : c_CMD_WAIT);
				r_response <= (r_counter + 1 == 0) ? 39'hffffff : 39'h000000;	// Resets r_response and sets to 1 on timeout
				o_dataOut <= 1'b1;	// Dummy bytes
				r_clockEnable <= 1'b1;
			end
			c_CMD_RESP : begin
				// Read response length bit response
				r_counter <= (r_counter >= r_responseLength) ? 0 : r_counter + 1;
				r_cmdState <= (r_counter >= r_responseLength) ? c_CMD_IDLE : c_CMD_RESP;
				r_response[r_counter] <= i_dataIn;
				r_clockEnable <= (r_counter >= r_responseLength) ? 1'b1 : 1'b0;
			end
		endcase

	end

endmodule
