# PartitionedParallelSampling.jl

This package provides a sampling algorithm that partitions parameter space into multiple subspaces and
samples/integrates them independently ([Caldwell et al.](https://arxiv.org/abs/2008.03098)).

PartitionedParallelSampling.jl is built to support the [BAT.jl](https://github.com/bat/BAT.jl) sampling interface, to use PartitionedParallelSampling, run

```julia
using PartitionedParallelSampling, BAT

bat_sample(target, PartitionedSampling())
```

## Installation

PartitionedParallelSampling.jl it not a registered Julia package yet and currently requires BAT.jl v3.0.0-DEV and AHMI.jl (not registered yet).

To install PartitionedParallelSampling, use

```julia
julia> using Pkg
julia> pkg"add BAT#main"
julia> pkg"add https://github.com/bat/AHMI.jl.git"
julia> pkg"add https://github.com/bat/PartitionedParallelSampling.jl.git"
```


## Citing PartitionedParallelSampling

If you use PartitionedParallelSampling as an important part of your work, please cite 
*Hafych et al. "Parallelizing MCMC Sampling via Space Partitioning", [arXiv:2008.03098 (2020)](https://arxiv.org/abs/2008.03098)*.

```
@article{Hafych:2008.03098,
  author        = {Hafych, Vasyl and Eller, Philipp and Caldwell, Allen and Schulz, Oliver},
  title         = {Parallelizing MCMC Sampling via Space Partitioning},
  year          = {2018},
  month         = {8},
  archiveprefix = {arXiv},
  eprint        = {2008.03098},
  primaryclass  = {stat.CO},
}
```
