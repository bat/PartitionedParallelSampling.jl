# This file is a part of PartitionedParallelSampling.jl, licensed under the MIT License (MIT).

using Test
using PartitionedParallelSampling
import Documenter

Documenter.DocMeta.setdocmeta!(
    PartitionedParallelSampling,
    :DocTestSetup,
    :(using PartitionedParallelSampling);
    recursive=true,
)
Documenter.doctest(PartitionedParallelSampling)
