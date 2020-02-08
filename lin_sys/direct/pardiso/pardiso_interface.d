module pardiso_interface;

nothrow @nogc extern(C):

import glob_opts;

import types; // CSC matrix type
import constants;
import lin_alg;
import cs;
import kkt;


/**
 * Pardiso solver structure
 *
 * NB: If we use Pardiso, we suppose that EMBEDDED is not enabled
 */
//typedef struct pardiso pardiso_solver;

struct pardiso_solver {
    linsys_solver_type type;

    /**
     * @name Functions
     * @{
     */
    c_int function(pardiso_solver* self, c_float* b) solve;
    void function(pardiso_solver* self) free;  ///< Free workspace (only if desktop)

    c_int function(pardiso_solver* self, const csc* P, const csc* A) update_matrices;  ///< Update solver matrices
    c_int function(pardiso_solver* self, const c_float* rho_vec) update_rho_vec;  ///< Update rho_vec parameter

    c_int nthreads;
    /** @} */


    /**
     * @name Attributes
     * @{
     */
    // Attributes
    csc *KKT;               ///< KKT matrix (in CSR format!)
    c_int *KKT_i;           ///< KKT column indices in 1-indexing for Pardiso
    c_int *KKT_p;           ///< KKT row pointers in 1-indexing for Pardiso
    c_float *bp;            ///< workspace memory for solves (rhs)
    c_float *sol;           ///< solution to the KKT system
    c_float *rho_inv_vec;   ///< parameter vector
    c_float sigma;          ///< scalar parameter
    c_int polish;           ///< polishing flag
    c_int n;                ///< number of QP variables
    c_int m;                ///< number of QP constraints

    // Pardiso variables
    void * [64]pt;     ///< internal solver memory pointer pt
    c_int [64] iparm;  ///< Pardiso control parameters
    c_int nKKT;       ///< dimension of the linear system
    c_int mtype;      ///< matrix type (-2 for real and symmetric indefinite)
    c_int nrhs;       ///< number of right-hand sides (1 for our needs)
    c_int maxfct;     ///< maximum number of factors (1 for our needs)
    c_int mnum;       ///< indicates matrix for the solution phase (1 for our needs)
    c_int phase;      ///< control the execution phases of the solver
    c_int error;      ///< the error indicator (0 for no error)
    c_int msglvl;     ///< Message level information (0 for no output)
    c_int idum;       ///< dummy integer
    c_float fdum;     ///< dummy float

    // These are required for matrix updates
    c_int * Pdiag_idx; ///< index and number of diagonal elements in P
    c_int Pdiag_n;  ///< index and number of diagonal elements in P
    c_int * PtoKKT; ///< Index of elements from P and A to KKT matrix
    c_int * AtoKKT;    ///< Index of elements from P and A to KKT matrix
    c_int * rhotoKKT;            ///< Index of rho places in KKT matrix

    /** @} */
};


/**
 * Initialize Pardiso Solver
 *
 * @param  s         Pointer to a private structure
 * @param  P         Cost function matrix (upper triangular form)
 * @param  A         Constraints matrix
 * @param  sigma     Algorithm parameter. If polish, then sigma = delta.
 * @param  rho_vec   Algorithm parameter. If polish, then rho_vec = OSQP_NULL.
 * @param  polish    Flag whether we are initializing for polish or not
 * @return           Exitflag for error (0 if no errors)
 */
c_int init_linsys_solver_pardiso(pardiso_solver ** sp, const csc * P, const csc * A, c_float sigma, const c_float * rho_vec, c_int polish);


/**
 * Solve linear system and store result in b
 * @param  s        Linear system solver structure
 * @param  b        Right-hand side
 * @return          Exitflag
 */
c_int solve_linsys_pardiso(pardiso_solver * s, c_float * b);


/**
 * Update linear system solver matrices
 * @param  s        Linear system solver structure
 * @param  P        Matrix P
 * @param  A        Matrix A
 * @return          Exitflag
 */
c_int update_linsys_solver_matrices_pardiso(pardiso_solver * s, const csc *P, const csc *A);


/**
 * Update rho parameter in linear system solver structure
 * @param  s        Linear system solver structure
 * @param  rho_vec  new rho_vec value
 * @return          exitflag
 */
