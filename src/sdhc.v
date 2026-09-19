// SPI SDHC Card Control

`include "clkdiv.v"

module SDHC (
	input i_clock25MHz,
	output o_CS,
	output o_DO,
	input i_DI,
	output o_SCLK
);

	// SPI Clock
	wire w_clock;
	reg r_FullSpeed = 1'b0;
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
	assign w_clock = r_FullSpeed ? i_clock25MHz : w_clock100kHz;

	// SPI Registers
	reg r_select = 1'b0;
	reg r_dataOut = 1'b0;
	reg r_dataIn = 1'b0;

	// States
	parameter c_INIT_WAIT = 4'h0;
	parameter c_INIT_DUMMY = 4'h1;
	parameter c_INIT_CMD0 = 4'h2;

	// State Registers
	reg [7:0] r_counter = 0;
	reg [3:0] r_state = c_INIT_WAIT;

	// Update
	always @(posedge w_clock)
	begin
		// Read Data In
		r_dataIn <= i_DI;
		// State Machine
		case (r_state)
			// Wait for 2.56 ms
			c_INIT_WAIT : begin
				r_counter <= r_counter + 1;
				if (r_counter == 0)
				begin
					r_state <= c_INIT_DUMMY;
				end
			end
			// Hold CS and DO high for 256 clock cycles
			c_INIT_DUMMY : begin
				r_select = 1'b1;
				r_dataOut = 1'b1;
				r_counter <= r_counter + 1;
				if (r_counter == 0)
				begin
					r_state <= c_INIT_CMD0;
				end
			end
			// Send CMD0 to initialize the SDHC card
			c_INIT_CMD0 : begin
				// TODO
			end
		endcase
	end

	// SPI Outputs
	assign o_CS = r_select;
	assign o_DO = r_dataOut;
	assign o_SCLK = w_clock;

endmodule
