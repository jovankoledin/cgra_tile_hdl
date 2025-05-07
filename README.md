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