c_int update_linsys_solver_rho_vec_pardiso(pardiso_solver * s, const c_float * rho_vec);


/**
 * Free linear system solver
 * @param s linear system solver object
 */
void free_linsys_solver_pardiso(pardiso_solver * s);




alias MKL_INT = c_int;

// Single Dynamic library interface
enum int MKL_INTERFACE_LP64 = 0x0;
enum int MKL_INTERFACE_ILP64 = 0x1;

// Solver Phases
enum int PARDISO_SYMBOLIC = 11;
enum int PARDISO_NUMERIC = 22;
enum int PARDISO_SOLVE   = 33;
enum int PARDISO_CLEANUP = -1;


// Prototypes for Pardiso functions
void pardiso(void**,         // pt
             const c_int*,   // maxfct
             const c_int*,   // mnum
             const c_int*,   // mtype
             const c_int*,   // phase
             const c_int*,   // n
             const c_float*, // a
             const c_int*,   // ia
             const c_int*,   // ja
             c_int*,         // perm
             const c_int*,   //nrhs
             c_int*,         // iparam
             const c_int*,   //msglvl
             c_float*,       // b
             c_float*,       // x
             c_int*          // error
             );
c_int mkl_set_interface_layer(c_int);
c_int mkl_get_max_threads();

// Free LDL Factorization structure
void free_linsys_solver_pardiso(pardiso_solver *s) {
    if (s) {

        // Free pardiso solver using internal function
        s.phase = PARDISO_CLEANUP;
        pardiso (cast(void**)s.pt, &(s.maxfct), &(s.mnum), &(s.mtype), &(s.phase),
                 &(s.nKKT), &(s.fdum), s.KKT_p, s.KKT_i, &(s.idum), &(s.nrhs),
                 cast(int*)s.iparm, &(s.msglvl), &(s.fdum), &(s.fdum), &(s.error));

      if ( s.error != 0 ){
version(PRINTING){
          c_eprint("ERROR in %s: Error during MKL Pardiso cleanup: %d\n", __FUNCTION__.ptr, cast(int)s.error);
}
      }
        // Check each attribute of the structure and free it if it exists
        if (s.KKT)         csc_spfree(s.KKT);
        if (s.KKT_i)       c_free(s.KKT_i);
        if (s.KKT_p)       c_free(s.KKT_p);
        if (s.bp)          c_free(s.bp);
        if (s.sol)         c_free(s.sol);
        if (s.rho_inv_vec) c_free(s.rho_inv_vec);

        // These are required for matrix updates
        if (s.Pdiag_idx) c_free(s.Pdiag_idx);
        if (s.PtoKKT)    c_free(s.PtoKKT);
        if (s.AtoKKT)    c_free(s.AtoKKT);
        if (s.rhotoKKT)  c_free(s.rhotoKKT);

        c_free(s);

    }
}


