RMDIR /s /q sim
MKDIR sim

vlib sim/mem
vmap mem sim/mem

vlib sim/rs232
vmap rs232 sim/rs232

vlib sim/procbus
vmap procbus sim/procbus

vlib sim/reg_map
vmap reg_map sim/reg_map

vlib sim/ddr3test
vmap ddr3test sim/ddr3test

vlib sim/tb
vmap tb sim/tb

