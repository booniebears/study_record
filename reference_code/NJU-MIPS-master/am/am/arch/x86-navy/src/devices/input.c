#include <am.h>
#include <amdev.h>
#include <ndl.h>

size_t input_read(uintptr_t reg, void *buf, size_t size){
  switch (reg) {
    case _DEVREG_INPUT_KBD:{
      _KbdReg *kbd = (_KbdReg *)buf;
      NDL_Event event;
      NDL_WaitEvent(&event);
      switch(event.type){
        case NDL_EVENT_KEYDOWN: kbd->keydown = 1; kbd->keycode = event.data; break;
        case NDL_EVENT_KEYUP: kbd->keydown = 0; kbd->keycode = event.data; break;
        default: kbd->keycode = _KEY_NONE;
      }
      return sizeof(_KbdReg);
    }
  }
  return 0;
}



