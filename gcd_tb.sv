`timescale 1ns/1ps

module gcd_tb;

  logic        clk, resetb, ld;
  logic [7:0]  u, v;
  logic [7:0]  res;
  logic        done;
  int         i;
  logic [7:0] ref1;

  gcd dut (
    .clk(clk),
    .resetb(resetb),
    .u(u),
    .v(v),
    .ld(ld),
    .res(res),
    .done(done)
  );

  // clock
  initial begin
    clk = 0;
    // forever #5 clk = ~clk; // 100 MHz
  end
  always #5ns clk = ~clk;

  // Euclidean golden model
  function automatic [7:0] gcd_ref(input [7:0] u_in, input [7:0] v_in);
    int uu, vv, t;
    begin
    //   uu = (u_in == 0) ? 1 : u_in;
    //   vv = (v_in == 0) ? 1 : v_in;
    uu = u_in;
    vv = v_in;
      while (vv != 0) begin
        t  = vv;
        vv = uu % vv;
        uu = t;
      end
      gcd_ref = uu[7:0];
    end
  endfunction

  // Random test repeated 100 times
  initial begin
    resetb = 0;
    ld     = 0;
    u      = 0;
    v      = 0;
    #20;
    resetb = 1;

    for (i = 0; i < 100; i++) begin
      u = $urandom_range(1, 255);
      v = $urandom_range(1, 255);
      @(posedge clk); // sample on next edge
      ld = 1'b1;
      @(posedge clk);
      ld = 1'b0;

      // wait until done
      wait(done == 1);
    //   @(posedge clk);

      ref1 = gcd_ref(u, v); 

      $display("GCD(%0d,%0d) = %0d (DUT)  ref = %0d", u, v, res, ref1);

      if (res !== ref1) begin
        $error("Mismatch: GCD(%0d,%0d) -> DUT=%0d, REF=%0d", u, v, res, ref1);
      end
      #20ns;

    //   @(posedge clk);
    end

    $display("Random GCD test completed.");
    $finish;
  end

endmodule
