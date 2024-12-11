#include "semantic.h"
#include "stdio.h"

int rtd(int t1, int t2){
    if (t1 == FLOAT || t2 == FLOAT)
        return FLOAT;
    if (t1 == INT || t2 == INT)
        return INT;
    if (t1 == CHAR || t2 == CHAR)
        return CHAR;
    return -1; 
}

int invalidtype(int tipo_destino, int tipo_origem){
    if (tipo_destino == tipo_origem)
        return 0; 
    if (tipo_destino == FLOAT || tipo_origem == FLOAT)
        return 0; 
    if (tipo_destino == INT && tipo_origem == CHAR)
        return 0; 
    return -1;
}
