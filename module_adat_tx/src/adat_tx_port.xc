// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

// history:
// 08 Jun 2010   forked from swc_usb/module_usb_audio_shared/src/adat_tx_port.xc tag ADAT_FORK



#include <platform.h>
#include <xclib.h>
#include <print.h>

extern unsigned int  lookup40w[256];
extern unsigned char lookup40b[256];
extern unsigned      lookup20[256];

#pragma unsafe arrays
void adat_transmit_port_until_ct_4x(chanend c_data, buffered out port:32 p_data, int smux)
{
  // note: byte reverse is necessary in order to output 40 bits as unint+uchar (rather than 5 uchars)
  unsigned last_lookup = 0;
  unsigned start;
  switch (smux) {
    case 0: start = 0b00001111111111111111111100000000; break;
    case 2: start = 0b11110000000000001111111100000000; break;
    case 4: break; // TODO
  }
  while (!testct(c_data)) {
    unsigned w[8];
    w[0] = inuint(c_data);
    w[1] = inuint(c_data);

    // sync and user bits - 16 bits output as 64 bits (4x oversampling)
    /*  smux 2:
            11110000000000001111111100000000
            1   0   0   0   1   1   0   0
            00110001
            00101001
               uuuu
        no smux:
            00001111111111111111111100000000
            0   1   1   1   1   1   0   0
            00111110
            00100001
               uuuu
    */
    if (last_lookup & 0x80) {
      p_data <: ~0;
      p_data <: ~start;
      last_lookup = ((~start >> 31) & 1) << 7;
    }
    else {
      p_data <: 0;
      p_data <: start;
      last_lookup = ((start >> 31) & 1) << 7;
    }

    // output 8 times three 10-bit chunks - each lookup is 40 bits (4x oversampling)
    for (int i = 0; i < 8; i++) {
      if (i == 2 || i == 4 || i == 6) {
        if (testct(c_data)) {
          return;
        }
        w[i] = inuint(c_data);
        w[i + 1] = inuint(c_data);
      }
#pragma loop unroll(3)
      for (int j = 24; j >= 8; j -= 8) {
        if (last_lookup & 0x80) {
        	// used to be:
            //outuint(c_port, ~lookup40w[(w[i] >> j) & 0xFF]);
            //last_lookup = ~lookup40b[(w[i] >> j) & 0xFF];
            //outuchar(c_port, last_lookup);

          p_data <: byterev(~lookup40w[(w[i] >> j) & 0xFF]);
          last_lookup = ~lookup40b[(w[i] >> j) & 0xFF];
          partout(p_data, 8, last_lookup);
        }
        else {
          p_data <: byterev(lookup40w[(w[i] >> j) & 0xFF]);
          last_lookup = lookup40b[(w[i] >> j) & 0xFF];
          partout(p_data, 8, last_lookup);
        }
      }
    }
  }
}

extern const int sinewave[100];

