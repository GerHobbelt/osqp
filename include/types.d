module types;

nothrow @nogc extern(C):

import glob_opts;
import constants;
import qdldl_types; // for QDLDL_int and others


version(PRINTING){
  import core.stdc.stdio;
} // ifdef PRINTING

/******************
* Internal types *
******************/

/**
 *  Matrix in compressed-column form.
 *  The structure is used internally to store matrices in the triplet form as well,
 *  but the API requires that the matrices are in the CSC format.
 */
struct csc {
  
  c_int    nzmax; ///< maximum number of entries
  c_int    m;     ///< number of rows
  c_int    n;     ///< number of columns
  c_int   *p;     ///< column pointers (size n+1); col indices (size nzmax) start from 0 when using triplet format (direct KKT matrix formation)
  c_int   *i;     ///< row indices, size nzmax starting from 0
  c_float *x;     ///< numerical values, size nzmax
  c_int    nz;    ///< number of entries in triplet matrix, -1 for csc  
};

/**
 * Linear system solver structure (sublevel objects initialize it differently)
 */

//typedef struct linsys_solver LinSysSolver;
//alias linsys_solver = LinSysSolver;
alias LinSysSolver = linsys_solver;  // todo : check it

/**
 * OSQP Timer for statistics
 */


/*********************************
* Timer Structs and Functions * *
*********************************/

/*! \cond PRIVATE */

version(PROFILING){

// Windows
version(Windows){

  // Some R packages clash with elements
  // of the windows.h header, so use a
version(R_LANG){
//#define NOGDI
enum bool NOGDI = true; // todo : test it
}

//#   include <windows.h>
import windows; // todo

struct OSQP_TIMER {
  LARGE_INTEGER tic;
  LARGE_INTEGER toc;
  LARGE_INTEGER freq;
};

} else version(OSX)
{
    //#   include <mach/mach_time.h>
    import core.time: mach_timebase_info_data_t;  // todo

    /* Use MAC OSX  mach_time for timing */
    struct OSQP_TIMER {
      ulong                  tic;
      ulong                  toc;
      mach_timebase_info_data_t tinfo;
    };
  }
else version(linux)
{

    /* Use POSIX clock_gettime() for timing on non-Windows machines */
    import core.sys.posix.sys.time;

    struct OSQP_TIMER {
      timespec tic;
      timespec toc;
    };
}

alias OSQPTimer = OSQP_TIMER;

}/* END #ifdef PROFILING */


/**
 * Problem scaling matrices stored as vectors
 */
struct OSQPScaling {
  c_float  c;    ///< cost function scaling
  c_float *D;    ///< primal variable scaling
  c_float *E;    ///< dual variable scaling
  c_float  cinv; ///< cost function rescaling
  c_float *Dinv; ///< primal variable rescaling
  c_float *Einv; ///< dual variable rescaling
};

/**
 * Solution structure
 */
struct OSQPSolution{
  c_float *x; ///< primal solution
  c_float *y; ///< Lagrange multiplier associated to \f$l <= Ax <= u\f$
};


/**
 * Solver return information
 */
struct OSQPInfo{
  c_int iter;          ///< number of iterations taken
  char [32] status;    ///< status string, e.g. 'solved'
  c_int status_val;    ///< status as c_int, defined in constants.h

version(EMBEDDED){}
else {
  c_int status_polish; ///< polish status: successful (1), unperformed (0), (-1) unsuccessful
} // ifndef EMBEDDED

  c_float obj_val;     ///< primal objective
  c_float pri_res;     ///< norm of primal residual
  c_float dua_res;     ///< norm of dual residual

version(PROFILING){
  c_float setup_time;  ///< time taken for setup phase (seconds)
  c_float solve_time;  ///< time taken for solve phase (seconds)
  c_float update_time; ///< time taken for update phase (seconds)
  c_float polish_time; ///< time taken for polish phase (seconds)
  c_float run_time;    ///< total time  (seconds)
} // ifdef PROFILING

version(EMBEDDED_1){}
else { // if EMBEDDED != 1
  c_int   rho_updates;  ///< number of rho updates
  c_float rho_estimate; ///< best rho estimate so far from residuals
}
};

