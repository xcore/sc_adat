// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "adat_rx.h"

buffered in port:32 adat = XS1_PORT_1P;

void adatReceiver48000(buffered in port:32 p, chanend oChan);

void receiveAdat(chanend c) {
    while(1) {
        adatReceiver48000(adat, c);
        adatReceiver44100(adat, c);   // delete this line if only 48000 required.
    }
}

void collectSamples(chanend c) {
    while(1) {
        unsigned head, channels[8];
        c :> head;                     // This will be a header nibble in bits 7..4 and 0001 in the bottom 4 bits
        for(int i = 0; i < 8; i++) {
            c :> channels[i];          // This will be 24 bits data in each word, shifted up 4 bits.
        }
    }
}

int main(void) {
    chan c;
    par {
        receiveAdat(c);
        collectSamples(c);
    }                                           
    return 0;
}
