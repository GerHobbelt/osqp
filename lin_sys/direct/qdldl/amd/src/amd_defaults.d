/* ========================================================================= */
/* === AMD_defaults ======================================================== */
/* ========================================================================= */

/* ------------------------------------------------------------------------- */
/* AMD, Copyright (c) Timothy A. Davis,					     */
/* Patrick R. Amestoy, and Iain S. Duff.  See ../README.txt for License.     */
/* email: DrTimothyAldenDavis@gmail.com                                      */
/* ------------------------------------------------------------------------- */

/* User-callable.  Sets default control parameters for AMD.  See amd.h
 * for details.
 */

module amd_defaults;

nothrow @nogc extern(C):

import glob_opts;
import amd_internal;
import amd;

/* ========================================================================= */
/* === AMD defaults ======================================================== */
/* ========================================================================= */

void AMD_defaults
(
    c_float *Control
)
{
    Int i ;

    if (Control != cast(c_float *) NULL)
    {
	for (i = 0 ; i < AMD_CONTROL ; i++)
	{
	    Control [i] = 0 ;
	}
	Control [AMD_DENSE] = AMD_DEFAULT_DENSE ;
	Control [AMD_AGGRESSIVE] = AMD_DEFAULT_AGGRESSIVE ;
    }
}
