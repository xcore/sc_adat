// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

// Example code for ADAT. Note that the adat_tx code can be changed to drive a port
// directly


buffered out port:32 adat_port;
in port mck;
clock mck_blk;

generateData(chanend c_data) {
    outuint(c_data, 512);  // master clock multiplier (1024, 256, or 512)
    outuint(c_data, 0);  // SMUX flag (0, 2, or 4)
    for (int i = 0; i < 1000; i++) {
        outuint(c_data, i);   // left aligned data (only 24 bits will be used)
    }
    outct(c_data, XS1_CT_END);
}
void drivePort(chanend c_port) {
    set_clock_src(mck_blk, mck);
    set_port_clock(adat_port, mck_blk);
    set_clock_fall_delay(mck_blk, 7);   // XAI2 board, set to appropriate value for board.
    start_clock(mck_blk);
    while (1) {
        adat_port <: byterev(inuint(c_port));
    }
}

int main(void) {
    chan c_data, c_port;
    par {
        generateData(c_data);
        adat_tx(c_data, c_port);
        drivePort(c_port);
    }
}
