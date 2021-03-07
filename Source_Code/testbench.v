


`include "floating_point_unit_top.v"

module fputester ();
  reg clk, rst, start;
  reg [31:0] input_a, input_b;
  wire [31:0] output_z;
  reg[1:0] operation;
  wire overflow, underflow, busy, output_done;
  integer inputfile_a, inputfile_b;
  reg give_input, lola, lolb, outputer;
  reg[1:0] state;
  
 
  
  floating_point_unit fputest (clk, rst, start, operation, input_a, input_b, output_z, overflow, underflow, busy, output_done);
  
   
  
  initial begin
    clk = 1;
    rst = 0;
    start = 0;
    give_input =1;
     inputfile_a = $fopen("inputs_a.txt","r");
  inputfile_b = $fopen("inputs_b.txt","r");
    operation = 2'b11;
   
    outputer=0;
    state = 2'b01;
    
   
    
    
  end
  
  always begin
    #2 clk = ~clk;
  end
  
  always @(posedge clk) begin
    if(!$feof(inputfile_a)) begin
    case (state) 
      
      2'b00 : begin
        //$display("busy");
       //$display("busy state %d  %b %b", $time, start, busy);
        if (output_done==1) begin
          state = 2'b10;
          
        end
        //#4 start <= 0;
        #10 start = 0;
      end
      
      2'b01 : begin
       
        lola <= $fscanf(inputfile_a,"%b\n",input_a);
        lolb <= $fscanf(inputfile_b,"%b\n", input_b);
        state <= 2'b00;
         rst <=0;
         start <= 1;
       //$display("new input %d",  $time);
        //$display("new input");
      end
      
      2'b10 : begin
       // $display ("%b %d %b %b %d %b    %b %d %b %b %b %b %d ", input_a[31],input_a[30:23],input_a[22:0],input_b[31],input_b[30:23], input_b[22:0], output_z[31],output_z[30:23],output_z[22:0], output_done, fputest.division.underflow,fputest.division.overflow,$time);
        
       $display("%b",output_z);
        rst <=1;
        state <= 2'b01;
        //$display("output");
       
      end
   
      
      
      endcase
    end
      
      else begin
        $display ("Input file end reached"  );
        $finish;
      end
    end
  
 
   
  
 
  
endmodule
