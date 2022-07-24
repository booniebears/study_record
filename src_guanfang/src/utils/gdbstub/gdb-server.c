#include <arpa/inet.h>
#include <malloc.h>
#include <setjmp.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cpu/reg.h"
#include "cpu/memory.h"
#include "monitor.h"
#include "utils/gdb-proto.h"

void cpu_exec(uint64_t);

jmp_buf gdb_mode_top_caller;

static char target_xml[] =
    "l<?xml version=\"1.0\"?>"
    "<!DOCTYPE target SYSTEM \"gdb-target.dtd\">"
    "<target>"
    "<architecture>mips</architecture>"
    "<xi:include href=\"mips-32bit.xml\"/>"
    "</target>";

static char mips_32bit_xml[] =
    "l<?xml version=\"1.0\"?>\n"
    "<!-- Copyright (C) 2010-2017 Free Software "
    "Foundation, Inc.\n"
    "\n"
    "     Copying and distribution of this file, with or "
    "without modification,\n"
    "     are permitted in any medium without royalty "
    "provided the copyright\n"
    "     notice and this notice are preserved.  -->\n"
    "\n"
    "<!-- MIPS32 with CP0 -->\n"
    "\n"
    "<!DOCTYPE target SYSTEM \"gdb-target.dtd\">\n"
    "<feature name=\"org.gnu.gdb.mips.32bit\">\n"
    "  <xi:include href=\"mips-32bit-cpu.xml\"/>\n"
    "  <xi:include href=\"mips-32bit-cp0.xml\"/>\n"
    "</feature>";

static char mips_32bit_cpu_xml[] =
    "l<?xml version=\"1.0\"?>\n"
    "<!-- Copyright (C) 2010-2015 Free Software "
    "Foundation, Inc.\n"
    "\n"
    "     Copying and distribution of this file, with or "
    "without modification,\n"
    "     are permitted in any medium without royalty "
    "provided the copyright\n"
    "     notice and this notice are preserved.  -->\n"
    "\n"
    "<!DOCTYPE feature SYSTEM \"gdb-target.dtd\">\n"
    "<feature name=\"org.gnu.gdb.mips.cpu\">\n"
    "  <reg name=\"zero\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"at\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"v0\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"v1\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"a0\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"a1\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"a2\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"a3\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t0\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t1\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t2\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t3\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t4\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t5\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t6\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t7\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s0\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s1\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s2\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s3\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s4\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s5\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s6\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"s7\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t8\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"t9\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"k0\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"k1\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"gp\" bitsize=\"32\" "
    "type=\"data_ptr\"/>\n"
    "  <reg name=\"sp\" bitsize=\"32\" "
    "type=\"data_ptr\"/>\n"
    "  <reg name=\"fp\" bitsize=\"32\" "
    "type=\"data_ptr\"/>\n"
    "  <reg name=\"ra\" bitsize=\"32\" type=\"int32\"/>\n"
    "</feature>\n";

static char mips_32bit_cp0_xml[] =
    "l<?xml version=\"1.0\"?>\n"
    "<!-- Copyright (C) 2010-2015 Free Software "
    "Foundation, Inc.\n"
    "\n"
    "     Copying and distribution of this file, with or "
    "without modification,\n"
    "     are permitted in any medium without royalty "
    "provided the copyright\n"
    "     notice and this notice are preserved.  -->\n"
    "\n"
    "<!DOCTYPE feature SYSTEM \"gdb-target.dtd\">\n"
    "<feature name=\"org.gnu.gdb.mips.cp0\">\n"
    "  <reg name=\"sr\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"lo\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"hi\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"bad\" bitsize=\"32\" type=\"int32\"/>\n"
    "  <reg name=\"cause\" bitsize=\"32\" "
    "type=\"int32\"/>\n"
    "  <reg name=\"pc\" bitsize=\"32\" "
    "type=\"code_ptr\"/>\n"
    "  <reg name=\"epc\" bitsize=\"32\" "
    "type=\"code_ptr\"/>\n"
    "</feature>\n";

typedef char *(*gdb_cmd_handler_t)(char *args, int arglen);

char *gdb_question(char *args, int arglen) { return "T05thread:01;"; }

char *gdb_xfer_handler(char *args) {
  char *category = args;
  if (!category || strcmp(category, "features") == 0) {
    char *op = strtok(NULL, ":");
    if (!op || strcmp(op, "read") != 0) return NULL;

    char *file = strtok(NULL, ":");
    char *offset_s = strtok(NULL, ":");

    int offset = 0;
    sscanf(offset_s, "%x", &offset);

    if (!file) return "";
    if (strcmp(file, "target.xml") == 0) {
      return &target_xml[offset];
    } else if (strcmp(file, "mips-32bit.xml") == 0) {
      return &mips_32bit_xml[offset];
    } else if (strcmp(file, "mips-32bit-cpu.xml") == 0) {
      return &mips_32bit_cpu_xml[offset];
    } else if (strcmp(file, "mips-32bit-cp0.xml") == 0) {
      return &mips_32bit_cp0_xml[offset];
    } else {
      return "";
    }
  } else {
    return NULL;
  }
}

