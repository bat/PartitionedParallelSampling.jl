# This file is a part of PartitionedParallelSampling.jl, licensed under the MIT License (MIT).

import Test

import Logging
import TerminalLoggers
Logging.global_logger(TerminalLoggers.TerminalLogger(stderr, Logging.Error))

Test.@testset "Package PartitionedParallelSampling" begin
    include("test_partitioned_sampling.jl")
    include("test_docs.jl")
end # testset
