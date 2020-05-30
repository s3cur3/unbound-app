#include "MathUtils.h"
#include <assert.h>
#include <math.h>

int  intround(double f) { return f < 0 ? (int)(f - 0.5f) : (int)(f + 0.5f); }
size_t sround(double f) { assert(f >= 0); return (size_t)(f + 0.5f); }

         int  intfloor(double f) { return (int)floor(f); }
unsigned int uintfloor(double f) { return (unsigned int)floor(f); }

         int  intceil(double f) { return (int)ceil(f); }
unsigned int uintceil(double f) { return (unsigned int)ceil(f); }

