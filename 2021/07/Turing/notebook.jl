### A Pluto.jl notebook ###
# v0.15.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 05b01107-c2b5-4dbb-916d-342ccf42bfbb
begin
    using AdvancedMH
    using LogExpFunctions
    using OrdinaryDiffEq
    using PlutoUI
    using StatsPlots
    using Turing

    using LinearAlgebra
    using Random
end

# ╔═╡ 6309ce46-304d-4847-8e15-46060a0fd0fe
html"<button onclick='present()'>present</button>"

# ╔═╡ f6bc0e5e-d086-11eb-0558-bb49daac1e9a
md"""
##### Package initialization
"""

# ╔═╡ ae1d2ef3-7746-47dd-947b-e835006544e5
md"""
# Probabilistic Modelling with Turing.jl

$(Resource("https://widmann.dev/assets/profile_small.jpg", :width=>75, :align=>"right"))
**David Widmann
(@devmotion $(Resource("https://raw.githubusercontent.com/edent/SuperTinyIcons/bed6907f8e4f5cb5bb21299b9070f4d7c51098c0/images/svg/github.svg", :width=>10)))**

Uppsala University, Sweden

*Julia User Group Munich, 5 July 2021*
"""

# ╔═╡ 38303b1e-7ed7-43fd-80ea-41da12f6fafd
md"""
## About me

- 👨‍🎓 PhD student at the [Department of Information Technology](http://www.it.uu.se/) and the [Centre for Interdisciplinary Mathematics (CIM)](https://www.math.uu.se/research/cim/) in Uppsala
  - BSc and MSc in Mathematics (TU Munich)
  - Human medicine (LMU and TU Munich)
- 👨‍🔬 Research topic: "Uncertainty-aware deep learning"
  - I.e., statistics, probability theory, machine learning, and computer science
- 💻 Julia programming, e.g.,
  - [SciML](https://sciml.ai/governance.html), in particular [DelayDiffEq.jl](https://github.com/SciML/DelayDiffEq.jl)
  - [Turing ecosystem](https://turing.ml/dev/team/)
"""

# ╔═╡ 77e64962-ed3e-4fb9-8431-a125ae33c702
md"""
## SIR model

Classical mathematical model of infectious diseases (e.g., influenza or COVID-19):

$(Resource("https://upload.wikimedia.org/wikipedia/commons/3/30/Diagram_of_SIR_epidemic_model_states_and_transition_rates.svg"))

```math
\begin{aligned}
\frac{\mathrm{d}S}{\mathrm{d}t}(t) &= - \beta S(t) I(t) / N\\
\frac{\mathrm{d}I}{\mathrm{d}t}(t) &= \beta S(t) I(t) / N - \gamma I(t) \\
\frac{\mathrm{d}R}{\mathrm{d}t}(t) &= \gamma I(t)
\end{aligned}
```

with infection rate ``\beta > 0``, recovery/death rate ``\gamma > 0``, and constant total population ``N = S(t) + I(t) + R(t) = \mathrm{const}``.
"""

# ╔═╡ d4334f1f-721c-4df8-9678-8a70ad76518f
function sir!(du, u, p, t)
    S, I, R = u
    β, γ = p

    N = S + I + R
    a = β * S * I / N
    b = γ * I

    du[1] = -a
    du[2] = a - b
    du[3] = b

    return nothing
end

# ╔═╡ 9cd67fe6-c7cb-413b-9c26-6edfe2d72350
md"""
``S(0)``: $(@bind S0 Slider(100:1:1000; default=990, show_value=true))
``I(0)``: $(@bind I0 Slider(1:1:1000; default=10, show_value=true))
``R(0)``: $(@bind R0 Slider(0:1:1000; show_value=true))

``\beta``: $(@bind β Slider(0.01:0.01:10; default=0.5, show_value=true))
``\gamma``: $(@bind γ Slider(0.01:0.01:10; default=0.25, show_value=true))
"""

# ╔═╡ 4295398d-176f-4fd4-b324-122ae6207de4
let
    sol = solve(ODEProblem{true}(sir!, [S0, I0, R0], (0.0, 50.0), (; β, γ)), Tsit5())
    Plots.plot(sol; label=["S(t)" "I(t)" "R(t)"], legend=:outertopright)
end

# ╔═╡ 4f02009c-636b-4cf9-a6bd-735bb6d5e985
md"""
Reproduction number: ``R_0 = \beta/\gamma \approx `` $(β / γ)
"""

# ╔═╡ 2474209b-2659-4c4b-9d2e-b8817541e6d5
md"""
## Inference problem

Model can be used to make predictions or reason about possible interventions

### But...

We do not know parameters such as
- transmission rate ``\beta``
- recovery rate ``\gamma``
- initial number of infected individuals ``I(0)``

We might just know
- population size ``N``
- initial number of removed individuals ``R(0) = 0``
- noisy (i.e., slightly incorrect) number of newly infected individuals for some days
"""

# ╔═╡ 53e4d56b-a9a5-4b92-becd-13563985dd7e
md"""
## Probabilistic modelling

**Idea:** model uncertainty of unknown parameters with probability distributions

$(begin
	Plots.plot(
		LogNormal();
		xlabel="β", ylabel="probability density function", legend=false, fill=true, alpha=0.3, xlims=(0, 20),
	)
	Plots.plot!(LogNormal(0.5); fill=true, alpha=0.3)
	Plots.plot!(LogNormal(1.5); fill=true, alpha=0.3)
end)

### Bayesian approach

Model uncertainty with conditional probability
```math
p_{\Theta|Y}(\theta | y)
```
of unknown parameters ``\theta`` given observations ``y``.

E.g.,
- ``\theta``: unknown parameters ``\beta``, ``\gamma``, and ``I(0)`` that we want to infer
- ``y``: number of newly infected individuals

### Bayes' theorem

Conditional probability ``p_{\Theta|Y}(\theta | y)`` can be calculated as

```math
p_{\Theta|Y}(\theta | y) = \frac{p_{Y|\Theta}(y | \theta) p_{\Theta}(\theta)}{p_{Y}(y)}
```

#### Workflow

- Choose model ``p_{Y|\Theta}(y | \theta)``
  - e.g., describes how daily cases of newly infected individuals depend on parameters
- Choose prior ``p_{\Theta}(\theta)``
  - should incorporate initial beliefs and knowledge about ``\theta``
  - e.g., ``\beta`` and ``\gamma`` are positive and ``I(0)`` is a natural number
- Compute
  ```math
  p_{\Theta|Y}(\theta | y) = \frac{p_{Y|\Theta}(y | \theta) p_{\Theta}(\theta)}{p_Y(y)} = \frac{p_{Y|\Theta}(y | \theta) p_{\Theta}(\theta)}{\int p_{Y|\Theta}(y | \theta') p_{\Theta}(\theta') \,\mathrm{d}\theta'}
  ```
"""

# ╔═╡ ea143f23-a7df-4c60-81a3-0a668270ac99
md"""
## Example: Coin flip

Coin with unknown probability of heads

- ``k``-times head in ``n`` coinflips (observation)
- unknown probability ``p`` of heads (parameter)
"""

# ╔═╡ 6b77ee3b-3c62-455e-a19a-644b57ce61c2
md"""
### Likelihood

```math
p_{Y|\Theta}(k|p) = \operatorname{Binom}(k; n, p)
```

``n``: $(@bind binom_n Slider(1:20; show_value=true, default=10))
``p``: $(@bind binom_p Slider(0.01:0.01:0.99; show_value=true, default=0.5))
"""

# ╔═╡ ce1540ae-37c2-48ef-a149-191696659185
Plots.plot(
    Binomial(binom_n, binom_p);
    seriestype=:sticks,
    markershape=:circle,
    xlabel=raw"$k$",
    ylabel=raw"$p_{Y|\Theta}(k|p)$",
    title="\$\\operatorname{Binom}($binom_n, $binom_p)\$",
    label=false,
)

# ╔═╡ eedafd4c-e996-4faf-986f-5f7265a9e793
md"""
### Prior

We choose a Beta distribution as prior:

```math
p_{\Theta}(p) = \operatorname{Beta}(p; \alpha, \beta)
```

!!! note
    Without any further information, ``\alpha = \beta = 1`` is a natural choice: without any observation, every possible value of ``p`` is equally likely.

``\alpha``: $(@bind beta_α Slider(0.1:0.1:10; show_value=true, default=1))
``\beta``: $(@bind beta_β Slider(0.1:0.1:10; show_value=true, default=1))
"""

# ╔═╡ a9e4cfca-93dc-4795-8eff-5fc4f4f1e49d
Plots.plot(
    Beta(beta_α, beta_β);
    xlabel=raw"$p$",
    ylabel=raw"$p_{\Theta}(p)$",
    title="\$\\mathrm{Beta}\\,($beta_α, $beta_β)\$",
    label=false,
    linewidth=3,
    fill=true,
    fillalpha=0.3,
)

