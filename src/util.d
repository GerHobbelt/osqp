module util;

nothrow @nogc extern(C):

import glob_opts;
import types;
import constants;
import lin_sys;
import core.sys.posix.time;

/* ================================= DEBUG FUNCTIONS ======================= */

version(PRINTING){
  import core.stdc.stdio;
} // ifdef PRINTING


/************************************
* Printing Constants to set Layout *
************************************/
version(PRINTING){
  enum int HEADER_LINE_LEN = 65;
} /* ifdef PRINTING */

/**********************
* Utility Functions  *
**********************/
void c_strcpy(char * dest, const(char) * source) {
  int i = 0;

  while (1) {
    dest[i] = source[i];

    if (dest[i] == '\0') break;
    i++;
  }
}

version(PRINTING){

static void print_line() {
  char [HEADER_LINE_LEN + 1] the_line;
  c_int i;

  for (i = 0; i < HEADER_LINE_LEN; ++i) the_line[i] = '-';
  the_line[HEADER_LINE_LEN] = '\0';
  c_print("%s\n", cast(char*)the_line);
}

void print_header() {
  // Different indentation required for windows
/*#if defined(Windows) && !defined(PYTHON)
  c_print("iter  ");
#else
  c_print("iter   ");*/


  version(Windows){
    version(PYTHON){}
    else {
      c_print("iter  ");
    }
  }
  else {
    c_print("iter  ");
  }
  version(PYTHON){}
  else {
    c_print("iter  ");
  }

//} // PRINTING // TODO : ambiguos

  // Main information
  c_print("objective    pri res    dua res    rho");
version(PROFILING){
  c_print("        time");
} /* ifdef PROFILING */
  c_print("\n");
}

void print_setup_header(const OSQPWorkspace *work) {
  OSQPData *data;
  OSQPSettings *settings;
  c_int nnz; // Number of nonzeros in the problem

  data     = cast(OSQPData*)work.data;
  settings = cast(OSQPSettings*)work.settings;

  // Number of nonzeros
  nnz = data.P.p[data.P.n] + data.A.p[data.A.n];

  print_line();
  c_print("           OSQP v%s  -  Operator Splitting QP Solver\n             (c) Bartolomeo Stellato,  Goran Banjac\n        University of Oxford  -  Stanford University 2019\n",
          cast(char*)OSQP_VERSION);
  print_line();

  // Print variables and constraints
  c_print("problem:  ");
  c_print("variables n = %i, constraints m = %i\n          ",
                                    cast(int)data.n,
          cast(int)data.m);
  c_print("nnz(P) + nnz(A) = %i\n", cast(int)nnz);

  // Print Settings
  c_print("settings: ");
  c_print("linear system solver = %s",
          cast(char*)(LINSYS_SOLVER_NAME[settings.linsys_solver]));

  if (work.linsys_solver.nthreads != 1) {
    c_print(" (%d threads)", cast(int)work.linsys_solver.nthreads);
  }
  c_print(",\n          ");

  c_print("eps_abs = %.1e, eps_rel = %.1e,\n          ",
          settings.eps_abs, settings.eps_rel);
  c_print("eps_prim_inf = %.1e, eps_dual_inf = %.1e,\n          ",
          settings.eps_prim_inf, settings.eps_dual_inf);
  c_print("rho = %.2e ", settings.rho);

  if (settings.adaptive_rho) c_print("(adaptive)");
  c_print(",\n          ");
  c_print("sigma = %.2e, alpha = %.2f, ",
          settings.sigma, settings.alpha);
  c_print("max_iter = %i\n", cast(int)settings.max_iter);

  if (settings.check_termination) c_print(
      "          check_termination: on (interval %i),\n",
      cast(int)settings.check_termination);
  else c_print("          check_termination: off,\n");

version(PROFILING){
  if (settings.time_limit) c_print("          time_limit: %.2e sec,\n",
                                    settings.time_limit);
} /* ifdef PROFILING */

  if (settings.scaling) c_print("          scaling: on, ");
  else c_print("          scaling: off, ");

  if (settings.scaled_termination) c_print("scaled_termination: on\n");
  else c_print("scaled_termination: off\n");

  if (settings.warm_start) c_print("          warm start: on, ");
  else c_print("          warm start: off, ");

  if (settings.polish) c_print("polish: on, ");
  else c_print("polish: off, ");

  if (settings.time_limit) c_print("time_limit: %.2e sec\n", settings.time_limit);
  else c_print("time_limit: off\n");

  c_print("\n");
}

void print_summary(OSQPWorkspace *work) {
  OSQPInfo *info;

  info = work.info;

  c_print("%4i",     cast(int)info.iter);
  c_print(" %12.4e", info.obj_val);
  c_print("  %9.2e", info.pri_res);
  c_print("  %9.2e", info.dua_res);
  c_print("  %9.2e", work.settings.rho);
version(PROFILING) {

  if (work.first_run) {
    // total time: setup + solve
    c_print("  %9.2es", info.setup_time + info.solve_time);
  } else {
    // total time: update + solve
    c_print("  %9.2es", info.update_time + info.solve_time);
  }
} /* ifdef PROFILING */
  c_print("\n");

  work.summary_printed = 1; // Summary has been printed
}

void print_polish(OSQPWorkspace *work) {
  OSQPInfo *info;

  info = work.info;

  c_print("%4s",     "plsh".ptr);
  c_print(" %12.4e", info.obj_val);
  c_print("  %9.2e", info.pri_res);
  c_print("  %9.2e", info.dua_res);

  // Different characters for windows/unix
  version(Windows){
    version(PYTHON){}
    else {
      c_print("  ---------");
    }
  }
  else {
    c_print("  ---------");
  }
  version(PYTHON){}
  else {
    c_print("  ---------");
  }
/*#if defined(Windows) && !defined(PYTHON)
  c_print("  ---------");
#else
  c_print("   --------");
#endif*/


version(PROFILING){
  if (work.first_run) {
    // total time: setup + solve
    c_print("  %9.2es", info.setup_time + info.solve_time +
            info.polish_time);
  } else {
    // total time: update + solve
    c_print("  %9.2es", info.update_time + info.solve_time +
            info.polish_time);
  }
} /* ifdef PROFILING */
  c_print("\n");
}

void print_footer(OSQPInfo *info, c_int polish) {
  c_print("\n"); // Add space after iterations

  c_print("status:               %s\n", cast(char*)info.status);

  if (polish && (info.status_val == OSQP_SOLVED)) {
    if (info.status_polish == 1) {
      c_print("solution polish:      successful\n");
    } else if (info.status_polish < 0) {
      c_print("solution polish:      unsuccessful\n");
    }
  }

  c_print("number of iterations: %i\n", cast(int)info.iter);

  if ((info.status_val == OSQP_SOLVED) ||
      (info.status_val == OSQP_SOLVED_INACCURATE)) {
    c_print("optimal objective:    %.4f\n", info.obj_val);
  }

version(PROFILING){
  c_print("run time:             %.2es\n", info.run_time);
} /* ifdef PROFILING */

version(EMBEDDED_1){}
else {
  c_print("optimal rho estimate: %.2e\n", info.rho_estimate);
} /* if EMBEDDED != 1 */
  c_print("\n");
}

} /* End #ifdef PRINTING */