char *gdb_general_query(char *args, int arglen) {
  char *kind = strtok(args, ":");
  if (strcmp(kind, "Supported") == 0) {
    return "PacketSize=1000;qXfer:features:read+";
  } else if (strcmp(kind, "MustReplyEmpty") == 0) {
    return "";
  } else if (strcmp(kind, "Xfer") == 0) {
    return gdb_xfer_handler(strtok(NULL, ":"));
  } else if (strcmp(kind, "Attached") == 0) {
    return "1";
  } else if (strcmp(kind, "fThreadInfo") == 0) {
    return "m1";
  } else if (strcmp(kind, "sThreadInfo") == 0) {
    return "l";
  } else if (strcmp(kind, "Symbol") == 0) {
    return "OK";
  } else if (strcmp(kind, "TStatus") == 0) {
    return "";
  } else {
    return NULL;
  }
}

char *gdb_vCont_handler(char *args) {
  if (strcmp(args, "?") == 0) {
    return "vCont;c;C;s;S";
  } else if (args[0] == ';') {
    char action = 0;
    int thread = 0;
    while (args) {
      args++;
      sscanf(args, "%c:%d", &action, &thread);

      switch (action) {
      case 'c': {
        int instr = dbg_vaddr_read(cpu.pc, 4);
        int ninstr = dbg_vaddr_read(cpu.pc + 4, 4);
        if (instr == 0x42000018 && ninstr == 0x0005000d) {
          printf("[NEMU] WARNING: continue at eret\n");
          cpu_exec(1);
        } else {
          cpu_exec(-1);
          cpu.pc -= 4;
        }
      } break;
      case 's': cpu_exec(1); break;
      }

      args = strchr(args, ';');
    }
    return "T05thread:01;";
  } else {
    return NULL;
  }
}

char *gdb_extend_commands(char *args, int arglen) {
  if (strcmp(args, "MustReplyEmpty") == 0) {
    return "";
  } else if (strncmp(args, "Cont", 4) == 0) {
    return gdb_vCont_handler(args + 4);
  } else if (strncmp(args, "File", 4) == 0) {
    return "";
  } else {
    return NULL;
  }
}

char *gdb_continue(char *args, int arglen) { return NULL; }

char *gdb_read_registers(char *args, int arglen) {
  static char regs[(32 + 6) * 8 + 10];
  int len = 0;
  for (int i = 0; i < 32; i++) {
    len += snprintf(&regs[len], sizeof(regs) - len, "%08x", htonl(cpu.gpr[i]));
  }
  len += snprintf(&regs[len], sizeof(regs) - len, "%08x",
      htonl(cpu.cp0.cpr[CP0_STATUS][0]));
  len += snprintf(&regs[len], sizeof(regs) - len, "%08x", htonl(cpu.lo));
  len += snprintf(&regs[len], sizeof(regs) - len, "%08x", htonl(cpu.hi));
  len += snprintf(&regs[len], sizeof(regs) - len, "%08x",
      htonl(cpu.cp0.cpr[CP0_BADVADDR][0]));
  len += snprintf(
      &regs[len], sizeof(regs) - len, "%08x", htonl(cpu.cp0.cpr[CP0_CAUSE][0]));
  len += snprintf(&regs[len], sizeof(regs) - len, "%08x", htonl(cpu.pc));
  assert(len < sizeof(regs));
  return regs;
}

char *gdb_write_registers(char *args, int arglen) { return NULL; }

char *gdb_set_thread(char *args, int arglen) { return "OK"; }

char *gdb_step(char *args, int arglen) { return NULL; }

char *gdb_read_memory(char *args, int arglen) {
  // m<addr>,len
  static char mem[4096];

  uint32_t addr = 0, size = 0;
  sscanf(args, "%x,%x", &addr, &size);

  int len = 0;
  for (int i = 0; i < size; i++) {
    int data = dbg_vaddr_read(addr + i, 1);
    len += snprintf(&mem[len], sizeof(mem) - len, "%02x", data & 0XFF);
  }
  assert(len < sizeof(mem));
  return mem;
}

char *gdb_write_memory(char *args, int arglen) {
  // M<addr>,len:<HEX>
  uint32_t addr = 0, size = 0;
  sscanf(args, "%x,%x:", &addr, &size);

  char *hex = strchr(args, ':');
  for (int i = 0; i < size; i++) {
    int data = 0;
    sscanf(hex + 1, "%02x", &data);
    dbg_vaddr_write(addr + i, 1, data);

    if (hex && (hex[1] == 0 || hex[2] == 0))
      hex = NULL;
    else
      hex += 2;
  }
  return "OK";
}

