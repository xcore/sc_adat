// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/* usage:
        buffered out port:32 adat_port;
        in port mck;
        clock mck_blk;
        par {
           {
             outuint(c_data, 1024 or 512 or 256);  // master clock multiplier
             outuint(c_data, 0 or 2 or 4);  // SMUX flag
             while (!done) {
               for (int i = 0; i < 8; i++) {
                 outuint(c_data, x);   // left aligned data (only 24 bits will be used)
               }
             }
             outct(c_data, XS1_CT_END);
           }
           adat_tx(c_data, c_port);
           {
             set_clock_src(mck_blk, mck);
             set_port_clock(adat_port, mck_blk);
             set_clock_fall_delay(mck_blk, 7);  // XAI2 board
             start_clock(mck_blk);
             while (1) {
               adat_port <: byterev(inuint(c_port));
             }
           }
        }
  why byte reverse? mixing word and byte channel outputs and channels are big endian
*/

/**Function that takes data over a channel end, and that outputs this in
 * ADAT format onto a 1-bit port. The 1-bit port should be clocked by the
 * master-clock, and an external flop should be used to precisely align the
 * edge of the signal to the master-clock.
 *
 * Data should be send onto c_data using outuint only, the first two values
 * should be The multiplier and the smux values, after that output any
 * number of eight samples (24-bit, right aligned), and if the process is
 * to be terminated send it an control token 1.
 *
 * The data is output onto a channel, which a separate process should
 * output to a port. This process should byte-reverse every word read over
 * the channel, and then output the reversed word to a buffered 1-bit port.
 *
 * \param   c_data   Channel over which to send sample values to the transmitter
 *
 * \param   c_port   Channel on which to generate the ADAT stream
 */
void adat_tx(chanend c_data, chanend c_port);


/**Function that takes data over a channel end, and that outputs this in
 * ADAT format onto a 1-bit port. The 1-bit port should be clocked by the
 * master-clock, and an external flop should be used to precisely align the
 * edge of the signal to the master-clock.
 *
 * Data should be send onto c_data using outuint only, the first two values
 * should be The multiplier and the smux values, after that output any
 * number of eight samples (24-bit, right aligned), and if the process is
 * to be terminated send it an control token 1.
 *
 * \param   c_data   Channel over which to send sample values to the transmitter
 *
 * \param   p_data   1-bit port on which to generate the ADAT stream
 */
void adat_tx_port(chanend c_data, buffered out port:32 p_data);

