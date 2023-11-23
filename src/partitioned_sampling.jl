# This file is a part of PartitionedParallelSampling.jl, licensed under the MIT License (MIT).

"""
    struct PartitionedSampling <: AbstractSamplingAlgorithm

A sampling algorithm that partitions parameter space into multiple subspaces and
samples/integrates them independently ([Caldwell et al.](https://arxiv.org/abs/2008.03098)).

Constructors:

* ```$(FUNCTIONNAME)(; fields...)```

Fields:

$(TYPEDFIELDS)
"""
@with_kw struct PartitionedSampling{
    TR<:AbstractTransformTarget,
    S<:AbstractSamplingAlgorithm,
    E<:AbstractSamplingAlgorithm,
    I<:IntegrationAlgorithm,
    P<:SpacePartitioningAlgorithm
} <: AbstractSamplingAlgorithm
    trafo::TR = PriorToUniform()
    npartitions::Integer = 10
    sampler::S = MCMCSampling(strict=false)
    exploration_sampler::E = MCMCSampling(nchains=30, nsteps = 800, strict=false)
    partitioner::P = KDTreePartitioning()
    integrator::I = AHMIntegration()
    nmax_resampling::AbstractFloat = 5
end

export PartitionedSampling

function BAT.bat_sample_impl(m::BATMeasure, algorithm::PartitionedSampling, context::BATContext)
    transformed_m, trafo = BAT.transform_and_unshape(algorithm.trafo, m, context)

    @info "Generating Exploration Samples"
    exploration_samples = bat_sample(transformed_m, algorithm.exploration_sampler).result

    @info "Constructing Partition Tree"
    partition_tree, cost_values = partition_space(exploration_samples, algorithm.npartitions, algorithm.partitioner)
    # Convert 'partition_tree' structure into a set of truncated posteriors:
    posteriors_array = convert_to_posterior(transformed_m, partition_tree, extend_bounds = algorithm.partitioner.extend_bounds)

    @info "Sampling Subspaces"
    iterator_subspaces = [
        [subspace_ind, posteriors_array[subspace_ind], algorithm.sampler] for subspace_ind in Base.OneTo(algorithm.npartitions)]
    samples_subspaces_run = pmap(inp -> sample_subspace(inp..., context), iterator_subspaces)

    unconv_mask = [samples_subspace.isvalid for samples_subspace in samples_subspaces_run] # returns "false" if subspace was not converged during tuning cycle
    unconv_ind = findall(x->x==false, unconv_mask)
    rep_sspace = !isempty(unconv_ind) # perform resampling if "true"

    if algorithm.nmax_resampling > 0
        samples_subspaces = samples_subspaces_run[unconv_mask]
    else
        samples_subspaces = samples_subspaces_run
    end

    rec_level = 1
    resampled_trees = []

    while rep_sspace && rec_level <= algorithm.nmax_resampling

        @info "Re-Sampling Subspaces: #$rec_level"

        posteriors_array_run = []

        for (ind, rep_ind) in enumerate(unconv_ind)

            exploration_samples_rep = bat_sample(
                samples_subspaces_run[rep_ind].samples,
                OrderedResampling(nsamples=algorithm.exploration_sampler.nsteps),
                context
            ).result

            partition_tree_rep, _ = partition_space(exploration_samples_rep, 2, algorithm.partitioner)
            push!(resampled_trees, partition_tree_rep)
            posteriors_rep_array = convert_to_posterior(posteriors_array[rep_ind], partition_tree_rep, extend_bounds = algorithm.partitioner.extend_bounds)

            append!(posteriors_array_run, posteriors_rep_array)

        end

        iterator_subspaces = [
            [subspace_ind, posteriors_array_run[subspace_ind], algorithm.sampler] for subspace_ind in Base.OneTo(length(posteriors_array_run))]
        samples_subspaces_run = pmap(inp -> sample_subspace(inp...), iterator_subspaces)

        unconv_mask = [samples_subspace.isvalid for samples_subspace in samples_subspaces_run]
        unconv_ind = findall(x->x==false, unconv_mask)
        rep_sspace = !isempty(unconv_ind)

        rec_level += 1
        if rep_sspace && (rec_level > algorithm.nmax_resampling)
            @warn "Convergence is not reached. Try to increase the number of resampling cycles."
            append!(samples_subspaces, samples_subspaces_run)
        else
            append!(samples_subspaces, samples_subspaces_run[unconv_mask])
        end

        posteriors_array = posteriors_array_run

    end

    @info "Integrating Subspaces"
    samples_subspaces = pmap(inp -> integrate_subspace(inp, algorithm.integrator), samples_subspaces)

    @info "Combining Samples"
    transformed_smpls = deepcopy(samples_subspaces[1].samples)
    info = deepcopy(samples_subspaces[1].info)
    # Save indices from different subspaces:
    info.samples_ind[1] = 1:length(transformed_smpls)
    for subspace in samples_subspaces[2:end]
        start_ind, stop_ind = length(transformed_smpls)+1, length(transformed_smpls)+length(subspace.samples)
        subspace.info.samples_ind[1] = start_ind:stop_ind
        append!(transformed_smpls, subspace.samples)
        append!(info, subspace.info)
    end

    smpls = inverse(trafo).(transformed_smpls)

    return (
        result = smpls, result_trafo = samples_trafo, trafo = trafo,
        info = info,
        exp_samples = exploration_samples, part_tree = partition_tree,
        cost_values = cost_values,
        resampled_trees = resampled_trees
    )
