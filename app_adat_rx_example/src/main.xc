// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

//::declaration
#include <xs1.h>
#include "adat_rx.h"

buffered in port:32 adat = XS1_PORT_1P;
//::

void adatReceiver48000(buffered in port:32 p, chanend oChan);

//::parser
void receiveAdat(chanend c) {
    while(1) {
        adatReceiver48000(adat, c);
        adatReceiver44100(adat, c);   // delete this line if only 48000 required.
    }
}
//::

//::data handler
void collectSamples(chanend c) {
    unsigned head, channels[9];
    while(1) {
        for(int i = 0; i < 9; i++) {
            head = inuint(c);         // This will be 24 bits data in each word, shifted up 4 bits.
            if ((head & 0xF) == 1) {
                break;
            }
            channels[i] = head << 4;
        }
        // One whole frame in channels [0..7]
    }
}
//::

//::main program
int main(void) {
    chan c;
    par {
        receiveAdat(c);
        collectSamples(c);
    }
    return 0;
}
//::
