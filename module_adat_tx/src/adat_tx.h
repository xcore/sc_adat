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
void adat_tx(chanend c_data, chanend c_port);
