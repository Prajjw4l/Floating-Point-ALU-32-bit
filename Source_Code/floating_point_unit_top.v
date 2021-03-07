//Floating Point Unit
//Performs Addition, Subtraction, Multiplication and Division
//Word Length 32
//Written by - Omkar Deshpande and Prajjwal Kumar

`include "Adder_Subtractor.v"
`include "Multiplier.v"
`include "Divider.v"

module floating_point_unit(
  clk,
  rst,
  start,
  operation,
  input_a,
  input_b,
  output_z,
  overflow,
  underflow,
  busy,
  output_done);
  
  input clk, rst, start;
  input [31:0] input_a, input_b;
  input [1:0] operation;
  
  output overflow, underflow, busy, output_done;
  output [31:0] output_z;
  
  wire [31:0] out_add, out_mult, out_div;
  
  parameter add = 2'b00, sub = 2'b01, multiply = 2'b10, divide = 2'b11;
  reg [31:0] z;
  reg [1:0] op;
  reg add_activate, sub_activate, multiply_activate, division_activate;
  
  reg busy=0,output_done;
  wire busy_add, busy_mult, busy_div, outdone_add, outdone_mult, outdone_div;
  
  assign output_z = z;
  reg rst_add, rst_mult, rst_div;
  
  adder_sub addition (clk,rst,add_activate,sub_activate,input_a,input_b, out_add, overflow, underflow, busy_add,outdone_add);
  
  multiplier multiplication (clk, rst, multiply_activate,input_a,input_b, out_mult, overflow, underflow,busy_mult, outdone_mult);
  
  divider division (clk, rst,division_activate, input_a, input_b, out_div, overflow, underflow, busy_div, outdone_div);
  initial begin
    //$monitor("%b %b %b %b %b %b %d",start, busy, output_done,addition.start,addition.busy,addition.output_done,$time);
  end
  always @ (posedge clk) begin
   // $display ("here %b %b  %b  %b  %d",start,busy, output_done, adder_sub.output_done, $time);
 
    if(rst)begin
      output_done <=0;
      busy <=0;
      add_activate <=0;
      sub_activate <=0;
      multiply_activate <= 0;
      division_activate <=0;
      
    end
      
    else if(start && !busy) begin
      output_done <= 0;
      op<=operation;
      
      //$display ("changing input");
     
      
     
      case(op) 
        
        add: begin
          add_activate <= 1;
          sub_activate <= 0;
          
          busy<=1;
         
          
        end
        
        sub: begin
          add_activate <= 1;
          sub_activate <= 1;
          
          busy<=1;
        end
        
        multiply: begin
          multiply_activate <=1;
          
          busy<=1;
        end
        
        divide: begin
          division_activate <=1;
          
          busy<=1;
        end
      endcase
      
      
    end
    else if(outdone_add && (op[1]==0)) begin
      output_done<=1;
      z<=out_add;
       add_activate <= 0;
       sub_activate <= 0;
      busy<=0;
      op <= 2'bxx;
      
     end
   
    else if(outdone_mult&& (op==2'b10)) begin
      output_done<=1;
      z<=out_mult;
       multiply_activate <=0;
      busy<=0;
      op <= 2'bxx;
     end
    else if(outdone_div&& (op==2'b11)) begin
      output_done<=1;
      z<=out_div;
      division_activate <=0;
      busy<=0;
      op <= 2'bxx;
     end
    
  
    
  end
  
 
          
  
  
  
  
 
endmodule
