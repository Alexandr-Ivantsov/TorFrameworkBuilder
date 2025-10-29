/* Реализация curved25519_scalarmult_basepoint_donna для iOS */
/* Эта функция декларирована но не определена в Tor исходниках */

#include "ext/ed25519/donna/ed25519_donna_tor.h"

/* Basepoint for curve25519 */
static const unsigned char curve25519_basepoint[32] = {9};

/* Объявление curve25519_donna из curve25519-donna.c */
extern int curve25519_donna(unsigned char *mypublic,
                            const unsigned char *secret,
                            const unsigned char *basepoint);

/* Wrapper к curve25519 scalar multiplication с basepoint */
void
curved25519_scalarmult_basepoint_donna(curved25519_key pk,
                                       const curved25519_key e)
{
  /* Используем curve25519_donna напрямую */
  /* Это медленнее чем ed25519-optimized версия, но работает */
  curve25519_donna(pk, e, curve25519_basepoint);
}
