// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

// history:
// 08 Jun 2010   forked from swc_usb/module_usb_audio_shared/src/adat_tx_port.xc tag ADAT_FORK

#include <platform.h>
#include <xclib.h>
#include <print.h>
#include "adat_lookups.h"

#pragma unsafe arrays
void adat_transmit_port_until_ct_4x(chanend c_data, buffered out port:32 p_data, int smux)
{
  // note: byte reverse is necessary in order to output 40 bits as unint+uchar (rather than 5 uchars)
  unsigned last_lookup = 0;
  unsigned start;

#ifdef ADAT_TX_USE_SHARED_BUFF
  volatile unsigned * unsafe bufferPtr;
#endif

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
  switch (smux) {
    case 0:
    case 1: start = 0b00001111111111111111111100000000; break;
    case 2:
    case 4: start = 0b11110000000000001111111100000000; break;
  }
  while (!testct(c_data)) {
    unsigned w[8];

#ifdef ADAT_TX_USE_SHARED_BUFF
    unsafe
    {
        /* Receive pointer to sample buffer over channel */
        bufferPtr = (unsigned * unsafe) inuint(c_data);
#pragma loop unroll
        for(int i = 0; i< 8; i++)
        {
            w[i] = bufferPtr[i];
        }
        /* Handshake back to indicate done with buffer */
        outuint(c_data, 0);
    }
#else
    w[0] = inuint(c_data);
    w[1] = inuint(c_data);
#endif

    if (last_lookup & 0x80) {
      p_data <: ~0; /* First 8 bits of sync */
      p_data <: ~start;
      last_lookup = ((~start >> 31) & 1) << 7;
    }
    else {
      p_data <: 0; /* First 8 bits of sync */
      p_data <: start;
      last_lookup = ((start >> 31) & 1) << 7;
    }

    // output 8 times three 10-bit chunks - each lookup is 40 bits (4x oversampling)
#pragma loop unroll
    for (int i = 0; i < 8; i++) {
#ifndef ADAT_TX_USE_SHARED_BUFF
      if (i == 2 || i == 4 || i == 6) {
        if (testct(c_data)) {
          return;
        }
        w[i] = inuint(c_data);
        w[i + 1] = inuint(c_data);
      }
#endif
#pragma loop unroll
      for (int j = 24; j >= 8; j -= 8) {
        if (last_lookup & 0x80) {
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
  unsigned start = 0;

#ifdef ADAT_TX_USE_SHARED_BUFF
  volatile unsigned * unsafe bufferPtr;
#endif

  /* Sync is provided by 10 consecutive 0 bits followed by a 1 bit provide frame synchronization

     4 user bits are also provided:

     User bit 0 is designated for Timecode transport
     User bit 1 is designated for MIDI data transport
     User bit 2 is designated for S/Mux indication (96 kHz sample rate mode)
     User bit 3 is reserved and set to 0

     Sync/user bits: 1uuuu10000000000 (LSB transmitted first)

     Note: NRZI encoding (0 no-trans, 1 trans), a 1 bit sent every 4 bits to force a transaction

     Sync and user bits - 16 bits output as 32 bits (2x oversampling)

  */
  switch (smux)
  {
    case 0:
    case 1:
        /*
            No SMUX:
            User bits all 0: 1000010000000000
            NRZI:             0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0
            2x oversample:   00111111111100000000000000000000
        */
        start = 0b00111111111100000000000000000000;
        break;
    case 2:
    case 4:
        /*
            Note: currently use same user bits for SMUX/2 and SMUX/4.
            SMUX
            User bits, SMUX set high:  1 0010 1 0000000000
            NRZI:                       1 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0
            2x oversample              11000000111100000000000000000000
        */
        start = 0b11000000111100000000000000000000;
        break;
  }
  while (!testct(c_data)) {
    unsigned w[8];

#ifdef ADAT_TX_USE_SHARED_BUFF
    unsafe
    {
        /* Receive pointer to sample buffer over channel */
        bufferPtr = (unsigned * unsafe) inuint(c_data);
#pragma loop unroll
        for(int i = 0; i< 8; i++)
        {
            w[i] = bufferPtr[i];
        }
        /* Handshake back to indicate done with buffer */
        outuint(c_data, 0);
    }
#else
    w[0] = inuint(c_data);
    w[1] = inuint(c_data);
#endif

#ifdef adat_tx_port_SINEWAVE
    w[0] = sinewave[sinewave_i];
    w[1] = sinewave[sinewave_i];
    if (++sinewave_i == 100) {
      sinewave_i = 0;
    }
#endif

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
#ifndef ADAT_TX_USE_SHARED_BUFF
        if (testct(c_data)) {
          return;
        }
	    w[i] = inuint(c_data);
        w[i + 1] = inuint(c_data);
#endif
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

  int multiplier = inuint(c_data);
  int smux = inuint(c_data);

  // prefilling the output port:
  // 3/6/12 outputs and 8 inputs per frame = 0.375/0.75/1.5 outputs per input

  /* Wait for the other side to start up */
  if(!testct(c_data))
  {
    p_data <: byterev(0);
    p_data <: byterev(0);
    p_data <: byterev(0);
    p_data <: byterev(0);

    switch (multiplier) {
      case 1024: adat_transmit_port_until_ct_4x(c_data, p_data, smux); break;
      case 512: adat_transmit_port_until_ct_2x(c_data, p_data, smux); break;
      case 256: adat_transmit_port_until_ct_1x(c_data, p_data, smux); break;
    }

  }

  chkct(c_data, XS1_CT_END);
}
