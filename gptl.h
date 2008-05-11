/*
$Id: gptl.h,v 1.32 2008-05-11 15:39:21 rosinski Exp $
*/
#ifndef GPTL_H
#define GPTL_H

/*
** Boolean options settable by a call to GPTLsetoption()
*/

typedef enum {
  GPTLwall           = 1,  /* Collect wallclock stats */
  GPTLcpu            = 2,  /* Collect CPU stats */
  GPTLabort_on_error = 3,  /* Abort on failure */
  GPTLoverhead       = 4,  /* Estimate overhead of GPTL itself */
  GPTLdepthlimit     = 5,  /* Only print timers which reach this depth in the tree */
  GPTLverbose        = 6,  /* Verbose output */
  GPTLnarrowprint    = 7,  /* Print PAPI stats in fewer columns */
  GPTLparentchild    = 8,  /* Guarantee parent/child ordering of printed output */
  GPTLpercent        = 9,  /* Add a column for percent of first timer */
  GPTLpersec         = 10, /* Add a PAPI column that prints "per second" stats */
  GPTLmultiplex      = 11  /* Allow PAPI multiplexing */
} Option;

/*
** Underlying wallclock timer: optimize for best granularity with least overhead
*/

typedef enum {
  GPTLgettimeofday   = 12, /* the default */
  GPTLnanotime       = 13, /* only available on x86 */
  GPTLrtc            = 14,
  GPTLmpiwtime       = 15,
  GPTLclockgettime   = 16,
  GPTLpapitime       = 17  /* only if PAPI is available */
} Funcoption;

/*
** Function prototypes
*/

extern int GPTLsetoption (const int, const int);
extern int GPTLinitialize (void);
extern int GPTLstart_instr (void *);
extern int GPTLstart (const char *);
extern int GPTLstop_instr (void *);
extern int GPTLstop (const char *);
extern int GPTLstamp (double *, double *, double *);
extern int GPTLpr (const int);
extern int GPTLpr_file (const char *);
extern int GPTLreset (void);
extern int GPTLfinalize (void);
extern int GPTLprint_memusage (const char *);
extern int GPTLget_memusage (int *, int *, int *, int *, int *);
extern int GPTLsetutr (const int);
extern int GPTLenable (void);
extern int GPTLdisable (void);
extern int GPTLquery (const char *, int, int *, int *, double *, double *, double *,
		      long long *, const int);
extern int GPTLquerycounters (const char *, int, long long *);
extern int GPTLget_nregions (int, int *);
extern int GPTLget_regionname (int, int, char *, int);

/* 
** These are defined in gptl_papi.c 
*/

extern void GPTL_PAPIprinttable (void);
extern int GPTL_PAPIname2id (const char *);
#endif