# ╔═╡ 44eaa5f2-7be2-4740-bf87-567bff3a9574
md"""
### Posterior

For these choices of likelihood and prior, Bayes' theorem yields
```math
p_{\Theta|Y}(p|k) = \mathrm{Beta}\,(\alpha + k, \beta + n - k)
```

!!! note
    Families of prior distributions for which the posterior is in the same family are called **conjugate priors**.
"""

# ╔═╡ 17bab785-c855-45a7-bd58-5f8f583af9e4
md"""
true ``p``: $(@bind coinflip_p Slider(0.01:0.01:0.99; show_value=true, default=0.5))
``n``: $(@bind coinflip_n Slider(1:100; show_value=true, default=50))
"""

# ╔═╡ 1c0f6aa1-ef19-4617-89d1-3715c98467a5
coinflip_k = let
    Random.seed!(100)
    heads = rand(coinflip_n) .< coinflip_p
    sum(heads)
end

# ╔═╡ eb5cdaca-d1d6-4c8a-a669-d30132420339
md"""
``\alpha``: $(@bind coinflip_α Slider(0.1:0.1:10; show_value=true, default=1))
``\beta``: $(@bind coinflip_β Slider(0.1:0.1:10; show_value=true, default=1))
"""

# ╔═╡ efad4cb7-07c9-4ec4-b982-db7f9e1d2f7a
let α̂ = coinflip_α + coinflip_k, β̂ = coinflip_β + coinflip_n - coinflip_k
    Plots.plot(
        Beta(α̂, β̂);
        xlabel=raw"$p$",
        ylabel=raw"$p_{\Theta|Y}(p\,|\,k)$",
        title="posterior: \$\\operatorname{Beta}($α̂, $β̂)\$",
        fill=true,
        label="",
        alpha=0.3,
    )
    Plots.vline!([mean(Beta(α̂, β̂))]; label="mean", linewidth=3)
end

# ╔═╡ b1476923-4cc2-4292-840c-ad6aead1aceb
md"""
!!! danger "⚠️ Issue"
    Often it is not possible to compute ``p_{\Theta|Y}(\theta\, |\, y)`` exactly
"""

# ╔═╡ 5fa81e36-24d8-4c2b-b0a9-cc66fc273e8b
md"""
#### Discrete approximation

**Idea:** Approximate ``p_{\Theta|Y}(\theta \,|\, y)`` with a weighted mixture of point measures

```math
p_{\Theta|Y}(\cdot \,|\, y) \approx \sum_{i} w_i \delta_{\theta_i}(\cdot)
```
where ``w_i > 0`` and ``\sum_{i} w_i = 1``.

This implies that
```math
\mathbb{E}(\Theta | Y = y) \approx \sum_{i} w_i \theta_i
```
and more generally
```math
\mathbb{E}(\phi(\Theta) | Y = y) \approx \sum_{i} w_i \phi(\theta_i)
```
"""

# ╔═╡ 5efb00bc-e494-49c2-aead-f3c26d2e5652
md"""
number of samples: $(@bind approx_samples Slider(1:10_000; show_value=true, default=500))
"""

# ╔═╡ be54d0fc-f57a-4ff4-b821-ac57de1d898f
let
    dist = MixtureModel([Normal(2, sqrt(2)), Normal(9, sqrt(19))], [0.3, 0.7])

    plt = Plots.plot(
        dist;
        xlabel=raw"$\theta$",
        ylabel=raw"$p_{\Theta|Y}(\theta\,|\,y)$",
        title="truth",
        fill=true,
        alpha=0.3,
        xlims=(-15, 25),
        label="",
        components=false,
    )
    Plots.vline!(plt, [mean(dist)]; label="mean", linewidth=3)

    Random.seed!(100)
    x = rand(dist, approx_samples)
    w = logpdf.(dist, x)
    softmax!(w)

    plt2 = Plots.plot(
        x,
        w;
        xlabel=raw"$\theta_i$",
        ylabel=raw"$w_i$",
        seriestype=:sticks,
        xlims=(-15, 25),
        title="approximation",
        label="",
    )
    Plots.vline!(plt2, [dot(w, x)]; label="mean", linewidth=3)

    Plots.plot(plt, plt2)
end

# ╔═╡ 7592f838-3046-4ee7-b62f-812eae1fe38e
md"""
The approximation can be constructed with e.g.
- importance sampling
- sequential Monte Carlo (SMC)
- Markov Chain Monte Carlo (MCMC)
"""

# ╔═╡ 018dab1f-551d-405c-b74c-3f3a152291b7
md"""
## Standalone samplers

One main design of the Turing ecosystem is to have many smaller packages that
- can be used independently of Turing
- are supported by Turing

For MCMC, currently we have e.g.
- [AbstractMCMC.jl](https://github.com/TuringLang/AbstractMCMC.jl)
- [AdvancedHMC.jl](https://github.com/TuringLang/AdvancedHMC.jl)
- [AdvancedMH.jl](https://github.com/TuringLang/AdvancedMH.jl)
- [AdvancedPS.jl](https://github.com/TuringLang/AdvancedPS.jl)
- [EllipticalSliceSamplig.jl](https://github.com/TuringLang/EllipticalSliceSampling.jl)
- [MCMCChains.jl](https://github.com/TuringLang/MCMCChains.jl)

Additionally, Turing supports also [DynamicHMC.jl](https://github.com/tpapp/DynamicHMC.jl).
"""

# ╔═╡ ebdaca0b-de2f-43c6-8aed-1809d9b539af
md"""
### AdvancedMH.jl

> [AdvancedMH.jl](https://github.com/TuringLang/AdvancedMH.jl) contains an implementation
> of the [Metropolis-Hastings algorithm](https://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm).
"""

# ╔═╡ ac953a8d-1952-4900-89b9-f90c8da6f0dc
md"""
We have to define the unnormalized log density, i.e., the sum of the log-likelihood and the log prior, as a function of the unknown parameter.
"""

# ╔═╡ 131662d4-1506-449b-b69e-963ba79fb7ed
logdensity_coinflip = let α = coinflip_α, β = coinflip_β, k = coinflip_k, n = coinflip_n
    p -> begin
        # compute log prior
        logprior = logpdf(Beta(α, β), p)

        return if isfinite(logprior)
            # only evalute log-likelihood if it is finite
            # (otherwise `p` might be < 0 or > 1
            logprior + logpdf(Binomial(n, p), k)
        else
            logprior
        end
    end
end

# ╔═╡ 1115f2ce-63cf-4f40-8c40-f94eeb3c4d98
md"""
The model is fully specified by the log density function.
"""

# ╔═╡ 8db53840-2e05-4762-b148-9ed7e339c620
model_coinflip_mh = DensityModel(logdensity_coinflip)

# ╔═╡ 264f20bf-a46b-4b9d-b644-3b96a339f4f9
md"""
We use a Metropolis-Hastings algorithm with a random walk proposal.
"""

# ╔═╡ 3730c2db-c95a-47c7-af4f-168c0855c047
sampler_coinflip_mh = RWMH(Normal())

# ╔═╡ 3773a017-7370-48d5-876c-9865f75ef6ae
md"""
#### AbstractMCMC.jl

> [AbstractMCMC.jl](https://github.com/TuringLang/AbstractMCMC.jl) defines an interface for MCMC algorithms.

The interface is supposed to make it easy to implement MCMC algorithms. The default definitions provide users with
- **progress bars**,
- support for **user-provided callbacks**,
- support for **thinning** and **discarding initial samples**,
- support for sampling with a **custom stopping criterion**,
- support for sampling **multiple chains**, serially or in parallel with **multiple threads** or **multiple processes**,
- an **iterator** and a **transducer** for sampling Markov chains.
"""

# ╔═╡ ed72a31f-0b24-4918-ab1e-1b47127d96f2
md"""
The main user-facing API is `sample`.
"""

# ╔═╡ 22e78da0-c699-4e50-98bb-c26a25f062bd
let
    # set seed
    Random.seed!(100)
    sample(model_coinflip_mh, sampler_coinflip_mh, 10)
end

# ╔═╡ 5149c1bf-e705-41e4-8e5b-8579fb0441af
md"""
Some common keyword arguments:
- `discard_initial` (default: `0`): number of initial samples that are discarded
- `thinning` (default: 1): factor by which samples are thinned
- `chain_type` (default: `Any`): type of the returned chain
- `callback` (default: `nothing`): callback that is called after every sampling step
- `progress` (default: `AbstractMCMC.PROGRESS[]` which is `true` initially): toggles progress logging
"""

# ╔═╡ d1e79d32-525c-4aac-8fbf-fd40f973a93e
let
    # set seed
    Random.seed!(100)
    sample(
        model_coinflip_mh,
        sampler_coinflip_mh,
        10;
        discard_initial=25,
        thinning=4,
        chain_type=Chains,
    )
end

# ╔═╡ eefa8c9b-8c87-439d-9892-d60cf2c7617d
md"""
AbstractMCMC.jl allows you to sample multiple chains with the following three algorithms:
- `MCMCSerial()`: sample in serial (no parallelization)
- `MCMCThreads()`: parallel sampling with multiple threads
- `MCMCDistributed()`: parallel sampling with multiple processes
"""

