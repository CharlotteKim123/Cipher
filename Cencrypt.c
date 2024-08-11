// version 1.0 11/12/2022
#include <stdio.h>
#include "cipher.h"

#ifdef MYENCRYPT_C
TODO("using Cencrypt.c");

int
encrypt(char *iobuf, char *bookbuf, int cnt)
{
    // your code here
    if (cnt<=0){
        return 0;
    }
    for(int i = 0; i < cnt; i++){
        unsigned int temp, x, y;
        x = (unsigned int)iobuf[i];
        y = (unsigned int)bookbuf[i];
        temp = x^y;
        iobuf[i] = (char)temp;
    }
    return cnt;
}

#elif defined MYENCRYPT_S
TODO("using encrypt.S");
#else
TODO("using solution encrypt");
#endif
