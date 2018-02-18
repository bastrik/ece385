// Parameterized 2:1 MUX

module MUX2to1 #(parameter width = 16) (input logic [width-1:0] in0, in1,
               		  	   	input logic select,
                	  	   	output logic [width-1:0] out);

always_comb
begin

	case (select)
	       1'b0:
		       out = in0;
	       1'b1:
		       out = in1;
       endcase
end

endmodule