# ╔═╡ 65b976cb-049b-4872-89f3-70d576ff5d6e
coinflip_mh = let
    # set seed
    Random.seed!(100)

    sample(
        model_coinflip_mh,
        sampler_coinflip_mh,
        MCMCThreads(),
        1_000,
        3;
        discard_initial=100,
        thinning=10,
        param_names=["p"],
        chain_type=Chains,
    )
end

# ╔═╡ 4d2a52fb-1889-4ecd-abe3-c60f89b6f703
md"""
The iterator interface allows us to e.g. plot the samples in every step:
"""

# ╔═╡ b5a29c1b-8f98-4347-b303-8a13e5a43019
let
    Random.seed!(100)

    # Container for samples
    n = 1_000
    samples = Float64[]
    sizehint!(samples, n)

    # Create animation
    @gif for transition in
             Iterators.take(AbstractMCMC.steps(model_coinflip_mh, sampler_coinflip_mh), n)
        push!(samples, transition.params)
        plot(samples; xlabel="iteration", ylabel="value", title="p", legend=false)
    end every 10
end

# ╔═╡ a782fa82-70d8-4a68-b316-96c7520c87d9
md"""
#### MCMCChains.jl

> [MCMCChains.jl](https://github.com/TuringLang/MCMCChains.jl) contains tools for
> analyzing and visualizing MCMC chains.
"""

# ╔═╡ 3be790e1-e5c4-4945-8679-806c66c4de62
Plots.plot(coinflip_mh)

# ╔═╡ 29082996-3d0b-4cc5-9458-b2fcc8da8f76
autocorplot(coinflip_mh)

# ╔═╡ 64d16319-09da-4dfe-b8ee-f4e795b33e1b
summarystats(coinflip_mh)

# ╔═╡ 5566d97b-cfa6-481a-9824-0fe9710d7ad2
md"""
### Posterior predictive check

> It is often useful to generate simulated data using samples from the posterior distribution and compare them to the original data.

*(see, e.g., "Statistical Rethinking" (section 3.3.2 - model checking) and the [documentation](https://turing.ml/dev/tutorials/10-bayesian-differential-equations/#data-retrodiction))*
"""

# ╔═╡ 255d5a0d-cdd9-4623-b44b-8bf4a2087ab3
coinflip_check_mh = let
    Random.seed!(100)
    map(Array(coinflip_mh)) do p
        return rand(Binomial(coinflip_n, p))
    end
end

# ╔═╡ ade32ecd-c0d7-42b8-b70e-0f2ec8a37526
let
    histogram(coinflip_check_mh; label="sampled k")
    vline!([mean(coinflip_check_mh)]; linewidth=3, label="sampled k (mean)")
    vline!([coinflip_k]; linewidth=3, label="observed k")
end

# ╔═╡ 0d1c8d2e-8022-4848-8ec9-0abf67ff180d
md"""
## [Probabilistic programming](https://en.wikipedia.org/wiki/Probabilistic_programming)

*Source: [Lecture slides](http://www.it.uu.se/research/systems_and_control/education/2019/smc/schedule/lecture17.pdf)*

> Developing probabilistic models and inference algorithms is a **time-consuming** and **error-prone** process.

- Probabilistic model written as a computer program

- Automatic inference (integral part of the programming language)

Advantages:
- Fast development of models
- Expressive models
- Widely applicable inference algorithms
"""

# ╔═╡ 54a4b670-c870-4e31-8f47-56d61ebfaacc
md"""
## Turing

Turing is a probabilistic programming language (PPL).

!!! info "Other PPLs"
    There are many other PPLs such as [Stan](https://mc-stan.org/), [Birch](https://www.birch.sh/), [Gen](https://www.gen.dev/), or [Soss](https://github.com/cscherrer/Soss.jl).

### General design

- Probabilistic models are implemented as a Julia function
- One may use any Julia code inside of the model
- Random variables and observations are declared with the `~` operator:
  ```julia
  @model function mymodel(x, y)
      ...
      # random variable `a` with prior distribution `dist_a`
      a ~ dist_a

      ...

      # observation `y` with data distribution `dist_y`
      y ~ dist_y
      ...
  end
  ```

- PPL is implemented in [DynamicPPL.jl](https://github.com/TuringLang/DynamicPPL.jl), including `@model` macro
- [Turing.jl](https://github.com/TuringLang/Turing.jl) integrates and reexports different parts of the ecosystem such as the PPL, inference algorithms, and tools for automatic differentiation
"""

# ╔═╡ 67f2a8c6-7150-4eb4-898b-fe597be051b0
md"""
## Coinflip model

A possible Turing model:
"""

# ╔═╡ c2fde13f-2557-4917-8778-a04ad78bfa86
"""
	coinflip(n, k; α=1, β=1)

Create a probabilistic model of `n` coinflips where head shows up `k` times and
the prior distribution of probability `p` of heads is `Beta(α, β)`.
"""
@model function coinflip(n::Int, k; α::Real=1, β::Real=1)
    # the prior distribution of parameter `p` is `Beta(α, β)`
    p ~ Beta(α, β)

    # observation `k` is binomially distributed with parameters `n` and `k`
    k ~ Binomial(n, p)

    return (; p, k)
end

# ╔═╡ 5aa9fc5c-5523-4c83-9fb1-b91009910ff2
md"""
`coinflip` is a Julia function: it creates a model of type `DynamicPPL.Model` that stores
- the name of the model,
- the generative function of the model (i.e., the function above that declares how to run the model),
- and the arguments of the model and their default values.
"""

# ╔═╡ 883fce8c-25a2-40b5-8f11-f48671908564
md"""
We can look up the documentation of `coinflip`:
"""

# ╔═╡ 50e02f94-ebdb-405b-9908-9715926f11ac
md"""
And we can inspect how the `@model` macro rewrites the function definition:
"""

# ╔═╡ 6c9181b4-a157-4afc-862f-6f603a8023e4
@macroexpand @model function conflip(n, k; α::Real, β::Real)
    p ~ Beta(α, β)
    k ~ Binomial(n, p)
    return (; p, k)
end

# ╔═╡ 36de2acb-1560-47cb-af8e-812e7eba4709
md"""
Since `coinflip` is a regular Julia function, we can also extend it. E.g., we can allow users to specify the results of the coin flips as a vector of `true` (heads) and `false` (tail):
"""

# ╔═╡ d8e95b63-3e2a-41ab-8d8c-510c671e2679
function coinflip(flips::AbstractVector{Bool}; α::Real=1, β::Real=1)
    return coinflip(length(flips), sum(flips); α, β)
end

# ╔═╡ 3cde7a23-3829-41ec-b05d-bd374d4737d7
coinflip(10, 1)

# ╔═╡ 1d85d00e-20d8-4df5-9072-6fdcb5d7c542
@doc coinflip

# ╔═╡ 75b1b6f1-c6a0-4b3c-8e4b-c4841e713118
coinflip([true, false, false, true, true, true])

# ╔═╡ d73ef204-b1b4-4a14-be8a-f9aef411fe6e
md"""
### Inference

We choose the same parameters as above:
``n = `` $coinflip_n, ``k = `` $coinflip_k, ``\alpha = `` $coinflip_α, ``\beta = `` $coinflip_β
"""

# ╔═╡ c55bc774-b8d8-4209-ad67-6f860b2fd0f8
coinflip_model = coinflip(coinflip_n, coinflip_k; α=coinflip_α, β=coinflip_β)

# ╔═╡ 37c47c60-a9b6-40fc-8e99-bb645b2a4564
md"""
If you call the model without arguments, it is executed and all variables are sampled
from the prior.
"""

# ╔═╡ d1460bbe-9331-480a-9bab-911f5f4d9ceb
coinflip_model()

# ╔═╡ ccb279ba-6991-48ff-aab8-8d97a6e8234c
md"""
Algorithm: $(@bind coinflip_algstr PlutoUI.Select([
	"MH" => "Metropolis-Hastings",
	"HMC" => "Hamiltonian Monte Carlo",
	"NUTS" => "No-UTurn Sampler",
	"PG" => "Particle Gibbs",
]))
"""

# ╔═╡ a4a82a7c-e640-431a-813a-10ebfdc38ba6
md"""
### Analysis
"""

# ╔═╡ ca0a8603-4351-4e90-ac88-12d2f1c068c4
md"""
### Posterior predictive check

Similar to above, we can check if the posterior predictions fit the observed data.
"""

# ╔═╡ 98587b0a-583c-4223-909a-1e3896442ad7
md"""
In more complicated models it can be tedious to rewrite how to sample the observations explicitly. Fortunately, we can use the following feature of Turing:

> If the left hand side of a `~` expression is `missing`, it is sampled even if it is an argument to the model.
"""

# ╔═╡ 12883dd8-916d-42e5-92ee-352d33ae95e9
coinflip(coinflip_n, missing)()

# ╔═╡ 6ca9211c-70e6-422b-9f65-57b4e01509f8
md"""
`generated_quantities` can be used to compute/sample an array of the return values of a model for each set of samples in the chain:
"""

