// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#ifndef ADAT_REF
#define ADAT_REF 100
#warning "Assuming 100 MHz reference clock"
#endif

#if (ADAT_REF == 100)
#include "adatReceiver-100.h"
#elif (ADAT_REF == 999375)
#include "adatReceiver-99-9375.h"
#else
#error "Unknown ADAT reference specified - only 100 and 999375 are supported"
#endif
