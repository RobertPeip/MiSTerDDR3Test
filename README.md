# MiSTerDDR3Test
Tests DDR3 latency and throughput at different clock speeds

# Visible on screen:
- Clockrate: will measure the currently used clock using a different clock, just to verify that the clock is stable and has the correct speed
- Transfers: will count up constantly by 1 for each full transfer being finished. Mostly useful to see that the measurement is still running
- Delay Min: will show the lowest latency for a single transaction that was measured over time. Value is in clock cycles. Usually does saturate instantly to the lowest value.
- Delay Max: same for maximum measured delay. This number will increase over time when some random events occur that lead to long latency.(DDR3 is shared with HDMI-Scaler and HPS)
- Delay Avg: average delay over the last 65536 transfers. The left number is a round down integer, the right value is the exact total delay in hexadecimal and can be used to see more exact values. E.g. Avg Delay of 15 clock cycles, but more exactly it's 0xFCD13, which calculates to around 15.8 clock cycles
- Bytes / s: will display how many Bytes could be written or read in the last second. Will update once per second. Measures the real throughput without any overhead.
- Burstwait: small detail which will show how many clock cycles a burst read was interrupted in the middle of the transfer. Has the same update interval as the Delay Avg. Can be used to check if you can rely on burst reads to deliver data without pause once the first data word is received. Result: you cannot.

# OSD Options
- Direction: test reading or writing performance
- Address Mode: You can either let the test read/write to static address, so always the same address is written or read, let the address count up or down or have it totally random in a 4 Mbyte area.
- Clock Mhz: change between 62.5, 85, 100 or 125 MHz at runtime
- Burst: only applies for reads. Change the amount of 64bit words that are read in a single transfer, sizes from 1,2,4,8...to 128

When you open up the OSD the test will pause and all measurements are reset, meaning you can reset the Delay Min/Max by opening and closing the OSD.
