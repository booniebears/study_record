#ifndef IMPL_CPU
#  error "this file can only be included by cpu.c"
#endif

#if CONFIG_DECODE_CACHE_PERF
uint64_t decode_cache_fast_hit = 0;
uint64_t decode_cache_hit = 0;
uint64_t decode_cache_miss = 0;
#endif

#define DECODE_CACHE_BITS 12

static decode_state_t decode_cache[1 << DECODE_CACHE_BITS];

void clear_decode_cache() {
  for (int i = 0;
       i < sizeof(decode_cache) / sizeof(*decode_cache);
       i++) {
    decode_cache[i].handler = NULL;
    decode_cache[i].next = NULL;
  }
}

static ALWAYS_INLINE uint32_t decode_cache_index(
    vaddr_t vaddr) {
  return (vaddr >> 2) & ((1 << DECODE_CACHE_BITS) - 1);
}

void free_decode_state_chain(decode_state_t *ds) {
  while (ds) {
    decode_state_t *next = ds->next;
    free(ds);
    ds = next;
  }
}

static ALWAYS_INLINE decode_state_t *decode_cache_get(
    vaddr_t pc) {
  return &decode_cache[decode_cache_index(pc)];
}

static ALWAYS_INLINE decode_state_t *decode_cache_fetch(
    vaddr_t pc) {
  uint32_t idx = decode_cache_index(pc);
  if (decode_cache[idx].pc != pc) {
    free_decode_state_chain(decode_cache[idx].next);

    decode_cache[idx].handler = NULL;
    decode_cache[idx].next = NULL;
    decode_cache[idx].pc = pc;
  }
  return &decode_cache[idx];
}
