#include <am.h>
#include <amdev.h>
#include <ndl.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

static int screen_h, screen_w;
size_t video_read(uintptr_t reg, void *buf, size_t size) {
  switch (reg) {
    case _DEVREG_VIDEO_INFO: {
      _VideoInfoReg *info = (_VideoInfoReg *)buf;

    FILE *dispinfo = fopen("/proc/dispinfo", "r");
    assert(dispinfo);
    screen_w = screen_h = 0;
    char buf[128], key[128], value[128], *delim;
    while (fgets(buf, 128, dispinfo)) {
      *(delim = strchr(buf, ':')) = '\0';
      sscanf(buf, "%s", key);
      sscanf(delim + 1, "%s", value);
      if (strcmp(key, "WIDTH") == 0) sscanf(value, "%d", &info->width);
      if (strcmp(key, "HEIGHT") == 0) sscanf(value, "%d", &info->height);
    }
    fclose(dispinfo);
    assert(info->width > 0 && info->height > 0);

    return sizeof(_VideoInfoReg);
    }
  }
  return 0;
}

size_t video_write(uintptr_t reg, void *buf, size_t size) {
  switch (reg) {
    case _DEVREG_VIDEO_FBCTL: {
      _FBCtlReg *ctl = (_FBCtlReg *)buf;
      NDL_DrawRect(ctl->pixels, ctl->x, ctl->y, ctl->w, ctl->h);
      /*
	  for (int i=0;i<ctl->h;++i)
	    for (int j=0;j<ctl->w;++j){
	      fb[(i+ctl->y)*w+j+ctl->x] = ctl->pixels[i*ctl->w+j];
	    }
      */
      if (ctl->sync) {
        // do nothing, hardware syncs.
      }
      NDL_Render();
      return sizeof(_FBCtlReg);
    }
  }
  return 0;
}

void vga_init() {
    FILE *dispinfo = fopen("/proc/dispinfo", "r");
    assert(dispinfo);
    screen_w = screen_h = 0;
    char buf[128], key[128], value[128], *delim;
    while (fgets(buf, 128, dispinfo)) {
      *(delim = strchr(buf, ':')) = '\0';
      sscanf(buf, "%s", key);
      sscanf(delim + 1, "%s", value);
      if (strcmp(key, "WIDTH") == 0) sscanf(value, "%d", &screen_w);
      if (strcmp(key, "HEIGHT") == 0) sscanf(value, "%d", &screen_h);
    }
    fclose(dispinfo);
    assert(screen_w > 0 && screen_h > 0);
  NDL_OpenDisplay(screen_w, screen_h);
}
