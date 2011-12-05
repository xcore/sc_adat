ADAT Receive
''''''''''''

The ADAT receive module comprises a single thread that parses data as it
arrives on a one-bit port and that outputs words of data onto a streaming
channel end. Each word of data carries 24 bits of sample data and 4 bits of
channel information.

This modules depends on the reference clock being exactly 100 Mhz.

THe module has two functions, one that receives adat at 48 KHz, and one
that receives ADAT at 44.1 KHz. If the frequency of the input signal is
known a priori, the call that function in a non terminating ``while(1)``
loop. If the frequency could be either, then call the two functions in
succession from a ``while(1)`` loop.

Note that the two functions use a normal chanend, but assume that data is
read as if it was a streaming channel end. This is historic, and the
interface should be changed to use a streaming chanend. This will require
any application using this function to be changed (no change is required in
the module itself).

API
===

.. doxygenfunction:: adatReceiver48000

.. doxygenfunction:: adatReceiver44100


Example
=======


An example program is shown below. *To be completed*

.. literalinclude:: app_adat_rx_example/src/main.xc
  :start-after: //::declaration
  :end-before: //::