# ╔═╡ c31a0604-055e-47fa-9d48-ded45887ebb8
coinflip_alg = if coinflip_algstr == "MH"
    MH()
elseif coinflip_algstr == "HMC"
    HMC(0.05, 10)
elseif coinflip_algstr == "NUTS"
    NUTS()
elseif coinflip_algstr == "PG"
    PG(10)
else
    error("algorithm choice not supported")
end;

# ╔═╡ 09be7d85-3d8b-42fc-ba49-896931ae9712
coinflip_alg

# ╔═╡ 17d54a64-17f7-4edd-8ae9-d723fb6955dc
coinflip_turing = let
    # set seed
    Random.seed!(100)

    sample(
        coinflip_model,
        coinflip_alg,
        MCMCThreads(),
        1_000,
        3;
        discard_initial=100,
        thinning=10,
        param_names=["p"],
        chain_type=Chains,
    )
end

# ╔═╡ dabc0e6d-9668-418e-a326-dfa2cb7fe651
Plots.plot(coinflip_turing)

# ╔═╡ c9c0e9c1-9de3-4a3c-ad33-be46068dbbed
autocorplot(coinflip_turing)

# ╔═╡ 5fd08098-4683-4dc2-a7cb-db76ec41adbe
summarystats(coinflip_turing)

# ╔═╡ f072dd40-5875-4887-83ed-0fd2ac860720
coinflip_check_turing = let
    Random.seed!(100)
    map(Array(coinflip_turing)) do p
        return rand(Binomial(coinflip_n, p))
    end
end

# ╔═╡ c7543c68-c07d-4667-a09c-fda947215150
let
    histogram(coinflip_check_turing; label="sampled k")
    vline!([mean(coinflip_check_turing)]; linewidth=3, label="sampled k (mean)")
    vline!([coinflip_k]; linewidth=3, label="observed k")
end

# ╔═╡ f4fa2d2c-dddd-4443-b72c-3b1b31bffc50
coinflip_return_turing = let
    # Model with `k` set to `missing`
    coinflip_missing_model = coinflip(coinflip_n, missing; α=coinflip_α, β=coinflip_β)

    # Return values for each sample of `p` in the chain
    Random.seed!(100)
    generated_quantities(coinflip_missing_model, coinflip_turing)
end

# ╔═╡ e4fde396-d56c-4305-b858-baed1c8007f8
coinflip_check_turing2 = map(x -> x.k, vec(coinflip_return_turing))

# ╔═╡ 8ad6d8aa-4f0d-445b-9436-144782a0d9d1
let
    histogram(coinflip_check_turing2; label="sampled k")
    vline!([mean(coinflip_check_turing2)]; linewidth=3, label="sampled k (mean)")
    vline!([coinflip_k]; linewidth=3, label="observed k")
end

# ╔═╡ 958dd50d-3a07-4e2b-a158-45dd99965d79
md"""
## Automatic differentiation

*[Documentation](https://turing.ml/dev/docs/using-turing/autodiff)*

> Algorithms such as Hamiltonian Monte Carlo (HMC) or no-U-turn sampler (NUTS) require the gradient of the log density function as well.

Turing computes the gradient automatically with automatic differentiation (AD). Different backends and algorithms are supported:
- [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl): forward-mode AD, the default backend
- [Tracker.jl](https://github.com/JuliaDiff/Tracker.jl): reverse-mode AD
- [ReverseDiff.jl](https://github.com/JuliaDiff/ReverseDiff.jl): reverse-mode AD, has to be loaded explicitly (optional cache for some models)
- [Zygote.jl](https://github.com/JuliaDiff/Zygote.jl): reverse-mode AD, has to be loaded explicitly
"""

# ╔═╡ d102294a-e4da-49e7-ab55-77fe5dcb9f07
md"""
If not set explicitly in the sampler, Turing uses the currently active global AD backend. It can be set with
- `setadbackend(:forwarddiff)`,
- `setadbackend(:tracker)`,
- `setadbackend(:reversediff)`, or
- `setadbackend(:zygote)`.

Alternatively, the backend can be set explicitly in the sampler:
"""

# ╔═╡ 2f08292d-e91e-4e6c-ab23-2f707dbcd031
let
    Random.seed!(100)
    chain = sample(
        coinflip_model,
        NUTS{Turing.ForwardDiffAD{3}}(0.65),
        # NUTS{Turing.TrackerAD}(0.65),
        1_000;
        discard_initial=100,
        thinning=10,
        param_names=["p"],
        chain_type=Chains,
    )
    plot(chain)
end

# ╔═╡ 9082ea11-f5c8-4c1d-8ab2-65fff6547260
md"""
!!! info "Rule of thumb"
    Use forward-mode AD for models with few parameters and reverse-mode AD for models with
    many parameters or linear algebra operations.

    If you use reverse-mode AD, in particular with Tracker or Zygote, you should avoid
    loops and use vectorized operations.
"""

# ╔═╡ b72a4887-ad6e-44bd-bea4-d113f70cc066
md"""
## Bayesian inference of SIR model

*Based on [Simon Frost's example](https://github.com/epirecipes/sir-julia/blob/master/markdown/ode_turing/ode_turing.md)*

### Setting

SIR model:
```math
\begin{aligned}
\frac{\mathrm{d}S}{\mathrm{d}t}(t) &= - \beta S(t) I(t) / N\\
\frac{\mathrm{d}I}{\mathrm{d}t}(t) &= \beta S(t) I(t) / N - \gamma I(t) \\
\frac{\mathrm{d}R}{\mathrm{d}t}(t) &= \gamma I(t)
\end{aligned}
```

We assume that
- ``S(0) = 990``, ``I(0) = 10``, and ``R(0) = 0`` at day 0,
- ``\beta = 0.5``, and
- ``\gamma = 0.25``.
"""

# ╔═╡ d26bf4bf-ae71-406c-b880-5798b2cce26c
begin
    sir_solution = solve(
        ODEProblem{true}(sir!, [990.0, 10.0, 0.0], (0.0, 50.0), (β=0.5, γ=0.25)), Tsit5()
    )
    Plots.plot(sir_solution; label=["S(t)" "I(t)" "R(t)"], legend=:outertopright)
end

# ╔═╡ cd499351-5f31-43e7-b38e-7cf9f44306a9
md"""
We observe the **number of new cases** for days 1 to 40 with some Poisson measurement error:
"""

# ╔═╡ 5a44adb5-5d5c-4e11-b44c-52aacac3f949
begin
    # new cases without noise
    sir_newcases = abs.(diff(sir_solution(0:40; idxs=1).u))

    # with Poisson noise
    sir_data = let
        Random.seed!(100)
        map(sir_newcases) do x
            return rand(Poisson(x))
        end
    end
end;

# ╔═╡ e9963a69-73ef-447c-9d52-7b35b959cd9b
let
    bar(1:40, sir_data; xlabel="day", ylabel="new cases", label="observed")
    plot!(1:40, sir_newcases; marker=:circle, label="SIR model")
end

# ╔═╡ 3169c50b-dca3-45f3-9289-fd74a4ddaf37
md"""
### Turing model

We define a probabilistic model of the observations, the initial proportion of infected
individuals ``i_0``, and parameters ``\beta`` and ``\gamma``. We use uniform priors for ``i₀``, ``\beta`` and ``\gamma``. All other parameters fixed.
"""

# ╔═╡ 356b2da9-56bc-4026-8307-2a95d4557678
@model function sir_model(t, y, ::Type{T}=Float64) where {T}
    # sample the parameters: uniform priors for `i₀`, `β` and `γ`
    i₀ ~ Uniform(0.0, 1.0)
    β ~ Uniform(0.0, 1.0)
    γ ~ Uniform(0.0, 1.0)

    # simulate the SIR model and save the number of infected
    # individuals at times `t`
    I₀ = 1_000 * i₀
    prob = ODEProblem{true}(sir!, T[1_000 - I₀, I₀, 0], (0.0, last(t)), (; β, γ))
    sol = solve(prob, Tsit5(); saveat=t, save_idxs=1)

    # ensure that the simulation was successful
    if sol.retcode !== :Success
        Turing.@addlogprob! -Inf
    else
        # compute new cases
        cases = map(abs, diff(Array(sol)))

        # noisy observations
        for i in 1:length(y)
            y[i] ~ Poisson(cases[i])
        end
    end

    return (; i₀, β, γ, y)
end;

# ╔═╡ 079e121d-27cc-4e7a-9531-a2bce08369e1
md"""
!!! info
    The initial state of the SIR model has to be compatible with automatic differentiation
    if a gradient-based sampler such as HMC or NUTS is used. This is ensured with the type
    parameter `T` which Turing sets to a suitable type for the sampler automatically.
"""

# ╔═╡ f07a78ab-11e1-4b3b-ac42-c9ad0d20421e
md"""
### Inference
"""

# ╔═╡ 8b6b55e9-9884-4ba5-b1d3-30348cb7d1d0
sir_nuts = let
    Random.seed!(100)
    sample(
        sir_model(0:40, sir_data),
        NUTS(0.65),
        MCMCThreads(),
        1_000,
        3;
        thinning=10,
        discard_initial=100,
    )
