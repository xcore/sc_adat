// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

// Example code for ADAT. Note that the adat_tx code can be changed to drive a port
// directly

#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "adat_tx.h"

//#define ADAT_TX_DIRECT_PORT_OUT
#define XSIM

buffered out port:32 adat_port = XS1_PORT_1P;
in port mck = XS1_PORT_1O;
clock mck_blk = XS1_CLKBLK_2;

void generateData(chanend c_data) {
	outuint(c_data, 512);  // master clock multiplier (1024, 256, or 512)
	outuint(c_data, 0);  // SMUX flag (0, 2, or 4)
	for (int i = 0; i < 1000; i++) {
		outuint(c_data, i);   // left aligned data (only 24 bits will be used)
	}
	printstrln("Finished transmitting data");

	outct(c_data, XS1_CT_END);

}

void setupClocks() {

#ifndef XSIM
    set_clock_src(mck_blk, mck);
    set_clock_fall_delay(mck_blk, 7);   // XAI2 board, set to appropriate value for board.
#else
    configure_clock_rate(mck_blk, 100, 4); // 25 MHz clock
#endif

    set_port_clock(adat_port, mck_blk);
    start_clock(mck_blk);
}

void drivePort(chanend c_port) {
    setupClocks();
	while (1) {
		adat_port <: byterev(inuint(c_port));
	}
}

int main(void) {
	chan c_data;

#ifndef ADAT_TX_DIRECT_PORT_OUT
    chan c_port;
#endif

	par {
		generateData(c_data);
#ifdef ADAT_TX_DIRECT_PORT_OUT
		{
            setupClocks();
			adat_tx(c_data, adat_port);
		}
#else
        adat_tx(c_data, c_port);
        drivePort(c_port);
#endif
	}
	return 0;
}
