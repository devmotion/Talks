### A Pluto.jl notebook ###
# v0.15.1

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

# ╔═╡ 14dbe097-648c-4480-bf4a-990a377ba984
begin
    using AbstractGPs
    using AbstractGPsMakie
    using AlgebraOfGraphics
    using CairoMakie
    using Distances
    using Distributions
    using EllipticalSliceSampling
    using LogExpFunctions
    using Luxor
    using PlutoUI
	import Turing

    using LinearAlgebra
    using Random

    # plotting settings
    CairoMakie.activate!(; type="svg")
    set_theme!(; AlgebraOfGraphics.aog_theme()..., resolution=(800, 400))
end

# ╔═╡ 9f6813de-08fe-4026-8bec-d5f0241e6752
html"<button onclick='present()'>present</button>"

# ╔═╡ 80b60191-0686-41f9-905d-4c7f8acb783f
md"""
#### Package initialization
"""

# ╔═╡ 11762e96-c9b6-11eb-0fef-27543b5f5084
md"""
#  EllipticalSliceSampling.jl: MCMC with Gaussian priors

$(Resource("https://widmann.dev/assets/profile_small.jpg", :width=>75, :align=>"right"))
**[David Widmann](https://widmann.dev)
(@devmotion $(Resource("https://raw.githubusercontent.com/edent/SuperTinyIcons/bed6907f8e4f5cb5bb21299b9070f4d7c51098c0/images/svg/github.svg", :width=>10)))**

Uppsala University, Sweden

*JuliaCon, July 2021*
"""

# ╔═╡ 1931da6a-59e0-401a-830a-41cad4b98c76
md"""
## Elliptical slice sampling

*Murray, I., Adams, R. & MacKay, D.. (2010). [Elliptical slice sampling](http://proceedings.mlr.press/v9/murray10a/murray10a.pdf). Proceedings of Machine Learning Research, 9:541-548.*

> [Markov chain Monte Carlo (MCMC)](https://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo) method for models with Gaussian prior
"""

# ╔═╡ 7bfec871-a912-430e-8341-b462584839be
md"""
#### Example: Point process

- Gaussian prior
  ```math
  p_X(x) := \mathcal{N}(x; -3.5, 1)
  ```
- Likelihood
  ```math
  \mathcal{L}(x) := p_{Y|X}(y \,|\, x) := \operatorname{Poisson}\big(y; \log(1 + \exp(x))\big)
  ```
- Elliptical slice sampling approximates
  ```math
  p_{X|Y}(x \,|\, y) \propto p_{Y|X}(y \,|\, x) p_{X}(x) = \mathcal{L}(x) p_{Y|X}(y \,|\, x)
  ```
"""

# ╔═╡ be1846e5-9725-4375-b7ce-0b7106be2032
md"""
``y``: $(@bind poisson_y PlutoUI.Slider(0:10; show_value=true, default=5))
"""

# ╔═╡ a979c0d7-ee36-49a3-930c-faea3b541595
begin
    # Gaussian prior
    poisson_prior = Normal(-3.5, 1)

    # Log-likelihood
    poisson_loglikelihood = let y = poisson_y
        x -> logpdf(Poisson(log1pexp(x)), y)
    end

    # Elliptical slice sampling
    poisson_samples = let
        Random.seed!(100)
        sample(
            ESSModel(poisson_prior, poisson_loglikelihood),
            ESS(),
            10_000;
            progress=false,
            thinning=10,
            discard_initial=100,
        )
    end
end;

# ╔═╡ 1a92abc8-bf14-4b70-a3e9-ab10d2949a97
let
    patchcolor = CairoMakie.Makie.wong_colors(0.6)

    fig = Figure(; resolution=(800, 250))
    ax = Axis(
        fig[1, 1];
        xlabel="x",
        palette=(patchcolor=patchcolor,),
        leftspinevisible=false,
        yticksvisible=false,
        yticklabelsvisible=false,
        limits=(nothing, (0, nothing)),
    )

    # plot prior
    xs = range(-8, 15; length=1_000)
    ys = map(Base.Fix1(pdf, poisson_prior), xs)
    plt_prior = [lines!(ax, xs, ys); band!(ax, xs, zeros(length(xs)), ys)]

    # plot likelihood
    likelihood = map(exp ∘ poisson_loglikelihood, xs)
    plt_likelihood = [
        lines!(ax, xs, likelihood)
        band!(ax, xs, zeros(length(xs)), likelihood)
    ]

    # plot samples
    plt_samples = hist!(
        ax, poisson_samples; normalization=:pdf, bins=25, color=patchcolor[3]
    )

    # add legend
    axislegend(
        ax,
        [plt_prior, plt_likelihood, plt_samples],
        ["Gaussian prior", "likelihood", "samples"];
    )

    fig
end

# ╔═╡ b29b907f-f33e-4247-8c7a-5cca00eb571f
md"""
### Motivation

Assume a Gaussian prior ``\mathcal{N}(0, \Sigma)`` with zero mean.

- Metropolis-Hastings method with proposal distribution
  ```math
  P_{\varepsilon}(x) = \mathcal{N}\Big(x \sqrt{1 - \varepsilon^2}, \epsilon^2 \Sigma\Big),
  ```
  where ``x`` is the current state and ``\varepsilon \in [0, 1]`` is a step-size parameter, requires tuning of the step-size ``\varepsilon`` for efficient mixing
- **Idea**: search over the step-size and consider (half-)ellipse of possible proposals for varying ``\varepsilon``
"""

