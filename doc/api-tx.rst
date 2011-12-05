ADAT Transmit
'''''''''''''

There are two modules that can produce an ADAT signal. The simplest
module is a single thread that receives samples over a channel and that
outputs data on the port, and the other module has a thread that receives
samples over a channel and it produces the output on a channel. The latter
is useful if the ADAT output port is on a different core.

The modules use the same protocol: the first word transmitted over the
chanend should be the multiplier of the master clock (either 1024 or 512),
the second word should be the smux (either 0 or 2), then there should be N
x 8 words of sample values, terminated by an END control token. If no
control token is sent, the transmission process will not terminate, and an
infinite stream of ADAT data can be sent.

The multiplier is the ratio between the master clock and the bit-rate; 1024
refers to a 49.152 Mhz masterclock, 512 assumes a 24.576 MHz master clock.

API
===

*This section is to be completed*

.. doxygenfunction:: adat_tx

.. doxygenfunction:: adat_tx_port


Example
=======


An example program is shown below::

  TBC.
