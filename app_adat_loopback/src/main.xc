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
#define GEN_DATA_SIZE 1024

buffered out port:32 p_adat_tx = XS1_PORT_1A;
buffered in port:32 p_adat_rx = XS1_PORT_1B;

in port mck = XS1_PORT_1C;

#ifdef XSIM
  // Generate Audio Master Clock clos
  // must be buffered to meet timing
  out buffered port:32 mck_out = XS1_PORT_1D;
#endif

//debug trace port (useful in simulator waveform)
out port trace_data = XS1_PORT_32A;

clock mck_blk = XS1_CLKBLK_2;
clock clk_adat_rx = XS1_CLKBLK_1;

void adatReceiver48000(buffered in port:32 p, chanend oChan);

void receiveAdat(chanend c) {
    set_thread_fast_mode_on();
    // Note The ADAT receiver expects a Audio Master Clock close to 24.576 MHz. See mck_gen for XSIM
    while(1) {
        adatReceiver48000(p_adat_rx, c);
        adatReceiver44100(p_adat_rx, c);   // delete this line if only 48000 required.
    }
}

void collectSamples(chanend c) {
    while(1) {
        unsigned head, channels[8];
        head = inuint(c);                    // This will be a header nibble in bits 7..4 and 0001 in the bottom 4 bits
        trace_data <: head;
        for(int i = 0; i < 8; i++) {
            channels[i] = inuint(c);         // This will be 24 bits data in each word, shifted up 4 bits.
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
		outuint(c_data, i<<8);   // left aligned data (only 24 bits will be used)
	}

    printf("Finished sending %d words", GEN_DATA_SIZE);

	outct(c_data, XS1_CT_END);
}


void setupClocks() {

	set_clock_src(mck_blk, mck);
#ifndef XSIM
	set_clock_fall_delay(mck_blk, 7);   // XAI2 board, set to appropriate value for board.
#endif

	set_port_clock(p_adat_tx, mck_blk);
	start_clock(mck_blk);
}

#ifdef XSIM
void mck_gen() {
	// generate clock close to 24.576 MHz

    unsigned time;
    unsigned clk_data = 0xcccccccc; // 100MHz / 4, 8 cycles in 32
    unsigned count = 0;

    set_thread_fast_mode_on();

    mck_out <: 0 @ time;

	// stretch clock by loosing 10ns every 16th cycle (40 ns every 64th cycle) -> loose one mck cycle every 64th cycle
    // Resulting average frequency = 25MHz * 63/64 = 24.6094.
	// As close as it gets to 24.576 with 100MHz ref clock.

	while(1) {
		time += 65;

		mck_out <: clk_data;
		mck_out @ time <: clk_data;

		count++; // 4 cycles
	}
}
#endif

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

#ifdef XSIM
        mck_gen();
#endif
	}
	return 0;
}
