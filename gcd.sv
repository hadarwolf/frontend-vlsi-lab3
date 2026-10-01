module gcd(
    input logic clk,
    input logic resetb,
    input logic [7:0] u,
    input logic [7:0] v,
    input logic ld, // Load signal (1-cycle pulse)
    output logic [7:0] res,
    output logic done
);

    // --- Data Path Registers ---
    logic [7:0] u_reg, v_reg; 
    logic [3:0] n_reg;      // <--- NOW DECOUPLED
    
    // Output Registers to hold the final, stable result
    logic [7:0] res_final_reg;
    logic done_reg; 
    
    // --- Control Signals (DCL Flags) ---
    logic load_active; 	 
    logic calc_active; 	 
    logic done_active; 	 
    
    // --- Derived Signals for Calculation ---
    logic [7:0] u_nxt, v_nxt;
    logic u_even, v_even;
    logic is_both_even;
    
    // Assign signals based on the internal registers (u_reg, v_reg)
    assign u_even = ~u_reg[0]; 
    assign v_even = ~v_reg[0]; 
    assign is_both_even = u_even && v_even;

    // --- Final Output Assignments (combinational from output registers) ---
    assign res = res_final_reg;
    assign done = done_active; 


    // ************************************************************
    // 1. Control Logic (Sequential - Always_ff) - Controls Load, Run, Stop
    // ************************************************************
    always_ff @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            load_active   <= 1'b0;
            calc_active   <= 1'b0;
            done_active   <= 1'b0;
        end else begin
            
            load_active <= ld; 
            
            // 1b. done_active: Set when u_reg == v_reg, cleared only by a new load
            if (u_reg == v_reg && calc_active) begin
                done_active <= 1'b1; // Calculation completed
            end else if (ld) begin
                done_active <= 1'b0; // New load clears the done flag
            end

            // 1c. calc_active: Starts after load, stops when done is set
            if (load_active) begin
                calc_active <= 1'b1; 
            end else if (done_active) begin
                calc_active <= 1'b0; 
            end
        end
    end


    // ************************************************************
    // 2A. DATA PATH REGISTERS (Sequential - Always_ff) - U, V, and Output
    // ************************************************************
    always_ff @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            u_reg           <= 8'd0;
            v_reg           <= 8'd0;
            res_final_reg   <= 8'd0;
            done_reg        <= 1'b0; 
        end else begin
            if (load_active) begin // Load inputs (Cycle 1)
                u_reg           <= u;
                v_reg           <= v;
                done_reg        <= 1'b0; 
            end else if (calc_active) begin // Loop is running 
                u_reg <= u_nxt;
                v_reg <= v_nxt;
            end else if (done_active) begin // Finalization
                // <--- This block now only updates output registers
                res_final_reg <= u_reg << n_reg;
                done_reg      <= 1'b1; 
            end
        end
    end

    // ************************************************************
    // 2B. N_REG COUNTER (NEW DEDICATED BLOCK) <--- FIX HERE
    // This runs completely independent of the U/V register updates.
    // ************************************************************
    always_ff @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            n_reg <= 4'd0;
        end else if (load_active) begin
            // Clear counter on load
            n_reg <= 4'd0;
        end else if (calc_active && is_both_even) begin
            // Increment only when loop is running AND both numbers are even
            n_reg <= n_reg + 1;
        end else begin
            // Hold value otherwise
            n_reg <= n_reg;
        end
    end


    // ************************************************************
    // 3. Next Value Calculation (Data Path Logic - Always_comb)
    // ************************************************************
    always_comb begin
        // Default: Hold the current values
        u_nxt = u_reg;
        v_nxt = v_reg;
        
        // This is the combinatorial logic that dictates the update path
        if (is_both_even) begin         // Case a: both even
            u_nxt = u_reg >> 1;
            v_nxt = v_reg >> 1;
        end else if (u_even) begin         // Case b: only u is even
            u_nxt = u_reg >> 1;
        end else if (v_even) begin         // Case b: only v is even
            v_nxt = v_reg >> 1;
        end else if (u_reg > v_reg) begin // Case c: both odd, u > v
            u_nxt = u_reg - v_reg;
        end else if (v_reg > u_reg) begin // Case c: both odd, v > u
            v_nxt = v_reg - u_reg; 
        end
    end

