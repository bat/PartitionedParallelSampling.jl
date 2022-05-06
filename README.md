# PartitionedParallelSampling.jl

[![Documentation for stable version](https://img.shields.io/badge/docs-stable-blue.svg)](https://bat.github.io/PartitionedParallelSampling.jl/stable)
[![Documentation for development version](https://img.shields.io/badge/docs-dev-blue.svg)](https://bat.github.io/PartitionedParallelSampling.jl/dev)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://github.com/bat/PartitionedParallelSampling.jl/workflows/CI/badge.svg?branch=main)](https://github.com/bat/PartitionedParallelSampling.jl/actions?query=workflow%3ACI)
[![Codecov](https://codecov.io/gh/bat/PartitionedParallelSampling.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/bat/PartitionedParallelSampling.jl)

This package provides a sampling algorithm that partitions parameter space into multiple subspaces and samples/integrates them independently ([Caldwell et al.](https://arxiv.org/abs/2008.03098)).

## Installation

PartitionedParallelSampling.jl it not a registered Julia package yet and currently requires BAT.jl v3.0.0-DEV and AHMI.jl (not registered yet).

To install PartitionedParallelSampling, use

```julia
julia> using Pkg
julia> pkg"add BAT#main"
julia> pkg"add https://github.com/bat/AHMI.jl.git"
julia> pkg"add https://github.com/bat/PartitionedParallelSampling.jl.git"
```

## Documentation

* [Documentation for stable version](https://bat.github.io/PartitionedParallelSampling.jl/stable)
* [Documentation for development version](https://bat.github.io/PartitionedParallelSampling.jl/dev)