# ╔═╡ 419d36b5-0572-4842-8040-2da05507c793
md"""
$(@bind framenumber PlutoUI.Slider(1:11; default=1))
"""

# ╔═╡ e721cebb-a136-494e-a0dd-a53575127fe9
begin
    function proposal_point(θ)
        sinθ, cosθ = sincos(θ)
        return Luxor.Point(100 * cosθ, 50 * sinθ)
    end

    function proposal(θ; label=false)
        @layer begin
            sethue("blue")
            pt = proposal_point(θ)
            circle(pt, 5, :fill)
            if label
                Luxor.text(
                    "proposal",
                    pt + Luxor.Point(8, 0);
                    angle=-π / 6,
                    halign=:left,
                    valign=:top,
                )
            end
        end
    end

    function current_state()
        @layer begin
            sethue("black")
            polycross(Luxor.Point(0, -50), 5, 4, 0.35, -π / 6 + π / 4, :fill)
            Luxor.text(
                "current state",
                Luxor.Point(0, -58);
                angle=-π / 6,
                halign=:left,
                valign=:bottom,
            )
        end
    end

    function prior_sample()
        @layer begin
            sethue("red")
            polycross(Luxor.Point(100, 0), 5, 4, 0.35, -π / 6, :fill)
            Luxor.text(
                "prior sample", Luxor.Point(108, 0); angle=-π / 6, halign=:left, valign=:top
            )
        end
    end

    function acceptance_region()
        @layer begin
            sethue("green")
            setline(3)
            setdash("solid")
            box(Luxor.Point(20, -50), 90, 50, :clip)
            ellipse(Luxor.Point(0, 0), 200, 100, :stroke)
            clipreset()
            box(Luxor.Point(-100, -30), 50, 50, :clip)
            ellipse(Luxor.Point(0, 0), 200, 100, :stroke)
            clipreset()
            Luxor.text(
                "acceptance region",
                Luxor.Point(-108, -20);
                angle=-π / 6,
                halign=:center,
                valign=:bottom,
            )
        end
    end

    function proposal_ellipse(θmin, θmax)
        point_min = proposal_point(θmin)
        point_max = proposal_point(θmax)
        θ1 = anglethreepoints(point_min, Luxor.Point(0, 0), Luxor.Point(1, 0))
        θ2 = anglethreepoints(point_max, Luxor.Point(0, 0), Luxor.Point(1, 0))
        @layer begin
            setline(1)
            @layer begin
                setdash("dot")
                ellipse(Luxor.Point(0, 0), 200, 100, :stroke)
            end
            @layer begin
                Luxor.pie(150, θ1, θ2, :clip)
                ellipse(Luxor.Point(0, 0), 200, 100, :stroke)
                clipreset()
                circle(point_min, 2, :fill)
                circle(point_max, 2, :fill)
            end
        end
    end
end;

# ╔═╡ b939278f-7f8d-4757-b1d5-3ca064515aed
@drawsvg begin
    proposals = [π / 4, -2 * π / 3, 11 * π / 6, 5 * π / 3]
    rotate(π / 6)
    fontsize(12)
    fontface("DejaVu Sans")

    if 2 < framenumber < 6
        @layer begin
            setline(1)
            ellipse(Luxor.Point(0, 0), 200, 100, :stroke)
        end
    elseif 6 <= framenumber <= 7
        @layer begin
            setline(1)
            ellipse(Luxor.Point(0, 0), 200, 100, :stroke)
            circle(proposal_point(proposals[1]), 2, :fill)
        end
    elseif framenumber > 7
        proposal_ellipse(
            extrema((proposals[framenumber ÷ 2 - 3], proposals[framenumber ÷ 2 - 2]))...
        )
    end
    framenumber > 3 && acceptance_region()
    current_state()
    framenumber > 1 && prior_sample()

    if framenumber > 4 && isodd(framenumber)
        proposal(proposals[framenumber ÷ 2 - 1]; label=framenumber == 5)
    end
end 400 200

# ╔═╡ b6f9c887-ac31-4a4c-90c6-3f812f800af1
md"""
## EllipticalSliceSampling.jl

Julia implementation of elliptical slice sampling.

Features:
- Supports arbitrary Gaussian priors, also with non-zero mean
- Based on the [AbstractMCMC.jl](https://github.com/TuringLang/AbstractMCMC.jl) interface
- Uses [ArrayInterface.jl](https://github.com/JuliaArrays/ArrayInterface.jl) to reduce allocations if samples are mutable
"""

# ╔═╡ 2bcda59a-14d7-4a8f-ac6d-1b357846c2e0
md"""
### AbstractMCMC.jl

> [AbstractMCMC.jl](https://github.com/TuringLang/AbstractMCMC.jl) defines an interface for MCMC algorithms.

If you want to implement an algorithm, you have to implement
```julia
AbstractMCMC.step(rng, model, sampler[, state; kwargs...])
```
that defines the sampling step of the algorithm (in the initial step no `state` is provided).

Then the default definitions provide you with
- **progress bars**,
- support for **user-provided callbacks**,
- support for **thinning** and **discarding initial samples**,
- support for sampling with a **custom stopping criterion**,
- support for sampling **multiple chains**, serially or in parallel with **multiple threads** or **multiple processes**,
- an **iterator** and a **transducer** for sampling Markov chains.
"""

# ╔═╡ 6e2cd527-9fad-4f1e-bea5-d9347390e3c6
html"""
<h1/><h3><center>See you at JuliaCon!</center></h3>

<img src="https://juliacon.org/assets/2021/img/world_1400.png"/>
"""

# ╔═╡ 79df97c7-3aee-4239-ad1e-92b85e42a2c4
md"""
# Additional material
"""