char *gdb_read_register(char *args, int arglen) {
  static char reg_value[32];

  int reg_no = 0;
  sscanf(args, "%x", &reg_no);
  if (reg_no < 32) {
    snprintf(reg_value, sizeof(reg_value), "%08x", htonl(cpu.gpr[reg_no]));
  } else {
    int value = 0;
    switch (reg_no) {
    case 0x20: value = 0; break;
    case 0x21: value = cpu.lo; break;
    case 0x22: value = cpu.hi; break;
    case 0x23: value = cpu.cp0.cpr[CP0_BADVADDR][0]; break;
    case 0x24: value = cpu.cp0.cpr[CP0_CAUSE][0]; break;
    case 0x25: value = cpu.pc; break;
    case 0x26: value = cpu.cp0.cpr[CP0_EPC][0]; break;
    default: value = 0; break;
    }
    snprintf(reg_value, sizeof(reg_value), "%08x", htonl(value));
  }
  return reg_value;
}

char *gdb_write_register(char *args, int arglen) { return NULL; }

char *gdb_reset(char *args, int arglen) { return NULL; }

char *gdb_single_step(char *args, int arglen) { return NULL; }

char *gdb_detach(char *args, int arglen) { return "OK"; }

char *gdb_write_memory_hex(char *args, int arglen) {
  // X<addr>,len:<BIN>
  uint32_t addr = 0, size = 0;
  sscanf(args, "%x,%x:", &addr, &size);

  char *hex = strchr(args, ':');
  printf("write memory hex:%08x: '", addr);
  for (char *p = hex + 1; p < args + arglen; p++) printf("%02hhx ", *p);
  printf("'\n");

  for (int i = 0; i < size; i++) {
    dbg_vaddr_write(addr + i, 1, hex[1]);

    if (hex > args + arglen)
      break;
    else
      hex += 1;
  }
  return "OK";
}

#define NR_BREAK_POINTS 32

struct break_point_t {
  bool used;
  uint32_t addr;
  uint32_t value;
} break_points[NR_BREAK_POINTS];

char *gdb_remove_break_point(char *args, int arglen) {
  int type = 0, addr = 0, kind = 0;
  sscanf(args, "%x,%x,%x", &type, &addr, &kind);
  // let gdb to maintain the breakpoints, :)
  for (int i = 0; i < NR_BREAK_POINTS; i++) {
    if (break_points[i].used && break_points[i].addr == addr) {
      break_points[i].used = false;
      dbg_vaddr_write(addr, 4, break_points[i].value);
      return "OK";
    }
  }
  return "";
}

char *gdb_insert_break_point(char *args, int arglen) {
  int type = 0, addr = 0, kind = 0;
  sscanf(args, "%x,%x,%x", &type, &addr, &kind);
  // let gdb to maintain the breakpoints, :)
  for (int i = 0; i < NR_BREAK_POINTS; i++) {
    if (!break_points[i].used) {
      break_points[i].addr = addr;
      break_points[i].value = dbg_vaddr_read(addr, 4);
      dbg_vaddr_write(addr, 4, 0x0005000d);
      break_points[i].used = true;
      return "OK";
    }
  }
  return "";
}

static gdb_cmd_handler_t handlers[128] = {
    ['?'] = gdb_question,
    ['c'] = gdb_continue,
    ['g'] = gdb_read_registers,
    ['G'] = gdb_write_registers,
    ['H'] = gdb_set_thread,
    ['i'] = gdb_step,
    ['m'] = gdb_read_memory,
    ['M'] = gdb_write_memory,
    ['D'] = gdb_detach,
    ['p'] = gdb_read_register,
    ['P'] = gdb_write_register,
    ['q'] = gdb_general_query,
    ['r'] = gdb_reset,
    ['R'] = gdb_reset,
    ['s'] = gdb_single_step,
    ['v'] = gdb_extend_commands,
    ['X'] = gdb_write_memory_hex,
    ['z'] = gdb_remove_break_point,
    ['Z'] = gdb_insert_break_point,
};

void gdb_server_mainloop(int servfd) {
  struct gdb_conn *conn = gdb_begin_server(servfd);
  while (1) {
    size_t size = 0;
    char *data = (void *)gdb_recv(conn, &size);

    gdb_cmd_handler_t handler = handlers[(int)data[0]];
    if (handler) {
      char *resp = handler(&data[1], size);
      // printf("[NEMU] Client request '%s'\n", data);
      if (resp) {
        // printf("[NEMU] Server response '%s'\n", resp);
        gdb_send(conn, (void *)resp, strlen(resp));
      } else {
        gdb_send(conn, (void *)"", 0);
      }
      free(data);
    } else {
      printf("[NEMU] WARNING: Unsupport conn request '%s'\n", data);
      gdb_send(conn, (void *)"", 0);
      free(data);
    }
  }
  free(conn);
}
