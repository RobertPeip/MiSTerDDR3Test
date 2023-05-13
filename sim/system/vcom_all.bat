
vcom -93 -quiet -work  sim/tb ^
src/tb/globals.vhd

vcom -93 -quiet -work sim/mem ^
../system/src/mem/dpram.vhd ^
../system/src/mem/RamMLAB.vhd

vcom -93 -quiet -work sim/psx ^
../system/src/mem/dpram.vhd

vcom -93 -quiet -work  sim/mem ^
../../rtl/SyncFifo.vhd ^
../../rtl/SyncFifoFallThrough.vhd ^
../../rtl/SyncFifoFallThroughMLAB.vhd ^
../../rtl/SyncRam.vhd

vcom -quiet -work  sim/rs232 ^
src/rs232/rs232_receiver.vhd ^
src/rs232/rs232_transmitter.vhd ^
src/rs232/tbrs232_receiver.vhd ^
src/rs232/tbrs232_transmitter.vhd

vcom -quiet -work sim/procbus ^
src/procbus/proc_bus.vhd ^
src/procbus/testprocessor.vhd

vcom -quiet -work sim/reg_map ^
src/reg_map/reg_tb.vhd

vcom -2008 -quiet -work sim/ddr3test ^
../../rtl/toBCD.vhd ^
../../rtl/gpu_overlay.vhd ^
../../rtl/gpu_videoout.vhd ^
../../rtl/ddr3test_mister.vhd 

vcom -quiet -work sim/tb ^
src/tb/stringprocessor.vhd ^
src/tb/tb_interpreter.vhd ^
src/tb/ddrram_model.vhd ^
src/tb/framebuffer.vhd ^
src/tb/tb.vhd

