//###########################################################################
//
//  Copyright 2011 XtremeEDA Corp.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//###########################################################################

`ifndef SVUNIT_UVM_MOCK_PKG
`define SVUNIT_UVM_MOCK_PKG

package svunit_uvm_mock_pkg;
  import uvm_pkg::*;
  import svunit_pkg::*;

  `include "uvm_macros.svh"

  `include "svunit_idle_uvm_domain.sv"
  `include "svunit_uvm_report_mock_types.svh"
  `include "svunit_uvm_report_mock.sv"
  `include "svunit_uvm_test.sv"
endpackage

`endif
