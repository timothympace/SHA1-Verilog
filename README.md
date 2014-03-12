SHA1-Verilog
============

Verilog implementation of SHA1 hashing algorithm.

sha1.v: Contains state machine that accepts input blocks from a stream and processes them one chunk at a time until the whole message is added to the hash.
sha1_update.v: Contains the state machine to process one 512-bit block.
sha1_compression: Combinational logic for SHA1 compression.
t_sha1.v: Testbench for hashing a file.  The input file is specified by a string in the file.  Hexdigest is printed to the console.

Test vector files are included in the project as .tv files.
Test vectors were taken from:
http://www.di-mgt.com.au/sha_testvectors.html

testvector1.tv: a9993e364706816aba3e25717850c26c9cd0d89d
testvector2.tv: 84983e441c3bd26ebaae4aa1f95129e5e54670f1
testvector3.tv: a49b2446a02c645bf419f995b67091253a04a259
testvector4.tv: 34aa973cd4c4daa4f61eeb2bdbad27316534016f
testvector5.tv: da39a3ee5e6b4b0d3255bfef95601890afd80709