version(EMBEDDED){}
else {

OSQPSettings* copy_settings(const OSQPSettings *settings) {
  OSQPSettings *newSettings = cast(OSQPSettings*)c_malloc(OSQPSettings.sizeof);

  if (!newSettings) return OSQP_NULL;

  // Copy settings
  // NB. Copying them explicitly because memcpy is not
  // defined when PRINTING is disabled (appears in string.h)
  newSettings.rho = settings.rho;
  newSettings.sigma = settings.sigma;
  newSettings.scaling = settings.scaling;

version(EMBEDDED_1){}
else {

  newSettings.adaptive_rho = settings.adaptive_rho;
  newSettings.adaptive_rho_interval = settings.adaptive_rho_interval;
  newSettings.adaptive_rho_tolerance = settings.adaptive_rho_tolerance;
version(PROFILING){
  newSettings.adaptive_rho_fraction = settings.adaptive_rho_fraction;
}
} // EMBEDDED != 1
  newSettings.max_iter = settings.max_iter;
  newSettings.eps_abs = settings.eps_abs;
  newSettings.eps_rel = settings.eps_rel;
  newSettings.eps_prim_inf = settings.eps_prim_inf;
  newSettings.eps_dual_inf = settings.eps_dual_inf;
  newSettings.alpha = settings.alpha;
  newSettings.linsys_solver = settings.linsys_solver;
  newSettings.delta = settings.delta;
  newSettings.polish = settings.polish;
  newSettings.polish_refine_iter = settings.polish_refine_iter;
  newSettings.verbose = settings.verbose;
  newSettings.scaled_termination = settings.scaled_termination;
  newSettings.check_termination = settings.check_termination;
  newSettings.warm_start = settings.warm_start;
version(PROFILING){
  newSettings.time_limit = settings.time_limit;
}

  return newSettings;
}

} // #ifndef EMBEDDED


/*******************
* Timer Functions *
*******************/

