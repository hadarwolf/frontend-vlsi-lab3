`timescale 1ns/1ns
module power_on_tb;

    // 1. Declarations and Clock
    localparam PERIOD = 10ns; 

    logic clk;
    logic resetb;
    logic power_good;
    logic enable;

    power_on dut (.*); // Connect DUT using .*

    // Clock Generator (100MHz)
    initial begin
        clk = 1'b0; // Start low
        
    end
    always #(PERIOD/2) clk = ~clk;
    // 2. Stimulus Block
    initial begin
        $display("[%t] *** Starting Power-On Sequence Testbench *** ", $realtime);

        // --- Sequence 1: Initial Reset and Successful Delay Check (PASS) ---
        resetb = 1'b0;     // Active Reset
        power_good = 1'b0; // Power not good
        #100ns;

        resetb = 1'b1; // De-assert Reset
        @(posedge clk) $display("[%t] Reset is high. Starting sequence.", $realtime);

        power_good = 1'b1; // Assert Power Good (Start 300ns timer)
        #350ns; // Wait past the 300ns mark
        
        // At 300ns + 1 clock cycle, enable should be high.
        if (enable == 1'b1) begin
            $display("[%t] PASS: Enable asserted correctly after > 300ns delay.", $realtime);
        end else begin
            $error("[%t] FAIL: Enable did not assert after 300ns delay!", $realtime);
        end
        power_good = 1'b0; // Turn off power_good
        #100ns;


        // --- Sequence 2: Short Power Good Pulse (FAIL - Early Enable Check) ---
        @(posedge clk) power_good = 1'b1; 
        #250ns; // Wait less than 300ns
        power_good = 1'b0; // De-assert power_good early
        
        // The enable should have remained 0, and the checker should have failed IF enable went high.
        $display("[%t] Test: Power_good dropped after 250ns. Enable should be 0.", $realtime);
        #50ns; // Ensure system settles


        // --- Sequence 3: Long delay test and finish ---
        @(posedge clk) power_good = 1'b1; 
        #600ns;
        
        $display("[%t] *** Testbench Complete *** ", $realtime);
        $stop;
    end

    // 3. Timing Checker using fork-join_any 
    // Checks if 'enable' rises before 300ns has elapsed.
    always @(posedge power_good) begin
        fork : enable_checker
            // Branch 1: The PASS Condition - wait for the required time to pass
            #300ns; 
            
            // Branch 2: The FAIL Condition - wait for 'enable' to rise
            begin
                @(posedge enable); 
                // If we reach here, it means 'enable' rose before the 300ns delay was over.
                $error("[%t] ERROR: Enable asserted early after power_good rise! Expected >= 300ns delay.", $realtime);
            end
        join_any // Whichever branch finishes first continues the testbench
        disable enable_checker; // Stop the other, non-finishing branch
    end
endmodule