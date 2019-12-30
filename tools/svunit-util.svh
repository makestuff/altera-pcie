  `include "svunit_defines.svh"

  svunit_pkg::svunit_testcase svunit_ut;
  localparam string name = NAME;

  function void build();
    svunit_ut = new(name);
  endfunction

  initial begin
    build();
    run();
    $display();
    svunit_ut.report();
    $display();
    if (svunit_ut.get_error_count() > 0) begin
      $error($sformatf("\033\133\061\155\033\133\063\061\155%0d tests failed\033\133\060\073\061\060\155", svunit_ut.get_error_count()));
      $display();
    end
    $stop();
  end
