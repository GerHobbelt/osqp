module qdldl_interface;

nothrow @nogc extern(C):

import glob_opts;
import types; // CSC matrix type
import constants; // for linsys_solver_type
import qdldl_types; // for QDLDL_float and others
import cs;

import qdldl;
import amd_internal;
/**
 * QDLDL solver structure
 */

//struct qdldl {
struct qdldl_solver {
    linsys_solver_type type;

    /**
     * @name Functions
     * @{
     */
    //c_int (*solve)(struct qdldl * self, c_float * b);
    c_int function(qdldl_solver* self, c_float* b) solve;

version (EMBEDDED){}
else {
    //void (*free)(struct qdldl * self); ///< Free workspace (only if desktop)
    void function(qdldl_solver* self) free;///< Free workspace (only if desktop)
}

    // This used only in non embedded or embedded 2 version
version (EMBEDDED_1){}
else {
    //c_int (*update_matrices)(struct qdldl * self, const csc *P, const csc *A);  ///< Update solver matrices
    //c_int (*update_rho_vec)(struct qdldl * self, const c_float * rho_vec);      ///< Update rho_vec parameter
    // todo: test qdldl_solver alias    
    c_int function(qdldl_solver* self, const csc* P, const csc* A) update_matrices;///< Update solver matrices
    c_int function(qdldl_solver* self, const c_float* rho_vec) update_rho_vec; ///< Update rho_vec parameter
}

version (EMBEDDED){}
else {
    c_int nthreads;
}
    /** @} */

    /**
     * @name Attributes
     * @{
     */
    csc *L;                 ///< lower triangular matrix in LDL factorization
    c_float *Dinv;          ///< inverse of diag matrix in LDL (as a vector)
    c_int   *P;             ///< permutation of KKT matrix for factorization
    c_float *bp;            ///< workspace memory for solves
    c_float *sol;           ///< solution to the KKT system
    c_float *rho_inv_vec;   ///< parameter vector
    c_float sigma;          ///< scalar parameter
version (EMBEDDED){}
else {
    c_int polish;           ///< polishing flag
}
    c_int n;                ///< number of QP variables
    c_int m;                ///< number of QP constraints


version (EMBEDDED_1){}
else {
    // These are required for matrix updates
    
    c_int * Pdiag_idx;
    c_int Pdiag_n;  ///< index and number of diagonal elements in P
    csc   * KKT;                 ///< Permuted KKT matrix in sparse form (used to update P and A matrices)
    c_int * PtoKKT;
    c_int * AtoKKT;    ///< Index of elements from P and A to KKT matrix
    c_int * rhotoKKT;            ///< Index of rho places in KKT matrix
    
    // QDLDL Numeric workspace
    QDLDL_float *D;
    QDLDL_int   *etree;
    QDLDL_int   *Lnz;
    QDLDL_int   *iwork;
    QDLDL_bool  *bwork;
    QDLDL_float *fwork;
}
    /** @} */
};

//typedef struct qdldl qdldl_solver;
//alias qdldl_solver = qdldl;

version (EMBEDDED){}
else {
    import amd; // #ifndef EMBEDDED
}

version (EMBEDDED_1) {}
else {
    import kkt; // #if EMBEDDED != 1
}

