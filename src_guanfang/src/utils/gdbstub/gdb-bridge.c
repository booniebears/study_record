#include <arpa/inet.h>
#include <assert.h>
#include <malloc.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/signal.h>
#include <unistd.h>

#include "debug.h"
#include "utils/gdb-proto.h"

extern char *symbol_file;

void init_sdl();
void gdb_server_mainloop(int port);

int start_gdb(int port) {
  char symbol_s[100], remote_s[100];
  const char *exec = "gdb-multiarch";

  snprintf(symbol_s, sizeof(symbol_s), "symbol %s", symbol_file);
  snprintf(remote_s, sizeof(remote_s), "target remote 127.0.0.1:%d", port);
  execlp(exec, exec, "-ex", "set arch mips",
	  "-ex", symbol_s, "-ex", remote_s, NULL);

  return -1;
}

void start_bridge(int port, int serv_port) {
  struct gdb_conn *client = gdb_server_start(port);
  struct gdb_conn *server = gdb_begin_inet("127.0.0.1", serv_port);

  size_t size = 0;
  char *data = NULL;
  while(1) {
	data = (void*)gdb_recv(client, &size);
	printf("$ message: client --> server:%lx:\n", size);
	printf("'%s'\n", data);
	printf("\n");
	gdb_send(server, (void*)data, size);
	free(data);

	data = (void*)gdb_recv(server, &size);
	printf("$ message: server --> client:%lx:\n", size);
	printf("'%s'\n", data);
	gdb_send(client, (void*)data, size);
	printf("\n\n");
	free(data);
  }
}

int get_free_servfd() {
  // fill the socket information
  struct sockaddr_in sa = {
    .sin_family = AF_INET,
    .sin_port = 0,
	.sin_addr.s_addr = htonl(INADDR_ANY),
  };

  // open the socket and start the tcp connection
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  if(bind(fd, (const struct sockaddr *)&sa, sizeof(sa)) != 0) {
	close(fd);
	panic("bind");
  }
  return fd;
}

int get_port_of_servfd(int fd) {
  struct sockaddr_in serv_addr;
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = 0;

  socklen_t len = sizeof(serv_addr);
  if (getsockname(fd, (struct sockaddr *)&serv_addr, &len) == -1) {
	  perror("getsockname");
	  return -1;
  }
  return ntohs(serv_addr.sin_port);
}

void gdb_mainloop() {
  int servfd = get_free_servfd();
  int port = get_port_of_servfd(servfd);

  int pid = fork();
  if(pid == 0) {
	init_sdl();
	gdb_server_mainloop(servfd);
  } else {
    close(servfd);
	usleep(20000);
	if(start_gdb(port) < 0) {
	  kill(pid, SIGKILL);
	}
	panic("Please install `gdb-multiarch' firstly\n");
  }
}

