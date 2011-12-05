ADAT Transmit
'''''''''''''

There are two modules that can produce an ADAT signal. The simplest module
is a single thread that inputs samples over a channel and that outputs data
on a 1-bit port. A more complex module has a thread that inputs samples
over a channel and that produces an ADAT signal onto a second channel.
Another thread has to copy this data from the channel onto a port. The
latter is useful if the ADAT output port is, for example, on a different
core. See the examples section on how to use this.

An identical protocol is used by both modules for inputting sample values
to be transmitted over ADAT. The first word transmitted over the
chanend should be the multiplier of the master clock (either 1024 or 512),
the second word should be the SMUX setting (either 0 or 2), then there should be N
x 8 words of sample values, terminated by an ``XS1_CT_END`` control token. If no
control token is sent, the transmission process will not terminate, and an
infinite stream of ADAT data can be sent.

The multiplier is the ratio between the master clock and the bit-rate; 1024
refers to a 49.152 Mhz masterclock, 512 assumes a 24.576 MHz master clock.

The output of the ADAT transmit thread has to be synchronised with an
external flip-flop. In order to make sure that the flip-flop captures the
signal on the right edge, the output port should be set up as follows::

  set_clock_src(mck_blk, mck);        // Connect Master Clock Block to mclk pin
  set_port_clock(adat_port, mck_blk); // Set ADAT_tx to be clocked from mck_blk
  set_clock_fall_delay(mck_blk, 7);   // Delay falling edge of mck_blk
  start_clock(mck_blk);               // Start mck_blk


API
===

.. doxygenfunction:: adat_tx

.. doxygenfunction:: adat_tx_port


Example
=======


An example program is shown below::

  TBC.