endmodule

// module gcd(
//     input logic clk,
//     input logic resetb,
//     input logic [7:0] u,
//     input logic [7:0] v,
//     input logic ld, // Load signal (1-cycle pulse)
//     output logic [7:0] res,
//     output logic done
// );

//     // --- Data Path Registers ---
//     logic [7:0] u_reg, v_reg; // Internal working copies (u_curr, v_curr in your notation)
//     logic [3:0] n_reg;      // Counts factor of 2 (counter_even in your notation)
    
//     // Output Registers to hold the final, stable result
//     logic [7:0] res_final_reg;
//     logic done_reg; // Sequential signal to hold the 'done' state
    
//     // --- Control Signals (Replaces the FSM states) ---
//     // load_active is needed to gate the calc_active start
//     logic load_active;     
//     logic calc_active;     
//     logic done_active;     
    
//     // --- Derived Signals for Calculation ---
//     logic [7:0] u_nxt, v_nxt; // Calculated next values (u_next, v_next in your notation)
//     logic u_even, v_even;
//     logic is_both_even;
    
//     // Assign signals based on the internal registers (u_reg, v_reg)
//     assign u_even = (u_reg[0] == 1'b0);
//     assign v_even = (v_reg[0] == 1'b0);
//     assign is_both_even = u_even && v_even;

//     // --- Final Output Assignments (combinational from output registers) ---
//     assign res = res_final_reg;
//     assign done = done_active; // Output is driven by the sequential register


//     // ************************************************************
//     // 1. Control Logic (Sequential - Always_ff)
//     // Manages the sequential flow using control flags (busy_curr/next equivalent)
//     // ************************************************************
//     always_ff @(posedge clk or negedge resetb) begin
//         if (!resetb) begin
//             load_active   <= 1'b0;
//             calc_active   <= 1'b0;
//             done_active   <= 1'b0;
//         end else begin
//             // 1a. load_active: Active for one cycle after 'ld' to capture inputs
//             // We use the input ld directly, and it will be active for one cycle only.
//             load_active <= ld; 
            
//             // 1b. done_active: Set when u_reg == v_reg, cleared only by a new load
//             if (u_reg == v_reg && calc_active) begin
//                 done_active <= 1'b1; // Calculation completed
//             end else if (ld) begin
//                 done_active <= 1'b0; // New load clears the done flag
//             end

//             // 1c. calc_active: Starts after load, stops when done is set
//             if (load_active) begin
//                 calc_active <= 1'b1; // Start calculation on the cycle AFTER load
//             end else if (done_active) begin
//                 calc_active <= 1'b0; // Stop calculation when done
//             end
//         end
//     end


//     // ************************************************************
//     // 2. Data Path Registers (Sequential - Always_ff)
//     // Updates only when loading, when calculation is running, or when done
//     // ************************************************************
//     always_ff @(posedge clk or negedge resetb) begin
//         if (!resetb) begin
//             u_reg           <= 8'd0;
//             v_reg           <= 8'd0;
//             n_reg           <= 4'd0;
//             res_final_reg   <= 8'd0;
//             done_reg        <= 1'b0; 
//         // Initialize done flag register
//         // end else begin
//         //     if (load_active) begin // Load inputs (Cycle 1)
//         //         // Capture inputs and reset counter 'n'
//         //         u_reg           <= u;
//         //         v_reg           <= v;
//         //         n_reg           <= 4'd0;
//         //         done_reg        <= 1'b0; // Clear done on load
//         //     end else if (calc_active) begin // Loop is running (Cycle 2, 3, 4, ...)
//         //         // Update registers with next calculated value
//         //         u_reg <= u_nxt;
//         //         v_reg <= v_nxt;
                
