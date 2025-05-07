## HDL Design of tiles for CGRAs

_Currently only verified Vector Tile_

By Jovan Koledin  

Inspired by Cheng Tan's [Vector CGRA](https://github.com/tancheng/VectorCGRA/tree/352cb9be75ee4fd7294d110ba4d0bf6f855198e6)  

### Testing with iVerilog

**Example:**
```bash
test/v_tile$ iverilog -g2012 -o out_sim v_tile_tb.sv ../../src/v_tile/v_tile.sv
test/v_tile$ vvp out_sim
```

### Design so far:  
![alt text](/draw/arch_20250406.png)

### TODO:
 * Finish and test Scalar tile modules:
    - main_mem_fu.sv
    - branch_fu.sv
    - comparator_fu.sv
    - phi_fu.sv
    - s_tile.sv
    - mem.sv
    - regfile.sv
 * Refactor all code to adhere to [BSG standards(https://docs.google.com/document/d/1xA5XUzBtz_D6aSyIBQUwFk_kSUdckrfxa2uzGjMgmCU/edit?tab=t.0#heading=h.mtsevafs4tag)
 * Make documentation super clean and helpful 