// Initialize factorization structure
c_int init_linsys_solver_pardiso(pardiso_solver ** sp, const csc * P, const csc * A, c_float sigma, const c_float * rho_vec, c_int polish){
    c_int i;                     // loop counter
    c_int nnzKKT;                // Number of nonzeros in KKT
    // Define Variables
    c_int n_plus_m;              // n_plus_m dimension


    // Allocate private structure to store KKT factorization
    pardiso_solver *s;
    s = cast(pardiso_solver*)c_calloc(1, (pardiso_solver.sizeof));
    *sp = s;

    // Size of KKT
    s.n = P.n;
    s.m = A.m;
    n_plus_m = s.n + s.m;
    s.nKKT = n_plus_m;

    // Sigma parameter
    s.sigma = sigma;

    // Polishing flag
    s.polish = polish;

    // Link Functions
    s.solve = &solve_linsys_pardiso;
    s.free = &free_linsys_solver_pardiso;
    s.update_matrices = &update_linsys_solver_matrices_pardiso;
    s.update_rho_vec = &update_linsys_solver_rho_vec_pardiso;

    // Assign type
    s.type = cast(linsys_solver_type)MKL_PARDISO_SOLVER;

    // Working vector
    s.bp = cast(c_float *)c_malloc((c_float.sizeof) * n_plus_m);

    // Solution vector
    s.sol  = cast(c_float *)c_malloc((c_float.sizeof) * n_plus_m);

    // Parameter vector
    s.rho_inv_vec = cast(c_float *)c_malloc((c_float.sizeof) * n_plus_m);

    // Form KKT matrix
    if (polish){ // Called from polish()
        // Use s.rho_inv_vec for storing param2 = vec(delta)
        for (i = 0; i < A.m; i++){
            s.rho_inv_vec[i] = sigma;
        }

        s.KKT = form_KKT(P, A, 1, sigma, s.rho_inv_vec, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL);
    }
    else { // Called from ADMM algorithm

        // Allocate vectors of indices
        s.PtoKKT = cast(int*)c_malloc((P.p[P.n]) * (c_int.sizeof));
        s.AtoKKT = cast(int*)c_malloc((A.p[A.n]) * (c_int.sizeof));
        s.rhotoKKT = cast(int*)c_malloc((A.m) * (c_int.sizeof));

        // Use s.rho_inv_vec for storing param2 = rho_inv_vec
        for (i = 0; i < A.m; i++){
            s.rho_inv_vec[i] = 1. / rho_vec[i];
        }

        s.KKT = form_KKT(P, A, 1, sigma, s.rho_inv_vec,
                             s.PtoKKT, s.AtoKKT,
                             &(s.Pdiag_idx), &(s.Pdiag_n), s.rhotoKKT);
    }

    // Check if matrix has been created
    if (!(s.KKT)) {
version(PRINTING){
	    c_eprint("ERROR in %s: Error in forming KKT matrix\n", __FUNCTION__.ptr);
}
        free_linsys_solver_pardiso(s);
        return OSQP_LINSYS_SOLVER_INIT_ERROR;
    } else {
	    // Adjust indexing for Pardiso
	    nnzKKT = s.KKT.p[s.KKT.m];
	    s.KKT_i = cast(int*)c_malloc((nnzKKT) * (c_int.sizeof));
	    s.KKT_p = cast(int*)c_malloc((s.KKT.m + 1) * (c_int.sizeof));

	    for(i = 0; i < nnzKKT; i++){
	    	s.KKT_i[i] = s.KKT.i[i] + 1;
	    }
	    for(i = 0; i < n_plus_m+1; i++){
	    	s.KKT_p[i] = s.KKT.p[i] + 1;
	    }

    }

    // Set MKL interface layer (Long integers if activated)
version(DLONG){
    mkl_set_interface_layer(MKL_INTERFACE_ILP64);
} else{
    mkl_set_interface_layer(MKL_INTERFACE_LP64);
}

    // Set Pardiso variables
    s.mtype = -2;        // Real symmetric indefinite matrix
    s.nrhs = 1;          // Number of right hand sides
    s.maxfct = 1;        // Maximum number of numerical factorizations
    s.mnum = 1;          // Which factorization to use
    s.msglvl = 0;        // Do not print statistical information
    s.error = 0;         // Initialize error flag
    for ( i = 0; i < 64; i++ ) {
        s.iparm[i] = cast(linsys_solver_type)0;  // Setup Pardiso control parameters
        s.pt[i] = cast(void*)0;     // Initialize the internal solver memory pointer
    }
    s.iparm[0] = 1;      // No solver default
    s.iparm[1] = 3;      // Fill-in reordering from OpenMP
    if (polish) {
        s.iparm[5] = 1;  // Write solution into b
    } else {
        s.iparm[5] = 0;  // Do NOT write solution into b
    }
    /* s.iparm[7] = 2;      // Max number of iterative refinement steps */
    s.iparm[7] = 0;      // Number of iterative refinement steps (auto, performs them only if perturbed pivots are obtained)
    s.iparm[9] = 13;     // Perturb the pivot elements with 1E-13
    s.iparm[34] = 0;     // Use Fortran-style indexing for indices
    /* s.iparm[34] = 1;     // Use C-style indexing for indices */

    // Print number of threads
    s.nthreads = mkl_get_max_threads();

    // Reordering and symbolic factorization
    s.phase = PARDISO_SYMBOLIC;
    pardiso (cast(void**)s.pt, &(s.maxfct), &(s.mnum), &(s.mtype), &(s.phase),
             &(s.nKKT), s.KKT.x, s.KKT_p, s.KKT_i, &(s.idum), &(s.nrhs),
             cast(int*)s.iparm, &(s.msglvl), &(s.fdum), &(s.fdum), &(s.error));
    if ( s.error != 0 ){
version(PRINTING){
        c_eprint("ERROR in %s: Error during symbolic factorization: %d\n", __FUNCTION__.ptr, cast(int)s.error);
}
        free_linsys_solver_pardiso(s);
        *sp = OSQP_NULL;
        return OSQP_LINSYS_SOLVER_INIT_ERROR;
    }

    // Numerical factorization
    s.phase = PARDISO_NUMERIC;
    pardiso (cast(void**)s.pt, &(s.maxfct), &(s.mnum), &(s.mtype), &(s.phase),
             &(s.nKKT), s.KKT.x, s.KKT_p, s.KKT_i, &(s.idum), &(s.nrhs),
             cast(int*)s.iparm, &(s.msglvl), &(s.fdum), &(s.fdum), &(s.error));
    if ( s.error ){
version (PRINTING){
        c_eprint("ERROR in %s: Error during numerical factorization: %d\n", __FUNCTION__.ptr, cast(int)s.error);
}
        free_linsys_solver_pardiso(s);
        *sp = OSQP_NULL;
        return OSQP_LINSYS_SOLVER_INIT_ERROR;
    }


    // No error
    return 0;
}

