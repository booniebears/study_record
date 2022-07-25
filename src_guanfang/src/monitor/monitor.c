#include <elf.h>
#include <getopt.h>
#include <signal.h>
#include <stdlib.h>

#include "cpu/memory.h"
#include "device.h"
#include "monitor.h"
#include "utils/console.h"
#include "utils/elfsym.h"
#include "utils/file.h"

elfsym_t elfsym;
const char *elf_file = NULL;
const char *symbol_file = NULL;
const char *boot_cmdline = "";
static char *img_file = NULL;
// static char *kernel_img = NULL;

vaddr_t elf_entry = CPU_INIT_PC;
work_mode_t work_mode = MODE_GDB;

void load_rom(uint32_t entry) {
  uint32_t *p = vaddr_map(CPU_INIT_PC, 16);
  assert(p);
  p[0] = 0x3c080000 | (entry >> 16); // lui t0, %hi(entry)
  p[1] = 0x35080000 |
         (entry & 0xFFFF); // ori t0, t0, %lo(entry)
  p[2] = 0x01000008;       // jr t0
  p[3] = 0x00000000;       // nop
}

void load_elf() {
  Assert(elf_file, "Need an elf file");

  /* set symbol file to elf_file */
  const uint32_t elf_magic = 0x464c457f;

  int size = get_file_size(elf_file);
  void *buf = read_file(elf_file);
  Assert(buf, "file '%s' cannot be opened for read\n",
      elf_file);

  Elf32_Ehdr *elf = buf;

  elf_entry = elf->e_entry;

  uint32_t *p_magic = buf;
  Assert(*p_magic == elf_magic, "wrong file format");
  Assert(elf->e_ident[EI_CLASS] == ELFCLASS32,
      "not a 32-bit elf file");
  Assert(elf->e_ident[EI_DATA] == ELFDATA2LSB,
      "not a little endian elf file");
  Assert(elf->e_machine == EM_MIPS, "not a mips elf file");

  for (int i = 0; i < elf->e_phnum; i++) {
    int phdr_off = i * elf->e_phentsize + elf->e_phoff;
    Elf32_Phdr *ph = (void *)buf + phdr_off;
    Assert(phdr_off < size, "ELF32_Phdr out of file");
    Assert(ph->p_offset < size, "ELF32_Ph out of file");
    if (ph->p_type != PT_LOAD) { continue; }

    void *ptr = vaddr_map(ph->p_vaddr, ph->p_memsz);
    memcpy(ptr, buf + ph->p_offset, ph->p_filesz);
    memset(
        ptr + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
  }

  if (elf->e_entry != CPU_INIT_PC) load_rom(elf->e_entry);

  free(buf);
}

static inline void load_image(
    const char *img, vaddr_t vaddr) {
  Assert(img, "Need an image file");
  Log("The image is %s\n", img);

  size_t size = get_file_size(img);
  void *buf = read_file(img);
  void *ptr = vaddr_map(vaddr, size);
  memcpy(ptr, buf, size);
  free(buf);
}

static inline void assume_elf_file() {
  /* assume img_file is xxx.bin and elf_file is xxx */
  char *end = strrchr(img_file, '.');
  if (end) {
    *end = 0;
    elf_file = img_file;
  }
}

enum {
  OPT_BEG = 128,
  OPT_BLOCK_DATA,
  OPT_BLKIO_FILE,
  OPT_FIFO_DATA,
  OPT_DIFF_TEST,
  OPT_BOOT_CMDLINE,
  OPT_PRINT_DEVICES,
};

const struct option long_options[] = {
    {"batch", 0, NULL, 'b'},
    {"commit", 0, NULL, 'c'},
    // {"diff-with-qemu", 0, NULL, 'D'},
    {"elf", 1, NULL, 'e'},
    {"image", 1, NULL, 'i'},
    {"symbol", 1, NULL, 'S'},
    {"help", 0, NULL, 'h'},
    /* ------------------ */
    {"block-data", 1, NULL, OPT_BLOCK_DATA},
    {"blkio-file", 1, NULL, OPT_BLKIO_FILE},
    {"fifo-data", 1, NULL, OPT_FIFO_DATA},
    {"diff-test", 0, NULL, OPT_DIFF_TEST},
    {"cmdline", 1, NULL, OPT_BOOT_CMDLINE},
    {"print-devices", 0, NULL, OPT_PRINT_DEVICES},
    {NULL, 0, NULL, 0},
};

static void print_help(const char *file) {
  printf("Usage: %s [OPTION...]\n", file);
  printf(
      "\n\
  -b, --batch                run with batch mode\n\
  -c, --commit               commit all executed instructions\n\
  -e, --elf=FILE             run with this elf file\n\
  -i, --image=FILE           run with this image file\n\
  -S, --symbol=FILE          file to provide symbols, default elf\n\
  --blkio-file dev:FILE      map given file to corresponding device\n\
  --block-data dev:addr:FILE initialize block dev data with FILE\n\
  --fifo-data dev:FILE       initialize fifo dev data with FILE\n\
  --diff-test                differential testing with QEMU\n\
  --cmdline                  pass cmdline to linux kernel\n\
  --print-devices            print available devices\n\
  \n\
  -h, --help                 print program help info\n\
\n\
Report bugs to ouxianfei@smail.nju.edu.cn.\n");
}

void parse_fifo_data_option(const char *optarg) {
  for (device_t *head = get_device_list_head(); head;
       head = head->next) {
    int len = strlen(head->name);
    if (memcmp(head->name, optarg, len) != 0) continue;
    if (optarg[len] != ':' || !head->set_fifo_data)
      continue;

    const char *file = &optarg[len + 1];
    int filesz = get_file_size(file);
    void *buf = read_file(file);
    head->set_fifo_data(buf, filesz);
    free(buf);
    return;
  }

  char *dup_s = strdup(optarg);
  char *delim = strchr(dup_s, ':');
  if (delim) *delim = '\0';
  panic("device '%s' not found\n", dup_s);
  free(dup_s);
}

void parse_block_data_option(const char *optarg) {
  for (device_t *head = get_device_list_head(); head;
       head = head->next) {
    int len = strlen(head->name);
    if (memcmp(head->name, optarg, len) != 0) continue;
    if (optarg[len] != ':' || !head->set_block_data)
      continue;

    const char *addr_s = &optarg[len + 1];
    char *file_s = NULL;

    uint32_t addr = 0;
    if (addr_s[0] == '0') {
      if (addr_s[1] == 'x' || addr_s[1] == 'X')
        addr = strtol(addr_s, &file_s, 16);
      else
        addr = strtol(addr_s, &file_s, 8);
    } else {
      addr = strtol(addr_s, &file_s, 10);
    }

    if (file_s[0] == ':') {
      const char *file = &file_s[1];
      int filesz = get_file_size(file);
      void *buf = read_file(file);
      if (!buf) panic("file %s not found\n", file);
      if (head->size <= addr || head->size <= addr + filesz)
        panic(
            "addr %08x in option %s is out of device "
            "bound\n",
            addr, optarg);
      head->set_block_data(addr, buf, filesz);
      free(buf);
    } else {
      panic("file not specified in %s\n", optarg);
    }
    return;
  }

  char *dup_s = strdup(optarg);
  char *delim = strchr(dup_s, ':');
  if (delim) *delim = '\0';
  panic("device '%s' not found\n", dup_s);
  free(dup_s);
}

void parse_blkio_file_option(const char *optarg) {
  for (device_t *head = get_device_list_head(); head;
       head = head->next) {
    int len = strlen(head->name);
    if (memcmp(head->name, optarg, len) != 0) continue;
    if (optarg[len] != ':' || !head->set_blkio_file)
      continue;

    const char *file = &optarg[len + 1];
    head->set_blkio_file(file);
    return;
  }

  char *dup_s = strdup(optarg);
  char *delim = strchr(dup_s, ':');
  if (delim) *delim = '\0';
  panic("device '%s' not found\n", dup_s);
  free(dup_s);
}

void parse_args(int argc, char *argv[]) {
  int o;
  while ((o = getopt_long(argc, argv, "-bcde:i:s:h",
              long_options, NULL)) != -1) {
    switch (o) {
    case 's': symbol_file = optarg; break;
    case 'b': work_mode |= MODE_BATCH; break;
    case 'c': work_mode |= MODE_LOG; break;
    case 'e':
      if (elf_file != NULL)
        Log("too much argument '%s', ignored", optarg);
      else
        elf_file = optarg;
      break;
    case 'i':
      if (img_file != NULL)
        Log("too much argument '%s', ignored", optarg);
      else
        img_file = optarg;
      break;
    case OPT_BLOCK_DATA:
      parse_block_data_option(optarg);
      break;
    case OPT_BLKIO_FILE:
      parse_blkio_file_option(optarg);
      break;
    case OPT_FIFO_DATA:
      parse_fifo_data_option(optarg);
      break;
#if CONFIG_DIFF_WITH_QEMU
    case OPT_DIFF_TEST: work_mode |= MODE_DIFF; break;
#endif
    case OPT_BOOT_CMDLINE: boot_cmdline = optarg; break;
    case OPT_PRINT_DEVICES:
      for (const device_t *dev = get_device_list_head();
           dev; dev = dev->next) {
        printf(
            "name: %15s, addr space: [0x%08x, 0x%08x] "
            "%s%s%s%s%s%s%s%s\n",
            dev->name, dev->start,
            dev->start + dev->size, dev->read ? "+R" : "",
            dev->write ? "+W" : "", dev->map ? "+M" : "",
            dev->peek ? "+P" : "",
            dev->set_fifo_data ? "+Sf" : "",
            dev->set_block_data ? "+Sb" : "",
            dev->set_blkio_file ? "+Bf" : "",
            dev->update_irq ? "+Uirq" : "");
      }
      exit(0);
      break;
    case 'h':
    default: print_help(argv[0]); exit(0);
    }
  }

  if (!symbol_file) symbol_file = elf_file;
}

static void gdb_sigint_handler(int sig) {
  nemu_state = NEMU_STOP;
}

work_mode_t init_monitor(void) {
  /* Load the image to memory. */
  if (elf_file) {
    load_elf();
  } else {
    load_image(img_file, CPU_INIT_PC);
  }

  if (symbol_file) elfsym_load(&elfsym, symbol_file);

#if CONFIG_ELF_PERF
  elfperf_start();
#endif

  if (!(work_mode & MODE_BATCH))
    signal(SIGINT, gdb_sigint_handler);

  /* Initialize this virtual computer system. */
  init_cpu(CPU_INIT_PC);

  return work_mode;
}
