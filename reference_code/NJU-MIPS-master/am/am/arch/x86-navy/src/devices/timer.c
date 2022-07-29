#include <am.h>
#include <amdev.h>
#include <ndl.h>

uint32_t curTime;

size_t timer_read(uintptr_t reg, void *buf, size_t size) {
  switch (reg) {
    case _DEVREG_TIMER_UPTIME: {
      _UptimeReg *uptime = (_UptimeReg *)buf;
      NDL_Event event;
      NDL_WaitEvent(&event);
      if (event.type == NDL_EVENT_TIMER){
        uptime->lo = event.data;
        curTime = event.data;
       }else {
        uptime->lo = curTime;
       }
      return sizeof(_UptimeReg);
    }
    case _DEVREG_TIMER_DATE: {
      _RTCReg *rtc = (_RTCReg *)buf;
      rtc->second = 0;
      rtc->minute = 0;
      rtc->hour   = 0;
      rtc->day    = 0;
      rtc->month  = 0;
      rtc->year   = 2018;
      return sizeof(_RTCReg);
    }
  }
  return 0;
}

void timer_init() {
}