version (EMBEDDED){}
else {
// Free LDL Factorization structure
void free_linsys_solver_qdldl(qdldl_solver *s) {
    if (s) {
        if (s.L)           csc_spfree(s.L);
        if (s.P)           c_free(s.P);
        if (s.Dinv)        c_free(s.Dinv);
        if (s.bp)          c_free(s.bp);
        if (s.sol)         c_free(s.sol);
        if (s.rho_inv_vec) c_free(s.rho_inv_vec);

        // These are required for matrix updates
        if (s.Pdiag_idx) c_free(s.Pdiag_idx);
        if (s.KKT)       csc_spfree(s.KKT);
        if (s.PtoKKT)    c_free(s.PtoKKT);
        if (s.AtoKKT)    c_free(s.AtoKKT);
        if (s.rhotoKKT)  c_free(s.rhotoKKT);

        // QDLDL workspace
        if (s.D)         c_free(s.D);
        if (s.etree)     c_free(s.etree);
        if (s.Lnz)       c_free(s.Lnz);
        if (s.iwork)     c_free(s.iwork);
        if (s.bwork)     c_free(s.bwork);
        if (s.fwork)     c_free(s.fwork);
        c_free(s);

    }
}


/**
 * Compute LDL factorization of matrix A
 * @param  A    Matrix to be factorized
 * @param  p    Private workspace
 * @param  nvar Number of QP variables
 * @return      exitstatus (0 is good)
 */
static c_int LDL_factor(csc *A,  qdldl_solver * p, c_int nvar){

    c_int sum_Lnz;
    c_int factor_status;

    // Compute elimination tree
    //sum_Lnz = QDLDL_etree(A.n, A.p, A.i, p.iwork, p.Lnz, p.etree);
    sum_Lnz = QDLDL_etree(cast(const QDLDL_int)(A.n), cast(const QDLDL_int*)(A.p), cast(const QDLDL_int*)(A.i), p.iwork, p.Lnz, p.etree);

    if (sum_Lnz < 0){
      // Error
version(PRINTING) {
      c_eprint(cast(char*)"ERROR in %s: Error in KKT matrix LDL factorization when computing the elimination tree. A is not perfectly upper triangular\n", cast(char*)__FUNCTION__);
}
      return sum_Lnz;
    }

    // Allocate memory for Li and Lx
    p.L.i = cast(c_int *)c_malloc((c_int.sizeof)*sum_Lnz);
    p.L.x = cast(c_float *)c_malloc((c_float.sizeof)*sum_Lnz);

    // Factor matrix
    factor_status = QDLDL_factor(A.n, A.p, A.i, A.x,
                                 p.L.p, p.L.i, p.L.x,
                                 p.D, p.Dinv, p.Lnz,
                                 p.etree, p.bwork, p.iwork, p.fwork);


    if (factor_status < 0){
      // Error
version(PRINTING) {
      c_eprint(cast(char*)"ERROR in %s: Error in KKT matrix LDL factorization when computing the nonzero elements. There are zeros in the diagonal matrix\n", cast(char*)__FUNCTION__);
}
      return factor_status;
    } else if (factor_status < nvar) {
      // Error: Number of positive elements of D should be equal to nvar
version(PRINTING) {
      c_eprint(cast(char*)"ERROR in %s: Error in KKT matrix LDL factorization when computing the nonzero elements. The problem seems to be non-convex\n", cast(char*)__FUNCTION__);
}
      return -2;
    }

    return 0;

}


static c_int permute_KKT(csc ** KKT, qdldl_solver * p, c_int Pnz, c_int Anz, c_int m, c_int * PtoKKT, c_int * AtoKKT, c_int * rhotoKKT){
    c_float *info;
    c_int amd_status;
    c_int * Pinv;
    csc *KKT_temp;
    c_int * KtoPKPt;
    c_int i; // Indexing

    info = cast(c_float *)c_malloc(AMD_INFO * (c_float.sizeof));

    // Compute permutation matrix P using AMD
    //amd_status = amd_l_order((*KKT).n, (*KKT).p, (*KKT).i, p.P, cast(c_float *)OSQP_NULL, info);
    //amd_status = amd_order((*KKT).n, (*KKT).p, (*KKT).i, p.P, cast(c_float *)OSQP_NULL, info);
    amd_status = AMD_order(cast(c_int)((*KKT).n), cast(const c_int*)(*KKT).p, cast(const c_int*)(*KKT).i, cast(c_int*)p.P, cast(c_float *)OSQP_NULL, info);

    if (amd_status < 0) {
        // Free Amd info and return an error
        c_free(info);
        return amd_status;
    }


    // Inverse of the permutation vector
    Pinv = csc_pinv(p.P, (*KKT).n);

    // Permute KKT matrix
    if (!PtoKKT && !AtoKKT && !rhotoKKT){  // No vectors to be stored
        // Assign values of mapping
        KKT_temp = csc_symperm((*KKT), Pinv, OSQP_NULL, 1);
    }
    else {
        // Allocate vector of mappings from unpermuted to permuted
        KtoPKPt = cast (c_int *) c_malloc((*KKT).p[(*KKT).n] * (c_int.sizeof));
        KKT_temp = csc_symperm((*KKT), Pinv, KtoPKPt, 1);

        // Update vectors PtoKKT, AtoKKT and rhotoKKT
        if (PtoKKT){
            for (i = 0; i < Pnz; i++){
                PtoKKT[i] = KtoPKPt[PtoKKT[i]];
            }
        }
        if (AtoKKT){
            for (i = 0; i < Anz; i++){
                AtoKKT[i] = KtoPKPt[AtoKKT[i]];
            }
        }
        if (rhotoKKT){
            for (i = 0; i < m; i++){
                rhotoKKT[i] = KtoPKPt[rhotoKKT[i]];
            }
        }

        // Cleanup vector of mapping
        c_free(KtoPKPt);
    }

    // Cleanup
    // Free previous KKT matrix and assign pointer to new one
    csc_spfree((*KKT));
    (*KKT) = KKT_temp;
    // Free Pinv
    c_free(Pinv);
    // Free Amd info
    c_free(info);

    return 0;
}


// Initialize LDL Factorization structure
c_int init_linsys_solver_qdldl(qdldl_solver ** sp, const csc * P, const csc * A, c_float sigma, const c_float * rho_vec, c_int polish){

    // Define Variables
    csc * KKT_temp;     // Temporary KKT pointer
    c_int i;            // Loop counter
    c_int n_plus_m;     // Define n_plus_m dimension

    // Allocate private structure to store KKT factorization
    qdldl_solver *s;
    //s = c_calloc(1, sizeof(qdldl_solver));    
    s = cast (qdldl_solver*)c_calloc(1, qdldl_solver.sizeof);
    

    *sp = s;

    // Size of KKT
    s.n = P.n;
    s.m = A.m;
    n_plus_m = s.n + s.m;

    // Sigma parameter
    s.sigma = sigma;

    // Polishing flag
    s.polish = polish;

    // Link Functions
    s.solve = &solve_linsys_qdldl;

version (EMBEDDED){}
else {
    s.free = &free_linsys_solver_qdldl;
}

version (EMBEDDED_1){}
else { // #if EMBEDDED != 1
    s.update_matrices = &update_linsys_solver_matrices_qdldl;
    s.update_rho_vec = &update_linsys_solver_rho_vec_qdldl;
}

    // Assign type
    s.type = cast(linsys_solver_type)QDLDL_SOLVER;

    // Set number of threads to 1 (single threaded)
    s.nthreads = 1;

    // Sparse matrix L (lower triangular)
    // NB: We don not allocate L completely (CSC elements)
    //      L will be allocated during the factorization depending on the
    //      resulting number of elements.
    s.L = cast(csc*)c_malloc((csc.sizeof));
    s.L.m = n_plus_m;
    s.L.n = n_plus_m;
    s.L.nz = -1;

    // Diagonal matrix stored as a vector D
    s.Dinv = cast(QDLDL_float *)c_malloc((QDLDL_float.sizeof) * n_plus_m);
    s.D    = cast(QDLDL_float *)c_malloc((QDLDL_float.sizeof) * n_plus_m);

    // Permutation vector P
    s.P    = cast(QDLDL_int *)c_malloc((QDLDL_int.sizeof) * n_plus_m);

    // Working vector
    s.bp   = cast(QDLDL_float *)c_malloc((QDLDL_float.sizeof) * n_plus_m);

    // Solution vector
    s.sol  = cast(QDLDL_float *)c_malloc((QDLDL_float.sizeof) * n_plus_m);

    // Parameter vector
    s.rho_inv_vec = cast(c_float *)c_malloc((c_float.sizeof) * s.m);

    // Elimination tree workspace
    s.etree = cast(QDLDL_int *)c_malloc(n_plus_m * (QDLDL_int.sizeof));
    s.Lnz   = cast(QDLDL_int *)c_malloc(n_plus_m * (QDLDL_int.sizeof));

    // Preallocate L matrix (Lx and Li are sparsity dependent)
    s.L.p = cast(c_int *)c_malloc((n_plus_m+1) * (QDLDL_int.sizeof));

    // Lx and Li are sparsity dependent, so set them to
    // null initially so we don't try to free them prematurely
    s.L.i = OSQP_NULL;
    s.L.x = OSQP_NULL;

    // Preallocate workspace
    s.iwork = cast(QDLDL_int *)c_malloc((QDLDL_int.sizeof)*(3*n_plus_m));
    s.bwork = cast(QDLDL_bool *)c_malloc((QDLDL_bool.sizeof)*n_plus_m);
    s.fwork = cast(QDLDL_float *)c_malloc((QDLDL_float.sizeof)*n_plus_m);

    // Form and permute KKT matrix
    if (polish){ // Called from polish()
        // Use s.rho_inv_vec for storing param2 = vec(delta)
        for (i = 0; i < A.m; i++){
            s.rho_inv_vec[i] = sigma;
        }

        KKT_temp = form_KKT(P, A, 0, sigma, s.rho_inv_vec, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL);

        // Permute matrix
        if (KKT_temp){
            //permute_KKT(&KKT_temp, s, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL, OSQP_NULL);
            permute_KKT(&KKT_temp, s, 0, 0, 0, OSQP_NULL, OSQP_NULL, OSQP_NULL);
        }
    }
    else { // Called from ADMM algorithm

        // Allocate vectors of indices
        s.PtoKKT = cast(c_int*)c_malloc((P.p[P.n]) * (c_int.sizeof));
        s.AtoKKT = cast(c_int*)c_malloc((A.p[A.n]) * (c_int.sizeof));
        s.rhotoKKT = cast(c_int*)c_malloc((A.m) * (c_int.sizeof));

        // Use p.rho_inv_vec for storing param2 = rho_inv_vec
        for (i = 0; i < A.m; i++){
            s.rho_inv_vec[i] = 1. / rho_vec[i];
        }

        KKT_temp = form_KKT(P, A, 0, sigma, s.rho_inv_vec,
                            s.PtoKKT, s.AtoKKT,
                            &(s.Pdiag_idx), &(s.Pdiag_n), s.rhotoKKT);

        // Permute matrix
        if (KKT_temp)
            permute_KKT(&KKT_temp, s, P.p[P.n], A.p[A.n], A.m, s.PtoKKT, s.AtoKKT, s.rhotoKKT);
    }

    // Check if matrix has been created
    if (!KKT_temp){
version (PRINTING){
        c_eprint(cast(char*)"ERROR in %s: Error forming and permuting KKT matrix\n", cast(char*)__FUNCTION__);
}
        free_linsys_solver_qdldl(s);
        *sp = OSQP_NULL;
        return OSQP_LINSYS_SOLVER_INIT_ERROR;
    }

    // Factorize the KKT matrix
    if (LDL_factor(KKT_temp, s, P.n) < 0) {
        csc_spfree(KKT_temp);
        free_linsys_solver_qdldl(s);
        *sp = OSQP_NULL;
        return OSQP_NONCVX_ERROR;
    }

    if (polish){ // If KKT passed, assign it to KKT_temp
        // Polish, no need for KKT_temp
        csc_spfree(KKT_temp);
    }
    else { // If not embedded option 1 copy pointer to KKT_temp. Do not free it.
        s.KKT = KKT_temp;
    }


    // No error
    return 0;
}
} // !version (EMBEDDED)


