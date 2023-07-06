# This file is a part of PartitionedParallelSampling.jl, licensed under the MIT License (MIT).

"""
    PartitionedParallelSampling

Parallel sampling via space partitioning ([Caldwell et al.](https://arxiv.org/abs/2008.03098)).
"""
module PartitionedParallelSampling

using Dates
using Distributed
using Random
using Statistics

using StatsBase: weights
using ArraysOfArrays: flatview
using StructArrays: StructArray
using InverseFunctions: inverse
using ValueShapes: unshaped, varshape
using IntervalSets: Interval
using TypedTables: Table
using CPUTime: @CPUelapsed

using Parameters: @with_kw
using DocStringExtensions

import BAT
using BAT: AbstractMeasureOrDensity, AbstractPosteriorMeasure, PosteriorMeasure
using BAT: bat_sample, AbstractSamplingAlgorithm, MCMCSampling, OrderedResampling
using BAT: bat_integrate, IntegrationAlgorithm, DensitySampleVector
using BAT: bat_transform, AbstractTransformTarget, PriorToUniform
using BAT: BATContext

# BAT-experimental:
using BAT: truncate_density

# BAT-internal:
using BAT: var_bounds, spatialvolume

using AHMI: AHMIntegration

include("partition_algorithms.jl")
include("kd_tree.jl")
include("partitioned_sampling.jl")

end # module
