sre-random
==========

Customizable stand-alone random number generation library, highly optimized for
both floating point and integer operations, with particular attention to execution
speed and configurable floating point precision.

Implemented as a C++ class, any kind of random number generator that can provide
32 random bits at a time can be used in a derived class, taking advantage of the
high degree of optimization in the random number generation functions in the base
class.

A high-performance default random number generator, based on the CMWC
(Complementary-multiply-with-carry) algorithm, is provided.

Also provided is a program that tests the execution speed performance and
statistical properties of the random number generator.