end;

# ╔═╡ c3f8d24b-0fa5-46b7-b0c0-eab1470d6af9
plot(sir_nuts)

# ╔═╡ be168a2f-a614-473a-8b4c-224bd82c1e5a
autocorplot(sir_nuts)

# ╔═╡ bb56eda7-a86a-440c-a879-89c5a20e5a1d
summarystats(sir_nuts)

# ╔═╡ 6fb6d5f7-b600-4ec6-b7f4-e3cde91812fa
md"""
### Posterior predictive check
"""

# ╔═╡ 3311638d-048c-451a-b168-df7c0e0a98d2
sir_return = let
    sir_missing_model = sir_model(0:40, Vector{Missing}(undef, 40))

    Random.seed!(100)
    generated_quantities(sir_missing_model, sir_nuts)
end

# ╔═╡ bab07574-8998-45df-9579-6c4ad77fe83a
sir_check = map(x -> convert(Vector{Float64}, x.y), vec(sir_return))

# ╔═╡ cbe995d6-0878-416d-8ef9-d058ea9b70b5
let
    # Plot observations
    plt = bar(1:40, sir_data; xlabel="day", ylabel="new cases", label="observed")
    plot!(plt, 1:40, sir_newcases; marker=:circle, label="SIR model")

    # Plot 300 samples from posterior
    Random.seed!(100)
    idxs = shuffle!(vcat(trues(300), falses(length(sir_check) - 300)))
    for y in sir_check[idxs]
        plot!(plt, 1:40, y; alpha=0.1, color="#BBBBBB", label="")
    end

    plt
end

# ╔═╡ 37f57554-c501-43e3-aeb2-210572d2fe91
md"""
## COVID-19 replication study

$(Resource("https://github.com/cambridge-mlg/Covid19/raw/3b1644701ef32063a65fbbc72332ba0eaa22f82b/figures/imperial-report13/uk-predictive-posterior-Rt.png"))

Links: [Blog post](https://turing.ml/dev/posts/2020-05-04-Imperial-Report13-analysis), [Github repo](https://github.com/cambridge-mlg/Covid19)
"""

