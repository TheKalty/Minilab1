// Copyright (c) 2020 University of Florida
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Greg Stitt
// University of Florida

// Module Name:  memory_map.sv
// Description:  This module implements a memory map for the basic loopback,
//               with the key difference being that the memory map now uses
//               the mmio_if interface instead of CCI-P. The behavior is
//               nearly identical with the exception that mmio_if does not
//               support multi-cycle reads. As a result, there is no
//               transaction ID.
//
//               Addresses still must follow all rules for CCI-P, which requires
//               even addresses for 64-bit data.
//
//               rd_addr and wr_addr are both 64-bit virtual byte addresses.
//               go starts the AFU and done signals completion.

//==========================================================================
// Parameter Description
// ADDR_WIDTH : The number of bits in the read and write addresses. This will
//              always be 64 since software provides 64-bit virtual addresses,
//              but is parameterized since the HAL abstracts away the platform.
//==========================================================================

//==========================================================================
// Interface Description (All control signals are active high)
// clk : clk
// rst : rst (asynchronous)
// mmio : the mmio_if interface (see mmio_if.vh or afu.sv for explanation)
// rd_addr : the starting read address for the DMA transfer
// wr_addr : the starting write address for the DMA transfer
// size    : the number of cachelines to transfer
// go      : starts the DMA transfer
// done    : Asserted when the DMA transfer is complete
//==========================================================================

module memory_map
  #(
    parameter int ADDR_WIDTH
    )
   (
   input 	       clk,
   input 	       rst, 
   
		       mmio_if.user mmio,
   
   // starting address for segments 0 thru 3
   output logic [ADDR_WIDTH-1:0] wr_addr_s0,
   output logic [ADDR_WIDTH-1:0] wr_addr_s1,
   output logic [ADDR_WIDTH-1:0] wr_addr_s2,
   output logic [ADDR_WIDTH-1:0] wr_addr_s3,
   output logic        go,
   input logic 	       done,
   input logic  [ADDR_WIDTH-1:0] cv_value
   );

   // =============================================================//   
   // MMIO write code
   // =============================================================//     
   always_ff @(posedge clk or posedge rst) begin 
      if (rst) begin
	 go       <= '0;
	 wr_addr_s0  <= '0;	     
	 wr_addr_s1  <= '0;	     
	 wr_addr_s2  <= '0;	     
	 wr_addr_s3  <= '0;	     
      end
      else begin
	 go <= '0;
 	 	 	 
         if (mmio.wr_en == 1'b1) begin
            case (mmio.wr_addr)
              16'h0050: go          <= mmio.wr_data[0];
	      16'h0052: wr_addr_s0  <= mmio.wr_data[$size(wr_addr_s0)-1:0];
	      16'h0054: wr_addr_s1  <= mmio.wr_data[$size(wr_addr_s1)-1:0];
	      16'h0056: wr_addr_s2  <= mmio.wr_data[$size(wr_addr_s2)-1:0];
	      16'h0058: wr_addr_s3  <= mmio.wr_data[$size(wr_addr_s3)-1:0];
            endcase
         end
      end
   end

   // ============================================================= 
   // MMIO read code
   // ============================================================= 	    
   always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
	    mmio.rd_data <= '0;
            // Here for legacy reasons might remove for optimization
	end
	else begin
           if (mmio.rd_en == 1'b1) begin
              case (mmio.rd_addr)
                 16'h005a: mmio.rd_data <= cv_value;
              endcase
           end 
	end
   end
endmodule
