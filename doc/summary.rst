ADAT software
=============

ADAT is a protocol to transmit audio
data over either coaxial or optical cables. The data transmission rate is
determined by the transmitter, and the receiver has to recover the sample
rate. ADAT normally carries 8 channels.

Important characteristics of ADAT software are the following:

* The sample rate(s) supported. Typical values are 44.1 or 48. 96 and 192
  may be supported, but typically with only 4 or 2 channels.

* Transmit and Receive support. Some systems require only ADAT output, or
  only ADAT input. Others require both.

Note that ADAT of eight channels at 48 Khz is identical to two channels at
192 KHz - a single bit in the data stream differentiates it (but the bit
rates, transmit, and receive code are identical).

module_adat_tx
--------------

This module can transmit S/PDIF signals at the following rates
(assuming eight threads on a 400 MHz part):

+---------------------------+-------------------------------+------------------------+
| Functionality provided    | Resources required            | Status                 | 
+----------+----------------+------------+---------+--------+                        |
| Channels | Sample Rate    | 1-bit port | Threads | Memory |                        |
+----------+----------------+------------+---------+--------+------------------------+
| 8        | up to 48 KHz   | 1-2        | 1+      | 3.6K   | Implemented and tested |
+----------+----------------+------------+---------+--------+------------------------+
| 8        | up to 48 KHz   | 1-2        | 1       | 3.5K   | Implemented and tested |
+----------+----------------+------------+---------+--------+------------------------+

It requires a single thread to run the transmit code. The number of 1-bit
ports depends on whether the master clock is already available on a one-bit
port. If available, then only a single 1-bit port is required to output
ADAT. If not, then two ports are required, one for the signal output, and
one for the master-clock input.

An external flip-flop is required to resynchronise the data signal to the
master-clock if more than 2 channels are used, or if the sample rate is
higher than 48 KHz. 

The precise transmission frequencies supported depend on the availability
of an external clock (eg, a PLL or a crystal oscillator) that runs at a
frequency of::

  512 * sampleRate

or a power-of-2 multiple. For example, for 48 Khz the
external clock has to run at a frequency of 24.576 MHz.
If both 44,1 and 48 Khz frequencies are to be supported, both a
24.587 MHz and a 22.579 MHz master clock are required. This is normally not
an issue since the same clocks can be used to drive the audio codecs.

Typical applications for this module include iPod docks, digital microphones,
digital mixing desks, USB audio, and AVB.

module_adat_rx
--------------


This module can receive ADAT signals at the following rates
(assuming 8 threads on a 400 MHz part (?)):

+---------------------------+-------------------------+------------------------+
| Functionality provided    | Resources required      | Status                 | 
+----------+----------------+------------+------------+                        |
| Channels | Sample Rate    | 1-bit port | Memory     |                        |
+----------+----------------+------------+------------+------------------------+
| 8        | up to 48 KHz   | 1          | 1.5-3.5 KB | Implemented and tested |
+----------+----------------+------------+------------+------------------------+

A single 50-MIPS thread is required. The receiver does not require any
external clock, but can only recover 44.1 and 48 KHz sample rates. The
amount of memory depends on whether both 44.1 and 48 KHz are to be
supported, or just a single frequency.

Typical applications for this module include digital speakers,
digital mixing desks, USB audio, and AVB.
