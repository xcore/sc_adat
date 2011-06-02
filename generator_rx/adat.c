#include <stdio.h>
#include <stdlib.h>
#include <math.h>

putOut(int a, int b, char c) {
    static char line0[97], line1[97], line2[97];
    static int x = 0;
    line0[x] = a + '0';
    line1[x] = b + '0';
    line2[x] = c;
    if (x == 95) {
        fprintf(stderr, "%s\n%s\n%s\n\n", line0, line1, line2);
        x = 0;
    } else {
        x++;
    }
}

double sqr(double x) {
    return x*x;
}
int main(int argc, char *argv[]) {
    int readBits = 0;
    int shift = 3;
    int bitsLeft = 0;
    double firstBitIsAt;
    double bitsPassed;
    int rounded;
    int getRidOfBit = 0;
    int bitsInCompressed =0;
    double freq = 48;
    int channel = 0;              // set to zero for port.
    int i;
    int total = 0;
    int verbose = 0;
    int last = 0;
    unsigned int mask = 0x80808080;
    int samplePoint = 0;
    double bitPoints[256], bitTime, theBitPoints[256];
    int nextBitToTake = 0;
    //double referenceFrequency = 999375.0;
    double referenceFrequency =1000000.0;

    firstBitIsAt = 15;
    for(i = 1; i < argc; i++) {
        if(strcmp(argv[i], "-t") == 0) {
            channel = 1; // test
        } else if(strcmp(argv[i], "-v") == 0) {
            verbose = 1; 
        } else if(strcmp(argv[i], "-4") == 0) {
            freq = 44.1; // different frequency
            mask = 0x80402010;
            shift = 1;
            firstBitIsAt = 20;
        } else {
            fprintf(stderr, "Usage: %s [-t] [-4]\n", argv[0]);
            exit(1);
        }
    }
    bitTime =  referenceFrequency/(freq*256);
    bitPoints[0] = bitTime/2;
    for(i = 1; i < 256; i++) {
        bitPoints[i] = bitPoints[i-1] + bitTime;
    }
    printf("// GENERATED CODE - DO NOT EDIT\n");
    printf("// Comments are in the generator \n");
    printf("// Generated for devices with a reference clock of %10.6f Mhz\n", referenceFrequency/10000.0);
    printf("// If both 48000 and 44100 are to be supported, then\n// call adatReceiver48000 and 44100 in a while(1) loop\n");
    printf("#include <xs1.h>\n");
    printf("#include <stdio.h>\n");
    if (channel) {
        printf("extern void output(unsigned x, unsigned y, int z);\n");
    }
    printf("#pragma unsafe arrays\n");
    printf("void adatReceiver%d(%s p, chanend oChan) {\n", freq > 46 ? 48000 : 44100, channel ? "streaming chanend" : "buffered in port:32");
    printf("    const unsigned int mask = 0x%08x;\n", mask);
    printf("    unsigned compressed;\n");
    printf("    unsigned nibble, word = 1, fourBits, data;\n");
    printf("    int old, violation;\n");
    printf("    unsigned int lookupCrcF[16] = ");
    if (freq > 46 ) {
        printf("{8, 9, 12, 13, 7, 6, 3, 2, 10, 11, 14, 15, 5, 4, 1, 0};\n");
    } else {
        printf("{8, 12, 10, 14, 9, 13, 11, 15, 7, 3, 5, 1, 6, 2, 4, 0};\n");
    }
    printf("    unsigned int lookupNRTZ[32] = {0, 8, 12, 4, 6, 14, 10, 2, 3, 11, 15, 7, 5, 13, 9, 1,\n");
    printf("                          1, 9, 13, 5, 7, 15, 11, 3, 2, 10, 14, 6, 4, 12, 8, 0};\n");
    printf("    for(int i =  0; i < 32; i++) { lookupNRTZ[i] <<= 4; }\n");
// This section of code will wait for a preamble - at least two words
// of all zeros or all ones.
    printf("    do {\n");
    printf("        old = word; p :> word;\n");
    printf("    } while (word != old || (word != 0 && word+1 != 0));\n");
    printf("    while(1) {\n");
// Invariant: the variable word contains the current line state - in the violation.
    printf("        violation = word;\n");

// Skip the rest of the violation - this will consume a single bit on the edge of the first sample.
    if (channel) {
        printf("        while (word == violation) { p :> word;}\n");
    } else {
        printf("        p when pinsneq(violation) :> int _;\n");
        printf("        p :> word;\n");
    }
    while (readBits < 8*24+4) {
// Loop invarariant: "word" contains a sample with 32 bits.
// Figure out optimal shift

        fprintf(stderr, "Next bit: %d expected at %f, we are at %f\n", nextBitToTake, bitPoints[nextBitToTake], firstBitIsAt);
        double maxError = 9999;
        unsigned theMask;
        for(i = -7; i < 8; i++) {
            int m = i > 0 ? mask >> i : mask << -i;
            int sampleNum = nextBitToTake;
            double error = 0;
            int total = 0;
            int j;
            for(j = 0; j < 32; j++) {
                if (m >> j & 1) {
                    double thisSample = firstBitIsAt +  j * 10 ;
                    error += sqr(bitPoints[sampleNum] - thisSample);
                  //  if (verbose) fprintf(stderr, "Mask %08x shift %d bit %d error %f\n", mask, i, j, error);
                    sampleNum++;
                    total++;
                }
            }
            error = sqrt(error/total);
          //  if (verbose) fprintf(stderr, "Mask %08x shift %d total error %f\n", mask, i, error);
            if (error < maxError) {
                maxError = error;
                shift = i;
                bitsInCompressed = total;
                theMask = m;
            }
        }
        if (shift < 0) {
            shift += 8;
        }
        if (verbose) {
            fprintf(stderr, "Shift %d for best error of %f (%d bits)\n", shift, maxError, bitsInCompressed);
            int sampleNum = nextBitToTake;
            int j;
            for(j = 0; j < 32; j++) {
                if (theMask >> j & 1) {
                    double thisSample = firstBitIsAt +  j * 10 ;
                    theBitPoints[sampleNum] = thisSample;
                    sampleNum++;
                }
            }
            
        }
        nextBitToTake += bitsInCompressed;

// The crc instruction compresses the four masked bits into a 4 bit number, the lookup
// table reconstructs the original four bits.
        printf("        fourBits = (word << %d) & mask;\n", shift);
   //     printf("        output(word, mask>> %d, %d);\n", shift, bitsInCompressed);
   //     printf("        printf(\"Extracted bits %%08x\\n\", fourBits);\n");
        printf("        crc32(fourBits, 0xf, 0xf);\n");
   //     printf("        printf(\"CRC-ed bits %%02x\\n\", fourBits);\n");
        printf("        compressed = lookupCrcF[fourBits];\n");
        if (bitsInCompressed < 4) {
// This code gets rid of a duplicated bit - whenever the mask shifts over the edge of the word,
// one bit will be duplicated. This means that we should drop one bit (the oldest), and use only
// three bits on this occasion
            printf("        compressed = compressed >> 1;\n");
        }
   //     printf("        printf(\"Looked up bits %%02x (%d bits)\\n\", compressed);\n", bitsInCompressed);
        if (verbose) {
            for(i = 0; i < 32; i++) {
                if ((mask >> shift) >> i & 1) {
                    if (bitsInCompressed == 4 || i > 7) {
                        int bitnum = total + i;
                        fprintf(stderr, "Bit %d sample %d (%d)%s\n", samplePoint, bitnum, bitnum-last, samplePoint % 5 == 0 ? " (Stuff bit)" : "");
                        last = bitnum;
                        samplePoint++;
                    }
                }
            }
            total += 32;
        }
        if (bitsLeft + bitsInCompressed > 4) {
// There are sufficient bits to form a nibble. The lookuptable decodes the NRTZ encoding.
// THe shift and or operations take the past few bits and the current bits and glue them together.
// The rest of the bits (that were masked off by the &31) are kept in the bottom bits of old.
  //          printf("        printf(\">>> Last 8 bits bits %%02x\\n\", (old | (compressed << %d)));\n", bitsLeft);
            printf("        nibble = lookupNRTZ[(old | (compressed << %d)) & 31];\n", bitsLeft);
   //         printf("        printf(\">>> Nibbled bits %%02x\\n\", nibble);\n");
            printf("        old = compressed >> %d;\n", (5-bitsLeft));
            readBits+=4;
            bitsLeft = bitsLeft - 5 + bitsInCompressed;
            if (readBits == 4) {
                printf("        outuint(oChan, nibble << 4 | 1);\n");
            } else if ((readBits-4) % 24 == 0) {
                printf("        data = (data | nibble) << 4;\n");
                printf("        outuint(oChan, data);\n");
            } else if ((readBits-8) % 24 == 0) {
                printf("        data = nibble << 4;\n");
            } else {
                printf("        data = (data | nibble) << 4;\n");
            }
        } else if (bitsLeft == 0) {
            printf("        old = compressed;\n");
            bitsLeft+=bitsInCompressed;
        } else { // odd case - a bit left and 3 compressed bits, only 4, collect in old.
            printf("        old = old | compressed << %d;\n", bitsLeft);
            bitsLeft+=bitsInCompressed;
        }
        firstBitIsAt += 320;
        printf("        p :> word;\n");
    }
    printf("        if (word != 0 && word+1 != 0) return;\n");
    printf("    }\n");
    printf("}\n");
    printf("\n");
    if (verbose) {
        for(i = 0; i < 256; i++) {
            fprintf(stderr, "Bit %d  should be at %f but at %f\n", i, bitPoints[i], theBitPoints[i]);
        }
        int state0 = 0;
        int state1 = 0;
        int k = 0, k1 = 0, k2 = 0; char c;
        for(i = 0; i < bitPoints[255]; i+=10) {
            if (theBitPoints[k2] == i) {
                c = '^';
                k2++;
            } else {
                c = ' ';
            }
            putOut(state0, state1, c);
            if ((bitPoints[k]+bitPoints[k+1]-10)/2 <= i) {
                state0 = !state0;
                k++;
            }
            if ((bitPoints[k1]+bitPoints[k1+1]+10)/2 <= i) {
                state1 = !state1;
                k1++;
            }
        }
    }
    return 0;
}
