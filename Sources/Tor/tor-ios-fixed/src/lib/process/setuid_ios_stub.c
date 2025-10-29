/* iOS stub для setuid.c - iOS sandbox не позволяет смену uid/gid */
#ifdef __APPLE__
#include <stdio.h>
#include <errno.h>

#include "lib/process/setuid.h"
#include "lib/log/log.h"

void
log_credential_status(void)
{
  log_info(LD_GENERAL, "iOS: Running in app sandbox, uid/gid management not available");
}

int
switch_id(const char *user, unsigned flags)
{
  (void)user;
  (void)flags;
  log_warn(LD_GENERAL, "iOS: switch_id() not supported in iOS sandbox");
  return -1;
}

#ifdef HAVE_PWD_H
const struct passwd *
tor_getpwnam(const char *username)
{
  (void)username;
  errno = ENOSYS;
  return NULL;
}

const struct passwd *
tor_getpwuid(uid_t uid)
{
  (void)uid;
  errno = ENOSYS;
  return NULL;
}
#endif

#endif /* __APPLE__ */