# ╔═╡ a378db41-9fba-4759-bd5b-97be9dc0e5ac
md"""
## Example: Gaussian likelihood

In this case the posterior is analytically tractable.

Here we choose
```math
p_X(x) := \mathcal{N}\bigg(x; \begin{bmatrix} 3.5 \\ 1.5\end{bmatrix}, \begin{bmatrix}0.5 & 0 \\
0 & 1.5 \end{bmatrix}\bigg)
```
and
```math
\mathcal{L}(x) := p_{Y|X}\big([0, 2.5]^\mathsf{T} | x\big) := \mathcal{N}\bigg(\begin{bmatrix}0 \\ 2.5\end{bmatrix}; x, \begin{bmatrix} 0.75 & 0 \\ 0 & 0.5 \end{bmatrix}\bigg).
```

We obtain
```math
p_{X|Y}(x) = \mathcal{N}\bigg(x; \begin{bmatrix} 2.1 \\ 2.25 \end{bmatrix}, \begin{bmatrix} 0.3 & 0 \\ 0 & 0.375 \end{bmatrix}\bigg)
```
"""

# ╔═╡ 0f315738-bbfc-4ff9-a75f-0103c1ebac79
gaussian_prior = MvNormal([3.5, 1.5], Diagonal([0.5, 1.5]))

# ╔═╡ 09c4efb9-6b96-42ec-8526-6f7e720abb2c
gaussian_loglikelihood(x) = logpdf(MvNormal(x, Diagonal([0.75, 0.5])), [0, 2.5])

# ╔═╡ 62beeb74-785d-4033-8aca-c57c701872c5
 gaussian_samples = let
	Random.seed!(100)
    sample(
        ESSModel(gaussian_prior, gaussian_loglikelihood),
        ESS(),
        1_000;
        progress=false,
        thinning=10,
        discard_initial=100,
    )
end

# ╔═╡ e6d61e1c-8955-4650-8ed9-4dfaf50d6ac8
md"""
The following plot shows the prior distribution (right), the likelihood (left), and the analytical posterior and the samples obtained with elliptical slice sampling (center).
"""

# ╔═╡ 06319c72-cfaa-4321-bdfd-30f826e6f894
let
    fig = Figure()
    ax = Axis(fig[1, 1])

    xs = range(-2, 5.5; length=100)
    ys = range(-1.5, 4.5; length=100)
    contour!(ax, xs, ys, (x, y) -> pdf(gaussian_prior, [x, y]); levels=10)

    contour!(ax, xs, ys, (x, y) -> exp(gaussian_loglikelihood([x, y])); levels=10)

    contour!(
        ax,
        xs,
        ys,
        (x, y) -> pdf(MvNormal([2.1, 2.25], Diagonal([0.3, 0.375])), [x, y]);
        levels=10,
    )

    scatter!(ax, first.(gaussian_samples), last.(gaussian_samples))

    fig
end

# ╔═╡ 88356183-d8b7-45c0-bf70-315469747eae
md"""
## Example: Gaussian likelihood with Turing

We can also formulate the analytically tractable example with Turing and use elliptical slice sampling for Bayesian inference.
"""

# ╔═╡ ff44defe-4277-46fc-adbe-d72320e2c1e6
md"""
Again, the following plot shows the prior distribution (right), the likelihood (left), and the analytical posterior and the samples obtained with elliptical slice sampling (center).
"""

# ╔═╡ b1b39bc2-60cc-4ed6-b4e3-e20dcece9b6f
md"""
## Example: Gibbs sampling with Turing

It is also possible to use elliptical slice sampling within a Gibbs sampler. For instance, here we consider a model with prior distributions
```math
\begin{aligned}
p_{\sigma^2}(v) &:= \operatorname{InverseGamma}(v; 2, 3),\\
p_{M|\sigma^2}(m | v) &:= \mathcal{N}(m; 0, v),
\end{aligned}
```
and likelihood function
```math
\mathcal{L}(m, v) := p_{Y|M, \sigma^2}\big([1.5, 2]^\mathsf{T} | m, v\big) := \mathcal{N}(1.5; m, v) \mathcal{N}(2; m, v).
```
"""

# ╔═╡ 778fb004-710b-469c-8578-bad5bfb3f112
Turing.@model function turing_model()
	# priors
    σ² ~ InverseGamma(2, 3)
    σ = sqrt(σ²)
    m ~ Normal(0, σ)

	# observations
    [1.5, 2] ~ Normal(m, σ)
end

# ╔═╡ 97b47704-9daf-4d0f-a7d6-2ab5573d0c39
turing_samples = let
	Random.seed!(100)
    sample(
		turing_model(),
        Turing.Gibbs(Turing.ESS(:m), Turing.MH(:σ²)),
        1_000;
        progress=false,
        thinning=10,
        discard_initial=100,
    )
end

# ╔═╡ 15003690-45e8-4cfa-9be9-a6a4f0c57f79
md"""
For illustration purposes we chose a model where the posterior is analytically tractable. The following plots visualize the samples obtained with the Gibbs sampler (gray) and their mean (blue). The mean of the posterior distribution is shown in yellow.
"""

