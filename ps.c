#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xscugic.h"
#include "xparameters.h"
#include "sleep.h"

//yw: Check parameter definitions in xparameters.h
#define BRAM_ADDR 0x40000000
#define INT_ID XPAR_FABRIC_WRAP_RSA_0_DONE_INTR_INTR

//yw: input data config
#define DATA_WIDTH 4 // yw: 4bytes

//yw: interrupt controller
XScuGic intc;
volatile int rsa_done = 0;
volatile int wr_addr = 0;

//yw: input
u32 data_1[5] = {
    0x00724183,  
    0x44444444,  
    0x12345678,
    0xCAFEBABE,
    0xFFFFFFFF   
};

u32 exp_1[1] = {
    0x00903AD9
};

u32 mod_1[1] = {
    0x03B2C159
};

//expected_result : 0x02c8b7c0, 0x00010001,0x03600fac, 0x04253fb0, 0x06e229b5


void read_bram(u32 offset, u32 *read){
	*read = Xil_In32(BRAM_ADDR + offset);
}
}


int main() {

		init_platform();
        Xil_Out32(XPAR_WRAP_RSA_0_BASEADDR + 0x0C,0x00000000); 
        xil_printf("MUX Control Signal Set to 0 \r\n");
        Xil_Out32(XPAR_WRAP_RSA_0_BASEADDR + 0x04,0x00903AD9); 
        xil_printf("Secret Key Set(Exp) \r\n");
        Xil_Out32(XPAR_WRAP_RSA_0_BASEADDR + 0x08,0x03B2C159); 
        xil_printf("Open Key Set(Mod) \r\n");
        for(int j=0 ; j<12; j++){
            for(int i =0 ; i<5 ; i++){
            Xil_Out32(XPAR_WRAP_RSA_0_BASEADDR, data_1[i]); //new
            }
        }
        xil_printf("Sent Data to WRAP_RSA Done! \r\n");
        xil_printf("Waiting for 10 seconds... \r\n");
        
        sleep(10);
        xil_printf("Read Memory... \r\n");
        Xil_Out32(XPAR_WRAP_RSA_0_BASEADDR + 0x0C,0x11111111); 

        u32 output[128]={0};
        for(int i = wr_addr, k = 0; k < 128; i += DATA_WIDTH , k++){
            read_bram(i, &output[k]);
        }
        for(int i = 0; i < 128; i++){
            printf("OUT[%d] = %08lx\n", i, output[i]);
        }
        //0x02c8b7c0
		}
