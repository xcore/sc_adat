ADAT Lightpipe Digital Audio Interface
......................................

:Latest release: 1.0.0rc0
:Maintainer: henkmuller
:Description: ADAT Lightpipe Receiver and Transmitter


Key Features
============

* 48000 and 44100 ADAT receivers
* 48000 and 44100 ADAT transmitters
* Application for loopback testing on Simulator or HW

To Do
=====

* This software relies on the reference clock being 100 MHz, there is no out of the box version for non
100 Mhz reference clocks.

* ADAT Tx for 256x master clock (i.e. 48kHz from 12.288MHz master clock) not yet implemented  

Firmware Overview
=================

The modules in this repo implement an ADAT transmitter and receiver in a
core each. Separate cores are required to collect and supply data.

Known Issues
============

* None

Support
=======

At the discretion of the maintainer.

Required software (dependencies)
================================

  * None