end

function sample_subspace(
    space_id::Integer,
    posterior::LBQIntegral,
    sampling_algorithm::A,
    context::BATContext
) where {N<:NamedTuple, A<:AbstractSamplingAlgorithm, I<:IntegrationAlgorithm}

    @info "Sampling subspace #$space_id"
    sampling_wc_start = Dates.Time(Dates.now())
    sampling_cpu_time = @CPUelapsed begin
        sampling_output = bat_sample(posterior, sampling_algorithm, context)
        samples_subspace = sampling_output.result
        isvalid = sampling_output.isvalid
    end
    sampling_wc_stop = Dates.Time(Dates.now())

    info_subspace = Table(
            sampling_cpu_time = [sampling_cpu_time],
            sampling_wc = [Dates.value(sampling_wc_start):Dates.value(sampling_wc_stop)],
            worker_id = [Distributed.myid()],
            n_threads = [Threads.nthreads()],
            samples_ind = [0:0],
            sum_weights = [sum(samples_subspace.weight)],
        )

    return (samples = samples_subspace, info = info_subspace, isvalid=isvalid)
end

function integrate_subspace(
    sampling_reuslt::N,
    integration_algorithm::I,
    context::BATContext
) where {N<:NamedTuple, A<:AbstractSamplingAlgorithm, I<:IntegrationAlgorithm}

    samples_subspace = sampling_reuslt.samples

    integration_wc_start = Dates.Time(Dates.now())
    integration_cpu_time = @CPUelapsed begin
        # ToDo: Use samples_subspace_trafo for integration instead of samples_subspace?
        integras_subspace = bat_integrate(samples_subspace, integration_algorithm, context).result
    end
    integration_wc_stop = Dates.Time(Dates.now())

    samples_subspace_reweighted = DensitySampleVector(
        (
            samples_subspace.v,
            samples_subspace.logd,
            integras_subspace.val .* samples_subspace.weight ./ sum(samples_subspace.weight),
            samples_subspace.info,
            samples_subspace.aux
        )
    )

    info_subspace = Table(
            density_integral = [integras_subspace],
            integration_cpu_time = [integration_cpu_time],
            integration_wc = [Dates.value(integration_wc_start):Dates.value(integration_wc_stop)],
        )

    return (samples = samples_subspace_reweighted, info = Table(info_subspace, sampling_reuslt.info))
end

function convert_to_posterior_resampled(
    posterior::LBQIntegral,
    partition_tree::SpacePartTree,
    posterior_subspace::LBQIntegral;
    extend_bounds::Bool=true
)

    # Note: this function is very inefficient
    # To improve it, truncation of truncated densities should be defined, or use space transformaton

    if extend_bounds
        # Exploration samples might not always cover properly tails of the distribution.
        # We will extend boudnaries of the partition tree with original bounds which are:
        lo_bounds = getprior(posterior_subspace).bounds.vol.lo
        hi_bounds = getprior(posterior_subspace).bounds.vol.hi
        extend_tree_bounds!(partition_tree, lo_bounds, hi_bounds)
    end

    #Get flattened rectangular parameter bounds from tree
    subspaces_rect_bounds = get_tree_par_bounds(partition_tree)

    n_params = size(subspaces_rect_bounds[1])[1]

    posterior_array = map(
        x -> begin
            bounds = HyperRectBounds(x[:,1], x[:,2])
            prior_dist = truncate_batmeasure(getprior(posterior), bounds)
            LBQIntegral(getlikelihood(posterior), prior_dist)
        end,
    subspaces_rect_bounds)

    return posterior_array
end



function convert_to_posterior(posterior::LBQIntegral, partition_tree::SpacePartTree; extend_bounds::Bool=true)

    if extend_bounds
        # Exploration samples might not always cover properly tails of the distribution.
        # We will extend boudnaries of the partition tree with original bounds which are:
        #!!!!!!!!!!!!!!!!!
        vol = spatialvolume(measure_support(posterior))
        lo_bounds = vol.lo
        hi_bounds = vol.hi
        extend_tree_bounds!(partition_tree, lo_bounds, hi_bounds)
    end

    #Get flattened rectangular parameter bounds from tree
    subspaces_rect_bounds = get_tree_par_bounds(partition_tree)

    posterior_array = map(subspaces_rect_bounds) do x
        bounds = StructArray{Interval}((x[:,1], x[:,2]))
        truncate_batmeasure(posterior, bounds)
    end

    return posterior_array
end