# ╔═╡ bd9813a5-222a-4195-aa7a-1b004ea32d51
let
    fig = Figure()

	# plot samples of `m`
	ax = Axis(fig[1, 1]; ylabel="m")
	samples = vec(turing_samples[:m])
    plot_samples = lines!(ax, samples; color=:gray, linewidth=1)
	plot_mean_samples = hlines!(ax, mean(samples); linewidth=3)
	plot_mean_analytic = hlines!(ax, 7/6; linestyle=:dash, linewidth=3)

	# plot samples of `σ2`
	ax2 = Axis(fig[2, 1]; ylabel="σ²")
	samples = vec(turing_samples[:σ²])
    lines!(ax2, samples; color=:gray, linewidth=1)
	hlines!(ax2, mean(samples); linewidth=3)
	hlines!(ax2, 49/24; linestyle=:dash, linewidth=3)

	linkxaxes!(ax, ax2)
	xlims!(ax, 1, 1000)
	hidexdecorations!(ax)

    # add legend
    Legend(
        fig[1:2, 2],
        [plot_samples, plot_mean_samples, plot_mean_analytic],
        ["samples", "mean (samples)", "mean (posterior)"];
    )

    fig
end

# ╔═╡ 1d6dc136-5e8f-421a-8236-d9d36aac19e4
md"""
## Example: Gaussian process regression

In this example, we consider a Gaussian process regression model, similar to the [PyMC3 documentation](https://pymc3.readthedocs.io/en/latest/notebooks/GP-slice-sampling.html). 

We use a squared exponential kernel with length scale ``0.1``. First, we generate noisy data with the [AbstractGPs.jl](https://github.com/TuringLang/AbstractGPs.jl) interface.
"""

# ╔═╡ 2f51be79-8e2a-4bea-9820-c76f3dcd70f0
gp = GP(SqExponentialKernel() ∘ ScaleTransform(10))

# ╔═╡ 3a8abd0a-6ff8-49fa-9a68-c400bbf77bc6
x = let
    Random.seed!(10)
    sort!(rand(30))
end

# ╔═╡ 53e85a87-93f9-4969-a83b-c6656771ac45
Turing.@model function gaussian_model()
	# prior
	x ~ MvNormal([3.5, 1.5], Diagonal([0.5, 1.5]))

	# observations
	[0, 2.5] ~ MvNormal(x, Diagonal([0.75, 0.5]))
end

# ╔═╡ e35a215f-d832-4ca0-9c5c-4a586228ed19
gaussian_samples_turing = let
	Random.seed!(100)
    sample(
		gaussian_model(),
        Turing.ESS(),
        1_000;
        progress=false,
        thinning=10,
        discard_initial=100,
    )
end

# ╔═╡ d1d2ebf5-95b7-4d04-beca-297eb5e845c8
let
    fig = Figure()
    ax = Axis(fig[1, 1])

    xs = range(-2, 5.5; length=100)
    ys = range(-1.5, 4.5; length=100)
    contour!(ax, xs, ys, (x, y) -> pdf(gaussian_prior, [x, y]); levels=10)

    contour!(ax, xs, ys, (x, y) -> exp(gaussian_loglikelihood([x, y])); levels=10)

    contour!(
        ax,
        xs,
        ys,
        (x, y) -> pdf(MvNormal([2.1, 2.25], Diagonal([0.3, 0.375])), [x, y]);
        levels=10,
    )

    scatter!(
		ax, vec(gaussian_samples_turing["x[1]"]), vec(gaussian_samples_turing["x[2]"])
	)

    fig
end

# ╔═╡ 9781d207-83f6-44b9-9976-71b0e942a093
gp_x = gp(x, 0.1)

# ╔═╡ ef2ef513-2acc-4442-aba0-0552135f9fe5
y = let
    Random.seed!(124)
    rand(gp_x)
end

# ╔═╡ c65daed3-855b-4ef1-b812-1f000e149340
let
    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel="x", ylabel="y")
    plot!(ax, x, y)
    xlims!(ax, 0, 1)
    fig
end

# ╔═╡ cdbe5f6b-944a-4621-be2e-dc756107126e
md"""
The following plot shows the data and the analytically tractable posterior distribution (mean ± one standard deviation).
"""

# ╔═╡ c021d89a-2ecb-4081-b58d-84400ceec39f
let
    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel="x", ylabel="y")
    plot!(ax, 0:0.01:1, posterior(gp_x, y); color=Makie.wong_colors(0.6)[1])
    plot!(ax, x, y)
    xlims!(ax, 0, 1)
    fig
end

# ╔═╡ d942b7cb-d5a2-4d44-8410-77bb69d5a039
md"""
We perform elliptical slice sampling of the original data (without noise).
"""

# ╔═╡ f6a73a9b-79b5-4c57-8f41-9b619ca60d2b
gp_regression_samples = let
    ℓ = let y = y, σ = 0.1
        x -> loglikelihood(MvNormal(x, σ), y)
    end
    Random.seed!(100)
    sample(
        ESSModel(MvNormal(mean_and_cov(gp(x, 1e-12))...), ℓ),
        ESS(),
        1_000;
        progress=false,
        thinning=10,
        discard_initial=100,
    )
end

# ╔═╡ dcc613d5-4776-4938-a17b-13b22af9a973
md"""
We plot the mean of the posterior distributions based on the samples from elliptical slice sampling.
"""

# ╔═╡ e47cece3-c1f3-408e-9561-a0372a2b4952
let
    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel="x", ylabel="y")
    color = CairoMakie.Makie.wong_colors(0.2)[1]
    for sample in gp_regression_samples
        lines!(ax, 0:0.01:1, mean(posterior(gp(x, 1e-12), sample)(0:0.01:1)); color=color)
    end
    plot!(ax, x, y)
    xlims!(ax, 0, 1)

    fig
end

