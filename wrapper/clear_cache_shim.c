#include <libkern/OSCacheControl.h>
#include <stdint.h>

void __clear_cache(void *start, void *end)
{
  uintptr_t begin = (uintptr_t)start;
  uintptr_t finish = (uintptr_t)end;
  if (finish > begin) {
    sys_icache_invalidate(start, finish - begin);
  }
}

