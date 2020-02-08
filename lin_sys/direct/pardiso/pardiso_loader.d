module pardiso_loader;

nothrow @nogc extern(C):

import glob_opts;
import constants;
import types;
import lib_handler;

version(Windows){
enum string PARDISOLIBNAME = "mkl_rt." ~ SHAREDLIBEXT;
} else {
enum string PARDISOLIBNAME = "libmkl_rt." ~ SHAREDLIBEXT;
}

//typedef void (*voidfun)(void);

//voidfun lh_load_sym (soHandle_t h, const char *symName);


// Interfaces for Pardiso functions
/*typedef void (*pardiso_t)(void**, const c_int*, const c_int*, const c_int*,
                          const c_int*, const c_int*, const c_float*,
                          const c_int*, const c_int*, c_int*,
                          const c_int*, c_int*, const c_int*, c_float*,
                          c_float*, c_int*);
typedef int (*mkl_set_ifl_t)(int);
typedef int (*mkl_get_mt_t)();*/
/*
// Handlers are static variables
static soHandle_t Pardiso_handle = OSQP_NULL;
static pardiso_t func_pardiso = OSQP_NULL;
static mkl_set_ifl_t func_mkl_set_interface_layer = OSQP_NULL;
static mkl_get_mt_t func_mkl_get_max_threads = OSQP_NULL;
*/
// todo : declare function pointers

void delegate(void**, const c_int*, const c_int*, const c_int*,
                          const c_int*, const c_int*, const c_float*,
                          const c_int*, const c_int*, c_int*,
                          const c_int*, c_int*, const c_int*, c_float*,
                          c_float*, c_int*) func_pardiso;

int delegate(int) func_mkl_set_interface_layer;
int delegate() func_mkl_get_max_threads;
soHandle_t Pardiso_handle = null;

// Wrappers for loaded Pardiso function handlers
void pardiso(void** pt, const c_int* maxfct, const c_int* mnum,
                  const c_int* mtype, const c_int* phase, const c_int* n,
                  const c_float* a, const c_int* ia, const c_int* ja,
                  c_int* perm, const c_int* nrhs, c_int* iparm,
                  const c_int* msglvl, c_float* b, c_float* x,
                  c_int* error) {
	if (func_pardiso){
            // Call function pardiso only if it has been initialized
	    func_pardiso(pt, maxfct, mnum, mtype, phase, n, a, ia, ja,
			 perm, nrhs, iparm, msglvl, b, x, error);
	}
	else
	{
version(PRINTING){
		c_eprint("ERROR in %s: Pardiso not loaded correctly\n", __FUNCTION__.ptr);
}
	}
}

c_int mkl_set_interface_layer(c_int code) {
    return cast(c_int)func_mkl_set_interface_layer(cast(int)code);
}

c_int mkl_get_max_threads() {
    return cast(c_int)func_mkl_get_max_threads();
}


c_int lh_load_pardiso(const char* libname) {
    // DEBUG
    // if (Pardiso_handle) return 0;

    // Load Pardiso library
    if (libname) {
        Pardiso_handle = lh_load_lib(libname);
    } else { /* try a default library name */
        Pardiso_handle = lh_load_lib(PARDISOLIBNAME);
    }
    if (!Pardiso_handle) return 1;

    // Load Pardiso functions
    //func_pardiso = cast(pardiso_t)lh_load_sym(Pardiso_handle, "pardiso");
    //func_pardiso = &lh_load_sym; // test func delegate
    lh_load_sym(Pardiso_handle, "pardiso"); // todo : test it   load library here
    //if (!func_pardiso) return 1;

    //func_mkl_set_interface_layer = cast(mkl_set_ifl_t)lh_load_sym(Pardiso_handle, "MKL_Set_Interface_Layer");
    //func_mkl_set_interface_layer = &lh_load_sym;
    lh_load_sym(Pardiso_handle, "MKL_Set_Interface_Layer"); // todo : test it
    //if (!func_mkl_set_interface_layer) return 1;

    //func_mkl_get_max_threads = cast(mkl_get_mt_t)lh_load_sym(Pardiso_handle, "MKL_Get_Max_Threads");
    //func_mkl_get_max_threads = &lh_load_sym;
    lh_load_sym(Pardiso_handle, "MKL_Get_Max_Threads");// todo : test it
    //if (!func_mkl_get_max_threads) return 1;

    return 0;
}

c_int lh_unload_pardiso() {

    if (Pardiso_handle == null) return 0;

    return lh_unload_lib(Pardiso_handle);

    /* If multiple OSQP objects are laoded, the lines below cause a crash */
    // Pardiso_handle = OSQP_NULL;
    // func_pardiso = OSQP_NULL;
    // func_mkl_set_interface_layer = OSQP_NULL;
    // func_mkl_get_max_threads = OSQP_NULL;

}
