/*
$Id: gptl.h,v 1.1 2004-12-25 00:13:18 rosinski Exp $
*/

typedef enum {
  GPTLwall           = 1,
  GPTLcpu            = 2,
  GPTLabort_on_error = 3,
  GPTLoverhead       = 4
} Option;

/*
** Function prototypes
*/

extern int GPTLsetoption (const int, const int);
extern int GPTLinitialize (void);
extern int GPTLfinalize (void);
extern int GPTLstart (const char *);
extern int GPTLstop (const char *);
extern int GPTLstamp (double *, double *, double *);
extern int GPTLpr (const int);
extern int GPTLreset (void);
#ifdef HAVE_PAPI
extern void GPTLPAPIprinttable (void);
#endif

