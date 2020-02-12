
module qdldl_types;

import core.stdc.limits;

// QDLDL types

/* Use customized number representation -----------------------------------   */
version (DLONG)
{
  alias QDLDL_int = long;
  enum long QDLDL_INT_MAX = LLONG_MAX;

}
else { // standard integers
  alias QDLDL_int = int;       /* for indices */
  enum long QDLDL_INT_MAX = INT_MAX;
}

version (DFLOAT)
{
  alias QDLDL_float = float;  /* for numerical values  */
}
else {
  alias QDLDL_float = double;
}


alias QDLDL_BOOL_TYPE = ubyte;
alias QDLDL_bool = ubyte;
