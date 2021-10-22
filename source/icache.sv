// interfaces
`include "system_if.vh"
`include "datapath_cache_if.vh"
`include "caches_if.vh"

// cpu types
`include "cpu_types_pkg.vh"

module icache(
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  caches_if.icache cif
);
    // import types
    import cpu_types_pkg::*;
    logic ihit, cache_hit;
    icachef_t addr;
    icache_frame [15:0]icaches;
    icache_frame [15:0]next_icaches;
    
    assign addr = icachef_t'(dcif.imemaddr);
    //assign 
    always_ff @ (posedge CLK, negedge nRST) begin
        if(!nRST) begin
            icaches <= '0;
        end
        else begin
            icaches <= next_icaches;
        end 
    end
    assign ihit = (cif.iREN) ? ~cif.iwait : 0;
    //assign cache_hit = icaches[addr.idx].tag == addr.tag && icaches[addr.idx].valid;
    always_comb begin
        cache_hit = 0;
        next_icaches = icaches;
        //dcif.ihit = 0;
        cif.iREN = 0;
        cif.iaddr = 0;
        dcif.imemload= 0;
        if (ihit) begin    
            next_icaches[addr.idx].data = cif.iload;
            next_icaches[addr.idx].valid = 1;
            next_icaches[addr.idx].tag = addr.tag;
        end

        if(dcif.halt) begin
            //halted
            dcif.ihit = 0;
		    dcif.imemload = 0;
            next_icaches = 0;
        end
        else if(dcif.imemREN && !dcif.dmemREN && !dcif.dmemWEN) begin
            //dcif.ihit = (ihit || cache_hit);
            //Hit
            if (icaches[addr.idx].tag == addr.tag && icaches[addr.idx].valid) begin
                dcif.ihit = 1;
                dcif.imemload = icaches[addr.idx].data;
            end
            //miss
            else begin
                dcif.ihit = ihit;
                dcif.imemload = cif.iload;
                cif.iREN = 1;
                cif.iaddr = dcif.imemaddr;
            end
        end
        else begin
		    dcif.ihit = 0;
		    dcif.imemload = 0;
        end
    end
    
endmodule