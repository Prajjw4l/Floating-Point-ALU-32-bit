
`include "floating_point_unit_top.v"

module fpu_testbench();

	reg clk, rst, start;
	wire overflow, underflow, busy, output_done;
	reg [1:0] operation, state;
	reg [31:0] input_a, input_b;
	wire [31:0] output_z;
	integer input_count, input_count_max=500,wrong_output_count;
	
	

	floating_point_unit fputest (clk, rst, start, operation, input_a, input_b, output_z, overflow, underflow, busy, output_done);

	parameter new_input = 2'b00, fpu_busy = 2'b01, check_output = 2'b11;

	initial begin
		clk = 1;
		rst = 0;
		start = 0;
		state = new_input;
		input_count = 0;
		wrong_output_count = 0;
	end
		

	always begin : clock
		#2 clk = ~clk;
	end

	always @(posedge clk) begin : main_block
		
		case(state)

			new_input : begin
				input_a = getinput();
				input_b = getinput();
				operation = getop();
				start = 1;
				rst = 0;
				state = fpu_busy;
				input_count = input_count + 1;
			end

			
			fpu_busy : begin
				if(output_done)begin
					state = check_output;
				end
				#10 start = 0;
			end

			check_output : begin
				if(expected_output(input_a, input_b, operation) != output_z )begin
					$display("Input No. - %0d : FAILED ; Operation - %d ; Input A = %b ; Input B = %b ; Expected Output - %b  ; Output Recieved - %b", input_count, operation, input_a, input_b, expected_output(input_a, input_b, operation), output_z);
					wrong_output_count ++;			
				end
				
				else begin
					$display("Input No. - %0d : SUCCESS", input_count);
				end
				rst = 1;
				state = new_input;
			end
		endcase

		if(input_count == input_count_max) begin
			$display("End of Simulation. Total Inputs : %0d ; Number of Wrong/Inaccurate Outputs : %0d", input_count, wrong_output_count);
			$stop;
		end
	end
				
				


  function [31:0] getinput ();
	getinput[31] = $urandom / 2;
	getinput[30:23] = $urandom / 256;
	getinput[22:0] = $urandom;
  endfunction

  function [1:0] getop ();
	
	getop = $urandom / 4;  
  endfunction


	function [31:0] expected_output ([31:0] input_a, [31:0] input_b, [1:0]operation);
		shortreal a,b,z,expected;
		
		a = $bitstoshortreal (input_a);
		b = $bitstoshortreal (input_b);
		

		case(operation)
			
			2'b00 : begin
				expected = a+b;
			end

			2'b01 : begin
				expected = a-b;
			end

			2'b10 : begin
				expected = a*b;
			end

			2'b11 : begin
				expected = a/b;
			end

		endcase

		expected_output = $shortrealtobits (expected);

		

	endfunction

	

		

endmodule
