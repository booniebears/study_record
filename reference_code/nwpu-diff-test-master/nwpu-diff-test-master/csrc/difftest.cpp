#include "difftest.h"
#include "cstdio"
#include "cstdlib"
#include "dlfcn.h"
#include "common.h"
#include "ram.h"
#include "difftest.h"
#include <cassert>
#include "VSocLite___024root.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "iostream"
#include "queue"
#include "emu.h"
using namespace std;

static int retire_queue_pointer = 0;
queue<uint32_t>PC_retire_queue;
queue<uint32_t>Instr_retire_queue;
queue<uint32_t>wdata_retire_queue;
queue<uint32_t>wnum_retire_queue;

void (*ref_napi_init)(int argc, const char *argv[]) = NULL;
void (*ref_napi_exec)(uint64_t n) = NULL;
uint32_t (*ref_napi_mmio_peek)(uint32_t paddr, int len) = NULL;
uint32_t (*ref_napi_get_instr)() = NULL;
uint32_t (*ref_napi_get_pc)() = NULL;
bool (*ref_napi_addr_is_valid)(uint32_t addr) = NULL;
void (*ref_napi_set_irq)(int irqno, bool val) = NULL;
void (*ref_napi_dump_states)() = NULL;
uint32_t (*ref_napi_get_gpr)(int i) = NULL;
void (*ref_napi_set_gpr)(int i, uint32_t val) = NULL;
void (*ref_print_registers)() = NULL;
//New add
uint32_t (*ref_napi_get_store_data)() = NULL;
uint32_t (*ref_napi_get_store_wen)() = NULL;
uint32_t (*ref_napi_get_store_vaddr)() = NULL;


// static uint32_t PC_retire_queue[RETIRE_QUEUE_MAX] = {0};
// static uint32_t Instr_retire_queue[RETIRE_QUEUE_MAX] = {0};

int nemu_find_pointer = 0;
static uint32_t nemu_pc_find_queue[RETIRE_QUEUE_MAX] = {0};
static uint32_t nemu_instr_find_queue[RETIRE_QUEUE_MAX] = {0};

void difftest_step(int step);


