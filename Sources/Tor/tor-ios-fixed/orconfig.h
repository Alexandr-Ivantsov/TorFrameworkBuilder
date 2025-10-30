/* orconfig.h - iOS-specific configuration for Tor */
/* Manually created for Swift Package Manager cross-compilation */

#ifndef ORCONFIG_H
#define ORCONFIG_H

/* ========================================
 * BASIC FEATURE DEFINES
 * ======================================== */

#define HAVE_CONFIG_H 1
#define RSHIFT_DOES_SIGN_EXTEND 1
#define FLEXIBLE_ARRAY_MEMBER /**/
#define SIZE_T_CEILING SIZE_MAX
#define TOR_UNIT_TESTS 0

/* ========================================
 * PLATFORM DEFINES
 * ======================================== */

#define __APPLE_USE_RFC_3542 1
#define _DARWIN_C_SOURCE 1
#define _POSIX_C_SOURCE 200112L
#define __USE_GNU 1

/* ========================================
 * STANDARD HEADERS
 * ======================================== */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <limits.h>
#include <sys/types.h>
#include <inttypes.h>

/* ========================================
 * TIME/SIZE FORMAT MACROS
 * ======================================== */

#define TIME_MAX ((time_t)INT64_MAX)
#define TIME_MIN ((time_t)INT64_MIN)
#define TOR_PRIuSZ "zu"
#define TOR_PRIdSZ "zd"
#define TOR_PRIuMAX PRIuMAX
#define TOR_PRIdMAX PRIdMAX

/* ========================================
 * STRUCT AVAILABILITY
 * ======================================== */

#define HAVE_STRUCT_TIMEVAL 1
#define HAVE_STRUCT_TIMEVAL_TV_SEC 1
#define HAVE_STRUCT_TIMEVAL_TV_USEC 1
#define HAVE_STRUCT_IN6_ADDR 1
#define HAVE_STRUCT_SOCKADDR_IN6 1
#define HAVE_SA_FAMILY_T 1
#define HAVE_SOCKADDR_SA_LEN 1
#define HAVE_NETINET_IN_H 1
#define HAVE_NETINET6_IN_H 1

/* ========================================
 * FUNCTION AVAILABILITY (iOS has most POSIX)
 * ======================================== */

#define HAVE_ACCEPT4 1
#define HAVE_BACKTRACE 1
#define HAVE_BACKTRACE_SYMBOLS_FD 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_DLADDR 1
#define HAVE_EVENTFD 0  /* Not on macOS/iOS */
#define HAVE_FLOCK 1
#define HAVE_FTIME 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETENTROPY 1
#define HAVE_GETIFADDRS 1
#define HAVE_GETNAMEINFO 1
#define HAVE_GETPASS 0  /* Deprecated */
#define HAVE_GETRLIMIT 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_GMTIME_R 1
#define HAVE_GNU_LIBC_VERSION_H 0  /* Not on iOS */
#define HAVE_INET_ATON 1
#define HAVE_INET_NTOP 1
#define HAVE_INET_PTON 1
#define HAVE_ISSETUGID 1
#define HAVE_LOCALTIME_R 1
#define HAVE_LROUND 1
#define HAVE_MACH_APPROXIMATE_TIME 1  /* iOS/macOS specific */
#define HAVE_MADVISE 1
#define HAVE_MALLOC_GOOD_SIZE 1
#define HAVE_MALLOC_USABLE_SIZE 0
#define HAVE_MEMMEM 1
#define HAVE_MINHERIT 1
#define HAVE_MLOCK 1
#define HAVE_MLOCKALL 0  /* Not available on iOS */
#define HAVE_PIPE 1
#define HAVE_PIPE2 0
#define HAVE_PRCTL 0  /* Linux-specific */
#define HAVE_PTHREAD_CONDATTR_SETCLOCK 0  /* Not on iOS */
#define HAVE_PWRITE 1
#define HAVE_READPASSPHRASE_H 0
#define HAVE_RINT 1
#define HAVE_SIGACTION 1
#define HAVE_SOCKETPAIR 1
#define HAVE_STATVFS 1
#define HAVE_STRLCAT 1
#define HAVE_STRLCPY 1
#define HAVE_STRPTIME 1
#define HAVE_STRTOK_R 1
#define HAVE_STRTOULL 1
#define HAVE_SYSCONF 1
#define HAVE_SYS_EVENTFD_H 0
#define HAVE_SYS_FILE_H 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_PRCTL_H 0
#define HAVE_SYS_RANDOM_H 1
#define HAVE_SYS_RESOURCE_H 1
#define HAVE_SYS_FCNTL_H 1
#define HAVE_FCNTL_H 1
#define HAVE_NETDB_H 1
#define HAVE_RLIM_T 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_STATVFS_H 1
#define HAVE_SYS_SYSCALL_H 1
#define HAVE_SYS_SYSCTL_H 1
#define HAVE_SYS_SYSLIMITS_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_UN_H 1
#define HAVE_SIGNAL_H 1
#define HAVE_ERRNO_H 1
#define HAVE_SYS_UTIME_H 0
#define HAVE_SYS_WAIT_H 1
#define HAVE_TIME_H 1
#define HAVE_TIMEGM 1
#define HAVE_UNAME 1
#define HAVE_UNISTD_H 1
#define HAVE_USLEEP 1
#define HAVE_UTIME_H 1
#define HAVE_VASPRINTF 1