version (EMBEDDED){}
else {

/**
 * Polish structure
 */
struct OSQPPolish{
  csc *Ared;          ///< active rows of A
  ///<    Ared = vstack[Alow, Aupp]
  c_int    n_low;     ///< number of lower-active rows
  c_int    n_upp;     ///< number of upper-active rows
  c_int   *A_to_Alow; ///< Maps indices in A to indices in Alow
  c_int   *A_to_Aupp; ///< Maps indices in A to indices in Aupp
  c_int   *Alow_to_A; ///< Maps indices in Alow to indices in A
  c_int   *Aupp_to_A; ///< Maps indices in Aupp to indices in A
  c_float *x;         ///< optimal x-solution obtained by polish
  c_float *z;         ///< optimal z-solution obtained by polish
  c_float *y;         ///< optimal y-solution obtained by polish
  c_float  obj_val;   ///< objective value at polished solution
  c_float  pri_res;   ///< primal residual at polished solution
  c_float  dua_res;   ///< dual residual at polished solution
};
} // !version (EMBEDDED)


/**********************************
* Main structures and Data Types *
**********************************/

/**
 * Data structure
 */
struct OSQPData{
  c_int    n; ///< number of variables n
  c_int    m; ///< number of constraints m
  csc     *P; ///< the upper triangular part of the quadratic cost matrix P in csc format (size n x n).
  csc     *A; ///< linear constraints matrix A in csc format (size m x n)
  c_float *q; ///< dense array for linear part of cost function (size n)
  c_float *l; ///< dense array for lower bound (size m)
  c_float *u; ///< dense array for upper bound (size m)
};


/**
 * Settings struct
 */
struct OSQPSettings{
  c_float rho;                    ///< ADMM step rho
  c_float sigma;                  ///< ADMM step sigma
  c_int   scaling;                ///< heuristic data scaling iterations; if 0, then disabled.

version(EMBEDDED_1){}
else { // if EMBEDDED != 1

  c_int   adaptive_rho;           ///< boolean, is rho step size adaptive?
  c_int   adaptive_rho_interval;  ///< number of iterations between rho adaptations; if 0, then it is automatic
  c_float adaptive_rho_tolerance; ///< tolerance X for adapting rho. The new rho has to be X times larger or 1/X times smaller than the current one to trigger a new factorization.
version(PROFILING){
  c_float adaptive_rho_fraction;  ///< interval for adapting rho (fraction of the setup time)
} // Profiling
}

  c_int                   max_iter;      ///< maximum number of iterations
  c_float                 eps_abs;       ///< absolute convergence tolerance
  c_float                 eps_rel;       ///< relative convergence tolerance
  c_float                 eps_prim_inf;  ///< primal infeasibility tolerance
  c_float                 eps_dual_inf;  ///< dual infeasibility tolerance
  c_float                 alpha;         ///< relaxation parameter
  linsys_solver_type      linsys_solver; ///< linear system solver to use

version(EMBEDDED){}
else { // ifndef EMBEDDED
  c_float delta;                         ///< regularization parameter for polishing
  c_int   polish;                        ///< boolean, polish ADMM solution
  c_int   polish_refine_iter;            ///< number of iterative refinement steps in polishing

  c_int verbose;                         ///< boolean, write out progress
} // ifndef EMBEDDED

  c_int scaled_termination;              ///< boolean, use scaled termination criteria
  c_int check_termination;               ///< integer, check termination interval; if 0, then termination checking is disabled
  c_int warm_start;                      ///< boolean, warm start

version(PROFILING){
  c_float time_limit;                    ///< maximum number of seconds allowed to solve the problem; if 0, then disabled
} // ifdef PROFILING
};


/**
 * OSQP Workspace
 */
struct OSQPWorkspace{
  /// Problem data to work on (possibly scaled)
  OSQPData *data;

  /// Linear System solver structure
  LinSysSolver *linsys_solver;

version(EMBEDDED){}
else { // ifndef EMBEDDED
  /// Polish structure
  OSQPPolish *pol;
} // ifndef EMBEDDED

  /**
   * @name Vector used to store a vectorized rho parameter
   * @{
   */
  c_float *rho_vec;     ///< vector of rho values
  c_float *rho_inv_vec; ///< vector of inv rho values

