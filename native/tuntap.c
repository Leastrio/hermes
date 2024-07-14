#include "erl_nif.h"
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/if.h>
#include <linux/if_tun.h>
#include <fcntl.h>
#include <unistd.h>

typedef struct {
  int fd;
} fd_t;

ErlNifResourceType *FD_RES_TYPE;

int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  FD_RES_TYPE = enif_open_resource_type(env, NULL, "fd", NULL, ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER, NULL);
  return 0;
}

static ERL_NIF_TERM tuntap_init(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  int fd;
  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));

  if ((fd = open("/dev/net/tun", O_RDWR)) < 0) {
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "open"));
  }

  ifr.ifr_flags = IFF_TAP | IFF_NO_PI;
  if (ioctl(fd, TUNSETIFF, &ifr) < 0) {
    perror("IOCTL ERROR");
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "ioctl"));
  }

  fd_t *fd_res = enif_alloc_resource(FD_RES_TYPE, sizeof(fd_t));
  fd_res->fd = fd;
  ERL_NIF_TERM term = enif_make_resource(env, fd_res);

  enif_select_read(env, fd, fd_res, NULL, enif_make_atom(env, "read_ready"), NULL);

  return enif_make_tuple3(env, enif_make_atom(env, "ok"), term, enif_make_string(env, ifr.ifr_name, ERL_NIF_LATIN1));
}

static ERL_NIF_TERM read_tap(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  fd_t *fd_res;
  char *buf[1518];
  ErlNifBinary bin;
  ssize_t bytes_read;

  if (!enif_get_resource(env, argv[0], FD_RES_TYPE, (void *) &fd_res)) {
    return enif_make_badarg(env);
  }

  if ((bytes_read = read(fd_res->fd, buf, 1518)) < 0) {
    perror("READ ERROR");
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "read"));
  }

  enif_alloc_binary(bytes_read, &bin);
  memcpy(bin.data, buf, bytes_read);

  enif_select_read(env, fd_res->fd, fd_res, NULL, enif_make_atom(env, "read_ready"), NULL);

  return enif_make_binary(env, &bin);
}

static ERL_NIF_TERM write_tap(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  fd_t *fd_res;
  ErlNifBinary bin;

  if (!enif_get_resource(env, argv[0], FD_RES_TYPE, (void *) &fd_res)) {
    return enif_make_badarg(env);
  }

  if (!enif_inspect_binary(env, argv[1], &bin)) {
    return enif_make_badarg(env);
  }

  if (write(fd_res->fd, bin.data, bin.size) < 0) {
    perror("WRITE ERROR");
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "write"));
  }

  return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] = {
  {"tuntap_init", 0, tuntap_init},
  {"read_tap", 1, read_tap, ERL_NIF_DIRTY_JOB_IO_BOUND},
  {"write_tap", 2, write_tap, ERL_NIF_DIRTY_JOB_IO_BOUND}
};

ERL_NIF_INIT(Elixir.Hermes.Native, nif_funcs, load, NULL, NULL, NULL);
