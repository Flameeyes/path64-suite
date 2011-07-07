
#include <ieeefp.h>

int isinf(double x) {
    return !finite(x) && x==x;
}

