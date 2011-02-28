#include <stdio.h>

main()
{
    int cnt;
    putchar(0xfb);

    for(cnt = 0 ; cnt < 42; cnt++)
    {
        putchar(0x00);
    }
    sleep(2);
    putchar(0x00);
    return(0);

}
