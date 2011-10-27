// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

// Example code for ADAT. Note that the adat_tx code can be changed to drive a port
// directly

#include <xs1.h>
#include <xclib.h>
#include "adat_tx.h"
#include "adat_rx.h"
#include "stdio.h"

#define XSIM
#define TRACE
#define GEN_DATA_SIZE 32

buffered in port:32 p_adat_rx = XS1_PORT_1N;
buffered out port:32 p_adat_tx = XS1_PORT_1P;
#ifndef XSIM
in port mck = XS1_PORT_1O;
#else
out port mck = XS1_PORT_1O;
#endif

//debug trace port (useful in simulator waveform)
out port trace_data = XS1_PORT_32A;

clock mck_blk = XS1_CLKBLK_2;
clock clk_adat_rx = XS1_CLKBLK_1;

void adatReceiver48000(buffered in port:32 p, chanend oChan);

void receiveAdat(chanend c) {
    set_thread_fast_mode_on();
    set_port_clock(p_adat_rx, clk_adat_rx);
	//configure_clock_rate(clk_adat_rx, 100, 4); // 25MHz clock
    start_clock(clk_adat_rx);
    clearbuf(p_adat_rx);
    while(1) {
        adatReceiver48000(p_adat_rx, c);
        adatReceiver44100(p_adat_rx, c);   // delete this line if only 48000 required.
    }
}

void collectSamples(chanend c) {
    while(1) {
        unsigned head, channels[8];
        head = inuint(c);//bug: c :> head;                     // This will be a header nibble in bits 7..4 and 0001 in the bottom 4 bits
        trace_data <: head;
        for(int i = 0; i < 8; i++) {
            channels[i] = inuint(c); //c :> channels[i];          // This will be 24 bits data in each word, shifted up 4 bits.
#ifdef TRACE
            trace_data <: channels[i];
#endif

        }
    }
}

void generateData(chanend c_data) {
	outuint(c_data, 512);  // master clock multiplier (1024, 256, or 512)
	outuint(c_data, 0);  // SMUX flag (0, 2, or 4)
	for (int i = 0; i < GEN_DATA_SIZE; i++) {
		outuint(c_data, i);   // left aligned data (only 24 bits will be used)
	}

    printf("Finished sending %d words", GEN_DATA_SIZE);

	outct(c_data, XS1_CT_END);

}
void drivePort(chanend c_port) {
	set_clock_src(mck_blk, mck);
	set_port_clock(p_adat_tx, mck_blk);
	set_clock_fall_delay(mck_blk, 7);   // XAI2 board, set to appropriate value for board.
	start_clock(mck_blk);
	while (1) {
		p_adat_tx <: byterev(inuint(c_port));
	}
}

void setupClocks() {

#ifndef XSIM
	set_clock_src(mck_blk, mck);
	set_clock_fall_delay(mck_blk, 7);   // XAI2 board, set to appropriate value for board.
#else
	configure_clock_rate(mck_blk, 100, 4); // 25MHz clock
	configure_port_clock_output(mck, mck_blk);
#endif
	set_port_clock(p_adat_tx, mck_blk);
	start_clock(mck_blk);
}

int main(void) {
	chan c_data_tx, c_data_rx;
	par {
		generateData(c_data_tx);
		{
			setupClocks();
			adat_tx(c_data_tx, p_adat_tx);
		}
        receiveAdat(c_data_rx);
        collectSamples(c_data_rx);
	}
	return 0;
}
