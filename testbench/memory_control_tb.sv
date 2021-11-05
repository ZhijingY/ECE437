/*
  Zhijing Yao
  yao192@purdue.edu

  memory_control test bench
*/

// interface
`include "system_if.vh"
`include "cache_control_if.vh"
`include "caches_if.vh"

// types
`include "cpu_types_pkg.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module memory_control_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  caches_if cif();
  caches_if cif1();
  cache_control_if ccif (cif, cif1);
  cpu_ram_if cramif();
  // test program
  test PROG (CLK, nRST);
  // DUT
`ifndef MAPPED
  memory_control DUT(CLK, nRST, ccif);
`else
  memory_control DUT(
    .\ccif.iREN (ccif.iREN),
    .\ccif.dREN (ccif.dREN),
    .\ccif.dWEN (ccif.dWEN),
    .\ccif.dstore (ccif.dstore),
    .\ccif.iaddr (ccif.iaddr),
    .\ccif.daddr (ccif.daddr),
    .\ccif.ramload (ccif.ramload),
    .\ccif.ramstate (ccif.ramstate),
    .\ccif.iwait (ccif.iwait),
    .\ccif.dwait (ccif.dwait),
    .\ccif.iload (ccif.iload),
    .\ccif.dload (ccif.dload),
    .\ccif.ramstore (ccif.ramstore),
    .\ccif.ramaddr (ccif.ramaddr),
    .\ccif.ramWEN (ccif.ramWEN),
    .\ccif.ramREN (ccif.ramREN),
    .\nRST (nRST),
    .\CLK (CLK)
  );
`endif

`ifndef MAPPED
  ram RAM (CLK, nRST, cramif);
`else
 ram RAM(
	.\CLK (CLK),
	.\nRST (nRST),
  .\cramif.ramWEN (cramif.ramWEN),
	.\cramif.ramREN (cramif.ramREN),
	.\cramif.ramstore (cramif.ramstore),
	.\cramif.ramaddr (cramif.ramaddr),
	.\cramif.ramload (cramif.ramload),
	.\cramif.ramstate (cramif.ramstate)
  );
`endif

assign cramif.ramWEN = ccif.ramWEN;
assign cramif.ramREN = ccif.ramREN;
assign cramif.ramstore = ccif.ramstore;
assign cramif.ramaddr = ccif.ramaddr;
assign ccif.ramload = cramif.ramload;
assign ccif.ramstate = cramif.ramstate;

endmodule