#pragma unsafe arrays
void adat_transmit_port_until_ct_2x(chanend c_data, buffered out port:32 p_data, int smux)
{
#ifdef adat_tx_port_SINEWAVE
  int sinewave_i = 0;
#endif
  unsigned last_lookup = 0;
  unsigned start;
  unsigned tmp;
  switch (smux)
  {
    case 0: start = 0b00111111111100000000000000000000; break; // 3ff00000
    case 2: start = 0b11000000111100000000000000000000; break;
    case 4: break; // TODO
  }
  while (!testct(c_data)) {
    unsigned w[8];
    w[0] = inuint(c_data);
    w[1] = inuint(c_data);
#ifdef adat_tx_port_SINEWAVE
    w[0] = sinewave[sinewave_i];
    w[1] = sinewave[sinewave_i];
    if (++sinewave_i == 100) {
      sinewave_i = 0;
    }
#endif

    // sync and user bits - 16 bits output as 32 bits (2x oversampling)
    /*  smux 2:
            11000000111100000000000000000000
            1 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0
            0000000000110001
            0000000000101001
                       uuuu
        no smux:
            00111111111100000000000000000000
            0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0
            0000000000111110
            0000000000100001
                       uuuu
    */
    if (last_lookup & 0x80000) {
      p_data <: ~start;
      last_lookup = ((~start >> 31) & 1) << 19;
    }
    else {
      p_data <: start;
      last_lookup = ((start >> 31) & 1) << 19;
    }

    // output 4 times six 10-bit chunks - each lookup is 20 bits (2x oversampling)
    for (int i = 0; i < 8; i += 2) {
      unsigned next_lookup;
      if (i > 0) {
        if (testct(c_data)) {
          return;
        }
	    w[i] = inuint(c_data);
        w[i + 1] = inuint(c_data);
#ifdef adat_tx_port_SINEWAVE
	w[i] = 0;
        w[i + 1] = 0;
#endif
      }

      if (last_lookup & 0x80000)
        last_lookup = ~lookup20[(w[i] >> 24) & 0xFF];
      else
        last_lookup = lookup20[(w[i] >> 24) & 0xFF];
      if (last_lookup & 0x80000)
        next_lookup = ~lookup20[(w[i] >> 16) & 0xFF];
      else
        next_lookup = lookup20[(w[i] >> 16) & 0xFF];

      // used to be:
      //outuintb(c_port, (next_lookup << 20) | (last_lookup & 0xFFFFF));
      //outuchar(c_port, next_lookup >> 12);

      //tmp = (next_lookup << 20) | (last_lookup & 0xFFFFF);
      p_data <: (next_lookup << 20) | (last_lookup & 0xFFFFF);
      partout(p_data, 8, (next_lookup >> 12));
      // Note: This is what's achieved by outuchar(c_port, next_lookup >> 12); in the original impl
      // I.e. outuchar manages to push 8 bit into the bottom of the output word
      last_lookup = next_lookup;

      if (last_lookup & 0x80000)
        last_lookup = ~lookup20[(w[i] >> 8) & 0xFF];
      else
        last_lookup = lookup20[(w[i] >> 8) & 0xFF];
      if (last_lookup & 0x80000)
        next_lookup = ~lookup20[(w[i + 1] >> 24) & 0xFF];
      else
        next_lookup = lookup20[(w[i + 1] >> 24) & 0xFF];

      p_data <: (next_lookup << 20) | (last_lookup & 0xFFFFF);
      partout(p_data, 8, (next_lookup >> 12));
      last_lookup = next_lookup;

      if (last_lookup & 0x80000)
        last_lookup = ~lookup20[(w[i + 1] >> 16) & 0xFF];
      else
        last_lookup = lookup20[(w[i + 1] >> 16) & 0xFF];
      if (last_lookup & 0x80000)
        next_lookup = ~lookup20[(w[i + 1] >> 8) & 0xFF];
      else
        next_lookup = lookup20[(w[i + 1] >> 8) & 0xFF];

      p_data <: (next_lookup << 20) | (last_lookup & 0xFFFFF);
      partout(p_data, 8, (next_lookup >> 12));
      last_lookup = next_lookup;
    }
  }
}

#pragma unsafe arrays
void adat_transmit_port_until_ct_1x(chanend c_data, buffered out port:32 p_data, int smux)
{
  // TODO
}

void adat_tx_port(chanend c_data, buffered out port:32 p_data)
{
  set_thread_fast_mode_on();

  while (1) {
    int multiplier = inuint(c_data);
    int smux = inuint(c_data);

    // prefilling the output port:
    // 3/6/12 outputs and 8 inputs per frame = 0.375/0.75/1.5 outputs per input
    for (int i = 0; i < 8; i++) {
      inuint(c_data);
    }
    p_data <: byterev(0);
    p_data <: byterev(0);
    p_data <: byterev(0);
    p_data <: byterev(0);

    switch (multiplier) {
      case 1024: adat_transmit_port_until_ct_4x(c_data, p_data, smux); break;
      case 512: adat_transmit_port_until_ct_2x(c_data, p_data, smux); break;
      case 256: adat_transmit_port_until_ct_1x(c_data, p_data, smux); break;
    }

    chkct(c_data, XS1_CT_END);
  }
}
