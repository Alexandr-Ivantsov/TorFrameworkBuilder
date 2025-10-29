#ifndef TOR_H
#define TOR_H

#ifdef __cplusplus
extern "C" {
#endif

// Main Tor entry point
int tor_main(int argc, char *argv[]);

// Tor control functions  
int tor_run_main(void *options);
void tor_cleanup(void);

// Version info
const char *get_version(void);

#ifdef __cplusplus
}
#endif

#endif /* TOR_H */

