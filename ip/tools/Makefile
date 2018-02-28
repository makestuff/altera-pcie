all: isatty_hack.so test

isatty_hack.so: isatty_hack.c
	gcc -Wall -O2 -fPIC -shared -ldl -o $@ $<

isatty_test: isatty_test.c
	gcc -Wall -O2 -o $@ $<

test: isatty_test
	@./isatty_test without-preload > temp.txt
	@cat temp.txt
	@LD_PRELOAD=$$(pwd)/isatty_hack.so ./isatty_test with-preload > temp.txt
	@cat temp.txt
	@rm -f temp.txt

clean: FORCE
	rm -f isatty_hack.so isatty_test temp.txt

FORCE:
