#include "openusb_common.h"

//-----------------------------------------------------------------
// Locals:
//-----------------------------------------------------------------
static int _endpoint_stalled[USB_FUNC_ENDPOINTS];
static int _addressed;
static int _configured;
static int _attached;
static FUNC_PTR _func_bus_reset;
static FUNC_PTR _func_setup;
static FUNC_PTR _func_ctrl_out;
static unsigned int _usb_base;

void _delay_us(uint32_t us)
{
    uint32_t i = us;
    uint32_t cnt = CPU_Frequency;
    while (i--) {
        cnt = CPU_Frequency;
        while (cnt--) {
            __asm__("nop");
        }
    }
}

void _delay_ms(uint32_t ms)
{
    uint32_t i = ms;
    uint32_t cnt = 1000 * CPU_Frequency;
    while (i--) {
        cnt = 1000 * CPU_Frequency;
        while (cnt--) {
            __asm__("nop");
        }
    }
}

void openusb_delay_us(uint32_t i) { _delay_us(i); }

void openusb_delay_ms(uint32_t i) { _delay_ms(i); }

//-----------------------------------------------------------------
// openusb_attach: 0->detach; 1->attach;
//-----------------------------------------------------------------
void openusb_attach(uint32_t state)
{
    OPEN_USB_FUNC_CTRL_TypeDef func_ctrl;
    OPEN_USB_FUNC_STAT_TypeDef func_stat;
    if (state) {
        _attached = 1;
        // func_ctrl.d32 = 0;
        func_ctrl.d32 = OPEN_USB_READ_REG(USB_FUNC_CTRL);
        func_ctrl.b.phy_opmode = 0;
        func_ctrl.b.phy_xcvrselect = 1;
        func_ctrl.b.phy_termselect = 1;
        func_ctrl.b.phy_dppulldown = 0;
        func_ctrl.b.phy_dmpulldown = 0;
        OPEN_USB_WRITE_REG(USB_FUNC_CTRL, func_ctrl.d32);

        func_stat.d32 = 0;
        func_stat.b.rst = 1;
        OPEN_USB_WRITE_REG(USB_FUNC_STAT, func_stat.d32);

        printf("ATTACH\n");
    } else {

        _attached = 0;

        // func_ctrl.d32 = 0;
        func_ctrl.d32 = OPEN_USB_READ_REG(USB_FUNC_CTRL);
        func_ctrl.b.phy_opmode = 1;
        func_ctrl.b.phy_xcvrselect = 0;
        func_ctrl.b.phy_termselect = 0;
        func_ctrl.b.phy_dppulldown = 0;
        func_ctrl.b.phy_dmpulldown = 0;
        OPEN_USB_WRITE_REG(USB_FUNC_CTRL, func_ctrl.d32);

        // add
        func_stat.d32 = 0;
        func_stat.b.rst = 1;
        OPEN_USB_WRITE_REG(USB_FUNC_STAT, func_stat.d32);

        printf("DETACH\n");
    }
}

//-----------------------------------------------------------------
// openusb_init
//-----------------------------------------------------------------
void openusb_init(unsigned int base, FUNC_PTR bus_reset, FUNC_PTR on_setup,
                  FUNC_PTR on_out)
{
    OPEN_USB_EPx_TX_CTRL_TypeDef ep_tx_ctrl;
    OPEN_USB_EPx_RX_CTRL_TypeDef ep_rx_ctrl;
    uint8_t i;

    printf("USB INIT...\n");
    ep_tx_ctrl.d32 = 0;
    ep_tx_ctrl.b.tx_flush = 1;

    ep_rx_ctrl.d32 = 0;
    ep_rx_ctrl.b.rx_flush = 1;

    for (i = 0; i < 4; i++) {
        OPEN_USB_WRITE_REG(USB_EP_TX_CTRL(i), ep_tx_ctrl.d32);
        OPEN_USB_WRITE_REG(USB_EP_RX_CTRL(i), ep_rx_ctrl.d32);
    }

    for (i = 0; i < USB_FUNC_ENDPOINTS; i++) {
        // _tx_count[i] = 0;
        _endpoint_stalled[i] = 0;
    }

    _addressed = 0;
    _configured = 0;
    _attached = 0;

    _func_bus_reset = bus_reset;
    _func_setup = on_setup;
    _func_ctrl_out = on_out;
}