# ╔═╡ c5c2e09a-1b42-4068-a3a4-db5c2288c632
md"""
## Additional resources

- [Official documentation](https://turing.ml/dev/docs/) and [tutorials](https://turing.ml/dev/tutorials/): Please open an issue or a pull request if you discover anything that is broken or outdated 🙏❤️

- [Turing versions](https://github.com/StatisticalRethinkingJulia/TuringModels.jl) of the Bayesian models in the book [Statistical Rethinking](https://xcelab.net/rm/statistical-rethinking/) by Richard McElreath

- [Turing workshop](https://github.com/storopoli/Turing-Workshop) and [tutorial](https://github.com/storopoli/Bayesian-Julia) by [José Storopoli](https://github.com/storopoli)

- [Turing models](http://hakank.org/julia/turing/) by [Håkan Kjellerstrand](http://hakank.org/)

"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AdvancedMH = "5b7e9947-ddc0-4b3f-9b55-0d8042f74170"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
OrdinaryDiffEq = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
Turing = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"

[compat]
AdvancedMH = "~0.6.2"
LogExpFunctions = "~0.2.4"
OrdinaryDiffEq = "~5.59.2"
PlutoUI = "~0.7.9"
StatsPlots = "~0.14.23"
Turing = "~0.16.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[AbstractMCMC]]
deps = ["BangBang", "ConsoleProgressMonitor", "Distributed", "Logging", "LoggingExtras", "ProgressLogging", "Random", "StatsBase", "TerminalLoggers", "Transducers"]
git-tree-sha1 = "db0a7ff3fbd987055c43b4e12d2fa30aaae8749c"
uuid = "80f14c24-f653-4e6a-9b94-39d6b0f70001"
version = "3.2.1"

[[AbstractPPL]]
deps = ["AbstractMCMC"]
git-tree-sha1 = "ba9984ea1829e16b3a02ee49497c84c9795efa25"
uuid = "7a57a42e-76ec-4ea3-a279-07e840d6d9cf"
version = "0.1.4"

[[AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[AdvancedHMC]]
deps = ["ArgCheck", "DocStringExtensions", "InplaceOps", "LinearAlgebra", "Parameters", "ProgressMeter", "Random", "Requires", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "7e85ed4917716873423f8d47da8c1275f739e0b7"
uuid = "0bf59076-c3b1-5ca4-86bd-e02cd72cde3d"
version = "0.2.27"

[[AdvancedMH]]
deps = ["AbstractMCMC", "Distributions", "Random", "Requires"]
git-tree-sha1 = "c777dc5bcdae838111edf412dfa2debbbb6f2f34"
uuid = "5b7e9947-ddc0-4b3f-9b55-0d8042f74170"
version = "0.6.2"

[[AdvancedPS]]
deps = ["AbstractMCMC", "Distributions", "Libtask", "Random", "StatsFuns"]
git-tree-sha1 = "06da6c283cf17cf0f97ed2c07c29b6333ee83dc9"
uuid = "576499cb-2369-40b2-a588-c64705576edc"
version = "0.2.4"

[[AdvancedVI]]
deps = ["Bijectors", "Distributions", "DistributionsAD", "DocStringExtensions", "ForwardDiff", "LinearAlgebra", "ProgressMeter", "Random", "Requires", "StatsBase", "StatsFuns", "Tracker"]
git-tree-sha1 = "130d6b17a3a9d420d9a6b37412cae03ffd6a64ff"
uuid = "b5ca4192-6429-45e5-a2d9-87aec30a685c"
version = "0.1.3"

[[ArgCheck]]
git-tree-sha1 = "dedbbb2ddb876f899585c4ec4433265e3017215a"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.1.0"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "f87e559f87a45bece9c9ed97458d3afe98b1ebb9"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.1.0"

[[Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra"]
git-tree-sha1 = "2ff92b71ba1747c5fdd541f8fc87736d82f40ec9"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.4.0"

[[Arpack_jll]]
deps = ["Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "e214a9b9bd1b4e1b4f15b22c0994862b66af7ff7"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.0+3"

[[ArrayInterface]]
deps = ["IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "045ff5e1bc8c6fb1ecb28694abba0a0d55b5f4f5"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.1.17"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "a4d07a1c313392a77042855df46c5f534076fab9"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.0"

[[AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "f31f50712cbdf40ee8287f0443b57503e34122ef"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.3"

[[BangBang]]
deps = ["Compat", "ConstructionBase", "Future", "InitialValues", "LinearAlgebra", "Requires", "Setfield", "Tables", "ZygoteRules"]
git-tree-sha1 = "e239020994123f08905052b9603b4ca14f8c5807"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.3.31"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[Bijectors]]
deps = ["ArgCheck", "ChainRulesCore", "Compat", "Distributions", "Functors", "LinearAlgebra", "MappedArrays", "NNlib", "NonlinearSolve", "Random", "Reexport", "Requires", "SparseArrays", "Statistics", "StatsFuns"]
git-tree-sha1 = "6d2eeafea62421f0e1a69093feac46d200f9a038"
uuid = "76274a88-744f-5084-9051-94815aaf08c4"
version = "0.9.6"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c3598e525718abcc440f69cc6d5f60dda0a1b61e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.6+5"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e2f47f6d8337369411569fd45ae5753ca10394c6"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.0+6"

[[ChainRules]]
deps = ["ChainRulesCore", "Compat", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "e7e3200bd24b77bcc849e6616f7c2f0d45d70f5b"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "0.8.17"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "be770c08881f7bb928dfd86d1ba83798f76cf62a"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "0.10.9"

[[Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random", "StaticArrays"]
git-tree-sha1 = "c8fd01e4b736013bc61b704871d20503b33ea402"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.12.1"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[CommonSolve]]
git-tree-sha1 = "68a0743f578349ada8bc911a5cbd5a2ef6ed6d1f"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.0"

[[CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "dc7dedc2c2aa9faf59a55c622760a25cbefbe941"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.31.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[CompositionsBase]]
git-tree-sha1 = "f3955eb38944e5dd0fabf8ca1e267d94941d34a5"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.0"

[[ConsoleProgressMonitor]]
deps = ["Logging", "ProgressMeter"]
git-tree-sha1 = "3ab7b2136722890b9af903859afcf457fa3059e8"
uuid = "88cd18e8-d9cc-4ea6-8889-5259c0d15c8b"
version = "0.1.2"

[[ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f74e9d5388b8620b4cee35d4c5a618dd4dc547f4"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.3.0"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DataAPI]]
git-tree-sha1 = "ee400abb2298bd13bfc3df1c412ed228061a2385"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.7.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4437b64df1e0adccc3e5d1adbc3ac741095e4677"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.9"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DefineSingletons]]
git-tree-sha1 = "77b4ca280084423b728662fe040e5ff8819347c5"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.1"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DiffEqBase]]
deps = ["ArrayInterface", "ChainRulesCore", "DataStructures", "DocStringExtensions", "FastBroadcast", "FunctionWrappers", "IterativeSolvers", "LabelledArrays", "LinearAlgebra", "Logging", "MuladdMacro", "NonlinearSolve", "Parameters", "Printf", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "Requires", "SciMLBase", "Setfield", "SparseArrays", "StaticArrays", "Statistics", "SuiteSparse", "ZygoteRules"]
git-tree-sha1 = "9488cb4c384de8d8dc79de9ab02ca320e0e9465e"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.67.0"

[[DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[DiffRules]]
deps = ["NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "214c3fcac57755cfda163d91c58893a8723f93e9"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.0.2"

[[Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "abe4ad222b26af3337262b8afb28fab8d215e9f8"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.3"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "2733323e5c02a9d7f48e7a3c4bc98d764fb704da"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.6"

[[DistributionsAD]]
deps = ["Adapt", "ChainRules", "ChainRulesCore", "Compat", "DiffRules", "Distributions", "FillArrays", "LinearAlgebra", "NaNMath", "PDMats", "Random", "Requires", "SpecialFunctions", "StaticArrays", "StatsBase", "StatsFuns", "ZygoteRules"]
git-tree-sha1 = "1c0ef4fe9eaa9596aca50b15a420e987b8447e56"
uuid = "ced4e74d-a319-5a8a-b0ac-84af2272839c"
version = "0.6.28"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[DynamicPPL]]
deps = ["AbstractMCMC", "AbstractPPL", "Bijectors", "ChainRulesCore", "Distributions", "MacroTools", "Random", "ZygoteRules"]
git-tree-sha1 = "5121b72cbe2f92558754ad601a6af33c2bc5fdbe"
uuid = "366bfd00-2699-11ea-058f-f148b4cae6d8"
version = "0.12.1"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "8041575f021cba5a099a456b4163c9a08b566a02"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.1.0"

[[EllipticalSliceSampling]]
deps = ["AbstractMCMC", "ArrayInterface", "Distributions", "Random", "Statistics"]
git-tree-sha1 = "254182080498cce7ae4bc863d23bf27c632688f7"
uuid = "cad2338a-1db2-11e9-3401-43bc07c9ede2"
version = "0.4.4"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[ExponentialUtilities]]
deps = ["ArrayInterface", "LinearAlgebra", "Printf", "Requires", "SparseArrays"]
git-tree-sha1 = "ad435656c49da7615152b856c0f9abe75b0b5dc9"
uuid = "d4d017d3-3776-5f7e-afef-a10c40355c18"
version = "1.8.4"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "LibVPX_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "3cc57ad0a213808473eafef4845a74766242e05f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.3.1+4"

[[FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "f985af3b9f4e278b1d24434cbb546d6092fca661"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.3"

[[FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3676abafff7e4ff07bbd2c42b3d8201f31653dcc"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.9+8"

[[FastBroadcast]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "26be48918640ce002f5833e8fc537b2ba7ed0234"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.1.8"

[[FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "a603e79b71bb3c1efdb58f0ee32286efe2d1a255"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.11.8"

[[FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "f6f80c8f934efd49a286bb5315360be66956dfc4"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.8.0"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "35895cf184ceaab11fd778b4590144034a167a2f"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.1+14"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "NaNMath", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "e2af66012e08966366a43251e1fd421522908be6"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.18"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "cbd58c9deb1d304f5a245a0b7eb841a2560cfec6"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.1+5"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[FunctionWrappers]]
git-tree-sha1 = "241552bc2209f0fa068b6415b1942cc0aa486bcc"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.2"

[[Functors]]
deps = ["MacroTools"]
git-tree-sha1 = "a7bb2af991c43dcf5c3455d276dd83976799634f"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.2.1"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "dba1e8614e98949abfa60480b13653813d8f0157"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+0"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "b83e3125048a9c3158cbb7ca423790c7b1b57bea"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.57.5"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e14907859a1d3aee73a019e7b3c98e9e7b8b5b3e"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.57.3+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "15ff9a14b9e1218958d3530cc288cf31465d9ae2"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.3.13"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "47ce50b742921377301e15005c96e979574e130b"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.1+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "c6a1fff2fd4b1da29d3dccaffb1e1001244d844e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.12"

[[Hwloc]]
deps = ["Hwloc_jll"]
git-tree-sha1 = "92d99146066c5c6888d5a3abc871e6a214388b91"
uuid = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
version = "2.0.0"

[[Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3395d4d4aeb3c9d31f5929d32760d8baeee88aaf"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.5.0+0"

[[IfElse]]
git-tree-sha1 = "28e837ff3e7a6c3cdb252ce49fb412c8eb3caeef"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.0"

[[Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InitialValues]]
git-tree-sha1 = "26c8832afd63ac558b98a823265856670d898b6c"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.2.10"

[[InplaceOps]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "50b41d59e7164ab6fda65e71049fee9d890731ff"
uuid = "505f98c9-085e-5b2c-8e89-488be7bf1f34"
version = "0.3.0"

[[IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "1470c80592cf1f0a35566ee5e93c5f8221ebc33a"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.3"

[[IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[InvertedIndices]]
deps = ["Test"]
git-tree-sha1 = "15732c475062348b0165684ffe28e85ea8396afc"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.0.0"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IterativeSolvers]]
deps = ["LinearAlgebra", "Printf", "Random", "RecipesBase", "SparseArrays"]
git-tree-sha1 = "1a8c6237e78b714e901e406c096fc8a65528af7d"
uuid = "42fd0dbc-a981-5370-80f2-aaf504508153"
version = "0.9.1"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "81690084b6198a2e1da36fcfda16eeca9f9f24e4"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.1"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "c7f1c695e06c01b95a67f0cd1d34994f3e7db104"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.2.1"

[[LabelledArrays]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools", "StaticArrays"]
git-tree-sha1 = "248a199fa42ec62922225334131c9330e1dd72f6"
uuid = "2ee39098-c373-598a-b85f-a56591580800"
version = "1.6.1"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a4b12a1bd2ebade87891ab7e36fdbce582301a92"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.6"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[LeftChildRightSiblingTrees]]
deps = ["AbstractTrees"]
git-tree-sha1 = "71be1eb5ad19cb4f61fa8c73395c0338fd092ae0"
uuid = "1d6d02ad-be62-4b6b-8a6d-2f90e265016e"
version = "0.1.2"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[LibVPX_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "12ee7e23fa4d18361e7c2cde8f8337d4c3101bc7"
uuid = "dd192d2f-8180-539f-9fb4-cc70b1dcf69a"
version = "1.10.0+0"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "761a393aeccd6aa92ec3515e428c26bf99575b3b"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+0"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libtask]]
deps = ["Libtask_jll", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "90c6ed7f9ac449cddacd80d5c1fca59c97d203e7"
uuid = "6f1fad26-d15e-5dc8-ae53-837a1d7b8c9f"
version = "0.5.3"

[[Libtask_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "901fc8752bbc527a6006a951716d661baa9d54e9"
uuid = "3ae2931a-708c-5973-9c38-ccf7496fb450"
version = "0.4.3+0"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LightGraphs]]
deps = ["ArnoldiMethod", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "432428df5f360964040ed60418dd5601ecd240b6"
uuid = "093fc24a-ae57-5d10-9952-331d41423f4d"
version = "1.3.5"

[[LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "f27132e551e959b3667d8c93eae90973225032dd"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.1.1"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["DocStringExtensions", "LinearAlgebra"]
git-tree-sha1 = "1ba664552f1ef15325e68dc4c05c3ef8c2d5d885"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.2.4"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "dfeda1c1130990428720de0024d4516b1902ce98"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.7"

[[LoopVectorization]]
deps = ["ArrayInterface", "DocStringExtensions", "IfElse", "LinearAlgebra", "OffsetArrays", "Polyester", "Requires", "SLEEFPirates", "Static", "StrideArraysCore", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "20316f08f70fae085ed90c7169ae318c036ee83b"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.49"

[[MCMCChains]]
deps = ["AbstractFFTs", "AbstractMCMC", "AxisArrays", "Compat", "Dates", "Distributions", "Formatting", "IteratorInterfaceExtensions", "LinearAlgebra", "MLJModelInterface", "NaturalSort", "PrettyTables", "Random", "RecipesBase", "Serialization", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "TableTraits", "Tables"]
git-tree-sha1 = "c20fea9223c650a11f2b6d4b22ceba98251ed2f6"
uuid = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
version = "4.13.0"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "c253236b0ed414624b083e6b72bfe891fbd2c7af"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+1"

[[MLJModelInterface]]
deps = ["Random", "ScientificTypesBase", "StatisticalTraits"]
git-tree-sha1 = "55c785a68d71c5fd7b64b490e0d9ab18cf13a04c"
uuid = "e80e1ace-859a-464e-9ed9-23947d8ae3ea"
version = "1.1.1"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "6a8a2a625ab0dea913aba95c11370589e0239ff0"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.6"

[[MappedArrays]]
git-tree-sha1 = "18d3584eebc861e311a552cbb67723af8edff5de"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.0"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[MicroCollections]]
deps = ["BangBang", "Setfield"]
git-tree-sha1 = "e991b6a9d38091c4a0d7cd051fcb57c05f98ac03"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.1.0"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "4ea90bd5d3985ae1f9a908bd4500ae88921c5ce7"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[MuladdMacro]]
git-tree-sha1 = "c6190f9a7fc5d9d5915ab29f2134421b12d24a68"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.2"

[[MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "8d958ff1854b166003238fe191ec34b9d592860a"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.8.0"

[[NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "50608f411a1e178e0129eab4110bd56efd08816f"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.0"

[[NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[NNlib]]
deps = ["Adapt", "ChainRulesCore", "Compat", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "7e6f31cfa39b1ff1c541cc8580b14b0ff4ba22d0"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.7.23"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "9ba8ddb0c06a08b1bad81b7120d13288e5d766fa"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.5"

[[NaturalSort]]
git-tree-sha1 = "eda490d06b9f7c00752ee81cfa451efe55521e21"
uuid = "c020b1a1-e9b0-503a-9c33-f039bfc54a85"
version = "1.0.0"

[[NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[NonlinearSolve]]
deps = ["ArrayInterface", "FiniteDiff", "ForwardDiff", "IterativeSolvers", "LinearAlgebra", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "SciMLBase", "Setfield", "StaticArrays", "UnPack"]
git-tree-sha1 = "ef18e47df4f3917af35be5e5d7f5d97e8a83b0ec"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "0.3.8"

[[Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "2bf78c5fd7fa56d2bbf1efbadd45c1b8789e6f57"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.2"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[OrdinaryDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "ExponentialUtilities", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "Logging", "MacroTools", "MuladdMacro", "NLsolve", "Polyester", "RecursiveArrayTools", "Reexport", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "f865c198eb4041535c9d27e0835c5b59cdb759d4"
uuid = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
version = "5.59.2"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "4dd403333bcf0909341cfe57ec115152f937d7d8"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.1"

[[Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "2276ac65f1e236e0a6ea70baff3f62ad4c625345"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.2"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "c8abc88faa3f7a3950832ac5d6e690881590d6dc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "1.1.0"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "ae9a295ac761f64d8c2ec7f9f24d21eb4ffba34d"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.10"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs"]
git-tree-sha1 = "df601eed7c9637235a26b26f9f648deccd277178"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.16.7"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

[[Polyester]]
deps = ["ArrayInterface", "IfElse", "Requires", "Static", "StrideArraysCore", "ThreadingUtilities", "VectorizationBase"]
git-tree-sha1 = "04a03d3f8ae906f4196b9085ed51506c4b466340"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.3.1"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "0d1245a357cc61c8cd61934c07447aa569ff22e6"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.1.0"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "12fbe86da16df6679be7521dfb39fbc861e1dc7b"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.1"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[Ratios]]
git-tree-sha1 = "37d210f612d70f3f7d57d488cb3b6eff56ad4e41"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.0"

[[RecipesBase]]
git-tree-sha1 = "b3fb709f3c97bfc6e948be68beeecb55a0b340ae"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.1"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "9b8e57e3cca8828a1bc759840bfe48d64db9abfb"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.3.3"

[[RecursiveArrayTools]]
deps = ["ArrayInterface", "ChainRulesCore", "DocStringExtensions", "LinearAlgebra", "RecipesBase", "Requires", "StaticArrays", "Statistics", "ZygoteRules"]
git-tree-sha1 = "b20384ee84f3e0e89cee36dbcb9c44b8bd61e133"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.14.3"

[[RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization"]
git-tree-sha1 = "2e1a88c083ebe8ba69bc0b0084d4b4ba4aa35ae0"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.1.13"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "da6d214ffc85b1292f300649ef86d3c4f9aaf25d"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.22"

[[SciMLBase]]
deps = ["ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "RecipesBase", "RecursiveArrayTools", "StaticArrays", "Statistics", "Tables", "TreeViews"]
git-tree-sha1 = "7d60436171978e9b4f73790ebf436fccd307df51"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "1.14.0"

[[ScientificTypesBase]]
git-tree-sha1 = "3f7ddb0cf0c3a4cff06d9df6f01135fa5442c99b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "1.0.0"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "ffae887d0f0222a19c406a11c3831776d1383e3d"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.3"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "d5640fc570fb1b6c54512f0bd3853866bd298b3e"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.7.0"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "daf7aec3fe3acb2131388f93a4c409b8c7f62226"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "2ec1962eba973f383239da22e75218565c390a96"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.0"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SparseDiffTools]]
deps = ["Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "LightGraphs", "LinearAlgebra", "Requires", "SparseArrays", "VertexSafeGraphs"]
git-tree-sha1 = "be20320958ccd298c98312137a5ebe75a654ebc8"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "1.13.2"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "LogExpFunctions", "OpenSpecFun_jll"]
git-tree-sha1 = "a50550fa3164a8c46747e62063b4d774ac1bcf49"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.5.1"

[[SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "edef25a158db82f4940720ebada14a60ef6c4232"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.13"

[[Static]]
deps = ["IfElse"]
git-tree-sha1 = "2740ea27b66a41f9d213561a04573da5d3823d4b"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.2.5"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "745914ebcd610da69f3cb6bf76cb7bb83dcb8c9a"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.4"

[[StatisticalTraits]]
deps = ["ScientificTypesBase"]
git-tree-sha1 = "5114841829816649ecc957f07f6a621671e4a951"
uuid = "64bff920-2084-43da-a3e6-9bb72801c0c9"
version = "2.0.0"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "2f6792d523d7448bbe2fec99eca9218f06cc746d"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.8"

[[StatsFuns]]
deps = ["LogExpFunctions", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "30cd8c360c54081f806b1ee14d2eecbef3c04c49"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.8"

[[StatsPlots]]
deps = ["Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "a8cf8da9a86b395915af526f8751f34746bf7872"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.14.23"

[[StrideArraysCore]]
deps = ["ArrayInterface", "Requires", "ThreadingUtilities", "VectorizationBase"]
git-tree-sha1 = "efcdfcbb8cf91e859f61011de1621be34b550e69"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.1.13"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "000e168f5cc9aded17b6999a560b7c11dda69095"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.0"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "a7cf690d0ac3f5b53dd09b5d613540b230233647"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.0.0"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "8ed4a3ea724dac32670b062be3ef1c1de6773ae8"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.4.4"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[TerminalLoggers]]
deps = ["LeftChildRightSiblingTrees", "Logging", "Markdown", "Printf", "ProgressLogging", "UUIDs"]
git-tree-sha1 = "d620a061cb2a56930b52bdf5cf908a5c4fa8e76a"
uuid = "5d786b92-1e48-4d6f-9151-6b4477ca9bed"
version = "0.1.4"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[ThreadingUtilities]]
deps = ["VectorizationBase"]
git-tree-sha1 = "28f4295cd761ce98db2b5f8c1fe6e5c89561efbe"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.4.4"

[[Tracker]]
deps = ["Adapt", "DiffRules", "ForwardDiff", "LinearAlgebra", "MacroTools", "NNlib", "NaNMath", "Printf", "Random", "Requires", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "bf4adf36062afc921f251af4db58f06235504eff"
uuid = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
version = "0.2.16"

[[Transducers]]
deps = ["Adapt", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "Setfield", "SplittablesBase", "Tables"]
git-tree-sha1 = "34f27ac221cb53317ab6df196f9ed145077231ff"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.65"

[[TreeViews]]
deps = ["Test"]
git-tree-sha1 = "8d0d7a3fe2f30d6a7f833a5f19f7c7a5b396eae6"
uuid = "a2a6695c-b41b-5b7d-aed9-dbfdeacea5d7"
version = "0.3.0"

[[Turing]]
deps = ["AbstractMCMC", "AdvancedHMC", "AdvancedMH", "AdvancedPS", "AdvancedVI", "BangBang", "Bijectors", "DataStructures", "Distributions", "DistributionsAD", "DocStringExtensions", "DynamicPPL", "EllipticalSliceSampling", "ForwardDiff", "Libtask", "LinearAlgebra", "MCMCChains", "NamedArrays", "Printf", "Random", "Reexport", "Requires", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Tracker", "ZygoteRules"]
git-tree-sha1 = "18cba2718ab55eed9152ac14c5683cba692525d5"
uuid = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"
version = "0.16.4"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[VectorizationBase]]
deps = ["ArrayInterface", "Hwloc", "IfElse", "Libdl", "LinearAlgebra", "Static"]
git-tree-sha1 = "0ba060e248edfacacafd764926cdd6de51af1343"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.20.19"

[[VertexSafeGraphs]]
deps = ["LightGraphs"]
git-tree-sha1 = "b9b450c99a3ca1cc1c6836f560d8d887bcbe356e"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.1.2"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll"]
git-tree-sha1 = "2839f1c1296940218e35df0bbb220f2a79686670"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.18.0+4"

[[Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "eae2fbbc34a79ffd57fb4c972b08ce50b8f6a00d"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.3"

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "59e2ad8fd1591ea019a5259bd012d7aee15f995c"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.3"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "9e7a1e8ca60b742e508a315c17eef5211e7fbfd7"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.1"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "acc685bcf777b2202a904cdcb49ad34c2fa1880c"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.14.0+4"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7a5780a0d9c6864184b3a2eeeb833a0c871f00ab"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "0.1.6+4"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d713c1ce4deac133e3334ee12f4adff07f81778f"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2020.7.14+2"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "487da2f8f2f0c8ee0e83f39d13037d6bbf0a45ab"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.0.0+3"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─6309ce46-304d-4847-8e15-46060a0fd0fe
# ╟─f6bc0e5e-d086-11eb-0558-bb49daac1e9a
# ╠═05b01107-c2b5-4dbb-916d-342ccf42bfbb
# ╟─ae1d2ef3-7746-47dd-947b-e835006544e5
# ╟─38303b1e-7ed7-43fd-80ea-41da12f6fafd
# ╟─77e64962-ed3e-4fb9-8431-a125ae33c702
# ╠═d4334f1f-721c-4df8-9678-8a70ad76518f
# ╟─9cd67fe6-c7cb-413b-9c26-6edfe2d72350
# ╟─4295398d-176f-4fd4-b324-122ae6207de4
# ╟─4f02009c-636b-4cf9-a6bd-735bb6d5e985
# ╟─2474209b-2659-4c4b-9d2e-b8817541e6d5
# ╟─53e4d56b-a9a5-4b92-becd-13563985dd7e
# ╟─ea143f23-a7df-4c60-81a3-0a668270ac99
# ╟─6b77ee3b-3c62-455e-a19a-644b57ce61c2
# ╟─ce1540ae-37c2-48ef-a149-191696659185
# ╟─eedafd4c-e996-4faf-986f-5f7265a9e793
# ╟─a9e4cfca-93dc-4795-8eff-5fc4f4f1e49d
# ╟─44eaa5f2-7be2-4740-bf87-567bff3a9574
# ╟─17bab785-c855-45a7-bd58-5f8f583af9e4
# ╠═1c0f6aa1-ef19-4617-89d1-3715c98467a5
# ╟─eb5cdaca-d1d6-4c8a-a669-d30132420339
# ╟─efad4cb7-07c9-4ec4-b982-db7f9e1d2f7a
# ╟─b1476923-4cc2-4292-840c-ad6aead1aceb
# ╟─5fa81e36-24d8-4c2b-b0a9-cc66fc273e8b
# ╟─5efb00bc-e494-49c2-aead-f3c26d2e5652
# ╟─be54d0fc-f57a-4ff4-b821-ac57de1d898f
# ╟─7592f838-3046-4ee7-b62f-812eae1fe38e
# ╟─018dab1f-551d-405c-b74c-3f3a152291b7
# ╟─ebdaca0b-de2f-43c6-8aed-1809d9b539af
# ╟─ac953a8d-1952-4900-89b9-f90c8da6f0dc
# ╠═131662d4-1506-449b-b69e-963ba79fb7ed
# ╟─1115f2ce-63cf-4f40-8c40-f94eeb3c4d98
# ╠═8db53840-2e05-4762-b148-9ed7e339c620
# ╟─264f20bf-a46b-4b9d-b644-3b96a339f4f9
# ╠═3730c2db-c95a-47c7-af4f-168c0855c047
# ╟─3773a017-7370-48d5-876c-9865f75ef6ae
# ╟─ed72a31f-0b24-4918-ab1e-1b47127d96f2
# ╠═22e78da0-c699-4e50-98bb-c26a25f062bd
# ╟─5149c1bf-e705-41e4-8e5b-8579fb0441af
# ╠═d1e79d32-525c-4aac-8fbf-fd40f973a93e
# ╟─eefa8c9b-8c87-439d-9892-d60cf2c7617d
# ╠═65b976cb-049b-4872-89f3-70d576ff5d6e
# ╟─4d2a52fb-1889-4ecd-abe3-c60f89b6f703
# ╠═b5a29c1b-8f98-4347-b303-8a13e5a43019
# ╟─a782fa82-70d8-4a68-b316-96c7520c87d9
# ╠═3be790e1-e5c4-4945-8679-806c66c4de62
# ╠═29082996-3d0b-4cc5-9458-b2fcc8da8f76
# ╠═64d16319-09da-4dfe-b8ee-f4e795b33e1b
# ╟─5566d97b-cfa6-481a-9824-0fe9710d7ad2
# ╠═255d5a0d-cdd9-4623-b44b-8bf4a2087ab3
# ╟─ade32ecd-c0d7-42b8-b70e-0f2ec8a37526
# ╟─0d1c8d2e-8022-4848-8ec9-0abf67ff180d
# ╟─54a4b670-c870-4e31-8f47-56d61ebfaacc
# ╟─67f2a8c6-7150-4eb4-898b-fe597be051b0
# ╠═c2fde13f-2557-4917-8778-a04ad78bfa86
# ╟─5aa9fc5c-5523-4c83-9fb1-b91009910ff2
# ╠═3cde7a23-3829-41ec-b05d-bd374d4737d7
# ╟─883fce8c-25a2-40b5-8f11-f48671908564
# ╠═1d85d00e-20d8-4df5-9072-6fdcb5d7c542
# ╟─50e02f94-ebdb-405b-9908-9715926f11ac
# ╠═6c9181b4-a157-4afc-862f-6f603a8023e4
# ╟─36de2acb-1560-47cb-af8e-812e7eba4709
# ╠═d8e95b63-3e2a-41ab-8d8c-510c671e2679
# ╠═75b1b6f1-c6a0-4b3c-8e4b-c4841e713118
# ╟─d73ef204-b1b4-4a14-be8a-f9aef411fe6e
# ╠═c55bc774-b8d8-4209-ad67-6f860b2fd0f8
# ╟─37c47c60-a9b6-40fc-8e99-bb645b2a4564
# ╠═d1460bbe-9331-480a-9bab-911f5f4d9ceb
# ╟─ccb279ba-6991-48ff-aab8-8d97a6e8234c
# ╠═09be7d85-3d8b-42fc-ba49-896931ae9712
# ╠═17d54a64-17f7-4edd-8ae9-d723fb6955dc
# ╟─a4a82a7c-e640-431a-813a-10ebfdc38ba6
# ╠═dabc0e6d-9668-418e-a326-dfa2cb7fe651
# ╠═c9c0e9c1-9de3-4a3c-ad33-be46068dbbed
# ╠═5fd08098-4683-4dc2-a7cb-db76ec41adbe
# ╟─ca0a8603-4351-4e90-ac88-12d2f1c068c4
# ╠═f072dd40-5875-4887-83ed-0fd2ac860720
# ╟─c7543c68-c07d-4667-a09c-fda947215150
# ╟─98587b0a-583c-4223-909a-1e3896442ad7
# ╠═12883dd8-916d-42e5-92ee-352d33ae95e9
# ╟─6ca9211c-70e6-422b-9f65-57b4e01509f8
# ╠═f4fa2d2c-dddd-4443-b72c-3b1b31bffc50
# ╠═e4fde396-d56c-4305-b858-baed1c8007f8
# ╟─8ad6d8aa-4f0d-445b-9436-144782a0d9d1
# ╟─c31a0604-055e-47fa-9d48-ded45887ebb8
# ╟─958dd50d-3a07-4e2b-a158-45dd99965d79
# ╟─d102294a-e4da-49e7-ab55-77fe5dcb9f07
# ╠═2f08292d-e91e-4e6c-ab23-2f707dbcd031
# ╟─9082ea11-f5c8-4c1d-8ab2-65fff6547260
# ╟─b72a4887-ad6e-44bd-bea4-d113f70cc066
# ╟─d26bf4bf-ae71-406c-b880-5798b2cce26c
# ╟─cd499351-5f31-43e7-b38e-7cf9f44306a9
# ╠═5a44adb5-5d5c-4e11-b44c-52aacac3f949
# ╟─e9963a69-73ef-447c-9d52-7b35b959cd9b
# ╟─3169c50b-dca3-45f3-9289-fd74a4ddaf37
# ╠═356b2da9-56bc-4026-8307-2a95d4557678
# ╟─079e121d-27cc-4e7a-9531-a2bce08369e1
# ╟─f07a78ab-11e1-4b3b-ac42-c9ad0d20421e
# ╠═c3f8d24b-0fa5-46b7-b0c0-eab1470d6af9
# ╠═be168a2f-a614-473a-8b4c-224bd82c1e5a
# ╠═bb56eda7-a86a-440c-a879-89c5a20e5a1d
# ╠═8b6b55e9-9884-4ba5-b1d3-30348cb7d1d0
# ╟─6fb6d5f7-b600-4ec6-b7f4-e3cde91812fa
# ╠═3311638d-048c-451a-b168-df7c0e0a98d2
# ╠═bab07574-8998-45df-9579-6c4ad77fe83a
# ╟─cbe995d6-0878-416d-8ef9-d058ea9b70b5
# ╟─37f57554-c501-43e3-aeb2-210572d2fe91
# ╟─c5c2e09a-1b42-4068-a3a4-db5c2288c632
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
