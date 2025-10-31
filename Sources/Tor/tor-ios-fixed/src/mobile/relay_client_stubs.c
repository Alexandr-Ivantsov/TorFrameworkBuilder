#include "orconfig.h"

#include "core/or/or.h"
#include "feature/relay/router.h"
#include "feature/nodelist/routerinfo_st.h"
#include "feature/nodelist/extrainfo_st.h"
#include "feature/nodelist/authority_cert_st.h"
#include "lib/crypt_ops/crypto_rsa.h"
#include "lib/net/address.h"
#include "lib/ctime/di_ops.h"

#include <string.h>

/*
 * Minimal stub implementations to satisfy linker dependencies for
 * relay/dirauth-only functions when building the mobile (client-only)
 * Tor binaries. None of these entry points should be reached at runtime
 * in the mobile configuration; they either return neutral defaults or
 * no-op.
 */

MOCK_IMPL(authority_cert_t *, get_my_v3_authority_cert, (void))
{
  return NULL;
}

authority_cert_t *
get_my_v3_legacy_cert(void)
{
  return NULL;
}

crypto_pk_t *
get_tlsclient_identity_key(void)
{
  return NULL;
}

int
client_identity_key_is_set(void)
{
  return 0;
}

int
server_identity_key_is_set(void)
{
  return 0;
}

int
init_keys(void)
{
  return 0;
}

int
init_keys_client(void)
{
  return 0;
}

void
mark_my_descriptor_dirty(const char *reason)
{
  (void)reason;
}

void
ntor_key_map_free_(di_digest256_map_t *map)
{
  if (map) {
    dimap_free_(map, NULL);
  }
}

void
onion_pending_add(const origin_circuit_t *circ)
{
  (void)circ;
}

void
onion_pending_remove(const origin_circuit_t *circ)
{
  (void)circ;
}

void
onion_consensus_has_changed(const networkstatus_t *ns)
{
  (void)ns;
}

void
onion_next_task(void)
{
}

void
relay_address_new_suggestion(const tor_addr_t *addr, uint16_t port, int flags)
{
  (void)addr;
  (void)port;
  (void)flags;
}

char *
relay_find_addr_to_publish(const tor_addr_port_t *addr_port, int family)
{
  (void)addr_port;
  (void)family;
  return NULL;
}

int
router_compare_to_my_exit_policy(const tor_addr_t *addr, uint16_t port)
{
  (void)addr;
  (void)port;
  return 0;
}

int
router_digest_is_me(const char *digest)
{
  (void)digest;
  return 0;
}

int
router_extrainfo_digest_is_me(const char *digest)
{
  (void)digest;
  return 0;
}

char *
router_dump_exit_policy_to_string(const routerinfo_t *router, int include_ipv4,
                                  int include_ipv6)
{
  (void)router;
  (void)include_ipv4;
  (void)include_ipv6;
  return NULL;
}

uint16_t
router_get_active_listener_port_by_type_af(int listener_type, sa_family_t family)
{
  (void)listener_type;
  (void)family;
  return 0;
}

const char *
router_get_descriptor_gen_reason(void)
{
  return "";
}

MOCK_IMPL(const routerinfo_t *, router_get_my_routerinfo, (void))
{
  return NULL;
}

MOCK_IMPL(const routerinfo_t *, router_get_my_routerinfo_with_err, (int *err))
{
  if (err) {
    *err = TOR_ROUTERINFO_ERROR_NOT_A_SERVER;
  }
  return NULL;
}

extrainfo_t *
router_get_my_extrainfo(void)
{
  return NULL;
}

crypto_pk_t *
router_get_rsa_onion_pkey(const char *pkey, size_t len)
{
  (void)pkey;
  (void)len;
  return NULL;
}

int
router_initialize_tls_context(void)
{
  return 0;
}

int
router_is_me(const routerinfo_t *router)
{
  (void)router;
  return 0;
}

MOCK_IMPL(int, router_my_exit_policy_is_reject_star, (void))
{
  return 1;
}

void
router_new_consensus_params(const networkstatus_t *ns)
{
  (void)ns;
}

void
router_reset_warnings(void)
{
}

uint16_t
routerconf_find_or_port(const or_options_t *options, sa_family_t family)
{
  (void)options;
  (void)family;
  return 0;
}

uint16_t
routerconf_find_dir_port(const or_options_t *options, uint16_t dirport)
{
  (void)options;
  (void)dirport;
  return 0;
}

int
routerinfo_err_is_transient(int err)
{
  (void)err;
  return 0;
}

const char *
routerinfo_err_to_string(int err)
{
  (void)err;
  return "";
}

int
should_refuse_unknown_exits(const or_options_t *options)
{
  (void)options;
  return 0;
}

char *
tor_getpass(const char *prompt)
{
  (void)prompt;
  return NULL;
}

int
server_mode(const or_options_t *options)
{
  (void)options;
  return 0;
}

int
public_server_mode(const or_options_t *options)
{
  (void)options;
  return 0;
}

int
advertised_server_mode(void)
{
  return 0;
}

void
set_server_advertised(int s)
{
  (void)s;
}

