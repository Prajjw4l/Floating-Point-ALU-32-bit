module divider (clk,
                rst,
                start,
                input_a,
                input_b,
                output_z,
                
                overflow,
                underflow,
                busy,
                output_done
                
                
               );
  
  input clk, rst, start;
  input [31:0] input_a, input_b;
  
  output [31:0] output_z;
  output busy, output_done, overflow, underflow;
  
  reg [31:0] z;
  reg a_s, b_s, z_s, s=1'b1, overflow, underflow, z_quo_rec=1'b0, guard, round, sticky;
  reg [7:0] a_e, b_e, z_e;
  reg [23:0] a_m, b_m, z_m;
  reg [3:0] state = 4'bxxxx;
  reg busy = 1'b0, output_done = 1'b0, mantissa_divide;
  reg [23:0] z_quotient;
  wire [23:0] z_quo;
  wire z_quo_busy, z_quo_done;
  
  assign output_z = z;
  
  parameter get_input = 4'd0, special_cases = 4'd1, divide=4'd2, divide_quo=4'd3, give_output = 4'd4;
  
  divide_man mantissa(clk,rst,{1'b1, input_a[22:0]},{1'b1, input_b[22:0]},z_quo,mantissa_divide,z_quo_done,z_quo_busy);
  
  initial begin 
   // $monitor ("%b %b %b %b %d       %b%d", mantissa.b,mantissa.start, mantissa.busy, mantissa.output_done,mantissa.i,z_quotient, $time);
    
   // $monitor ("%b %d %b  %b %d %b   %b %d %b %d",a_s,a_e,a_m,b_s,b_e,b_m,z[31],z[30:23],z[22:0],$time);
    //$monitor("%b %b %b %b  %h %h %h %b %b %b %b %h %h %d",rst, start, busy, output_done,input_a,input_b,z,mantissa.rst, mantissa.start,mantissa.busy, mantissa.output_done,mantissa.b,mantissa.q,$time);
  end
  
  
  always @ (posedge clk) begin
    //$display("%b %b %b %b",state,start, busy,output_done);
    if(rst) begin
      busy <= 0;
      output_done <= 0;
      
      z <= 0;
      
      state <= 4'bxxxx;
    end
    
    if(start&& !busy) begin
      state <= get_input;
      busy <= 1'b1;
      output_done <= 1'b0;
      overflow <=0;
      underflow <= 0;
        
       // $display("Starting shit");
    end
    
    else begin
    
    case (state)
      
    get_input : begin
        a_s <= input_a[31];
      	a_e <= input_a[30:23];
        a_m[22:0] <=  input_a[22:0];
      a_m[23] <= 1'b1;
          
        b_s <= input_b[31];
      	b_e <= input_b[30:23];
        b_m[22:0] <= input_b[22:0];
      b_m[23] <= 1'b1;
        	
        
        busy <= 1'b1;
        output_done <= 1'b0;
        state <= special_cases;
      
      //$display("Assigning inputs %b %b",start, busy);
        end
        
    special_cases: begin
        //if a is NaN or b is NaN return NaN 
          if ((a_e == 255 && a_m[22:0] != 0) || (b_e == 255 && b_m[22:0] != 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= give_output;
		
          end
            
           //if b is zero return Inf
          else if (((b_e) == 0) && (b_m[22:0] == 0)) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 255;
            
            z[22:0] <= 0;
            state <= give_output;
          end
          
        //if b is inf return zero
        else if ((b_e==255)&&(b_m[22:0]==0)) begin
          z<=0;
          state <= give_output;
        end 
          
          //if a is zero return zero
     else if (((a_e) == 0) && (a_m[22:0] == 0)) begin
        z<=0;
       state <= give_output;
          end
      
      //if a is inf return inf
      else if ((a_e == 255) && (a_m[22:0] == 0)) begin
        z<=input_a;
        state <= give_output;
      end
         
      else begin
       // $display("Special Cases checked");
        mantissa_divide <= 1'b1;
        state <= divide;
    end
   end
      
     divide: begin
       mantissa_divide <= 1'b0;
       
       if((a_e > b_e)&&((a_e - b_e) >= 127)) begin
        
           overflow <= 1'b1;
           state <= give_output;
         //$display("overflow! %d",$time);
        
       end else if ((b_e>a_e)&&((b_e - a_e) >= 127)) begin
         underflow <= 1'b1;
         state <= give_output;
         //$display("underflow! %d",$time);
       end else begin
        
         z[30:23] <= a_e - b_e + 127;
         state <= divide_quo;
       end
       //$display("Exponent done, doing mantissa.");
       z[31] <= a_s ^ b_s;
     
       
        
         
       end
         
 
      
      divide_quo: begin
        if(z_quo_done&&(!z_quo_rec)) begin
          z_quotient <= z_quo;
          z_quo_rec <= 1'b1;
         // $display ("here1");
        end
           
        else if(z_quo_rec) begin
          if(~z_quotient[23]) begin
           // $display("here2");
            if( z[30:23] == 1) begin
              underflow <= 1;
              state <= give_output;
            end else begin
              z_quotient <= z_quotient << 1;
              z[30:23] <=  z[30:23] - 1;
            end
          end else begin 
           // $display("here3");
            z[22:0] <= z_quotient [22:0];
            state <= give_output;
            z_quo_rec <= 0;
          end
        end
        //$display("Mantissa done %b %b ",z_quo_done,z_quo_rec);
    end
      
      give_output: begin
        if(underflow )  begin
          z <= 0;
        end else if (overflow) begin
          z[31] <= a_e ^ b_e;
          z[30:23] <= 255;
          z[22:0] <= 0;
        end
        output_done <= 1;
        busy <= 0;
       // $display("here %d", $time);
        state <= 4'bxxxx;
        
        
       // $display("Output done");
      end
     
    endcase
    end
  end
endmodule

/////////////////////////////////////////////////////////////////////////////////////////  

module divide_man
  (clk,
   rst,
   input_a,
   input_b, 
   output_z,
   start,
   output_done,
   busy);
  
  input [23:0] input_a,input_b;
  input clk, rst, start;
  
  output [23:0] output_z;
  output output_done, busy;
  
  reg [23:0] b;
  reg [47:0] acc=48'b0;
  reg [23:0]  q = 24'b0;
  reg [23:0] z=24'b0;
  reg        output_done=1'b0, busy=1'b0;
  reg [5:0] i = 6'b0;
  
  assign output_z = z;
  initial begin
    //$monitor ("%b %b %b %b %d       %b%d", b,start, busy, output_done,i,z, $time);
    
    //$monitor("%b %b %b %b %b %b %b %d %d",b,z,q,rst,start,busy,output_done,i,$time);
  end
  
  always @ (posedge clk) begin
    
    if(rst) begin
      
      busy <= 0;
      output_done <= 0;
      z <= 0;
      acc <= 0;
      b <= 0;
      q <= 0;
      i <= 0;
    end
    
    else if(start ||busy) begin
    if(i==0) begin
      
      b <= input_b;
      i <= i + 1;
      busy <= 1'b1;
      acc[23:0] <= input_a;
     // $display("Work started on mantissa");
      output_done <= 1'b0;
      q <= 0;
    end 
    
    
      else if ((6'd24 >= i)) begin
       // $display("%d",i);
      i <= i+1;
      if(acc >=  b) 
        begin
       		{acc, q} <= {acc[46:0]-b,q,1'b1};
        end 
     
      else 
        begin
      	{acc, q} <= {acc[46:0],q,1'b0};
      	end
    end
      
    else begin
    //  $display ("Mantissa divivsion done");
      z <= q;
      busy <= 1'b0;
      output_done <= 1'b1;
      i <= 0;
      acc <= 0;
    end
    end
  end
  
  /*always @ (posedge start)begin
    output_done <=0;
  end*/
  
endmodule
  
  
  
  

      
      
     

     
      
          
        
  
  
  
  
  
  
                

