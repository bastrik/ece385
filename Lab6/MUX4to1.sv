// Parameterized 4:1 MUX

module MUX4to1 #(parameter width = 16) (input logic [width-1:0] in00, in01, in10, in11,
               		  	   	input logic [1:0] select,
                	  	   	output logic [width-1:0] out);

always_comb
begin

	case (select)
	       2'b00:
		       out = in00;
	       2'b01:
		       out = in01;
	       2'b10:
		       out = in10;
	       2'b11:
		       out = in11;
       endcase
end

endmodule