# ╔═╡ 8f1cc195-0140-4b40-8a80-b6dbbe723b65
md"""
## Example: Gaussian process classification

In this example, we consider a Gaussian process classification model, similar to the [PyMC3 documentation](https://pymc3.readthedocs.io/en/latest/notebooks/GP-slice-sampling.html). 

Again, we use a squared exponential kernel with length scale ``0.1`` and the same noisy data as above. However, this time we assign a value of ``0`` (or `false`) to all negative values, and a value of ``1`` (or `true`) to all non-negative values.
"""

# ╔═╡ 14bbe282-a8d9-4145-89f1-faa702d92e35
z = y .>= 0

# ╔═╡ 092eabe6-dd6f-413d-8999-d6783fc1d526
let
    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel="x", ylabel="z")
    plot!(ax, x, z)
    xlims!(ax, 0, 1)
    fig
end

# ╔═╡ 92f095f9-799a-4a7d-987e-4e3a64fc1170
md"""
We perform elliptical slice sampling to infer the posterior distribution of the original, non-noisy values of the Gaussian process model.
"""

# ╔═╡ 9bfc5a65-c615-438e-890c-12c9353709d4
gp_classification_samples = let
    ℓ = let z = z
        x -> -sum(log1pexp((1 - 2 * zi) * xi) for (xi, zi) in zip(x, z))
    end
    Random.seed!(100)
    samples = sample(
        ESSModel(MvNormal(mean_and_cov(gp(x, 1e-12))...), ℓ),
        ESS(),
        500;
        progress=false,
        thinning=10,
        discard_initial=100,
    )
end

# ╔═╡ c4a30da1-89ad-407f-881d-38e43c1272fc
md"""
We plot the mean of the posterior distributions of the Gaussian process based on the samples from elliptical slice sampling.
"""

# ╔═╡ f083edce-af60-4eca-8a91-e0ca6a993bed
let
    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel="x", ylabel="y")
    color = CairoMakie.Makie.wong_colors(0.3)[1]
    for sample in gp_classification_samples
        lines!(
            ax,
            0:0.01:1,
            logistic.(mean(posterior(gp(x, 1e-12), sample)(0:0.01:1)));
            color=color,
        )
    end
    plot!(ax, x, z)
    xlims!(ax, 0, 1)

    fig
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractGPs = "99985d1d-32ba-4be9-9821-2ec096f28918"
AbstractGPsMakie = "7834405d-1089-4985-bd30-732a30b92057"
AlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
Distances = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
EllipticalSliceSampling = "cad2338a-1db2-11e9-3401-43bc07c9ede2"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
Luxor = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Turing = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"

[compat]
AbstractGPs = "~0.3.6"
AbstractGPsMakie = "~0.2.1"
AlgebraOfGraphics = "~0.4.6"
CairoMakie = "~0.6.1"
Distances = "~0.10.3"
Distributions = "~0.25.5"
EllipticalSliceSampling = "~0.4.4"
LogExpFunctions = "~0.2.4"
Luxor = "~2.12.0"
PlutoUI = "~0.7.9"
Turing = "~0.16.6"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[AbstractGPs]]
deps = ["ChainRulesCore", "Distributions", "FillArrays", "KernelFunctions", "LinearAlgebra", "Random", "RecipesBase", "Reexport", "Statistics", "StatsBase"]
git-tree-sha1 = "d8b6584ff1d523dd1304671f2c8a557dad26e214"
uuid = "99985d1d-32ba-4be9-9821-2ec096f28918"
version = "0.3.6"

[[AbstractGPsMakie]]
deps = ["AbstractGPs", "LinearAlgebra", "Makie"]
git-tree-sha1 = "bd44f422fcbdeada1528711d56135fa0652ae8ea"
uuid = "7834405d-1089-4985-bd30-732a30b92057"
version = "0.2.1"

[[AbstractMCMC]]
deps = ["BangBang", "ConsoleProgressMonitor", "Distributed", "Logging", "LoggingExtras", "ProgressLogging", "Random", "StatsBase", "TerminalLoggers", "Transducers"]
git-tree-sha1 = "21279159f6be4b2fd00e1a4a1f736893100408fc"
uuid = "80f14c24-f653-4e6a-9b94-39d6b0f70001"
version = "3.2.0"

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
deps = ["AbstractMCMC", "ArgCheck", "DocStringExtensions", "InplaceOps", "LinearAlgebra", "ProgressMeter", "Random", "Requires", "Setfield", "Statistics", "StatsBase", "StatsFuns", "UnPack"]
git-tree-sha1 = "38dc9bd338445735b7c11b07ddcfe5a117012e5e"
uuid = "0bf59076-c3b1-5ca4-86bd-e02cd72cde3d"
version = "0.3.0"

[[AdvancedMH]]
deps = ["AbstractMCMC", "Distributions", "Random", "Requires"]
git-tree-sha1 = "6fcaabc5def4dcb20218a12c73a261090182b0c1"
uuid = "5b7e9947-ddc0-4b3f-9b55-0d8042f74170"
version = "0.6.3"

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

[[AlgebraOfGraphics]]
deps = ["Colors", "DataAPI", "Dates", "FileIO", "GLM", "GeoInterface", "GeometryBasics", "GridLayoutBase", "KernelDensity", "Loess", "Makie", "PlotUtils", "PooledArrays", "StatsBase", "StructArrays", "Tables"]
git-tree-sha1 = "24f2aedfc2e5be687650e4afc7b3a8f7acdfb5d4"
uuid = "cbdf2221-f076-402e-a563-3d30da359d67"
version = "0.4.6"