// Permute x = P*b using P
void permute_x(c_int n, c_float * x, const c_float * b, const c_int * P) {
    c_int j;
    for (j = 0 ; j < n ; j++) x[j] = b[P[j]];
}

// Permute x = P'*b using P
void permutet_x(c_int n, c_float * x, const c_float * b, const c_int * P) {
    c_int j;
    for (j = 0 ; j < n ; j++) x[P[j]] = b[j];
}


static void LDLSolve(c_float *x, c_float *b, const csc *L, const c_float *Dinv, const c_int *P, c_float *bp) {
    /* solves P'LDL'P x = b for x */
    permute_x(L.n, bp, b, P);
    QDLDL_solve(L.n, L.p, L.i, L.x, Dinv, bp);
    permutet_x(L.n, x, bp, P);

}

version (EMBEDDED){
    c_int solve_linsys_qdldl(qdldl_solver * s, c_float * b) {
        c_int j;

        /* stores solution to the KKT system in s.sol */
        LDLSolve(s.sol, b, s.L, s.Dinv, s.P, s.bp);

        /* copy x_tilde from s.sol */
        for (j = 0 ; j < s.n ; j++) {
            b[j] = s.sol[j];
        }

        /* compute z_tilde from b and s.sol */
        for (j = 0 ; j < s.m ; j++) {
            b[j + s.n] += s.rho_inv_vec[j] * s.sol[j + s.n];
        }

        return 0;
    }
}
else {
    c_int solve_linsys_qdldl(qdldl_solver * s, c_float * b) {
        c_int j;

        if (s.polish) {
            /* stores solution to the KKT system in b */
            LDLSolve(b, b, s.L, s.Dinv, s.P, s.bp);
        } else {
            /* stores solution to the KKT system in s.sol */
            LDLSolve(s.sol, b, s.L, s.Dinv, s.P, s.bp);

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
}

version (EMBEDDED_1){}
else { // #if EMBEDDED != 1
// Update private structure with new P and A
c_int update_linsys_solver_matrices_qdldl(qdldl_solver * s, const csc *P, const csc *A) {

    // Update KKT matrix with new P
    update_KKT_P(s.KKT, P, s.PtoKKT, s.sigma, s.Pdiag_idx, s.Pdiag_n);

    // Update KKT matrix with new A
    update_KKT_A(s.KKT, A, s.AtoKKT);

    return (QDLDL_factor(s.KKT.n, s.KKT.p, s.KKT.i, s.KKT.x,
        s.L.p, s.L.i, s.L.x, s.D, s.Dinv, s.Lnz,
        s.etree, s.bwork, s.iwork, s.fwork) < 0);

}


c_int update_linsys_solver_rho_vec_qdldl(qdldl_solver * s, const c_float * rho_vec){
    c_int i;

    // Update internal rho_inv_vec
    for (i = 0; i < s.m; i++){
        s.rho_inv_vec[i] = 1. / rho_vec[i];
    }

    // Update KKT matrix with new rho_vec
    update_KKT_param2(s.KKT, s.rho_inv_vec, s.rhotoKKT, s.m);

    return (QDLDL_factor(s.KKT.n, s.KKT.p, s.KKT.i, s.KKT.x,
        s.L.p, s.L.i, s.L.x, s.D, s.Dinv, s.Lnz,
        s.etree, s.bwork, s.iwork, s.fwork) < 0);
}

} // !version (EMBEDDED_1)