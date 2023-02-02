#ifndef __OPENUSB_CONMMON__
#define __OPENUSB_CONMMON__

#include <stdio.h>
#include "openusb_regs.h"
#include "openusb_defs.h"
#include "openusb_device.h"

//-----------------------------------------------------------------
// Types
//-----------------------------------------------------------------
typedef void (*FUNC_PTR)(void);

void openusb_delay_us(uint32_t i);
void openusb_delay_ms(uint32_t i);

void openusb_attach(uint32_t state);
void openusb_init(unsigned int base, FUNC_PTR bus_reset, FUNC_PTR on_setup, FUNC_PTR on_out);

int openusb_is_rx_ready(uint8_t endpoint);
int openusb_get_rx_count(uint8_t endpoint);
uint8_t openusb_get_rx_data_byte(uint8_t endpoint);
void openusb_clear_rx_ready_flag(uint8_t endpoint);
void openusb_tx_data(uint8_t endpoint, uint8_t *tx_buffer, uint32_t tx_len);

void openusb_enable_int(uint8_t en_rst, uint8_t en_sof);
int openusb_has_tx_space(uint8_t endpoint);
void openusb_set_endpoint_stall(uint8_t endpoint);
void openusb_control_endpoint_stall();
void openusb_clear_endpoint_stall(uint8_t endpoint);
uint8_t openusb_is_endpoint_stalled(uint8_t endpoint);
uint32_t openusb_get_rx_data(uint8_t endpoint, uint8_t *rdata_buf, uint32_t max_len);
void openusb_control_endpoint_send_status();

void openusb_set_address(uint8_t addr);
int openusb_is_addressed();
int openusb_is_configured();
int openusb_is_attached();
void openusb_set_configured(int configured);

void openusb_service(OPEN_USB_FUNC_STAT_TypeDef func_stat, OPEN_USB_EP_INTSTS_TypeDef ep_intsts, uint8_t is_process_rst);

void openusb_scaledown_enable(uint8_t mode);
void openusb_ulpi_reset(uint32_t ms);


#endif
