# Dataset

```@meta
CurrentModule = HDF5
```

Many dataset operations are available through the indexing interface, which is aliased to the functional interface. Below describes the functional interface.

```@docs
Dataset
create_dataset
Base.copyto!
Base.similar
create_external_dataset
get_datasets
open_dataset
write_dataset
read_dataset
```

## Chunks

```@docs
do_read_chunk
do_write_chunk
get_chunk_index
get_chunk_info_all
get_chunk_length
get_chunk_offset
get_num_chunks
get_num_chunks_per_dim
read_chunk
write_chunk
```

### Private Implementation

These functions select private implementations of the public high-level API.
They should be used for diagnostic purposes only.

```@docs
_get_chunk_info_all_by_index
_get_chunk_info_all_by_iter
```
