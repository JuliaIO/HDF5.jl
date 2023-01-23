# Dataset

```@meta
CurrentModule = HDF5
```

Many dataset operations are available through the indexing interface, which is aliased to the functional interface. Below describes the functional interface.

```@docs
create_dataset
Base.copyto!
Base.similar
create_external_dataset
get_datasets
```

## Chunks

```@docs
do_read_chunk
do_write_chunk
get_chunk_index
get_chunk_length
get_chunk_offset
get_num_chunks
get_num_chunks_per_dim
read_chunk
write_chunk
```