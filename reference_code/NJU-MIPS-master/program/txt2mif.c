#include <stdio.h>
#include <math.h>
#include <assert.h>

#define DEPTH 4096     /*数据深度，即存储单元的个数*/
#define WIDTH 32       /*存储单元的宽度*/

int main(void)
{
    int i,temp;
    float s;

    FILE *fp;
    fp = fopen("inst_rom.mif","w");   /*文件名随意，但扩展名必须为.mif*/
    if(NULL==fp)
        printf("Can not creat file!\r\n");
    else
    {
        printf("File created successfully!\n");
        /*
        *    生成文件头：注意不要忘了“;”
        */
        fprintf(fp,"DEPTH = %d;\n",DEPTH);
        fprintf(fp,"WIDTH = %d;\n",WIDTH);
        fprintf(fp,"ADDRESS_RADIX = HEX;\n");
        fprintf(fp,"DATA_RADIX = HEX;\n");
        fprintf(fp,"CONTENT\n");
        fprintf(fp,"BEGIN\n");

        FILE *txt = fopen("inst_rom.data", "r");
        assert(txt);
        for(i=0;i<DEPTH;i++)
        {
            long long temp;
            fscanf(txt,"%llx", &temp);
            fprintf(fp,"%x\t:\t%08llx;\n",i,temp);
        }//end for

        fprintf(fp,"END;\n");
        fclose(fp);
        fclose(txt);
    }
}