void difftest_init(){
  void *handle;
    const char* REF_SO = "/root/difftest/nwpu-diff-test-master/nemu_pmon.so"; 
    printf("%s\n",REF_SO);
    handle = dlopen(REF_SO, RTLD_LAZY | RTLD_DEEPBIND);
    //   printf("hello\n");
   // assert(handle);
    //initial_the_api_function
    ref_napi_exec             = (void (*)(uint64_t))dlsym(handle, "napi_exec");
    ref_napi_init             = (void (*)(int,const char **))dlsym(handle, "napi_init");
    ref_napi_mmio_peek        = (uint32_t (*)(uint32_t,int))dlsym(handle, "napi_mmio_peek");
    ref_napi_get_instr        = (uint32_t (*)())dlsym(handle, "napi_get_instr");
    ref_napi_get_pc           = (uint32_t (*)())dlsym(handle, "napi_get_pc");
    ref_napi_addr_is_valid    = (bool (*)(uint32_t))dlsym(handle, "napi_addr_is_valid");
    ref_napi_set_irq          = (void (*)(int,bool))dlsym(handle, "napi_set_irq");
    ref_napi_dump_states      = (void (*)())dlsym(handle, "napi_dump_states");//true
    ref_napi_get_gpr          = (uint32_t  (*)(int))dlsym(handle, "napi_get_gpr");
    ref_napi_set_gpr          = (void (*)(int,uint32_t))dlsym(handle, "napi_set_gpr");

    ref_napi_dump_states      = (void (*)())dlsym(handle, "napi_dump_states");//true
    ref_napi_get_gpr          = (uint32_t  (*)(int))dlsym(handle, "napi_get_gpr");
    ref_napi_set_gpr          = (void (*)(int,uint32_t))dlsym(handle, "napi_set_gpr");
            
    ref_napi_get_store_data   = (uint32_t (*)())dlsym(handle, "napi_get_store_data");
    ref_napi_get_store_wen        = (uint32_t (*)())dlsym(handle, "napi_get_store_wen");
    ref_napi_get_store_vaddr  = (uint32_t (*)())dlsym(handle, "napi_get_store_vaddr");


   // assert(ref_napi_init          );
   // assert(ref_napi_exec          );
   // assert(ref_napi_mmio_peek     );
   // assert(ref_napi_get_instr     );
   // assert(ref_napi_get_pc        );
   // assert(ref_napi_addr_is_valid );
   // assert(ref_napi_set_irq       );
   // assert(ref_napi_dump_states   );
   // assert(ref_napi_get_gpr       );
   // assert(ref_napi_set_gpr       );
   //     
   // assert(ref_napi_get_store_data);
   // assert(ref_napi_get_store_wen     );
   // assert(ref_napi_get_store_vaddr);

    
    //make sure all work normal
    const char* command[2];
    command[0]="-b";
    command[1]="-i";
    command[2]="./ceo/gzrom-NO-PASSWORD.bin";  
    ref_napi_init(3,command);
    printf("Initial NEMU Finish\n");
    // for (int i=0;i<20000;i++){
    //             ref_napi_exec(1);
    // }
    // printf("test");
    // ref_napi_init(argc,argv);
    // printf("---------------Argc:%d--------------\n",argc);
    // printf("---------------Argv:----------------\n");
    // for (int i = 0; i < argc; i++)
    // {
    //     printf("%s\n",argv[i]);
    // }
    // printf("---------------Argv_end-------------\n");
    // difftest_step(10);
    return ;
}
void nemu_get_regs(rtlreg_t* r)
{
    for(int i=0;i<32;i++){
        r[i] = ref_napi_get_gpr(i);
    }
}
void difftest_step(int step){
    //   for (int i = 0; i < step; i++)
    // {
    //     ref_napi_exec(1);
    //     printf("PC:%x Instr:%x\n",ref_napi_get_pc(),ref_napi_get_instr());
    //     // ref_napi_dump_states();
    //     for (int i = 0; i < 31; i++)
    //     {
    //         printf("%x ",ref_napi_get_gpr(i));
    //     }
    //     printf("\n");
    // }
}
void disp_rertire_queue()
{
    printf("\n==============Retire Trace==============\n");
    for(int j = 0; j < wnum_retire_queue.size(); j++){
      printf("retire trace[%d]:pc:0x%08x\tinst:0x%08x\twdata:0x%08x\twnum:%d(%s)\n", wnum_retire_queue.size()-j, 
        PC_retire_queue.front(), 
        Instr_retire_queue.front(),
        wdata_retire_queue.front(),
        wnum_retire_queue.front(),
        reg_name[ wnum_retire_queue.front()] );
        PC_retire_queue.pop();
        Instr_retire_queue.pop();
        wdata_retire_queue.pop();
        wnum_retire_queue.pop();
    }
}
void retire_queue_push(int pc,int instr,int wdata,int wnum)
{
    if (retire_queue_pointer>=15){
        retire_queue_pointer = 15;
        PC_retire_queue.pop();
        Instr_retire_queue.pop();
        wdata_retire_queue.pop();
        wnum_retire_queue.pop();
    }
    retire_queue_pointer++;
    PC_retire_queue.push(pc);
    Instr_retire_queue.push(instr);
    wdata_retire_queue.push(wdata);
    wnum_retire_queue.push(wnum);
}
void clear_nemu_queue()
{
    for(int i=0;i<16;i++){
        nemu_pc_find_queue   [i]  = 0;
        nemu_instr_find_queue[i]  = 0;
    }
}
void nemu_find_queue_push(int pc,int instr)
{
    nemu_find_pointer =(nemu_find_pointer+1) % RETIRE_QUEUE_MAX;
    nemu_pc_find_queue   [nemu_find_pointer]  = pc;
    nemu_instr_find_queue[nemu_find_pointer]  = instr;
}
void disp_nemu_find_queue()
{
    printf("\n==============NEMU  Trace==============\n");
    for(int j = 0; j < RETIRE_QUEUE_MAX; j++){
      printf("nemu find trace [%d]: pc 0x%x\t inst 0x%x \n", j, 
        nemu_pc_find_queue[j], 
        nemu_instr_find_queue[j] );
    }
}
void difftest_handle_timer_int()
{
    ref_napi_set_irq(7,1); 
}