  /** @} */

version(EMBEDDED_1){}
else { // if EMBEDDED != 1
  c_int *constr_type; ///< Type of constraints: loose (-1), equality (1), inequality (0)
} // if EMBEDDED != 1

  /**
   * @name Iterates
   * @{
   */
  c_float *x;        ///< Iterate x
  c_float *y;        ///< Iterate y
  c_float *z;        ///< Iterate z
  c_float *xz_tilde; ///< Iterate xz_tilde

  c_float *x_prev;   ///< Previous x

  /**< NB: Used also as workspace vector for dual residual */
  c_float *z_prev;   ///< Previous z

  /**< NB: Used also as workspace vector for primal residual */

  /**
   * @name Primal and dual residuals workspace variables
   *
   * Needed for residuals computation, tolerances computation,
   * approximate tolerances computation and adapting rho
   * @{
   */
  c_float *Ax;  ///< scaled A * x
  c_float *Px;  ///< scaled P * x
  c_float *Aty; ///< scaled A * x

  /** @} */

  /**
   * @name Primal infeasibility variables
   * @{
   */
  c_float *delta_y;   ///< difference between consecutive dual iterates
  c_float *Atdelta_y; ///< A' * delta_y

  /** @} */

  /**
   * @name Dual infeasibility variables
   * @{
   */
  c_float *delta_x;  ///< difference between consecutive primal iterates
  c_float *Pdelta_x; ///< P * delta_x
  c_float *Adelta_x; ///< A * delta_x

  /** @} */

  /**
   * @name Temporary vectors used in scaling
   * @{
   */

  c_float *D_temp;   ///< temporary primal variable scaling vectors
  c_float *D_temp_A; ///< temporary primal variable scaling vectors storing norms of A columns
  c_float *E_temp;   ///< temporary constraints scaling vectors storing norms of A' columns


  /** @} */

  OSQPSettings *settings; ///< problem settings
  OSQPScaling  *scaling;  ///< scaling vectors
  OSQPSolution *solution; ///< problem solution
  OSQPInfo     *info;     ///< solver information

version(PROFILING){
  OSQPTimer *timer;       ///< timer object

  /// flag indicating whether the solve function has been run before
  c_int first_run;

  /// flag indicating whether the update_time should be cleared
  c_int clear_update_time;

  /// flag indicating that osqp_update_rho is called from osqp_solve function
  c_int rho_update_from_solve;
} // ifdef PROFILING

version(PRINTING){
  c_int summary_printed; ///< Has last summary been printed? (true/false)
} // ifdef PRINTING

};


/**
 * Define linsys_solver prototype structure
 *
 * NB: The details are defined when the linear solver is initialized depending
 *      on the choice
 */
alias solve_t = c_int function(LinSysSolver* self, c_float* b);
alias update_matrices_t = c_int function(LinSysSolver* s, const csc* P, const csc* A);
alias update_rho_vec_t = c_int function(LinSysSolver* s, const c_float* rho_vec);
alias free_t = void function(LinSysSolver* self);

struct linsys_solver {
  linsys_solver_type type;                 ///< linear system solver type functions
  //c_int (*solve)(LinSysSolver *self,
  //               c_float      *b);              ///< solve linear system
  solve_t solve;

version(EMBEDDED){}
else { // ifndef EMBEDDED
  //void (*free)(LinSysSolver *self);             ///< free linear system solver (only in desktop version)
  free_t free; // todo
} // ifndef EMBEDDED

version(EMBEDDED_1){}
else { // ifndef EMBEDDED
  //c_int (*update_matrices)(LinSysSolver *s,
  //                         const csc *P,            ///< update matrices P
  //                         const csc *A);           //   and A in the solver
  update_matrices_t update_matrices;

  //c_int (*update_rho_vec)(LinSysSolver  *s,
  //                        const c_float *rho_vec);  ///< Update rho_vec
  update_rho_vec_t update_rho_vec;
} // if EMBEDDED != 1

version(EMBEDDED){}
else { // ifndef EMBEDDED
  c_int nthreads; ///< number of threads active
} // ifndef EMBEDDED
};
