
//=================================================================
// 
// CDC class test main.c
//
// Version: V1.0
// Created by Zeba-Xie @github
//
//=================================================================
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "hbird_sdk_hal.h"

#define DEBUG_MODE

#include "openusb_defs.h"
#include "openusb_regs.h"
#include "openusb_common.h"
#include "openusb_cdc.h"

uint8_t rx_packet_buf[64];
uint8_t tx_packet_buf[64];
uint8_t ep1_tx_suc=0;
uint8_t ep2_tx_suc=0;
uint8_t ep1_rx_suc=0;
uint16_t ep1_rx_len=0;
uint8_t enable_rst_intr=0;

void my_usb_intr(){
	printf("[USB INT]\n");
    uint8_t endpoint_num;
	int j;

	OPEN_USB_EP_INTSTS_TypeDef ep_intsts;
	OPEN_USB_FUNC_STAT_TypeDef func_stat;

	func_stat.d32 = OPEN_USB_READ_REG(USB_FUNC_STAT);
	ep_intsts.d32 = OPEN_USB_READ_REG(USB_EP_INTSTS);

    openusb_service(func_stat, ep_intsts, enable_rst_intr);

	if(ep_intsts.b.ep1_rx_ready){
		endpoint_num = 1;

		ep1_rx_len = openusb_get_rx_count(endpoint_num);

		DEBUG_INFO("[%d USB_EP%1d_DATA]\n", ep1_rx_len, endpoint_num);

		if(ep1_rx_len > 64){
			ep1_rx_len = 64;
		}

		for(j=0; j<ep1_rx_len; j++){
			rx_packet_buf[j] = openusb_get_rx_data_byte(endpoint_num);
		}
		openusb_clear_rx_ready_flag(endpoint_num);

		ep1_rx_suc = 1;
	}

	if(ep_intsts.b.ep1_tx_complete){
		ep1_tx_suc = 1;
		DEBUG_INFO("[EP 1 SUC TX]\r\n");
	}
	
	if(ep_intsts.b.ep2_tx_complete){
		ep2_tx_suc = 1;
		DEBUG_INFO("[EP 2 SUC TX]\r\n");
	}

	// clear
	OPEN_USB_WRITE_REG(USB_EP_INTSTS, ep_intsts.d32);
	OPEN_USB_WRITE_REG(USB_FUNC_STAT, func_stat.d32);
}

void enable_usb_int(){
    int returnCode = PLIC_Register_IRQ(PLIC_USB_DEVICE_IRQn, 1, my_usb_intr); 
	__enable_irq();
}


void process_reset(){
	OPEN_USB_FUNC_STAT_TypeDef func_stat;
	OPEN_USB_EPx_TX_CTRL_TypeDef ep_tx_ctrl;
    OPEN_USB_EPx_RX_CTRL_TypeDef ep_rx_ctrl;

	uint8_t i;

	func_stat.d32 = OPEN_USB_READ_REG(USB_FUNC_STAT);
	if(func_stat.b.rst){
		for(i=0; i<4; i++){
            ep_tx_ctrl.d32 = OPEN_USB_READ_REG(USB_EP_TX_CTRL(i));
            ep_rx_ctrl.d32 = OPEN_USB_READ_REG(USB_EP_RX_CTRL(i));

            ep_tx_ctrl.b.tx_flush = 1;
            ep_rx_ctrl.b.rx_flush = 1;

            OPEN_USB_WRITE_REG(USB_EP_TX_CTRL(i), ep_tx_ctrl.d32);
            OPEN_USB_WRITE_REG(USB_EP_RX_CTRL(i), ep_rx_ctrl.d32);
        }

		OPEN_USB_WRITE_REG(USB_FUNC_STAT, func_stat.d32);
		printf("USB: reset done\n");
	}

}

int main(){

	printf("USB CDC test\r\n");

	openusb_attach(0);
	usbf_init(USB_BASE, 0, usb_cdc_process_request);
	enable_usb_int();

	openusb_delay_ms(500);

	printf("Connecting...\r\n");
	openusb_attach(0);
	openusb_delay_ms(500);
	openusb_attach(1);

	openusb_enable_int(1,0); 
	enable_rst_intr=1;

	while(1){
		process_reset();

		if(ep1_rx_suc && ep1_rx_len!=0){ 
			DEBUG_INFO("[EP1 RX]: ");
			for(uint16_t k=0; k<ep1_rx_len; k+=1)
				DEBUG_INFO("%x ", rx_packet_buf[k]);
			DEBUG_INFO("\r\n");

			openusb_tx_data(2, rx_packet_buf, ep1_rx_len); 

			ep1_rx_suc = 0;
			ep1_rx_len = 0;
		}

	}

    printf("Finish!\r\n");
    return 0;
}