program test (input logic CLK, output logic nRST);
  // import word type
  import cpu_types_pkg::word_t;
  parameter PERIOD = 10;
  int test_case_num = 0;
  string test_case;

  initial 
  begin
    // *******************************************
    // Test Case 1: Power-on Reset of the DUT
    // *******************************************
    test_case_num += 1;
    test_case = "Reset dut";
    nRST = 0;
    @(posedge CLK);
    nRST = 1;
    #(PERIOD * 5)
  
    // *******************************************
    // Test Case 2: cache0 and cache1 both Read Instr from RAM
    // *******************************************
    test_case_num += 1;
    test_case = "cache0 and cache1 both Read Instr";
    reset_bus();
    #(PERIOD * 1)
    read_instr(0, 32'h00000020);
    cif.ccwrite = '0;
    read_instr(1, 32'h00000030);
    cif.ccwrite = '0;
    #(PERIOD * 6)
    cif1.iREN = '0;
    cif.iREN = '0;
    #(PERIOD * 4)

    // *******************************************
    // Test Case 3: Read data from RAM
    // *******************************************
    test_case_num += 1;
    test_case = "cache0 Read Data";
    reset_bus();
    read_data(0, 32'h00000020);
    #(PERIOD * 6)
    cif.cctrans = '1;
    cif.dREN= 0;
    #(PERIOD * 4)
    
    // *******************************************
    // Test Case 4: Read data and invoke a write back
    // *******************************************
    test_case_num += 1;
    test_case = "Cache0 Read data and invoke a write back";
    reset_bus();
    read_data(0, 32'h00000020);
    cif1.ccwrite = '1;
    cif1.dstore = 32'habababab;
    #(PERIOD * 6)
    cif1.cctrans= '1;
    #(PERIOD * 4)
    cif.cctrans = '1;
    cif.dREN= 0;
    #(PERIOD * 2)

    // *******************************************
    // Test Case 5: write data and invoke a write back
    // *******************************************
    test_case_num += 1;
    test_case = "Cache0 write data and invoke a write back";
    reset_bus();
    write_data(0, 32'habababab, 32'h00000020);
    cif1.ccwrite = '1;
    cif1.dstore = 32'habababab;
    #(PERIOD * 6)
    cif1.cctrans= '1;
    #(PERIOD * 4)
    cif.cctrans = '1;
    cif.dWEN= 0;
    #(PERIOD * 2)

    // *******************************************
    // Test Case 6: Read data and invoke a write back
    // *******************************************
    test_case_num += 1;
    test_case = "Cache1 Read data and invoke a write back";
    reset_bus();
    read_data(1, 32'h00000020);
    cif.ccwrite = '1;
    cif.dstore = 32'hbaddbadd;
    #(PERIOD * 6)
    cif.cctrans= '1;
    #(PERIOD * 4)
    cif1.cctrans = '1;
    cif1.dREN= 0;
    #(PERIOD * 2)

        // *******************************************
    // Test Case 7: write data and invoke a write back
    // *******************************************
    test_case_num += 1;
    test_case = "Cache1 write data and invoke a write back";
    reset_bus();
    write_data(1, 32'habababab, 32'h00000020);
    cif.ccwrite = '1;
    cif.dstore = 32'habababab;
    #(PERIOD * 6)
    cif.cctrans= '1;
    #(PERIOD * 4)
    cif1.cctrans = '1;
    cif1.dWEN= 0;
    #(PERIOD * 2);
/*  

    // *******************************************
    // Test Case 5: Conflicting instruction read and data read
    // *******************************************
    test_case_num += 1;
    test_case = "Conflicting instruction read and data read";
    reset_bus();
    read_instr(32'h00000020);
    read_data(32'h00000020);
    #(PERIOD * 5)

    // *******************************************
    // Test Case 6: Confliif(ccif.iREN)
        ccif.iwait = 1;cting instruction read and data write
    // *******************************************
    test_case_num += 1;sim:/memory_control_tb/DUT/ccif/iREN

    test_case = "Conflicting instruction read and data write";
    reset_bus();
    read_instr(32'h00000020);
    write_data(32'hAAAABBBB, 32'h00000020);
    #(PERIOD * 5) */

    // *******************************************
    // Test Case 7: Dump memory content
    // *******************************************sim:/memory_control_tb/DUT/ccif/dREN


  end

  task automatic dump_memory();
    string filename = "memcpu.hex";
    int memfd;

    memory_control_tb.cif.daddr = 0;
    memory_control_tb.cif.dWEN = 0;
    memory_control_tb.cif.dREN = 0;

    memfd = $fopen(filename,"w");
    if (memfd)
      $display("Starting memory dump.");
    else
      begin $display("Failed to open %s.",filename); $finish; end

    for (int unsigned i = 0; memfd && i < 16384; i++)
    begin
      int chksum = 0;
      bit [7:0][7:0] values;
      string ihex;

      memory_control_tb.cif.daddr = i << 2;
      memory_control_tb.cif.dREN = 1;
      repeat (4) @(posedge CLK);
      if (memory_control_tb.cif.dload === 0)
        continue;
      values = {8'h04,16'(i),8'h00,memory_control_tb.cif.dload};
      foreach (values[j])
        chksum += values[j];
      chksum = 16'h100 - chksum;
      ihex = $sformatf(":04%h00%h%h",16'(i),memory_control_tb.cif.dload,8'(chksum));
      $fdisplay(memfd,"%s",ihex.toupper());
    end //for
    if (memfd)
    begin
      memory_control_tb.cif.dREN = 0;
      $fdisplay(memfd,":00000001FF");
      $fclose(memfd);
      $display("Finished memory dump.");
    end
  endtask

  task reset_bus;
    cif.iaddr = '0;
    cif.iREN = '0;
    cif.dREN = '0;
    cif.dWEN = '0;
    cif.daddr = '0;
    cif.dstore = '0;
    cif.cctrans = '0;
    cif.ccwrite = '0;
    cif1.iaddr = '0;
    cif1.iREN = '0;
    cif1.dREN = '0;
    cif1.dWEN = '0;
    cif1.daddr = '0;
    cif1.dstore = '0;
    cif1.cctrans = '0;
    cif1.ccwrite = '0;
  endtask

  task read_instr;
  input logic cache_number;
  input word_t iaddr;
  begin
    if(!cache_number) begin
      cif.iaddr = iaddr;
      cif.iREN = 1;
    end
    else begin
      cif1.iaddr = iaddr;
      cif1.iREN = 1;
    end
    
  end
  endtask

  task read_data;
  input logic cache_number;
  input word_t daddr;
  begin
    if(!cache_number) begin
      cif.daddr = daddr;
      cif.dREN = 1;
      cif.dWEN = 0;
    end
    else begin
      cif1.daddr = daddr;
      cif1.dREN = 1;
      cif1.dWEN = 0;
    end
    
  end
  endtask

  task write_data;
  input logic cache_number;
  input word_t data;
  input word_t daddr;
  begin
    if(!cache_number) begin
      cif.dREN = 0;
      cif.dstore = data;
      cif.daddr = daddr;
      cif.dWEN = 1;
    end
    else begin
      cif1.dREN = 0;
      cif1.dstore = data;
      cif1.daddr = daddr;
      cif1.dWEN = 1;
    end
    
  end
  endtask

  //$finish
endprogram