//-----------------------------------------------------------------
// openusb_is_rx_ready: 1->ready; 0->not ready
//-----------------------------------------------------------------
int openusb_is_rx_ready(uint8_t endpoint)
{
    OPEN_USB_EPx_STS_TypeDef ep_sts;
    ep_sts.d32 = OPEN_USB_READ_REG(USB_EP_STS(endpoint));
    return (ep_sts.b.rx_ready ? 1 : 0);
}

//-----------------------------------------------------------------
// openusb_get_rx_count
//-----------------------------------------------------------------
int openusb_get_rx_count(uint8_t endpoint)
{
    OPEN_USB_EPx_STS_TypeDef ep_sts;
    ep_sts.d32 = OPEN_USB_READ_REG(USB_EP_STS(endpoint));
    return (ep_sts.b.rx_count);
}

//-----------------------------------------------------------------
// openusb_get_rx_data_byte by byte
//-----------------------------------------------------------------
uint8_t openusb_get_rx_data_byte(uint8_t endpoint)
{
    return OPEN_USB_READ_REG(USB_EP_DATA(endpoint));
}

//-----------------------------------------------------------------
// openusb_clear_rx_ready_flag
//-----------------------------------------------------------------
void openusb_clear_rx_ready_flag(uint8_t endpoint)
{
    OPEN_USB_EPx_RX_CTRL_TypeDef ep_rx_ctrl;
    ep_rx_ctrl.d32 = 0;
    ep_rx_ctrl.b.rx_accept = 1;
    OPEN_USB_WRITE_REG(USB_EP_RX_CTRL(endpoint), ep_rx_ctrl.d32);
}

//-----------------------------------------------------------------
// openusb_tx_data tx_len<=64
//-----------------------------------------------------------------
void openusb_tx_data(uint8_t endpoint, uint8_t *tx_buffer, uint32_t tx_len)
{
    OPEN_USB_EPx_STS_TypeDef ep_sts;
    OPEN_USB_EPx_TX_CTRL_TypeDef ep_tx_ctrl;

    uint32_t len;
    uint32_t time = 1000;

    ep_sts.d32 = 0;
    ep_tx_ctrl.d32 = 0;

    if (tx_len > 64)
        tx_len = 64; // TODO

    for (len = 0; len < tx_len; len++) {
        // wait until space available
        ep_sts.d32 = OPEN_USB_READ_REG(USB_EP_STS(endpoint));
        while (ep_sts.b.tx_busy) {
            ep_sts.d32 = OPEN_USB_READ_REG(USB_EP_STS(endpoint));
            DEBUG_INFO("USB: Tx busy...\n");
            time--;
            if (time == 10) {
                ep_tx_ctrl.d32 = 0;
                ep_tx_ctrl.b.tx_flush = 1;
                OPEN_USB_WRITE_REG(USB_EP_TX_CTRL(endpoint), ep_tx_ctrl.d32);

                break;
            }
        }

        // load data to fifo
        OPEN_USB_WRITE_REG(USB_EP_DATA(endpoint), *(tx_buffer + len));
    }

    // tx the data
    ep_tx_ctrl.b.tx_start = 1;
    ep_tx_ctrl.b.tx_len = tx_len;
    OPEN_USB_WRITE_REG(USB_EP_TX_CTRL(endpoint), ep_tx_ctrl.d32);
}

//-----------------------------------------------------------------
// openusb_enable_int
//-----------------------------------------------------------------
void openusb_enable_int(uint8_t en_rst, uint8_t en_sof)
{
    OPEN_USB_EPx_CFG_TypeDef ep_cfg;
    OPEN_USB_FUNC_CTRL_TypeDef func_ctrl;
    uint8_t i;

    // enable ep0-3 tx rx int
    for (i = 0; i < 4; i++) {
        ep_cfg.d32 = OPEN_USB_READ_REG(USB_EP_CFG(i));
        ep_cfg.b.int_rx = 1;
        ep_cfg.b.int_tx = 1;

        if (i == 0)
            ep_cfg.b.int_tx = 0;

        OPEN_USB_WRITE_REG(USB_EP_CFG(i), ep_cfg.d32);
    }

    // enable rst and sof int
    func_ctrl.d32 = OPEN_USB_READ_REG(USB_FUNC_CTRL);
    func_ctrl.b.int_en_rst = en_rst;
    func_ctrl.b.int_en_sof = en_sof;
    OPEN_USB_WRITE_REG(USB_FUNC_CTRL, func_ctrl.d32);
}

