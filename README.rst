ADAT Digital Audio Interface
............................

:Stable release:  unreleased (see `versioning <https://github.com/xcore/Community/wiki/Versioning>`_)

:Status:  Feature complete

:Maintainer:  https://github.com/henkmuller

:Description:  Modules for receiving and transmitting ADAT streams


Key Features
============

* 48000 and 44100 ADAT receivers
* 48000 and 44100 ADAT transmitters
* Application for loopback testing on Simulator or HW

To Do
=====

This software relies on the reference clock being 100 MHz, there is no out of the box version for non
100 Mhz reference clocks.


Firmware Overview
=================

The modules in this repo implement an ADAT transmitter and receiver in a
thread each. Separate threads are required to collect and supply data.

Known Issues
============

* None

Required Repositories
=====================

* xcommon git\@github.com:xcore/xcommon.git
* xdoc git\@github.com:xcore/xdoc.git

Support
=======

At the discretion of the maintainer.
