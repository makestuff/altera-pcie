set QUARTUS_INSTALL_DIR "$::env(ALTERA)/quartus"
onerror {exit -force -code 1}

# Prepare shared libraries
proc ensure_lib {lib} {
  if ![file isdirectory $lib] {
    vlib $lib
  }
}

if {![string match "*ModelSim ALTERA*" [vsim -version]]} {
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/altera_lnsim_ver
  vmap altera_lnsim_ver \$PROJ_HOME/ip/sim-libs/altera_lnsim_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/altera_mf_ver
  vmap altera_mf_ver \$PROJ_HOME/ip/sim-libs/altera_mf_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/altera_ver
  vmap altera_ver \$PROJ_HOME/ip/sim-libs/altera_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/cyclonev_hssi_ver
  vmap cyclonev_hssi_ver \$PROJ_HOME/ip/sim-libs/cyclonev_hssi_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/cyclonev_pcie_hip_ver
  vmap cyclonev_pcie_hip_ver \$PROJ_HOME/ip/sim-libs/cyclonev_pcie_hip_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/cyclonev_ver
  vmap cyclonev_ver \$PROJ_HOME/ip/sim-libs/cyclonev_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/lpm_ver
  vmap lpm_ver \$PROJ_HOME/ip/sim-libs/lpm_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/sgate_ver
  vmap sgate_ver \$PROJ_HOME/ip/sim-libs/sgate_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/stratixiv_hssi_ver
  vmap stratixiv_hssi_ver \$PROJ_HOME/ip/sim-libs/stratixiv_hssi_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/stratixiv_pcie_hip_ver
  vmap stratixiv_pcie_hip_ver \$PROJ_HOME/ip/sim-libs/stratixiv_pcie_hip_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/stratixiv_ver
  vmap stratixiv_ver \$PROJ_HOME/ip/sim-libs/stratixiv_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/stratixv_hssi_ver
  vmap stratixv_hssi_ver \$PROJ_HOME/ip/sim-libs/stratixv_hssi_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/stratixv_pcie_hip_ver
  vmap stratixv_pcie_hip_ver \$PROJ_HOME/ip/sim-libs/stratixv_pcie_hip_ver
  ensure_lib $::env(PROJ_HOME)/ip/sim-libs/stratixv_ver
  vmap stratixv_ver \$PROJ_HOME/ip/sim-libs/stratixv_ver

  # Common libs
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                     -work altera_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                              -work lpm_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                 -work sgate_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                             -work altera_mf_ver
  vlog -sv "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                         -work altera_lnsim_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiv_hssi_atoms.v"                  -work stratixiv_hssi_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiv_pcie_hip_atoms.v"              -work stratixiv_pcie_hip_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiv_atoms.v"                       -work stratixiv_ver

  # Stratix V libs
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_atoms_ncrypt.v"          -work stratixv_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.v"                        -work stratixv_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v"     -work stratixv_hssi_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.v"                   -work stratixv_hssi_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v" -work stratixv_pcie_hip_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.v"               -work stratixv_pcie_hip_ver

  # Cyclone V libs
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/cyclonev_atoms_ncrypt.v"          -work cyclonev_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/cyclonev_hmi_atoms_ncrypt.v"      -work cyclonev_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cyclonev_atoms.v"                        -work cyclonev_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/cyclonev_hssi_atoms_ncrypt.v"     -work cyclonev_hssi_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cyclonev_hssi_atoms.v"                   -work cyclonev_hssi_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/cyclonev_pcie_hip_atoms_ncrypt.v" -work cyclonev_pcie_hip_ver
  vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cyclonev_pcie_hip_atoms.v"               -work cyclonev_pcie_hip_ver
}

exit
