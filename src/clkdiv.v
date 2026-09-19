module ClockDivider #(
	parameter DIVISOR = 250,
	parameter BIT_WIDTH = 8
) (
	input i_clock,
	output o_clock
);

	reg [BIT_WIDTH-1:0] r_counter = 0;
	reg r_clock = 1'b0;

	always @(posedge i_clock) begin
		if (r_counter < DIVISOR-1) begin
			r_counter <= r_counter + 1;
		end
		else begin
			r_counter <= 0;
			r_clock <= ~r_clock;
		end
	end

	assign o_clock = r_clock;

endmodule
