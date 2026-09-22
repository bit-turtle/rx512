// Clock Divider

`ifndef CLKDIV
`define CLKDIV

module ClockDivider #(
	parameter DIVISOR = 250,
	parameter BIT_WIDTH = 8
) (
	input i_clock,
	output reg o_clock
);

	// Counter
	reg [BIT_WIDTH-1:0] r_counter = 0;

	// Count and toggle on 0
	always @(posedge i_clock) begin
		if (r_counter == DIVISOR-1) begin
			r_counter = 0;
			o_clock = ~o_clock;
		end
		else begin
			r_counter = r_counter + 1;
			o_clock = o_clock;
		end
	end

endmodule

`endif // CLKDIV
