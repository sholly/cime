#include <sys/time.h> /* gettimeofday */
#include <sys/times.h> /* times */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef THREADED_OMP
#include <omp.h>
#endif

#ifdef HAVE_PAPI
#include <papi.h>
#endif

#include "../gpt.h"

static void *getentry (char *, char *, int *);
static void overhead (int, int);

int main ()
{
  int nompiter;
  int ompiter;
  int ninvoke;
  int papiopt;
  int gptopt;
  int val;

#ifdef HAVE_PAPI
  GPTPAPIprinttable ();
  while (1) {
    printf ("Enter PAPI option to enable, non-negative number when done\n");
    scanf ("%d", &papiopt);
    if (papiopt >= 0)
      break;
    if (GPTsetoption (papiopt, 1) < 0)
      printf ("gptsetoption failure\n");
  }
#endif

  printf ("GPTwall           = 1\n");
  printf ("GPTcpu            = 2\n");
  printf ("GPTabort_on_error = 3\n");
  printf ("GPToverhead       = 4\n");
  while (1) {
    printf ("Enter GPT option and enable flag, negative numbers when done\n");
    scanf ("%d %d", &gptopt, &val);
    if (gptopt <= 0)
      break;
    if (GPTsetoption (gptopt, val) < 0)
      printf ("gptsetoption failure\n");
  }

  printf ("Enter number of iterations for threaded loop:\n");
  scanf ("%d", &nompiter);
  printf ("Enter number of invocations of overhead portion:\n");
  scanf ("%d", &ninvoke);
  printf ("nompiter=%d ninvoke=%d\n", nompiter, ninvoke);

  GPTinitialize ();
  GPTstart ("total");

#ifdef THREADED_OMP
#pragma omp parallel for private (ompiter)
#endif

  for (ompiter = 0; ompiter < nompiter; ++ompiter) {
    overhead (ompiter, ninvoke);
  }
  GPTstop ("total");
  GPTpr (0);
  GPTfinalize ();
}

static void overhead (int iter, int ninvoke)
{
  int i;
#ifdef THREADED_OMP
  int tnum;
#endif
  int indx;
  char **strings1;
  char **strings2;
  struct timeval tp;
  struct tms buf;
  void *nothing;

  GPTstart ("mallocstuff");
  strings1 = (char **) malloc (ninvoke * sizeof (char *));
  strings2 = (char **) malloc (ninvoke * sizeof (char *));
  for (i = 0; i < ninvoke; ++i) {
    strings1[i] = malloc (8);
    strings2[i] = malloc (8);
    sprintf (strings1[i], "str%3d", i);
    sprintf (strings2[i], "str%3d", i);
  }
  GPTstop ("mallocstuff");
  
#ifdef THREADED_OMP
  GPTstart ("get_thread_num");
  for (i = 0; i < ninvoke; ++i) {
    tnum = omp_get_thread_num ();
  }
  GPTstop ("get_thread_num");
#endif

  GPTstart ("gettimeofday");
  for (i = 0; i < ninvoke; ++i) {
    gettimeofday (&tp, 0);
  }
  GPTstop ("gettimeofday");

  GPTstart ("times");
  for (i = 0; i < ninvoke; ++i) {
    (void) times (&buf);
  }
  GPTstop ("times");
  
  GPTstart ("getentry");
  for (i = 0; i < ninvoke; ++i) {
    nothing = getentry (strings1[i], strings2[i], &indx);
  }
  GPTstop ("getentry");

  GPTstart ("freestuff");
  for (i = 0; i < ninvoke; ++i) {
    free (strings1[i]);
    free (strings2[i]);
  }
  free (strings1);
  free (strings2);
  GPTstop ("freestuff");

  for (i = 0; i < ninvoke; ++i) {
    GPTstart ("2or4PAPI_reads");
    GPTstop ("2or4PAPI_reads");
  }
}

static void *getentry (char *string,
		       char *name, 
		       int *indx)
{
  char *c = name;

  for (*indx = 0; *c; c++)
    *indx += *c;

  if (strcmp (name, string) == 0)
    return (void *) c;

  return 0;
}