//-----------------------------------------------------------------
// openusb_has_tx_space: Is there sapce in the tx buffer
//-----------------------------------------------------------------
int openusb_has_tx_space(uint8_t endpoint)
{
    OPEN_USB_EPx_STS_TypeDef ep_sts;
    ep_sts.d32 = OPEN_USB_READ_REG(USB_EP_STS(endpoint));
    return ep_sts.b.tx_busy;
}

//-----------------------------------------------------------------
// openusb_set_endpoint_stall
//-----------------------------------------------------------------
void openusb_set_endpoint_stall(uint8_t endpoint)
{
    OPEN_USB_EPx_CFG_TypeDef ep_cfg;

    ep_cfg.d32 = OPEN_USB_READ_REG(USB_EP_CFG(endpoint));
    ep_cfg.b.stall_ep = 1;
    OPEN_USB_WRITE_REG(USB_EP_CFG(endpoint), ep_cfg.d32);

    _endpoint_stalled[endpoint] = 1;
}

//-----------------------------------------------------------------
// openusb_control_endpoint_stall
//-----------------------------------------------------------------
void openusb_control_endpoint_stall()
{
    DEBUG_INFO("Error, send EP0 stall!\n");
    openusb_set_endpoint_stall(0);
}

//-----------------------------------------------------------------
// openusb_is_endpoint_stalled
//-----------------------------------------------------------------
uint8_t openusb_is_endpoint_stalled(uint8_t endpoint)
{
    return _endpoint_stalled[endpoint];
}

//-----------------------------------------------------------------
// openusb_clear_endpoint_stall
//-----------------------------------------------------------------
void openusb_clear_endpoint_stall(uint8_t endpoint)
{
    OPEN_USB_EPx_CFG_TypeDef ep_cfg;

    ep_cfg.d32 = OPEN_USB_READ_REG(USB_EP_CFG(endpoint));
    ep_cfg.b.stall_ep = 0;
    OPEN_USB_WRITE_REG(USB_EP_CFG(endpoint), ep_cfg.d32);

    _endpoint_stalled[endpoint] = 0;
}

//-----------------------------------------------------------------
// openusb_get_rx_data
//-----------------------------------------------------------------
uint32_t openusb_get_rx_data(uint8_t endpoint, uint8_t *rdata_buf,
                             uint32_t max_len)
{
    uint32_t i;
    uint32_t bytes_ready;
    uint32_t bytes_read = 0;

    bytes_ready = openusb_get_rx_count(endpoint);

    bytes_read = MIN(bytes_ready, max_len);

    for (i = 0; i < bytes_read; i++)
        *rdata_buf++ = openusb_get_rx_data_byte(endpoint);

    // Return number of bytes read
    return bytes_read;
}

//-----------------------------------------------------------------
// openusb_control_endpoint_send_status : Send ZLP on EP0
//-----------------------------------------------------------------
void openusb_control_endpoint_send_status()
{
    DEBUG_INFO("Send ZLP\n");

    openusb_tx_data(0, NULL, 0); // send status

    while (!openusb_has_tx_space(0))
        ;
}

//-----------------------------------------------------------------
// openusb_set_address
//-----------------------------------------------------------------
void openusb_set_address(uint8_t addr)
{
    OPEN_USB_WRITE_REG(USB_FUNC_ADDR, (uint32_t)addr);

    _addressed = 1;
}

//-----------------------------------------------------------------
// openusb_is_addressed
//-----------------------------------------------------------------
int openusb_is_addressed() { return _addressed; }

