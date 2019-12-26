  logic sysClk, dispClk;

  initial begin: sysClk_drv
    sysClk = 0;
    #(5000*CLK_PERIOD/8)
    forever #(1000*CLK_PERIOD/2) sysClk = ~sysClk;
  end

  initial begin: dispClk_drv
    dispClk = 0;
    #(1000*CLK_PERIOD/2)
    forever #(1000*CLK_PERIOD/2) dispClk = ~dispClk;
  end
