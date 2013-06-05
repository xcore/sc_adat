all: adat

adatReceiver.xc: adat.c
	cc adat.c -o adat
	./adat    > adatReceiver.xc
	./adat -4 >> adatReceiver.xc

clean:
	rm -f adat
    