// Returns solution to linear system  Ax = b with solution stored in b
c_int solve_linsys_pardiso(pardiso_solver * s, c_float * b) {
    c_int j;

    // Back substitution and iterative refinement
    s.phase = PARDISO_SOLVE;
    pardiso (cast(void**)s.pt, &(s.maxfct), &(s.mnum), &(s.mtype), &(s.phase),
             &(s.nKKT), s.KKT.x, s.KKT_p, s.KKT_i, &(s.idum), &(s.nrhs),
             cast(int*)s.iparm, &(s.msglvl), b, s.sol, &(s.error));
    if ( s.error != 0 ){
version(PRINTING){
        c_eprint("ERROR in %s: Error during linear system solution: %d\n", __FUNCTION__.ptr, cast(int)s.error);
}
        return 1;
    }

    if (!(s.polish)) {
        /* copy x_tilde from s.sol */
        for (j = 0 ; j < s.n ; j++) {
            b[j] = s.sol[j];
        }

        /* compute z_tilde from b and s.sol */
        for (j = 0 ; j < s.m ; j++) {
            b[j + s.n] += s.rho_inv_vec[j] * s.sol[j + s.n];
        }
    }

    return 0;
}

// Update solver structure with new P and A
c_int update_linsys_solver_matrices_pardiso(pardiso_solver * s, const csc *P, const csc *A) {

    // Update KKT matrix with new P
    update_KKT_P(s.KKT, P, s.PtoKKT, s.sigma, s.Pdiag_idx, s.Pdiag_n);

    // Update KKT matrix with new A
    update_KKT_A(s.KKT, A, s.AtoKKT);

    // Perform numerical factorization
    s.phase = PARDISO_NUMERIC;
    pardiso (cast(void**)s.pt, &(s.maxfct), &(s.mnum), &(s.mtype), &(s.phase),
             &(s.nKKT), s.KKT.x, s.KKT_p, s.KKT_i, &(s.idum), &(s.nrhs),
             cast(int*)s.iparm, &(s.msglvl), &(s.fdum), &(s.fdum), &(s.error));

    // Return exit flag
    return s.error;
}


c_int update_linsys_solver_rho_vec_pardiso(pardiso_solver * s, const c_float * rho_vec) {
    c_int i;

    // Update internal rho_inv_vec
    for (i = 0; i < s.m; i++){
        s.rho_inv_vec[i] = 1. / rho_vec[i];
    }

    // Update KKT matrix with new rho_vec
    update_KKT_param2(s.KKT, s.rho_inv_vec, s.rhotoKKT, s.m);

    // Perform numerical factorization
    s.phase = PARDISO_NUMERIC;
    pardiso (cast(void**)s.pt, &(s.maxfct), &(s.mnum), &(s.mtype), &(s.phase),
             &(s.nKKT), s.KKT.x, s.KKT_p, s.KKT_i, &(s.idum), &(s.nrhs),
             cast(int*)s.iparm, &(s.msglvl), &(s.fdum), &(s.fdum), &(s.error));

    // Return exit flag
    return s.error;
}
