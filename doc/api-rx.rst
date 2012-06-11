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

Compile time defines
--------------------

*ADAT_REF*
  Define this to 100 to state that the reference clock is exactly
  100 MHz (for example when using a 20 or 25 MHz crystal), or 999375
  to state that the reference clock is 99.9375 MHz (the
  result of using a 13 MHz crystal on an L1 or L2). Other values are at
  present not supported.

Functions
---------

.. doxygenfunction:: adatReceiver48000

.. doxygenfunction:: adatReceiver44100


Example
=======


An example program is shown below. The input port needs to be declared as a
buffered port:

.. literalinclude:: app_adat_rx_example/src/main.xc
  :start-after: //::declaration
  :end-before: //::

The receive function should be called from a ``while(1)`` loop. The second
call in the while loop is optional, and only required if 44,100 Hz data
should be received:

.. literalinclude:: app_adat_rx_example/src/main.xc
  :start-after: //::parser
  :end-before: //::

The data handler should inspect received data samples and synchronise with
the beginning of each frame. In this case, we expect every 9th value to be
marked with a '1' nibble to indicate end-of-frame.

.. literalinclude:: app_adat_rx_example/src/main.xc
  :start-after: //::data handler
  :end-before: //::

The main program simply forks the data handling thread and the receiver in
parallel in two threads:

.. literalinclude:: app_adat_rx_example/src/main.xc
  :start-after: //::main program
  :end-before: //::

