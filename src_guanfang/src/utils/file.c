#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

size_t get_file_size(const char *img_file) {
  struct stat file_status;
  lstat(img_file, &file_status);
  if (S_ISLNK(file_status.st_mode)) {
    char *buf = malloc(file_status.st_size + 1);
    size_t size = readlink(img_file, buf, file_status.st_size);
    (void)size;
    buf[file_status.st_size] = 0;
    size = get_file_size(buf);
    free(buf);
    return size;
  } else {
    return file_status.st_size;
  }
}

void *read_file(const char *filename) {
  size_t size = get_file_size(filename);
  int fd = open(filename, O_RDONLY);
  if (fd == -1) return NULL;

  // malloc buf which should be freed by caller
  void *buf = malloc(size);
  int len = 0;
  while (len < size) { len += read(fd, buf, size - len); }
  close(fd);
  return buf;
}

ssize_t write_s(int fd, const void *buf, size_t count) {
  size_t off = 0;
  while (off < count) {
    int ret = write(fd, buf + off, count - off);
    if (ret < 0) return -1;
    off += ret;
  }
  return count;
}

ssize_t read_s(int fd, void *buf, size_t count) {
  size_t off = 0;
  while (off < count) {
    int ret = read(fd, buf + off, count - off);
    if (ret < 0) return -1;
    off += ret;
  }
  return count;
}
