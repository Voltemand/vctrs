#include "vctrs.h"
#include "utils.h"

// Initialised at load time
static SEXP syms_vec_is_vector_dispatch = NULL;
static SEXP fns_vec_is_vector_dispatch = NULL;


bool is_data_frame(SEXP x) {
  return Rf_inherits(x, "data.frame");
}

bool is_record(SEXP x) {
  return Rf_inherits(x, "vctrs_rcrd") || Rf_inherits(x, "POSIXlt");
}

enum vctrs_type vec_typeof_impl(SEXP x, bool dispatch) {
  switch (TYPEOF(x)) {
  case NILSXP: return vctrs_type_null;
  case LGLSXP: return OBJECT(x) && dispatch ? vctrs_type_s3 : vctrs_type_logical;
  case INTSXP: return OBJECT(x) && dispatch ? vctrs_type_s3 : vctrs_type_integer;
  case REALSXP: return OBJECT(x) && dispatch ? vctrs_type_s3 : vctrs_type_double;
  case CPLXSXP: return OBJECT(x) && dispatch ? vctrs_type_s3 : vctrs_type_complex;
  case STRSXP: return OBJECT(x) && dispatch ? vctrs_type_s3 : vctrs_type_character;
  case RAWSXP: return OBJECT(x) && dispatch ? vctrs_type_s3 : vctrs_type_raw;
  case VECSXP:
    if (!OBJECT(x)) {
      return vctrs_type_list;
    } else if (is_data_frame(x)) {
      return vctrs_type_dataframe;
    } else if (dispatch) {
      return vctrs_type_s3;
    } else {
      return vctrs_type_scalar;
    }
  default:
    return vctrs_type_scalar;
  }
}
enum vctrs_type vec_typeof(SEXP x) {
  return vec_typeof_impl(x, true);
}

const char* vec_type_as_str(enum vctrs_type type) {
  switch (type) {
  case vctrs_type_null:      return "null";
  case vctrs_type_logical:   return "logical";
  case vctrs_type_integer:   return "integer";
  case vctrs_type_double:    return "double";
  case vctrs_type_complex:   return "complex";
  case vctrs_type_character: return "character";
  case vctrs_type_raw:       return "raw";
  case vctrs_type_list:      return "list";
  case vctrs_type_dataframe: return "dataframe";
  case vctrs_type_s3:        return "s3";
  case vctrs_type_scalar:    return "scalar";
  }
}

static bool vec_is_vector_rec(SEXP x, bool dispatch) {
  switch (vec_typeof_impl(x, dispatch)) {
  case vctrs_type_logical:
  case vctrs_type_integer:
  case vctrs_type_double:
  case vctrs_type_complex:
  case vctrs_type_character:
  case vctrs_type_raw:
  case vctrs_type_list:
  case vctrs_type_dataframe:
    return true;

  case vctrs_type_s3: {
    SEXP proxy = PROTECT(vec_proxy(x));
    bool out = vec_is_vector_rec(proxy, false);
    UNPROTECT(1);
    return out;
  }

  default:
    return false;
  }
}

// [[ include("vctrs.h") ]]
bool vec_is_vector(SEXP x) {
  return vec_is_vector_rec(x, true);
}

// [[ register ]]
SEXP vctrs_is_vector(SEXP x, SEXP dispatch) {
  return Rf_ScalarLogical(vec_is_vector_rec(x, LOGICAL(dispatch)[0]));
}

void vctrs_stop_unsupported_type(enum vctrs_type type, const char* fn) {
  Rf_errorcall(R_NilValue,
               "Unsupported vctrs type `%s` in `%s`",
               vec_type_as_str(type),
               fn);
}

SEXP vctrs_typeof(SEXP x, SEXP dispatch) {
  return Rf_mkString(vec_type_as_str(vec_typeof_impl(x, LOGICAL(dispatch)[0])));
}


SEXP vctrs_shared_empty_lgl = NULL;
SEXP vctrs_shared_empty_int = NULL;
SEXP vctrs_shared_empty_dbl = NULL;
SEXP vctrs_shared_empty_cpl = NULL;
SEXP vctrs_shared_empty_chr = NULL;
SEXP vctrs_shared_empty_raw = NULL;
SEXP vctrs_shared_empty_list = NULL;

SEXP vctrs_shared_true = NULL;
SEXP vctrs_shared_false = NULL;

Rcomplex vctrs_shared_na_cpl;

void vctrs_init_types(SEXP ns) {
  syms_vec_is_vector_dispatch = Rf_install("vec_is_vector");
  fns_vec_is_vector_dispatch = Rf_findVar(syms_vec_is_vector_dispatch, ns);

  vctrs_shared_empty_lgl = Rf_allocVector(LGLSXP, 0);
  R_PreserveObject(vctrs_shared_empty_lgl);
  MARK_NOT_MUTABLE(vctrs_shared_empty_lgl);

  vctrs_shared_empty_int = Rf_allocVector(INTSXP, 0);
  R_PreserveObject(vctrs_shared_empty_int);
  MARK_NOT_MUTABLE(vctrs_shared_empty_int);

  vctrs_shared_empty_dbl = Rf_allocVector(REALSXP, 0);
  R_PreserveObject(vctrs_shared_empty_dbl);
  MARK_NOT_MUTABLE(vctrs_shared_empty_dbl);

  vctrs_shared_empty_cpl = Rf_allocVector(CPLXSXP, 0);
  R_PreserveObject(vctrs_shared_empty_cpl);
  MARK_NOT_MUTABLE(vctrs_shared_empty_cpl);

  vctrs_shared_empty_chr = Rf_allocVector(STRSXP, 0);
  R_PreserveObject(vctrs_shared_empty_chr);
  MARK_NOT_MUTABLE(vctrs_shared_empty_chr);

  vctrs_shared_empty_raw = Rf_allocVector(RAWSXP, 0);
  R_PreserveObject(vctrs_shared_empty_raw);
  MARK_NOT_MUTABLE(vctrs_shared_empty_raw);

  vctrs_shared_empty_list = Rf_allocVector(VECSXP, 0);
  R_PreserveObject(vctrs_shared_empty_list);
  MARK_NOT_MUTABLE(vctrs_shared_empty_list);

  vctrs_shared_true = Rf_allocVector(LGLSXP, 1);
  R_PreserveObject(vctrs_shared_true);
  MARK_NOT_MUTABLE(vctrs_shared_true);
  LOGICAL(vctrs_shared_true)[0] = 1;

  vctrs_shared_false = Rf_allocVector(LGLSXP, 1);
  R_PreserveObject(vctrs_shared_false);
  MARK_NOT_MUTABLE(vctrs_shared_false);
  LOGICAL(vctrs_shared_false)[0] = 0;

  vctrs_shared_na_cpl.i = NA_REAL;
  vctrs_shared_na_cpl.r = NA_REAL;
}
