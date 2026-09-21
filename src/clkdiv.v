module ClockDivider #(
	parameter DIVISOR = 250,
	parameter BIT_WIDTH = 8
) (
	input i_clock,
	output reg o_clock
);

	reg [BIT_WIDTH-1:0] r_counter = 0;

	// Count and toggle on 0
	always @(posedge i_clock) begin
		r_counter <= (r_counter < DIVISOR-1) ? r_counter + 1 : 0;
		o_clock <= (r_counter == 0) ? ~o_clock : o_clock;
	end

endmodule
