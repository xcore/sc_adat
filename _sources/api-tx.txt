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

Below we show two example programs: a program that uses the direct
interface, and a program that uses an intermediate thread to output to the
port.


Example of direct port code
---------------------------

The output port needs to be declared as a
buffered port, and the master clock input must be declared as an unbuffered
input port. A clock block is also required:

.. literalinclude:: app_adat_tx_direct_example/src/main.xc
  :start-after: //::declaration
  :end-before: //::

The ports need to be setup so that the output port is clocked of the master
clock with a suitable delay (to enable the external flop to latch the
signal). Do not forget to start the clock block, otherwise nothing shall happen:

.. literalinclude:: app_adat_tx_direct_example/src/main.xc
  :start-after: //::setup
  :end-before: //::

The data generator should first transmit the clock multiplier and the SMUX
flags, prior to transmitting data. To terminate, send an END token:

.. literalinclude:: app_adat_tx_direct_example/src/main.xc
  :start-after: //::generate
  :end-before: //::

The main program simply forks the data generating thread and the transmitter in
parallel in two threads. Prior to starting the transmitter, the clocks
should be set up:

.. literalinclude:: app_adat_tx_direct_example/src/main.xc
  :start-after: //::main
  :end-before: //::



Example of ADAT with an extra thread
------------------------------------

The output port needs to be declared as a
buffered port, and the master clock input must be declared as an unbuffered
input port. A clock block is also required:

.. literalinclude:: app_adat_tx_example/src/main.xc
  :start-after: //::declaration
  :end-before: //::

The ports need to be setup so that the output port is clocked of the master
clock with a suitable delay (to enable the external flop to latch the
signal). Do not forget to start the clock block, otherwise nothing shall happen:

.. literalinclude:: app_adat_tx_example/src/main.xc
  :start-after: //::setup
  :end-before: //::

The thread that drives the port should input words from the channel, and
output them with *reversed byte order*. Note that this activity of INPUT,
BYTEREV and OUTPUT takes only three instructions and can often be merged
with other threads; for example if there is an I2S thread that delivers
data syncrhonised to the same master clock, then that thread can
simultaneously drive the ADAT and I2S ports:

.. literalinclude:: app_adat_tx_example/src/main.xc
  :start-after: //::drive
  :end-before: //::

The data generator should first transmit the clock multiplier and the SMUX
flags, prior to transmitting data. To terminate, send an END token:

.. literalinclude:: app_adat_tx_example/src/main.xc
  :start-after: //::generate
  :end-before: //::

The main program simply forks the data generating thread and the transmitter in
parallel in two threads. Prior to starting the transmitter, the clocks
should be set up:

.. literalinclude:: app_adat_tx_example/src/main.xc
  :start-after: //::main
  :end-before: //::

