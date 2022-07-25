#include <signal.h>
#include <stdbool.h>

#include "device.h"
#include "utils/console.h"
#include "utils/fifo.h"
#include "utils/file.h"

// UART
#define Rx 0x0
#define Tx 0x4
#define STAT 0x8
#define CTRL 0xC
#define XLNX_ULITE_SIZE 0x10

#define XLNX_ULITE_IRQ_NO 4

#define SR_CTRL_INTR_BIT (1 << 4)

/* status */
#define SR_TX_FIFO_FULL (1 << 3) /* transmit FIFO full */
#define SR_TX_FIFO_EMPTY          \
  (1 << 2) /* transmit FIFO empty \
            */
#define SR_RX_FIFO_VALID_DATA \
  (1 << 0)                       /* data in receive FIFO */
#define SR_RX_FIFO_FULL (1 << 1) /* receive FIFO full */

/* ctrl */
#define ULITE_CONTROL_RST_TX 0x01
#define ULITE_CONTROL_RST_RX 0x02

/* ulite queue */
static fifo_type(int, 1024) ulite_q;

void xlnx_ulite_enqueue(int ch) { fifo_push(ulite_q, ch); }

/* ulite queue end */

static uint32_t xlnx_ulite_intr_enabled = 0;
static uint32_t xlnx_ulite_tx_fifo_empty = 0;

static const char *xlnx_ulite_stop_string = NULL;
static const char *xlnx_ulite_stop_string_ptr = NULL;

void xlnx_ulite_set_irq() {
  if (xlnx_ulite_intr_enabled) {
    nemu_set_irq(XLNX_ULITE_IRQ_NO, 1);
  }
}

void stop_cpu_when_ulite_send(const char *string) {
  xlnx_ulite_stop_string = string;
  xlnx_ulite_stop_string_ptr = string;
}

static void stop_cpu_check(char ch) {
  if (!xlnx_ulite_stop_string_ptr) return;

  if (*xlnx_ulite_stop_string_ptr == ch) {
    xlnx_ulite_stop_string_ptr++;
    if (*xlnx_ulite_stop_string_ptr == 0) {
      eprintf("ulite recv '%s', stop the cpu\n",
          xlnx_ulite_stop_string);
      kdbg_print_frames();
      kdbg_print_backtraces();
      nemu_state = NEMU_STOP;
    }
  } else {
    xlnx_ulite_stop_string_ptr = xlnx_ulite_stop_string;
  }
}

static uint32_t xlnx_ulite_peek(paddr_t addr, int len) {
  switch (addr) {
  case Rx: return fifo_top(ulite_q);
  case STAT: {
    uint32_t status = 0;
    if (!fifo_is_empty(ulite_q))
      status |= SR_RX_FIFO_VALID_DATA;
    if (xlnx_ulite_intr_enabled) status |= SR_CTRL_INTR_BIT;
    if (xlnx_ulite_tx_fifo_empty)
      status |= SR_TX_FIFO_EMPTY;
    return status;
  } break;
  case CTRL: return 0;
  default:
    CPUAssert(false,
        "uart: address(0x%08x) is not readable", addr);
    break;
  }
  return 0;
}

static uint32_t xlnx_ulite_read(paddr_t addr, int len) {
  check_ioaddr(addr, len, XLNX_ULITE_SIZE, "ulite.read");
  if (addr == Rx) {
    nemu_set_irq(XLNX_ULITE_IRQ_NO, 0);
    return fifo_pop(ulite_q);
  }
  return xlnx_ulite_peek(addr, len);
}

static void xlnx_ulite_write(
    paddr_t addr, int len, uint32_t data) {
  check_ioaddr(addr, len, XLNX_ULITE_SIZE, "ulite.write");
  switch (addr) {
  case Tx:
    putchar((char)data);
    stop_cpu_check(data);
    fflush(stdout);
    if ((char)data == '\n') {
      xlnx_ulite_tx_fifo_empty |= SR_TX_FIFO_EMPTY;
      // xlnx_ulite_set_irq();
    }
    break;
  case CTRL:
    xlnx_ulite_intr_enabled = data & SR_CTRL_INTR_BIT;
    if (!xlnx_ulite_intr_enabled) {
      xlnx_ulite_tx_fifo_empty = 0;
      nemu_set_irq(XLNX_ULITE_IRQ_NO, 0);
    }
    break;
  default:
    CPUAssert(false,
        "uart: address(0x%08x) is not writable", addr);
    break;
  }
}

static void check_ctrl_x_commands(char ch) {
  if (ch == 0x18) {
    /* ^X */
    printf("^X [q:quit]: ");
    fflush(stdout);
    switch (getchar()) {
    case 'q':
      resume_console();
      nemu_exit();
      break;
    default:
      break;
    }
  }
}

static bool xlnx_ulite_update_irq() {
  int n = nchars_stdin();
  if (n <= 0) return false;

  char *data = malloc(n);
  read_s(0, data, n);
  for (int i = 0; i < n; i++) {
    check_ctrl_x_commands(data[i]);
    xlnx_ulite_enqueue(data[i]);
  }
  free(data);

  xlnx_ulite_set_irq();
  return true;
}

void xlnx_ulite_set_fifo_data(const void *data, int len) {
  /* send command to uboot */
  const char *buf = data;
  for (int i = 0; i < len; i++) xlnx_ulite_enqueue(buf[i]);
}

void ulite_ctrl_code_handler(int no) {
  if (no == SIGINT) {
    /* https://en.wikipedia.org/wiki/Control-C */
    xlnx_ulite_enqueue('\x03');
    xlnx_ulite_set_irq();
  } else if (no == SIGTSTP) {
    /* https://en.wikipedia.org/wiki/Substitute_character */
    xlnx_ulite_enqueue('\x1a');
    xlnx_ulite_set_irq();
  }
}

static void xlnx_ulite_init() {
  fifo_init(ulite_q);

#if CONFIG_INTR
  signal(SIGINT, ulite_ctrl_code_handler);
  signal(SIGTSTP, ulite_ctrl_code_handler);
#endif
}

DEF_DEV(xlnx_ulite_dev) = {
    .name = "xlnx-ulite",
    .init = xlnx_ulite_init,
    .start = CONFIG_XLNX_ULITE_BASE,
    .size = XLNX_ULITE_SIZE,
    .peek = xlnx_ulite_peek,
    .read = xlnx_ulite_read,
    .write = xlnx_ulite_write,
    .set_fifo_data = xlnx_ulite_set_fifo_data,
    .map = NULL,
    .update_irq = xlnx_ulite_update_irq,
};
