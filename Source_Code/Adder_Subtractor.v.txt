module adder_sub(
  clk,
  rst,
  start, 
  subtract,
  input_a,
  input_b,
  output_z,
  overflow,
  underflow,
  busy,
  output_done
   );
  
  input     subtract, start;
  input     clk;
  input     rst;
  input     [31:0] input_a;
  input     [31:0] input_b;
  
  output    [31:0] output_z;
  output    busy, output_done, overflow, underflow; 		//To Show the current state of the adder
  
  assign output_z = z;
  
  reg overflow, underflow;
  reg       [3:0] state;     		 //Stages/States/Steps involved in addition
  parameter get_input     = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            align         = 4'd4,
            add_0         = 4'd5,
            add_1         = 4'd6,
            normalise_1   = 4'd7,
            normalise_2   = 4'd8,
            round         = 4'd9,
            pack          = 4'd10,
  			done		  = 4'd11;		
            
  reg       [31:0] a, b, z;
  reg       [26:0] a_m, b_m;  	//mantissa + Round + Guard + Sticky Bit
  reg       [23:0] z_m;      	//Output mantissa
  reg       [7:0] a_e, b_e, z_e;	//Exponents
  reg       a_s, b_s, z_s, busy = 0, output_done =0;			//Signs
  reg       guard, round_bit, sticky;	
  reg       [27:0] sum;				//raw sum of mantissas
  
  
  
  always @(posedge clk)
  begin
    
    if(start && ~busy) begin
      state <= get_input;
      busy<= 1;
      output_done <= 0;
    end

    case(state)
		
      
	  get_input:
        begin
         
          a<=input_a;
          b<=input_b;
          state<=unpack;
          
        end
      
      unpack:					//Unpacking the input and putting E,F,S in their reg
      begin
        
        a_m <= {1'b1, a[22 : 0], 3'd0};
        b_m <= {1'b1, b[22 : 0], 3'd0};
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        
        if(subtract)
          b_s <= ~b[31];
        else
          b_s <= b[31];
       
           
        
        state <= special_cases;
        
      end

      special_cases:
      begin
        //if a is NaN or b is NaN return NaN 
        
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= done;
        //if a is inf return inf
        end else if (a_e == 128) begin
          z[31] <= a_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          //if a is inf and signs don't match return nan
          if ((b_e == 128) && (a_s != b_s)) begin
              z[31] <= b_s;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
          end
          state <= done;
        //if b is inf return inf
        end else if (b_e == 128) begin
          z[31] <= b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          state <= done;
        //if a is zero return b
        end else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin
          z[31] <= a_s & b_s;
          z[30:23] <= b_e[7:0] + 127;
          z[22:0] <= b_m[26:3];
          state <= done;
        //if a is zero return b
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= b_s;
          z[30:23] <= b_e[7:0] + 127;
          z[22:0] <= b_m[26:3];
          state <= done;
        //if b is zero return a
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s;
          z[30:23] <= a_e[7:0] + 127;
          z[22:0] <= a_m[26:3];
          state <= done;
        end else begin
         
          state <= align;
        end
      end

      align:			//Adjusting Exponents to be same
      begin
        if ($signed(a_e) > $signed(b_e)) begin
          b_e <= b_e + 1;
          b_m <= b_m >> 1;
          b_m[0] <= b_m[0] | b_m[1];
        end else if ($signed(a_e) < $signed(b_e)) begin
          a_e <= a_e + 1;
          a_m <= a_m >> 1;
          a_m[0] <= a_m[0] | a_m[1];
        end else begin
          
          state <= add_0;				//This case (state) keeps running until any of above if statement is true. Thus this acts like a while loop.
        end
      end

      add_0:
      begin
        z_e <= a_e;
        if (a_s == b_s) begin
          sum <= a_m + b_m;
          z_s <= a_s;
        end else begin
          if (a_m >= b_m) begin
            sum <= a_m - b_m;
            z_s <= a_s;
          end else begin
            sum <= b_m - a_m;
            z_s <= b_s;
          end
        end
        
        state <= add_1;
      end

      add_1:
      begin
       
        if (sum[27]) begin
          z_m <= sum[27:4];
          guard <= sum[3];
          round_bit <= sum[2];
          sticky <= sum[1] | sum[0];
          z_e <= z_e + 1;
        end else begin
          z_m <= sum[26:3];
          guard <= sum[2];
          round_bit <= sum[1];
          sticky <= sum[0];
        end
         
        state <= normalise_1;
         
      end

      normalise_1:
      begin
        if (z_m[23] == 0 && $signed(z_e) > -126) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end        
        state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) begin
          z[31] <= 1'b0; // FIX SIGN BUG: -a + a = +0.
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        
        state <= done;
      end
      
      done:							
        begin
          busy <= 0;
          output_done <= 1;
          
         
        end
      

    endcase

    if (rst == 1) begin						//rst =Reset
      state<=4'bxxxx;
      a<=0;
      b<=0;
      z<=0;
      output_done <= 0;
      busy <=0;
      
      
      
    
      
  
    end

  end
 
 

endmodule


	