version(PROFILING){

// Windows
version(Windows){

  void osqp_tic(OSQPTimer *t)
  {
    QueryPerformanceFrequency(&t.freq);
    QueryPerformanceCounter(&t.tic);
  }

  c_float osqp_toc(OSQPTimer *t)
  {
    QueryPerformanceCounter(&t.toc);
    return (t.toc.QuadPart - t.tic.QuadPart) / cast(c_float)t.freq.QuadPart;
  }

} else {
  version(OSX){

    import core.time: mach_absolute_time, mach_timebase_info;

    void osqp_tic(OSQPTimer *t)
    {
      /* read current clock cycles */
      t.tic = mach_absolute_time();
    }

    c_float osqp_toc(OSQPTimer *t)
    {
      ulong duration; /* elapsed time in clock cycles*/

      t.toc   = mach_absolute_time();
      duration = t.toc - t.tic;

      /*conversion from clock cycles to nanoseconds*/
      mach_timebase_info(&(t.tinfo));
      duration *= t.tinfo.numer;
      duration /= t.tinfo.denom;

      return cast(c_float)duration / 1e9;
    }

   } else { /* linux */
      /* read current time */
      void osqp_tic(OSQPTimer *t)
      {
        clock_gettime(CLOCK_MONOTONIC, &t.tic);
      }

      /* return time passed since last call to tic on this timer */
      c_float osqp_toc(OSQPTimer *t)
      {
        timespec temp;

        clock_gettime(CLOCK_MONOTONIC, &t.toc);

        if ((t.toc.tv_nsec - t.tic.tv_nsec) < 0) {
          temp.tv_sec  = t.toc.tv_sec - t.tic.tv_sec - 1;
          temp.tv_nsec = cast(long)(1e9 + t.toc.tv_nsec - t.tic.tv_nsec); // todo : check it
        } else {
          temp.tv_sec  = t.toc.tv_sec - t.tic.tv_sec;
          temp.tv_nsec = cast(long)(t.toc.tv_nsec - t.tic.tv_nsec);
        }
        return cast(c_float)temp.tv_sec + cast(c_float)temp.tv_nsec / 1e9;
      }
    } // linux  
} // Windows

} // If Profiling end


/* ==================== DEBUG FUNCTIONS ======================= */



// If debug mode enabled
version(DEBUG){  // todo : was DDEBUG

version(PRINTING){

void print_csc_matrix(csc *M, const char *name)
{
  c_int j, i, row_start, row_stop;
  c_int k = 0;

  // Print name
  c_print("%s :\n", name);

  for (j = 0; j < M.n; j++) {
    row_start = M.p[j];
    row_stop  = M.p[j + 1];

    if (row_start == row_stop) continue;
    else {
      for (i = row_start; i < row_stop; i++) {
        c_print("\t[%3u,%3u] = %.3g\n", cast(int)M.i[i], cast(int)j, M.x[k++]);
      }
    }
  }
}

void dump_csc_matrix(csc *M, const char *file_name) {
  c_int j, i, row_strt, row_stop;
  c_int k = 0;
  FILE *f = fopen(file_name, "w");

  if (f != NULL) {
    for (j = 0; j < M.n; j++) {
      row_strt = M.p[j];
      row_stop = M.p[j + 1];

      if (row_strt == row_stop) continue;
      else {
        for (i = row_strt; i < row_stop; i++) {
          fprintf(f, "%d\t%d\t%20.18e\n",
                  cast(int)M.i[i] + 1, cast(int)j + 1, M.x[k++]);
        }
      }
    }
    fprintf(f, "%d\t%d\t%20.18e\n", cast(int)M.m, cast(int)M.n, 0.0);
    fclose(f);
    c_print("File %s successfully written.\n", file_name);
  } else {
    c_eprint("Error during writing file %s.\n", file_name);
  }
}

void print_trip_matrix(csc *M, const char *name)
{
  c_int k = 0;

  // Print name
  c_print("%s :\n", name);

  for (k = 0; k < M.nz; k++) {
    c_print("\t[%3u, %3u] = %.3g\n", cast(int)M.i[k], cast(int)M.p[k], M.x[k]);
  }
}

void print_dns_matrix(c_float *M, c_int m, c_int n, const char *name)
{
  c_int i, j;

  c_print("%s : \n\t", name);

  for (i = 0; i < m; i++) {   // Cycle over rows
    for (j = 0; j < n; j++) { // Cycle over columns
      if (j < n - 1)
        // c_print("% 14.12e,  ", M[j*m+i]);
        c_print("% .3g,  ", M[j * m + i]);

      else
        // c_print("% 14.12e;  ", M[j*m+i]);
        c_print("% .3g;  ", M[j * m + i]);
    }

    if (i < m - 1) {
      c_print("\n\t");
    }
  }
  c_print("\n");
}

void print_vec(c_float *v, c_int n, const char *name) {
  print_dns_matrix(v, 1, n, name);
}

void dump_vec(c_float *v, c_int len, const char *file_name) {
  c_int i;
  FILE *f = fopen(file_name, "w");

  if (f != NULL) {
    for (i = 0; i < len; i++) {
      fprintf(f, "%20.18e\n", v[i]);
    }
    fclose(f);
    c_print("File %s successfully written.\n", file_name);
  } else {
    c_print("Error during writing file %s.\n", file_name);
  }
}

void print_vec_int(c_int *x, c_int n, const char *name) {
  c_int i;

  c_print("%s = [", name);

  for (i = 0; i < n; i++) {
    c_print(" %i ", cast(int)x[i]);
  }
  c_print("]\n");
}

} // PRINTING

} // DEBUG MODE