[[Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[ArgCheck]]
git-tree-sha1 = "dedbbb2ddb876f899585c4ec4433265e3017215a"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.1.0"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

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
git-tree-sha1 = "d127d5e4d86c7680b20c35d40b503c74b9a39b5e"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.4"

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
git-tree-sha1 = "f032f0b27318b0ea5e35fc510759971fbba65179"
uuid = "76274a88-744f-5084-9051-94815aaf08c4"
version = "0.9.7"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "StaticArrays"]
git-tree-sha1 = "63bddf4fdece1aa72011bb1add90d4b9e7e76113"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.6.1"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f2202b55d816427cd385a9a4f3ffb226bee80f99"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+0"

[[ChainRules]]
deps = ["ChainRulesCore", "Compat", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "dabb81719f820cddd6df4916194d44f1fe282bd1"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "0.8.22"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "be770c08881f7bb928dfd86d1ba83798f76cf62a"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "0.10.9"

[[ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

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

[[ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "42a9b08d3f2f951c9b283ea427d96ed9f1f30343"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.5"

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
git-tree-sha1 = "dfb3b7e89e395be1e25c2ad6d7690dc29cc53b1d"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.6.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4437b64df1e0adccc3e5d1adbc3ac741095e4677"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.9"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

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
git-tree-sha1 = "62e1ac52e9adf4234285cd88c94954924aa3f9ef"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.5"

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
git-tree-sha1 = "94c766fb4432d359a6968094ffce36660cbaa05a"
uuid = "366bfd00-2699-11ea-058f-f148b4cae6d8"
version = "0.12.4"

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

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

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

[[FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "256d8e6188f3f1ebfa1a5d17e072a0efafa8c5bf"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.10.1"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "31939159aeb8ffad1d4d8ee44d07f8558273120a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.11.7"

[[FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "8b3c09b56acaf3c0e581c66638b85c8650ee9dca"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.8.1"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

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

[[FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "cabd77ab6a6fdff49bfd24af2ebe76e6e018a2b4"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.0.0"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "StaticArrays"]
git-tree-sha1 = "d51e69f0a2f8a3842bca4183b700cf3d9acce626"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.9.1"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[Functors]]
deps = ["MacroTools"]
git-tree-sha1 = "a7bb2af991c43dcf5c3455d276dd83976799634f"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.2.1"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLM]]
deps = ["Distributions", "LinearAlgebra", "Printf", "Reexport", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "StatsModels"]
git-tree-sha1 = "f564ce4af5e79bb88ff1f4488e64363487674278"
uuid = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
version = "1.5.1"

[[GeoInterface]]
deps = ["RecipesBase"]
git-tree-sha1 = "38a649e6a52d1bea9844b382343630ac754c931c"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "0.5.5"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "4136b8a5668341e58398bb472754bff4ba0456ff"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.3.12"

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

[[Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "2c1cf4df419938ece72de17f368a021ee162762e"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.0"

[[Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Match", "Observables"]
git-tree-sha1 = "db033d75853d0668011f5ab9cc3c4f8977516af9"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.5.4"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "8a954fed8ac097d5be04921d595f741115c1b2ad"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+0"

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

[[ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "8aa4a5c9b0b0a0fea9cac59549222078e375b867"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.0"

[[ImageIO]]
deps = ["FileIO", "Netpbm", "PNGFiles"]
git-tree-sha1 = "0d6d09c28d67611c68e25af0c2df7269c82b73c7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.4.1"

[[ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils", "Libdl", "Pkg", "Random"]
git-tree-sha1 = "5bc1cb62e0c5f1005868358db0692c994c3a13c6"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.1"

[[ImageMagick_jll]]
deps = ["JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1c0a2295cca535fabaf2029062912591e9b61987"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.10-12+3"

[[IndirectArrays]]
git-tree-sha1 = "c2a145a145dc03a7620af1444e0264ef907bd44f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "0.5.1"

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
deps = ["AxisAlgorithms", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "1e0e51692a3a77f1eeb51bf741bdd0439ed210e7"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.2"

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

[[Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

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

[[Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[KernelFunctions]]
deps = ["ChainRulesCore", "Compat", "CompositionsBase", "Distances", "FillArrays", "Functors", "LinearAlgebra", "Random", "Requires", "SpecialFunctions", "StatsBase", "StatsFuns", "TensorCore", "Test", "ZygoteRules"]
git-tree-sha1 = "c7b25bc625ca2ee217021d29e3ddf031967bf0ff"
uuid = "ec8451be-7e33-11e9-00cf-bbf324bd1392"
version = "0.10.5"

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

[[Libcroco_jll]]
deps = ["Artifacts", "Glib_jll", "JLLWrappers", "Libdl", "Pkg", "XML2_jll"]
git-tree-sha1 = "a8e3b1b67458c8933992b95db9c4b37865906e3f"
uuid = "57eb2189-7eb1-52c8-ac0e-99495f550b14"
version = "0.6.13+2"

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

[[Librsvg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libcroco_jll", "Libdl", "Pango_jll", "Pkg", "gdk_pixbuf_jll"]
git-tree-sha1 = "af3e6dc6747e53a0236fbad80b37e3269cf66a9f"
uuid = "925c91fb-5dd6-59dd-8e8c-345e74382d89"
version = "2.42.2+3"

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

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "b5254a86cf65944c68ed938e575f5c81d5dfe4cb"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.5.3"

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
git-tree-sha1 = "6f9f080a40e48b9f57be6ddcbd64dd399df3c567"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.58"

[[Luxor]]
deps = ["Base64", "Cairo", "Colors", "Dates", "FFMPEG", "FileIO", "ImageMagick", "Juno", "QuartzImageIO", "Random", "Rsvg"]
git-tree-sha1 = "3c5b13bb6f50b3fcb86c6cf43fe5c9356dc54eb6"
uuid = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
version = "2.12.0"

[[MCMCChains]]
deps = ["AbstractFFTs", "AbstractMCMC", "AxisArrays", "Compat", "Dates", "Distributions", "Formatting", "IteratorInterfaceExtensions", "LinearAlgebra", "MLJModelInterface", "NaturalSort", "PrettyTables", "Random", "RecipesBase", "Serialization", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "TableTraits", "Tables"]
git-tree-sha1 = "09e3390e2c9825ec1cdcacaa470f738b7ed61ae0"
uuid = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
version = "4.13.1"

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

[[Makie]]
deps = ["Animations", "Artifacts", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "IntervalSets", "Isoband", "KernelDensity", "LinearAlgebra", "MakieCore", "Markdown", "Match", "Observables", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "Serialization", "Showoff", "SignedDistanceFields", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "UnicodeFun"]
git-tree-sha1 = "273e14b86d69443013237d47a7c2e91e7dac14cd"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.14.1"

[[MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "7bcc8323fb37523a6a51ade2234eee27a11114c8"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.1.3"

[[ManualMemory]]
git-tree-sha1 = "71c64ebe61a12bad0911f8fc4f91df8a448c604c"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.4"

[[MappedArrays]]
git-tree-sha1 = "18d3584eebc861e311a552cbb67723af8edff5de"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.0"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[Match]]
git-tree-sha1 = "5cf525d97caf86d29307150fcba763a64eaa9cbe"
uuid = "7eb4fadd-790c-5f42-8a69-bfa0b872bfbf"
version = "1.1.0"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

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

[[MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NNlib]]
deps = ["Adapt", "ChainRulesCore", "Compat", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "d27c8947dab6e3a315f6dcd4d2493ed3ba541791"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.7.26"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[NaturalSort]]
git-tree-sha1 = "eda490d06b9f7c00752ee81cfa451efe55521e21"
uuid = "c020b1a1-e9b0-503a-9c33-f039bfc54a85"
version = "1.0.0"

[[Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

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
git-tree-sha1 = "e436bb81d2ce4f01fb02374c4410e5a9229c85f9"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.0"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

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

[[PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "520e28d4026d16dcf7b8c8140a3041f0e20a9ca8"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.7"

[[Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "f4049d379326c2c7aa875c702ad19346ecb2b004"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.4.1"

[[PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fa5e78929aebc3f6b56e1a88cf505bb00a354c4"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.8"

[[Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9bc1871464b12ed19297fbc56c4fb4ba84988b0d"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.47.0+0"

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

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "ae9a295ac761f64d8c2ec7f9f24d21eb4ffba34d"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.10"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

[[Polyester]]
deps = ["ArrayInterface", "IfElse", "ManualMemory", "Requires", "Static", "StrideArraysCore", "ThreadingUtilities", "VectorizationBase"]
git-tree-sha1 = "4b692c8ce1912bae5cd3b90ba22d1b54eb581195"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.3.7"

[[PolygonOps]]
git-tree-sha1 = "c031d2332c9a8e1c90eca239385815dc271abb22"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.1"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "cde4ce9d6f33219465b55162811d8de8139c0414"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.2.1"

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

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

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

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "12fbe86da16df6679be7521dfb39fbc861e1dc7b"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.1"

[[QuartzImageIO]]
deps = ["FileIO", "ImageCore", "Libdl"]
git-tree-sha1 = "16de3b880ffdfbc8fc6707383c00a2e076bb0221"
uuid = "dca85d43-d64c-5e67-8c65-017450d5d020"
version = "0.7.4"

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

[[RecursiveArrayTools]]
deps = ["ArrayInterface", "ChainRulesCore", "DocStringExtensions", "LinearAlgebra", "RecipesBase", "Requires", "StaticArrays", "Statistics", "ZygoteRules"]
git-tree-sha1 = "0426474f50756b3b47b08075604a41b460c45d17"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.16.1"

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

[[Rsvg]]
deps = ["Cairo", "Glib_jll", "Librsvg_jll"]
git-tree-sha1 = "3d3dc66eb46568fb3a5259034bfc752a0eb0c686"
uuid = "c4c386cf-5103-5370-be45-f3a111cca3b8"
version = "1.0.0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "bfdf9532c33db35d2ce9df4828330f0e92344a52"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.25"

[[SciMLBase]]
deps = ["ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "RecipesBase", "RecursiveArrayTools", "StaticArrays", "Statistics", "Tables", "TreeViews"]
git-tree-sha1 = "f0bf114650476709dd04e690ab2e36d88368955e"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "1.18.2"

[[ScientificTypesBase]]
git-tree-sha1 = "3f7ddb0cf0c3a4cff06d9df6f01135fa5442c99b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "1.0.0"

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

[[ShiftedArrays]]
git-tree-sha1 = "22395afdcf37d6709a5a0766cc4a5ca52cb85ea0"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "1.0.0"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

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

[[StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

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
git-tree-sha1 = "93f7326079b73910e5a81f8848e7a633f99a2946"
uuid = "64bff920-2084-43da-a3e6-9bb72801c0c9"
version = "2.0.1"

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

[[StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "dfdf16cc1e531e154c7e62cd42d531e00f8d100e"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.23"

[[StrideArraysCore]]
deps = ["ArrayInterface", "ManualMemory", "Requires", "ThreadingUtilities", "VectorizationBase"]
git-tree-sha1 = "e1c37dd3022ba6aaf536541dd607e8d5fb534377"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.1.17"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "Tables"]
git-tree-sha1 = "44b3afd37b17422a62aea25f04c1f7e09ce6b07f"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.5.1"

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

[[TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[TerminalLoggers]]
deps = ["LeftChildRightSiblingTrees", "Logging", "Markdown", "Printf", "ProgressLogging", "UUIDs"]
git-tree-sha1 = "e185a19bb9172f0cf5bc71233fab92a46f7ae154"
uuid = "5d786b92-1e48-4d6f-9151-6b4477ca9bed"
version = "0.1.3"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "03013c6ae7f1824131b2ae2fc1d49793b51e8394"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.4.6"

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
git-tree-sha1 = "a330a52cbbc2b926b4e5b4296105fe1fc7d656b9"
uuid = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"
version = "0.16.6"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[VectorizationBase]]
deps = ["ArrayInterface", "Hwloc", "IfElse", "Libdl", "LinearAlgebra", "Static"]
git-tree-sha1 = "a4bc1b406dcab1bc482ce647e6d3d53640defee3"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.20.25"

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

[[gdk_pixbuf_jll]]
deps = ["Artifacts", "Glib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Xorg_libX11_jll", "libpng_jll"]
git-tree-sha1 = "031f60d4362fba8f8778b31047491823f5a73000"
uuid = "da03df04-f53b-5353-a52f-6a8b0620ced0"
version = "2.38.2+9"

[[isoband_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "a1ac99674715995a536bbce674b068ec1b7d893d"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.2+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

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
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╟─9f6813de-08fe-4026-8bec-d5f0241e6752
# ╟─80b60191-0686-41f9-905d-4c7f8acb783f
# ╠═14dbe097-648c-4480-bf4a-990a377ba984
# ╟─11762e96-c9b6-11eb-0fef-27543b5f5084
# ╟─1931da6a-59e0-401a-830a-41cad4b98c76
# ╟─7bfec871-a912-430e-8341-b462584839be
# ╟─be1846e5-9725-4375-b7ce-0b7106be2032
# ╟─1a92abc8-bf14-4b70-a3e9-ab10d2949a97
# ╠═a979c0d7-ee36-49a3-930c-faea3b541595
# ╟─b29b907f-f33e-4247-8c7a-5cca00eb571f
# ╟─b939278f-7f8d-4757-b1d5-3ca064515aed
# ╟─419d36b5-0572-4842-8040-2da05507c793
# ╟─e721cebb-a136-494e-a0dd-a53575127fe9
# ╟─b6f9c887-ac31-4a4c-90c6-3f812f800af1
# ╟─2bcda59a-14d7-4a8f-ac6d-1b357846c2e0
# ╟─6e2cd527-9fad-4f1e-bea5-d9347390e3c6
# ╟─79df97c7-3aee-4239-ad1e-92b85e42a2c4
# ╟─a378db41-9fba-4759-bd5b-97be9dc0e5ac
# ╠═0f315738-bbfc-4ff9-a75f-0103c1ebac79
# ╠═09c4efb9-6b96-42ec-8526-6f7e720abb2c
# ╠═62beeb74-785d-4033-8aca-c57c701872c5
# ╟─e6d61e1c-8955-4650-8ed9-4dfaf50d6ac8
# ╟─06319c72-cfaa-4321-bdfd-30f826e6f894
# ╟─88356183-d8b7-45c0-bf70-315469747eae
# ╠═53e85a87-93f9-4969-a83b-c6656771ac45
# ╟─e35a215f-d832-4ca0-9c5c-4a586228ed19
# ╟─ff44defe-4277-46fc-adbe-d72320e2c1e6
# ╟─d1d2ebf5-95b7-4d04-beca-297eb5e845c8
# ╟─b1b39bc2-60cc-4ed6-b4e3-e20dcece9b6f
# ╠═778fb004-710b-469c-8578-bad5bfb3f112
# ╠═97b47704-9daf-4d0f-a7d6-2ab5573d0c39
# ╟─15003690-45e8-4cfa-9be9-a6a4f0c57f79
# ╟─bd9813a5-222a-4195-aa7a-1b004ea32d51
# ╟─1d6dc136-5e8f-421a-8236-d9d36aac19e4
# ╟─c65daed3-855b-4ef1-b812-1f000e149340
# ╠═2f51be79-8e2a-4bea-9820-c76f3dcd70f0
# ╠═3a8abd0a-6ff8-49fa-9a68-c400bbf77bc6
# ╠═9781d207-83f6-44b9-9976-71b0e942a093
# ╠═ef2ef513-2acc-4442-aba0-0552135f9fe5
# ╟─cdbe5f6b-944a-4621-be2e-dc756107126e
# ╟─c021d89a-2ecb-4081-b58d-84400ceec39f
# ╟─d942b7cb-d5a2-4d44-8410-77bb69d5a039
# ╠═f6a73a9b-79b5-4c57-8f41-9b619ca60d2b
# ╟─dcc613d5-4776-4938-a17b-13b22af9a973
# ╟─e47cece3-c1f3-408e-9561-a0372a2b4952
# ╟─8f1cc195-0140-4b40-8a80-b6dbbe723b65
# ╠═14bbe282-a8d9-4145-89f1-faa702d92e35
# ╟─092eabe6-dd6f-413d-8999-d6783fc1d526
# ╟─92f095f9-799a-4a7d-987e-4e3a64fc1170
# ╠═9bfc5a65-c615-438e-890c-12c9353709d4
# ╟─c4a30da1-89ad-407f-881d-38e43c1272fc
# ╟─f083edce-af60-4eca-8a91-e0ca6a993bed
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