//         //         // Only increment 'n' (shift counter) in Case (a)
//         //         if (is_both_even) 
//         //             n_reg <= n_reg + 1;
//         //         else
//         //             n_reg <= n_reg; 
//         //     end else if (done_active) begin // Calculation is finished (Final Cycle)
//         //         // Calculation is finished: calculate and hold the final result
//         //         res_final_reg <= u_reg << n_reg;
//         //         done_reg      <= 1'b1; // Assert done (this is the final result cycle)
//         //     end
//         // end
//     end

//     // ************************************************************
//     // 3. Next Value Calculation (Data Path Logic - Always_comb)
//     // Implements the GCD rules based on current u_reg, v_reg
//     // ************************************************************
//     always_comb begin
//         // Default: hold the current values
//         u_nxt = u_reg;
//         v_nxt = v_reg;
        
//         // This is the combinatorial logic that dictates the update path
//         if (is_both_even) begin         // Case a: both even
//             u_nxt = u_reg >> 1;
//             v_nxt = v_reg >> 1;
//         end else if (u_even) begin         // Case b: only u is even
//             u_nxt = u_reg >> 1;
//         end else if (v_even) begin         // Case b: only v is even
//             v_nxt = v_reg >> 1;
//         end else if (u_reg > v_reg) begin // Case c: both odd, u > v
//             u_nxt = u_reg - v_reg;
//         end else if (v_reg > u_reg) begin // Case c: both odd, v > u
//             // u_nxt = u_reg;
//             v_nxt = v_reg - u_reg;
//         end
//         // If u_reg == v_reg, u_nxt and v_nxt hold the same values (u_reg, v_reg).
//     end

// endmodule

// // module gcd (
// //   input  logic        clk,
// //   input  logic        resetb,
// //   input  logic [7:0]  u,
// //   input  logic [7:0]  v,
// //   input  logic        ld,    // load pulse
// //   output logic [7:0]  res,
// //   output logic        done
// // );
// //   logic [7:0] u_reg, v_reg;
// //   logic [3:0] k;       // enough up to factor 2^15 for 8-bit numbers

// //   always_ff @(posedge clk or negedge resetb) begin
// //     if (!resetb) begin
// //       u_reg <= 8'd0;
// //       v_reg <= 8'd0;
// //       k     <= 4'd0;
// //       res   <= 8'd0;
// //       done  <= 1'b0;
// //     end else begin
// //       if (ld) begin
// //         // load new values, clear state
// //         u_reg <= (u == 0) ? 8'd1 : u; // avoid 0 edge cases; lab says >0
// //         v_reg <= (v == 0) ? 8'd1 : v;
// //         k     <= 4'd0;
// //         res   <= 8'd0;
// //         done  <= 1'b0;
// //       end else if (!done) begin
// //         if (u_reg == v_reg) begin
// //           // finished: res = u * 2^k
// //           res  <= u_reg << k;
// //           done <= 1'b1;
// //         end else begin
// //           // both even
// //           if (!u_reg[0] && !v_reg[0]) begin
// //             u_reg <= u_reg >> 1;
// //             v_reg <= v_reg >> 1;
// //             k     <= k + 4'd1;
// //                   end
// //           // only u even
// //           else if (!u_reg[0] && v_reg[0]) begin
// //             u_reg <= u_reg >> 1;
// //           end
// //           // only v even
// //           else if (u_reg[0] && !v_reg[0]) begin
// //             v_reg <= v_reg >> 1;
// //           end
// //           // both odd
// //           else begin
// //             if (u_reg > v_reg)
// //               u_reg <= u_reg - v_reg;
// //             else
// //               v_reg <= v_reg - u_reg;
// //           end
// //         end
// //       end
// //       // if done==1, keep res & done until next ld
// //     end
// //   end

// // endmodule
