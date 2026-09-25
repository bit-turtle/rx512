// SPI Driver

module SPI (
	// Input clock
	input i_clock,
	// SPI lines
	output reg o_chipSelect = 1'b0,
	output reg o_dataOut = 1'b0,
	input i_dataIn,
	output o_clockSPI,
	// SPI control
	input [1:0] i_command,
	output reg [7:0] o_byte = 8'h00,
	input [7:0] i_byte,
	output o_busy
);

	// Clock enable
	reg r_clockEnable = 1'b0;
	assign o_clockSPI = r_clockEnable ? i_clock : 1'b0;

	// Read on rising edge
	reg r_dataIn = 1'b0;
	always @(posedge o_clockSPI)
	begin
		r_dataIn <= i_dataIn;
	end

	// State machine
	parameter s_IDLE = 2'b00;
	parameter s_SEND = 2'b01;
	parameter s_READ = 2'b10;
	parameter s_HOLD = 2'b11;
	reg [1:0] r_state = s_IDLE;
	reg [2:0] r_counter = 0;

	// Busy
	assign o_busy = r_state != s_IDLE;

	// State and output on falling edge
	always @(negedge i_clock)
	begin
	case (r_state)
		// Waits for a new command
		s_IDLE : begin
			// Enable the clock early for reads so the data will be ready sooner
			r_clockEnable <= (i_command == s_READ) ? 1'b1 : 1'b0;
			o_chipSelect <= 1'b0;
			o_dataOut <= 1'b0;
			r_counter <= 0;
			r_state <= i_command;
		end
		// Sends one byte over SPI
		s_SEND : begin
			r_clockEnable <= 1'b1;
			o_chipSelect <= 1'b0;
			o_dataOut <= i_byte[7-r_counter];
			r_state <= (r_counter == 7) ? s_IDLE : s_SEND;
			r_counter <= r_counter + 1;
		end
		// Reads one byte
		s_READ : begin
			// Disable the clock on the last bit so there isn't a 9th clock cycle
			r_clockEnable <= (r_counter == 7) ? 1'b0 : 1'b1;
			o_chipSelect <= 1'b0;
			r_state <= (r_counter == 7) ? s_IDLE : s_READ;
			o_byte[7-r_counter] <= r_dataIn;
			r_counter <= r_counter + 1;
		end
		// Holds chipSelect and dataOut high while clocking
		s_HOLD : begin
			r_clockEnable <= 1'b1;
			o_chipSelect <= 1'b1;
			o_dataOut <= 1'b1;
			r_state <= (r_counter == 7) ? s_IDLE : s_HOLD;
			r_counter <= r_counter + 1;
		end
	endcase
end

endmodule