//-----------------------------------------------------------------
// openusb_is_configured
//-----------------------------------------------------------------
int openusb_is_configured() { return _configured; }

//-----------------------------------------------------------------
// openusb_is_attached:
//-----------------------------------------------------------------
int openusb_is_attached() { return _attached; }

//-----------------------------------------------------------------
// openusb_set_configured:
//-----------------------------------------------------------------
void openusb_set_configured(int configured) { _configured = configured; }

//-----------------------------------------------------------------
// openusb_service:
//-----------------------------------------------------------------
void openusb_service(OPEN_USB_FUNC_STAT_TypeDef func_stat,
                     OPEN_USB_EP_INTSTS_TypeDef ep_intsts,
                     uint8_t is_process_rst)
{
    OPEN_USB_EPx_TX_CTRL_TypeDef ep_tx_ctrl;
    OPEN_USB_EPx_RX_CTRL_TypeDef ep_rx_ctrl;
    OPEN_USB_EPx_STS_TypeDef ep_sts;

    uint32_t i;
    static uint32_t _initial = 1;
    static uint32_t _reset_count = 0;

    //----------------------
    // Bus reset event
    //----------------------
    if (func_stat.b.rst && is_process_rst) {
        _configured = 0;
        _addressed  = 0;

        // if(_initial){
        //     _initial = 0;
        //     return;
        // }

        for (i=0;i<USB_FUNC_ENDPOINTS;i++)
        {
            _endpoint_stalled[i] = 0;
        }

        for(i=0; i<4; i++){
            ep_tx_ctrl.d32 = OPEN_USB_READ_REG(USB_EP_TX_CTRL(i));
            ep_rx_ctrl.d32 = OPEN_USB_READ_REG(USB_EP_RX_CTRL(i));

            ep_tx_ctrl.b.tx_flush = 1;
            ep_rx_ctrl.b.rx_flush = 1;

            OPEN_USB_WRITE_REG(USB_EP_TX_CTRL(i), ep_tx_ctrl.d32);
            OPEN_USB_WRITE_REG(USB_EP_RX_CTRL(i), ep_rx_ctrl.d32);
        }

        if (_func_bus_reset)
            _func_bus_reset();

        OPEN_USB_WRITE_REG(USB_FUNC_STAT, func_stat.d32);
        printf("DEVICE: BUS RESET\n");
    }

    //----------------------
    // Bus sof event
    //----------------------
    if (func_stat.b.sof) {
        DEBUG_INFO("DEVICE: SOF\n");
    }

    //----------------------
    // SETPUP TRANSFER
    //----------------------
    if (ep_intsts.b.ep0_rx_ready) {

        ep_sts.d32 = OPEN_USB_READ_REG(USB_EP_STS(0));

        if (ep_sts.b.rx_setup) {
            DEBUG_INFO("SETUP packet received\n");

            if (_func_setup)
                _func_setup();

            DEBUG_INFO("SETUP packet processed\n");
        } else {
            DEBUG_INFO("OUT packet received on EP0\n");

            if (_func_ctrl_out)
                _func_ctrl_out();
        }
    }

}

//-----------------------------------------------------------------
// openusb_scaledown_enable
// set reset detect time
// mode [0]: 1092.27 us
// mode [1]: 546.13  us
// mode [2]: 273.07  us
// mode [3]: 68.27   us
//-----------------------------------------------------------------
void openusb_scaledown_enable(uint8_t mode)
{
    uint32_t rdata;
    // Device Control 0 Register
    // OTG_SCALEDOWN
    rdata = *(reg32_t *)(0x10030000);
    *(reg32_t *)(0x10030000) = rdata | (mode << 0);
}

//-----------------------------------------------------------------
// openusb_ulpi_reset
//-----------------------------------------------------------------
void openusb_ulpi_reset(uint32_t ms)
{
    uint32_t rdata;
    // SFT_RESET_REG
    // ULPI_SW_RSTN
    rdata = *(reg32_t *)(0x10000010);

    *(reg32_t *)(0x10000010) = rdata | (0x1 << 3);
    openusb_delay_ms(ms);
    *(reg32_t *)(0x10000010) = rdata & (~(0x1 << 3));
}
