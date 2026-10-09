/*
 * A minimal HDF5 filter plugin used by test/filter_implementations.jl to test that
 * HDF5.jl can prefer a plugin that libhdf5 loads itself (from HDF5_PLUGIN_PATH) over
 * a Julia implementation of the same filter id.
 *
 * The filter XORs every byte with 0x5a and has the experimental filter id 301.
 * It is declared without the HDF5 headers so that building it needs only a C compiler.
 */
#include <stddef.h>

#define XOR_FILTER_ID 301
#define H5PL_TYPE_FILTER 0

typedef size_t (*filter_func)(unsigned, size_t, const unsigned *, size_t, size_t *, void **);

/* Matches H5Z_class2_t from H5Zpublic.h */
typedef struct {
    int version;
    int id;
    unsigned encoder_present;
    unsigned decoder_present;
    const char *name;
    void *can_apply;
    void *set_local;
    filter_func filter;
} filter_class;

static size_t
xor_filter(unsigned flags, size_t cd_nelmts, const unsigned *cd_values, size_t nbytes,
           size_t *buf_size, void **buf)
{
    unsigned char *p = (unsigned char *)*buf;
    size_t i;
    (void)flags;
    (void)cd_nelmts;
    (void)cd_values;
    (void)buf_size;
    for (i = 0; i < nbytes; i++)
        p[i] ^= 0x5a;
    return nbytes;
}

static const filter_class xor_class = {
    1, /* H5Z_CLASS_T_VERS */
    XOR_FILTER_ID, 1, 1, "native xor test filter", NULL, NULL, xor_filter};

int
H5PLget_plugin_type(void)
{
    return H5PL_TYPE_FILTER;
}

const void *
H5PLget_plugin_info(void)
{
    return &xor_class;
}