int difftest_rtl_nemu(rtlreg_t* reg_sv,int emu_pc,int emu_instr,int emu_store_len,int emu_store_data,int emu_store_vaddr,int emu_wdata,int emu_wnum)
{
    static uint32_t ninstr=0;
    rtlreg_t nemu_reg[31];
    int nemu_pc,nemu_instr,nemu_store_data,nemu_store_vaddr,nemu_store_len;
    int nemu_steps_cnt = 0;
    int nemu_rtl_find  = 0;
    mips_instr_t instr = emu_instr;

    // keep pace with emu
    while (nemu_steps_cnt < 16)
    {
        ref_napi_exec(1);
        nemu_find_pointer = 0;
        ninstr++;
        nemu_get_regs(nemu_reg);
        nemu_pc    = ref_napi_get_pc();
        nemu_instr = ref_napi_get_instr();
        nemu_store_data  = ref_napi_get_store_data();
        nemu_store_vaddr = ref_napi_get_store_vaddr();
        nemu_store_len   = ref_napi_get_store_wen();
        // if (nemu_store_len !=0)
        //     printf("nemu_store_data:0x%08x , nemu_store_vaddr:0x%08x ,nemu_store_len:%x\n ",
        //         nemu_store_data,nemu_store_vaddr,nemu_store_len);
        nemu_find_queue_push(nemu_pc,nemu_instr);
        if (nemu_pc == emu_pc) {
            nemu_rtl_find = 1;
            break;
        }
        nemu_steps_cnt++;
    }
    // check dev
    bool dev = 0;
    if(nemu_store_vaddr >= 0xbfe40002 && nemu_store_vaddr <=0xbfe40004 ){
        dev = 1;
    }

    // keep consistency when execute mfc0 count 
    if (instr.is_mfc0_count()) {   
        uint32_t r = instr.get_rt();
        uint32_t count0 = reg_sv[r];  // set reg_sv's count0 for nemu
        ref_napi_set_gpr(r, count0);
        return 0;
    }
    // pretreatment for nemu's store type instr
    switch (nemu_store_len)
    {
    case 1:
        nemu_store_data = nemu_store_data&0xff;
        break;
     case 2:
        nemu_store_data = nemu_store_data&0xffff;
        break;
    case 4:
        nemu_store_data = nemu_store_data;
        break;
    }
    // printf("nemu_pc %X,nemu_instr %X\n ",nemu_pc,nemu_instr);
    // printf("emu_pc %X,emu_instr %X\n\n",emu_pc,emu_instr);
    /*************************first check data of store type instr*******************************************/
    if (dev==0 &&nemu_rtl_find &&(nemu_store_len&& emu_store_len) && (nemu_store_data!=emu_store_data || nemu_store_vaddr !=emu_store_vaddr)){
        printf(" $$$$$$$$$$$$$   WRONG TYPE : STORE WRONG!!!     $$$$$$$$$$$$$ \n\n\n");
        printf("store_len %X,store_DATA %X , store_vaddr %x\n ",emu_store_len,emu_store_data,emu_store_vaddr);
        printf("nemu_store_data:0x%08x , nemu_store_vaddr:0x%08x ,nemu_store_len:%x\n ",
        nemu_store_data,nemu_store_vaddr,nemu_store_len);
        disp_rertire_queue();
        return 1;
    }
    /*************************second check data of reg*******************************************/
   else if (nemu_rtl_find && (memcmp(reg_sv, nemu_reg, sizeof(nemu_reg)) != 0) ){
        printf("$$$$$$$$$$$$$      WRONG TYPE : REG WRONG!!!   $$$$$$$$$$$$$\n\n ");
        printf("nemu_pc %X,nemu_instr %X\n ",nemu_pc,nemu_instr);
        printf("emu_pc %X,emu_instr %X\n ",emu_pc,emu_instr);

        printf("\n==============  Reg Diff  ==============\n");
        for (int o=0;o<32;o++){
            if (reg_sv[o] != nemu_reg[o]){
                printf("different pc in : %x,o:%d ",emu_pc,o);
                printf("num of the reg %d , wrong = 0x%x , right = 0x%x\n",o,reg_sv[o],nemu_reg[o]);
                printf("number of execute instr:%d\n",ninstr);
                break;
            }
        }
        disp_nemu_find_queue();
        disp_rertire_queue();
        return 1;
   } 
    /*************************third check data of pc can't match*******************************************/
   else if (nemu_rtl_find == 0){
        printf(" $$$$$$$$$$$$$     WRONG TYPE : PC CAN'T MATCH TRACE!!! $$$$$$$$$$$$$  \n\n\n");
        printf("nemu searching for 16 instructions , but no match for emu_pc,emu probably wrong\n ");
        printf("emu_current pc : 0x%x \t , emu_instr : 0x%x\n",emu_pc,emu_instr);
        printf("number of execute instr:%d\n",ninstr);
        disp_nemu_find_queue();
        disp_rertire_queue();
        return 1;
    }
    /***************************correct !!!*****************************************/
    else {
        retire_queue_push(emu_pc,emu_instr,emu_wdata,emu_wnum);
        // printf("timer_interrupt_happen!!!\n");
        clear_nemu_queue();
        return 0;
    }    
}