/* ========================================
 * FEATURE FLAGS
 * ======================================== */

/* Compression */
#define HAVE_ZLIB 1
#define HAVE_LZMA 1

/* TLS/Crypto */
#define ENABLE_OPENSSL 1
#undef ENABLE_NSS  /* Explicitly disable NSS */
#define USE_OPENSSL_1_1_API 1

/* Networking */
#define HAVE_GETADDRINFO 1
#define HAVE_GETHOSTBYNAME_R 0  /* Not on iOS */

/* Threading */
#define HAVE_PTHREAD 1
#define HAVE_PTHREAD_H 1
#define HAVE_PTHREAD_CREATE 1

/* Cap support */
#define HAVE_LIBCAP 0  /* Linux-only */

/* Seccomp */
#define HAVE_SECCOMP_H 0  /* Linux-only */
#define HAVE_LIBSECCOMP 0

/* systemd */
#define HAVE_SYSTEMD 0
#define HAVE_SYS_CAPABILITY_H 0

/* ========================================
 * COMPILER/TOOLCHAIN
 * ======================================== */

#define COMPILER "clang"
#define COMPILER_VERSION __VERSION__
#define APPROX_RELEASE_DATE "2024-10-01"

/* ========================================
 * TOR-SPECIFIC SETTINGS
 * ======================================== */

#define CONFDIR "/var/lib/tor"
#define LOCALSTATEDIR "/var/lib/tor"
#define SHARE_DATADIR "/usr/share"
#define BINDIR "/usr/bin"

/* Build configuration */
#define CONFIGURE_LINE "iOS SPM Build"
#define TOR_BUILD_TAG "v0.4.8.19"
/* Autoconf-style package/version macros expected by version.c */
#define PACKAGE_NAME "tor"
#define PACKAGE_TARNAME "tor"
#define PACKAGE_VERSION "0.4.8.19"
#define PACKAGE_STRING PACKAGE_NAME " " PACKAGE_VERSION
#define PACKAGE_BUGREPORT "https://gitlab.torproject.org/tpo/core/tor/-/issues"
#define VERSION PACKAGE_VERSION

/* Disable modules we don't need */
#define DISABLE_MODULE_DIRAUTH 1

/* ========================================
 * SIZE/ARCHITECTURE
 * ======================================== */

#ifdef __LP64__
#define SIZEOF_VOID_P 8
#define SIZEOF_SIZE_T 8
#define SIZEOF_LONG 8
#else
#define SIZEOF_VOID_P 4
#define SIZEOF_SIZE_T 4
#define SIZEOF_LONG 4
#endif

#define SIZEOF_INT 4
#define SIZEOF_SHORT 2
#define SIZEOF_CHAR 1
#define SIZEOF_LONG_LONG 8
#define SIZEOF_INT64_T 8
#define SIZEOF_INT32_T 4
#define SIZEOF_INT16_T 2
#define SIZEOF_INT8_T 1
#define SIZEOF_UINT64_T 8
#define SIZEOF_UINT32_T 4
#define SIZEOF_UINT16_T 2
#define SIZEOF_UINT8_T 1
#define SIZEOF_INTPTR_T SIZEOF_VOID_P
#define SIZEOF_UINTPTR_T SIZEOF_VOID_P
#define SIZEOF_PID_T 4
#define SIZEOF_TIME_T 8
#define SIZEOF_SOCKLEN_T 4

/* ========================================
 * INLINE/ATTRIBUTE SUPPORT
 * ======================================== */

#define HAVE___ATTRIBUTE__ 1
#define HAVE_INLINE 1
#define inline __inline__

/* ========================================
 * ENDIANNESS
 * ======================================== */

#ifdef __BIG_ENDIAN__
#define WORDS_BIGENDIAN 1
#endif

/* ========================================
 * iOS-SPECIFIC WORKAROUNDS
 * ======================================== */

/* iOS doesn't support fork() properly in most cases */
#define TOR_SKIP_FORK_TESTS 1

/* Use mach_approximate_time for performance */
#define USE_MACH_APPROXIMATE_TIME 1

/* ========================================
 * SAFETY CHECKS
 * ======================================== */

#ifndef SIZE_MAX
#error "SIZE_MAX not defined"
#endif

#ifndef TIME_MAX
#error "TIME_MAX not defined"
#endif

#endif /* ORCONFIG_H */
