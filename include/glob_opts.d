module glob_opts;

nothrow @nogc extern(C):

/*
   Define OSQP compiler flags
 */

// cmake generated compiler flags
//#include "osqp_configure.h"
import osqp_configure;

/* DATA CUSTOMIZATIONS (depending on memory manager)-----------------------   */

// We do not need memory allocation functions if EMBEDDED is enabled
version (EMBEDDED) {}
else {  // # ifndef EMBEDDED
/* define custom printfs and memory allocation (e.g. matlab/python) */
  version (MATLAB)
  {
    // todo: not tested
    // #   include "mex.h"
    import mex;
    static void* c_calloc(size_t num, size_t size) {
    void *m = mxCalloc(num, size);
      mexMakeMemoryPersistent(m);
      return m;
    }

    static void* c_malloc(size_t size) {
      void *m = mxMalloc(size);
      mexMakeMemoryPersistent(m);
      return m;
    }

    static void* c_realloc(void *ptr, size_t size) {
      void *m = mxRealloc(ptr, size);
      mexMakeMemoryPersistent(m);
      return m;
    }

    //#   define c_free mxFree
    alias c_free = mxFree;    
  }
  else {   // elif defined PYTHON
    version (PYTHON) 
    {
      // Define memory allocation for python. Note that in Python 2 memory manager
      // Calloc is not implemented
        import python;
        //#   include <Python.h>
        //#   define c_malloc PyMem_Malloc
        alias c_malloc = PyMem_Malloc;
        
        // todo : not tested, review below

        /*
        #   if PY_MAJOR_VERSION >= 3
        #    define c_calloc PyMem_Calloc
        #   else  // if PY_MAJOR_VERSION >= 3 
        static void* c_calloc(size_t num, size_t size) {
          void *m = PyMem_Malloc(num * size);
          memset(m, 0, num * size);
          return m;
        }
          #   endif  *//* if PY_MAJOR_VERSION >= 3 */
          alias c_free = PyMem_Free;
          alias c_realloc = PyMem_Realloc;
          //#   define c_free PyMem_Free
          //#   define c_realloc PyMem_Realloc

    }
    else {
      version (OSQP_CUSTOM_MEMORY) {}
      else {
      /* If no custom memory allocator defined, use
      * standard linux functions. Custom memory allocator definitions
      * appear in the osqp_configure.d generated file. */
          import core.stdc.stdlib;
          alias c_malloc = malloc;
          alias c_calloc = calloc;
          alias c_free = free;
          alias c_realloc = realloc;
          //#  include <stdlib.h>
          //#  define c_malloc  malloc
          //#  define c_calloc  calloc
          //#  define c_free    free
          //#  define c_realloc realloc
      }
    }
  }
}

/* Use customized number representation -----------------------------------   */
version (DLONG)
{
  alias c_int = long; /* for indices */
}
else { // standard integers
  alias c_int = int;       /* for indices */
}

version (DFLOAT)
{
  alias c_float = float;  /* for numerical values  */
}
else {
  alias c_float = double; /* for numerical values  */
}

/* Use customized operations */

//# ifndef c_absval
//#  define c_absval(x) (((x) < 0) ? -(x) : (x))
//# endif /* ifndef c_absval */
auto ref c_absval(T)(auto ref return T x) { return (x < 0) ? -x : x; }

//# ifndef c_max
//#  define c_max(a, b) (((a) > (b)) ? (a) : (b))
//# endif /* ifndef c_max */
auto ref c_max(T)(auto ref return T a, auto ref return T b) { return (a > b) ? a : b; }

//# ifndef c_min
//#  define c_min(a, b) (((a) < (b)) ? (a) : (b))
//# endif /* ifndef c_min */
auto ref c_min(T)(auto ref return T a, auto ref return T b) { return (a < b) ? a : b; }

// Round x to the nearest multiple of N
//# ifndef c_roundmultiple
//#  define c_roundmultiple(x, N) ((x) + .5 * (N)-c_fmod((x) + .5 * (N), (N)))
//# endif /* ifndef c_roundmultiple */
auto ref c_roundmultiple(T)(auto ref return T x, auto ref return T N) { return x + .5 * N-c_fmod(x + .5 * N, N); }


/* Use customized functions -----------------------------------------------   */

// todo : test EMBEDDED_1
version (EMBEDDED_1) {} // if EMBEDDED != 1
else {
  import core.stdc.math;
  version (DFLOAT){
    //#define c_sqrt sqrtf
    //#define c_fmod fmodf
    alias c_sqrt = sqrtf;
    alias c_fmod = fmodf;
  }
  else {
    //#define c_sqrt sqrt
    //#define c_fmod fmod
    alias c_sqrt = sqrt;
    alias c_fmod = fmod;
  }
}

import core.stdc.stdio;
alias c_print = printf; // todo : for SuiteSparse_config module

version (PRINTING)
{
  import core.stdc.stdio;
  import core.stdc.string;

  version (MATLAB)
  {
    //define c_print mexPrintf
    alias c_print = mexPrintf;
    // The following trick slows down the performance a lot. Since many solvers
    // actually
    // call mexPrintf and immediately force print buffer flush
    // otherwise messages don't appear until solver termination
    // ugly because matlab does not provide a vprintf mex interface
    // #include <stdarg.h>
    // static int c_print(char *msg, ...)
    // {
    //   va_list argList;
    //   va_start(argList, msg);
    //   //message buffer
    //   int bufferSize = 256;
    //   char buffer[bufferSize];
    //   vsnprintf(buffer,bufferSize-1, msg, argList);
    //   va_end(argList);
    //   int out = mexPrintf(buffer); //print to matlab display
    //   mexEvalString("drawnow;");   // flush matlab print buffer
    //   return out;
    // }
  }
  else {
    version (PYTHON)
    {
      //include <Python.h>
      //#   define c_print PySys_WriteStdout
      // todo : not tested
      import python;
      alias c_print = PySys_WriteStdout;
    }
    else {
      version (R_LANG)
      {        
        //include <R_ext/Print.h>
        //#   define c_print Rprintf
        // todo : not tested
        import R_ext.Print;
        alias c_print = Rprintf;
      }
      else {
        //define c_print printf
        alias c_print = printf;
      }
    }
  }  

  alias c_eprint = c_print;

  /* Print error macro */
  //#  define c_eprint(...) c_print("ERROR in %s: ", __FUNCTION__); c_print(__VA_ARGS__); c_print("\n");
  //void c_eprint(ref c_int a, ref c_int b) { c_print("ERROR in %s: ", __FUNCTION__); c_print(__VA_ARGS__); c_print("\n"); }
/*
  import core.stdc.stdarg;
  import core.vararg;  

  void c_eprint(char* a, ...) {
    // We can't use hte following method because of
    // Error: @nogc function glob_opts.c_eprint cannot call non-@nogc function core.stdc.stdarg.va_end
    //va_list args;
    //va_start(args, a);
    // it's up to you to figure out the end of the list!
    // isn't that fun?
    //va_end(args);
  
    // todo : so I skip all arguments printing for now

    c_print("ERROR in %s: ", __FUNCTION__.ptr); 
    //for (int i = 0; i < _arguments.length; i++) c_print(_arguments[i]);  // works only for extern (D) functions

  

    c_print("\n"); 
  }*/
}
