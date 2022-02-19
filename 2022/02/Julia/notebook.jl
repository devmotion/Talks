### A Pluto.jl notebook ###
# v0.18.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 4cf10ace-aa9e-4c83-b766-3c8ec0ac88af
begin
	using DifferentialEquations
	using GalacticOptim
	using PlutoUI
	using StatsPlots
	using Turing

	using DiffEqProblemLibrary: DDEProblemLibrary
	DDEProblemLibrary.importddeproblems()

	import BlackBoxOptim
	import DiffEqFlux
	import Graphs
	import GraphRecipes
	import LogExpFunctions
	import StatsBase
	import Random
	import LinearAlgebra

	# Plot settings
	default(palette=:Dark2_8, linewidth=2, fontfamily="JuliaMono")
	ENV["GKS_ENCODING"] = "utf-8";
end

# ╔═╡ 1aab1648-ae1a-46b5-af7c-3db839eda775
html"<button onclick='present()'>present</button>"

# ╔═╡ dc9484dc-3d5b-4edd-b8e6-50e9a9384ccf
md"""
##### Package initialization
"""

# ╔═╡ 44a14e5e-8f8b-11ec-1a0d-e1f4fd89bbc9
md"""
# Scientific computing with Julia

$(Resource("https://widmann.dev/assets/profile_small.jpg", :width=>75, :align=>"right"))
**David Widmann
(@devmotion $(Resource("https://raw.githubusercontent.com/edent/SuperTinyIcons/bed6907f8e4f5cb5bb21299b9070f4d7c51098c0/images/svg/github.svg", :width=>10)))**

Uppsala University, Sweden

*American University in Bulgaria, 17 February 2022*
"""

# ╔═╡ d186ea33-ae8c-452d-bd35-05b02770078c
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

# ╔═╡ 7961a64e-24a2-4184-87ae-ee5362c94524
md"""
## Outline

We will see examples from and I will discuss my relation to
- SciML (a lot)
- Turing (a bit)
- my research (a bit)

This is a very opinionated choice, there are many other great packages and organizations in Julia for scientific computing.

!!! note
    I use Julia a lot and generally I am very satisfied with it. But this means:
    - I am quite biased
    - You will hear mostly good things about Julia in this talk

Please interrupt me at any time if you have a question 🙂
"""

# ╔═╡ 3db082dd-7663-43fc-a84e-25c9cafa9bee
md"""
## "Why we created Julia"

[Bezanson, Karpinski, Shah, and Edelman (2012)](https://julialang.org/blog/2012/02/why-we-created-julia/):

> In short, because we are greedy.

> We want a language that's open source, with a liberal license.

> We want the speed of C with the dynamism of Ruby.

> We want something as usable for general programming as Python, as easy for statistics as R, as natural for string processing as Perl, as powerful for linear algebra as Matlab, as good at gluing programs together as the shell.

> Something that is dirt simple to learn, yet keeps the most serious hackers happy.

> We want it interactive and we want it compiled.
"""

# ╔═╡ 25284a37-6c21-4b67-9c1f-5222e4b7c890
md"""
## Why we use Julia, 10 years later

[14 February 2022](https://julialang.org/blog/2022/02/10years)

$(Resource("https://user-images.githubusercontent.com/35577566/153917389-f9e3cbbf-8c14-47f7-a8ae-a3dcbd60f4a8.png", :width => 300, :align => "center"))
"""

# ╔═╡ 27b8fc94-eef0-41a8-bff1-c83577216a1d
md"""
## Why do I use Julia?

I was curious and excited early on:
- a, supposedly fast and cool, programming language! 🎉
- that is open source 📖
- and has a nice math-like syntax 😍

At TUM I had to learn and use MATLAB and R...

...but I used the opportunity and tried to work and become familiar with it for a course project during my Erasmus exchange in Uppsala.
"""

# ╔═╡ 2baccd93-9524-47d7-a99d-29567cde10b0
md"""
## Initial contributions

I had noticed some things that were missing and maybe could be improved.

After I was done with my exchange year, I had some time and started to make my first small contributions.
"""

# ╔═╡ 874c1c27-77f9-4651-85d5-5136d85b50df
md"""
## Barabási-Albert random graphs

[First PR](https://github.com/sbromberger/LightGraphs.jl/pull/373) (archived, use Graphs.jl nowadays) 
"""

# ╔═╡ 4963b2fd-f1a3-457f-b5c8-ed87efd45b41
@doc Graphs.barabasi_albert

# ╔═╡ 87dc589b-7951-4c48-ab1f-a59b969c84af
let
	graph = Graphs.barabasi_albert(10, 3; complete=true)
	GraphRecipes.graphplot(graph; curves=false)
end

# ╔═╡ 4d4f219d-cfa3-4dd5-bfbf-ce3a485508bb
md"""
## Weighted sampling without replacement

[Faster algorithms](https://github.com/JuliaStats/StatsBase.jl/pull/176)
"""

# ╔═╡ f55c3c79-24fa-4c88-aeca-84ee77a99d43
@doc StatsBase.efraimidis_aexpj_wsample_norep!

# ╔═╡ 3417db1e-476e-4ec2-8e26-bd28762bab72
md"""
# SciML $(PlutoUI.Resource("https://diffeq.sciml.ai/dev/assets/logo.png", :height=>38))
"""

# ╔═╡ 91272182-913b-4cfd-9594-f09d0ffdb02e
html"""
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">SciML is now an official NumFOCUS sponsored organization! <a href="https://t.co/d7SohCYibq">https://t.co/d7SohCYibq</a> We will continue to develop and support sustainable software for scientific simulation and scientific machine learning <a href="https://twitter.com/hashtag/sciml?src=hash&amp;ref_src=twsrc%5Etfw">#sciml</a> in <a href="https://twitter.com/hashtag/julialang?src=hash&amp;ref_src=twsrc%5Etfw">#julialang</a> <a href="https://twitter.com/hashtag/python?src=hash&amp;ref_src=twsrc%5Etfw">#python</a> and <a href="https://twitter.com/hashtag/RStats?src=hash&amp;ref_src=twsrc%5Etfw">#RStats</a>. Thank you everyone for your support!</p>&mdash; SciML Scientific Machine Learning Software Org (@SciML_Org) <a href="https://twitter.com/SciML_Org/status/1307028166058401792?ref_src=twsrc%5Etfw">September 18, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 
"""

# ╔═╡ be1f53cf-a001-4712-b0c8-466abb503495
md"""
Excerpt from the [NumFOCUS project page](https://numfocus.org/project/sciml):

> SciML is an open source software organization created to unify the packages for scientific machine learning. This includes the development of modular scientific simulation support software, such as differential equation solvers, along with the methodologies for inverse problems and automated model discovery. By providing a diverse set of tools with a common interface, we provide a modular, easily-extendable, and highly performant ecosystem for handling a wide variety of scientific simulations.

> SciML tools are used by many organizations, such as (but not limited to!) the CliMA: Climate Modeling Alliance, the New York Federal Reserve Bank, the Julia Robotics community, Pumas-AI: Pharmaceutical Modeling and Simulation, and the Brazilian National Institute for Space Research (INPE).

**Disclaimer:** I am a Github admin and member of the steering council of SciML, so I'm definitely biased 🙃
"""

# ╔═╡ c61bc310-117d-4f1b-922a-4e761dd47916
md"""
## Ordinary differential equation (ODE): Lotka-Volterra model

Differential equation model of predator-prey interaction:

$$\begin{align}
\frac{\mathrm{d}}{\mathrm{d}t} 🐰 &= \alpha 🐰 - \beta 🐰 🦊 \\
\frac{\mathrm{d}}{\mathrm{d}t} 🦊 &= - \gamma 🦊 + \delta 🐰 🦊
\end{align}$$
"""

# ╔═╡ 7b01dced-84d1-405c-81ca-da8558c6301b
function lotkavolterra!(du, u, p, t)
	🐰, 🦊 = u
	α, β, γ, δ = p

	du[1] = d🐰 = α * 🐰 - β * 🐰 * 🦊
	du[2] = d🦊 = - γ * 🦊 + δ * 🐰 * 🦊
end

# ╔═╡ 1314ea89-8f18-454d-afb9-edd92f6799cf
md"Problem formulation with initial value, integration time span, and default parameters:"

# ╔═╡ 1031c4ff-0021-47a6-9b40-6d050bcbe72f
lotkavolterra_prob = ODEProblem(
	lotkavolterra!, # ODE function
	[1.0, 1.0], # initial values
	(0.0, 10.0), # integration time span
	(α = 1.5, β = 1.0, γ = 3.0, δ = 1.0) # parameters
)

# ╔═╡ 002ebd6b-115c-400d-a35c-b6eaa1844553
md"Solve problem:"

# ╔═╡ 78b0bf4f-6ac6-47b3-abd2-c3366730f45a
solve(lotkavolterra_prob)

# ╔═╡ ca014089-13cb-436c-8422-416368897a9a
let
	sol = solve(lotkavolterra_prob)
	sol(1.5)
end

# ╔═╡ 3a9ebd39-b5b2-4605-9f99-6cd993bc0c25
function plot_lotkavolterra(sol)
	plt1 = plot(sol, vars=(0, 1); label="🐰", legend=:outertopright)
	plot!(plt1, sol, vars=(0, 2); label="🦊", ylabel="population")

	plt2 = plot(sol, vars=(1, 2); xlabel="🐰", ylabel="🦊", legend=false)

	plot(plt1, plt2; layout=@layout[a; b])
end

# ╔═╡ 2a48707c-a9e5-4267-a5bf-47e9ee877133
plot_lotkavolterra(solve(lotkavolterra_prob))

# ╔═╡ 7274b0ae-0ab8-42ea-bb87-63108cdb6677
md"Different parameter choices:"

# ╔═╡ e748a9c8-f50c-422c-a0ee-9c4c363b06fa
lotkavolterra_params = [1.0, 0.5, 1.0, 1.0];

# ╔═╡ 9444f2bb-d2c4-4d08-914f-63161db4ee50
let
	# Solve ODE
	sol = solve(lotkavolterra_prob; p=lotkavolterra_params)

	# Plot solution
	plot_lotkavolterra(sol)
end

# ╔═╡ 40f29b3a-fe04-42b2-99fb-07875e9b76fb
md"""
!!! note
    Many more details and explanations can be found in the [official documentation](https://diffeq.sciml.ai). If you notice that anything is missing, unclear, or incorrect, it's great if you open an issue or pull request! 🙏
"""

# ╔═╡ a97f083a-9eb5-49de-8be8-ff82da8d50d0
md"""
## Why don't we always use Euler's method?

Reference: [Blog by Chris Rackauckas](https://nextjournal.com/ChrisRackauckas/why-you-shouldnt-use-eulers-method-to-solve-odes)

A [chaotic model of random neural networks](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.61.259) (reference solution, computed with a high-order algorithm and very low tolerance):
"""

# ╔═╡ 1a6e99db-6a42-485b-a100-e23574c17dda
chaos_methods = [
	(name = "Reference", alg = Vern9(), opts = (abstol = 1e-14, reltol=1e-14)),
	(name = "Euler (dt = 0.1)", alg = Euler(), opts = (dt = 0.1,)),
	(name = "Euler (dt = 0.01)", alg = Euler(), opts = (dt = 0.01,)),
	(name = "Euler (dt = 0.001)", alg = Euler(), opts = (dt = 0.001,)),
	(name = "Tsit5", alg = Tsit5(), opts = ()),
];

# ╔═╡ d354e9b2-9566-490b-9faf-6fcde3e56ac4
md"""
A corresponding work-precision diagram:

$(PlutoUI.Resource("https://i.imgur.com/WxBIHuT.png", :width=>"900px"))

> Whenever someone in 2019 uses more code to internally implement a quick and dirty solver instead of running standard codes, a baby sheds a tear. It's not just about error or speed (or even accuracy: libraries undergo lots of tests!), it's about how much error you get with a certain speed. Euler's method (and even RK4) just don't scale well if you need non-trivial error on most equations.
"""

# ╔═╡ 8fcf8bdb-3119-43f2-9abf-44dced28d31a
md"""
## Comparison of different solvers

[Lotka-Volterra (non-stiff)](https://benchmarks.sciml.ai/html/NonStiffODE/LotkaVolterra_wpd.html)

[ROBER (stiff)](https://benchmarks.sciml.ai/html/StiffODE/ROBER.html)
"""

# ╔═╡ afd160a1-74da-41a7-990d-c9981e9f5f5b
md"""
## Only ODEs?!

[Supported equations](https://diffeq.sciml.ai/dev/) include
- Discrete equations (function maps, discrete stochastic (Gillespie/Markov) simulations)
- Ordinary differential equations (ODEs)
- Split and Partitioned ODEs (Symplectic integrators, IMEX Methods)
- Stochastic ordinary differential equations (SODEs or SDEs)
- Stochastic differential-algebraic equations (SDAEs)
- Random differential equations (RODEs or RDEs)
- Differential algebraic equations (DAEs)
- Delay differential equations (DDEs)
- Neutral, retarded, and algebraic delay differential equations (NDDEs, RDDEs, and DDAEs)
- Stochastic delay differential equations (SDDEs)
- Experimental support for stochastic neutral, retarded, and algebraic delay differential equations (SNDDEs, SRDDEs, and SDDAEs)
- Mixed discrete and continuous equations (Hybrid Equations, Jump Diffusions)
- (Stochastic) partial differential equations ((S)PDEs) (with both finite difference and finite element methods)
"""

# ╔═╡ 30c3f022-b0fb-4df7-a292-e1a190829b3b
md"""
## My relation to SciML

I wrote my master thesis about a mathematical model of quorum sensing of *P. putida*.

$(Resource("https://www.researchgate.net/profile/Maria-Barbarossa/publication/303246621/figure/fig1/AS:362383982776320@1463410482029/Model-structure-for-the-quorum-sensing-system-in-one-Pseudomonas-putida-cell-N-Acyl_W640.jpg", :width => 400, :align => "middle"))

[doi:10.3390/app6050149](https://doi.org/10.3390/app6050149)

!!! note
    Often biological processes do not occur instantaneously but with **some delay**.

Here lactonase activity is regulated by PpuR-AHL complex with a specific **time delay**:
```math
\begin{aligned}
    S'(t) ={}& D(S_0 - S(t)) - \frac{\gamma_S{S(t)}^{n_S}}{K^{n_S}_m+{S(t)}^{n_S}}N(t) \\
    N'(t) ={}& N(t)\left(\frac{a{S(t)}^{n_S}}{K^{n_S}_m+{S(t)}^{n_S}} -
      D\right) \\
    A'(t) ={}& \begin{split}
 \left(\alpha_A + \frac{\beta_A{C(t)}^{n_1}}{C^{n_1}_1 +
        {C(t)}^{n_1}}\right) N(t) - \gamma_A A(t) - DA(t) \\
+\gamma_3C(t) - \alpha_C (R_{tot} - C(t)) A(t) - K_EA(t)L(t)
\end{split} \\
    C'(t) ={}& \alpha_C (R_{tot} - C(t))A(t) - \gamma_3 C(t)\\
    L'(t) ={}& \frac{\alpha_L
      {\textcolor{red}{C(t-\tau)}}^{n_2}}{C^{n_2}_2+{ \textcolor{red}{C(t-\tau)}}^{n_2}}N(t) -
    \gamma_L L(t) - DL(t)
\end{aligned}
```
"""

# ╔═╡ bea72389-f73b-4c5c-87a5-3d240346e3f7
md"""
#### Experimental data and numerical simulations:

$(Resource("https://www.researchgate.net/profile/Maria-Barbarossa/publication/303246621/figure/fig2/AS:362383982776321@1463410482066/Experimental-data-and-numerical-solution-of-the-mathematical-model-4-Picture-adapted_W640.jpg", :width => 400))

[doi:10.3390/app6050149](https://doi.org/10.3390/app6050149) (adapted from [doi:10.1007/s00216-014-8063-6](https://doi.org/10.1007/s00216-014-8063-6))
"""

# ╔═╡ df7f2ec7-9981-417e-b2cb-315fb4e51b84
md"#### Simulation with MATLAB (dde23)"

# ╔═╡ 8d2a0997-e5f7-4141-bd66-8167b160068b
md"""
### Simulation with DelayDiffEq.jl

Similar issues with default settings:
"""

# ╔═╡ 5e88a3b7-00e8-43aa-8469-beaabe79eb46
let
    sol = solve(
        DDEProblemLibrary.prob_dde_qs,
        MethodOfSteps(Tsit5());
        save_idxs=3,
    )
    plot(sol; xlabel="t [h]", ylabel="A(t) [mol/l]", legend=false)
    scatter!(sol.t, sol.u)
end

# ╔═╡ 3bb8c4ba-897c-4b51-b6dc-377b239760b7
md"Decreasing the step size improves the solution (also in MATLAB):"

# ╔═╡ 242b55bd-bbda-4cc5-88e6-cba81acbb672
let
    sol = solve(
        DDEProblemLibrary.prob_dde_qs,
        MethodOfSteps(Tsit5());
        dtmax=0.1,
        save_idxs=3,
    )
    plot(sol; xlabel="t [h]", ylabel="A(t) [mol/l]", legend=false)
end

# ╔═╡ 511c9a1e-7c61-45f6-87c6-87a68c6c8cbe
md"""
But this increases the number of steps and hence makes the computation slower! 😢

I really wanted to perform computations both efficiently and accurate.

So I decided to
- work with Julia and improve DelayDiffEq
- add support for more and also stiff methods based on the vast amount of existing methods for ODEs,
- add callbacks that preserve domain constraints
"""

# ╔═╡ a4d90951-5051-4bab-a6c5-1641596effa3
md"""
### Stiff methods

Methods such as `MethodOfSteps(Rosenbrock23())` can solve the DDE without restricting the step size:
"""

# ╔═╡ bf4c1e64-f7a8-45cd-9345-7bb1ec3e889e
let
    sol = solve(
        DDEProblemLibrary.prob_dde_qs,
        MethodOfSteps(Rosenbrock23());
        save_idxs=3,
    )
    plot(sol; xlabel="t [h]", ylabel="A(t) [mol/l]", legend=false)
    scatter!(sol.t, sol.u)
end

# ╔═╡ b6a5aa0f-2334-414e-a206-ade905997c26
md"""
### A simpler example: Mackey-Glass equation

Model of circulating blood cells ``x(t)`` at time ``t`` by Mackey and Glass

Given by
```math
\begin{aligned}
x'(t) &= \frac{\beta x(t-\tau)}{1 + {x(t-\tau)}^n} - \gamma x(t), \quad t \geq 0,\\
x(t) &= x_0(t), \quad t \in [-\tau, 0]
\end{aligned}
```

- Blood cells are destroyed at rate $\gamma$
- Their production rate depends on concentration $x(t-\tau)$ since
  > [t]here is a significant delay $\tau$ between the initiation of cellular production in the bone marrow and the release of mature cells into the blood
"""

# ╔═╡ c44a7e31-723b-4c72-b845-f8fce0c4979b
function mackeyglass(x, h, p, t)
    (; β, γ, n, τ) = p
    xlag = h(p, t - τ)
    return β * xlag / (1 + xlag^n) - γ * x
end

# ╔═╡ 1a1f0444-deec-48cc-9a61-22d0a3ebb03c
mackeyglass_history(p, t) = p.x₀

# ╔═╡ eedc301a-ab50-4e7e-8d6f-63052ad852eb
mackeyglass_prob = DDEProblem(
    mackeyglass, # derivative
    0.5, # initial value
    mackeyglass_history, # history function
    (0.0, 600.0), # time span
    (; x₀=0.5, β=2, γ=1, n=9.65, τ=2); # parameters
    constant_lags=(2,) # collection of constant lags
)

# ╔═╡ 679fa6cd-029d-494d-9ccc-67a5a7c79b99
md"""
Define DDE problem with $x_0 = 0.5$, $\beta = 2$, $\gamma = 1$, $n = 9.65$, and $\tau = 2$ (values taken from [here](http://www.scholarpedia.org/article/Mackey-Glass_equation)):
"""

# ╔═╡ b373c5c7-c45c-4161-90ae-3ab4c6bedcd3
let
    sol = solve(mackeyglass_prob, MethodOfSteps(Rosenbrock23()))

	plt1 = plot(sol; xlabel="t", ylabel="x(t)", legend=false)

	ts = range(2, 600; length=50_000)
    plt2 = plot(
        sol(ts),
        sol(ts .- 2);
        xlabel="x(t)",
        ylabel="x(t-2)",
        legend=false,
    )

	plot(plt1, plt2; layout=@layout[a; b])
end

# ╔═╡ 21802542-35fd-4034-9ddd-9f783bf59ccb
md"""
## Only differential equations?!

[Core components](https://sciml.ai/#core_components) are
- Differential Equation Solving
- Physics-Informed Model Discovery and Learning
- Bridges to Python and R
- Compiler-Assisted Model Analysis and Sparsity Acceleration
- ML-Assisted Tooling for Model Acceleration
- Differentiable Scientific Data Structures and Simulators
- Tools for Accelerated Algorithm Development and Research
"""

# ╔═╡ b7354aa0-d242-462e-9c94-9cd1a3d0298d
md"""
## Parameter estimation

Some noisy data:
"""

# ╔═╡ 1d6500d0-109e-42f3-a469-870d7bbf621a
lotkavolterra_data = let
	Random.seed!(7389)
	sol = solve(lotkavolterra_prob; saveat=0.1)
	DiffEqArray(
		[sol.u[i] .+ 0.1 .* randn(2) for i in 1:length(sol)],
		sol.t,
	)
end;

# ╔═╡ 19d90bc8-f566-4da7-af5c-333e9d2f73cc
let
	sol = solve(lotkavolterra_prob)
	
	plot(
		sol, vars=(0,1);
		label="🐰", ylabel="population", legend=:outertopright
	)
	plot!(sol, vars=(0,2); label="🦊")
	
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 1);
		color=1, label="",
	)
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 2);
		color=2, label="",
	)
end

# ╔═╡ 56591331-ed74-443e-9f23-6b636c47eb29
md"""
SciML supports many different packages for local and global optimization such as [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), [LeastSquaresOptim.jl](https://github.com/matthieugomez/LeastSquaresOptim.jl), [JuMP](https://github.com/JuliaOpt/JuMP.jl),
and any package that implements the MathProgBase interface such as [NLOpt.jl](https://github.com/JuliaOpt/NLopt.jl).

The default evoluationary optimization algorithm in the package [BlackBoxOptim.jl](https://github.com/robertfeldt/BlackBoxOptim.jl)
yields the following optimal parameters:
"""

# ╔═╡ 6ca7370f-5ac4-4179-9192-2c836cc3af73
blackbox_params = let prob=lotkavolterra_prob, data=lotkavolterra_data
	Random.seed!(8212)
	
	# Define optimization problem
	optimprob = OptimizationProblem(
		5 .* rand(4); # initial values
		lb=zeros(4), # lower bound
		ub=fill(5.0, 4), # upper bound
	) do x, p
		# Solve ODE
		sol = solve(
			prob,
			Tsit5();
			p=x,
			saveat=data.t,
			reltol=1e-6,
		)

		# Check if numerical solver succeeded
		if (sol.retcode !== :Success && sol.retcode !== :Terminated) || length(sol) != length(data)
			return Inf
		end

		# Compute squared Euclidean distance between simulation and observation
		sumsq = 0.0
		@inbounds for i in 1:length(sol)
			soli = sol[i]
			datai = data[i]
			sumsq += (soli[1] - datai[1])^2 + (soli[2] - datai[2])^2
		end
		return sumsq
	end

	# Solve optimization problem
	optimsol = solve(
		optimprob,
		BBO_adaptive_de_rand_1_bin_radiuslimited();
		maxiters = 10_000,
	)

	optimsol.u
end

# ╔═╡ 9a440f90-2535-4203-87c1-0cd16cc43fbf
md"Optimized trajectories:"

# ╔═╡ b0ce4ad8-94b8-4c07-990c-4d1735d5b81a
let
	# True dynamics
	sol = solve(lotkavolterra_prob)
	plot(
		sol, vars=(0, 1);
		label="🐰", ylabel="population", legend=:outertopright,
	)
	plot!(sol, vars=(0, 2); label="🦊")

	# Optimized dynamics
	bbosol = solve(lotkavolterra_prob; p=blackbox_params)
	plot!(
		bbosol, vars=(0, 1);
		label="🐰 (optimized)", ylabel="population", legend=:outertopright,
	)
	plot!(bbosol, vars=(0, 2); label="🦊 (optimized)")

	# Data
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 1);
		color=1, label="",
	)
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 2);
		color=2, label="",
	)
end

# ╔═╡ 1fa0638a-99d0-4eda-8684-9b93c07095d6
md"""
## Neural ODEs

### Example 1

Neural ODE:

$$\begin{align}
\frac{\mathrm{d}}{\mathrm{d}t}\begin{bmatrix} 🐰 \\ 🦊 \end{bmatrix} &= \mathrm{NeuralNetwork}\left(\begin{bmatrix} 🐰 \\ 🦊 \end{bmatrix}\right)
\end{align}$$
"""

# ╔═╡ 5dd8d9f7-3272-46f6-ac82-8f81440dc575
let
	Random.seed!(100)

	# Define the ODE function
	layers = DiffEqFlux.FastChain(
		DiffEqFlux.FastDense(2, 50, DiffEqFlux.tanh),
		DiffEqFlux.FastDense(50, 2),
	)
	dudt_(u, p, t) = layers(u, p)
	
	# Define the ODE problem
	prob = ODEProblem{false}(
		dudt_, [1f0, 1f0], (0f0, 10f0), DiffEqFlux.initial_params(layers),
	)
	
	# Define the loss function
	function loss_function(p, (u, t))
		sol = solve(
			prob,
			Tsit5();
			p=p,
			saveat=t,
			reltol=1f-6,
		)

		# Check if numerical solver succeeded
		if (sol.retcode !== :Success && sol.retcode !== :Terminated) || length(sol) != length(t)
			return Inf32
		end
		
		return sum(abs2, u .- Array(sol))
	end
	
	# Use Float32
	us = Float32.(Array(lotkavolterra_data))
	ts = Float32.(lotkavolterra_data.t)

	# Perform gradient descent with initial data
	optimf = OptimizationFunction(loss_function, GalacticOptim.AutoZygote())
	optimprob = OptimizationProblem(
		optimf, prob.p, (us[:, 1:30], ts[1:30]),
	)
	result = solve(
		optimprob, DiffEqFlux.ADAM(0.01f0);
		maxiters = 300,
	)
	
	# Decreased learning rate with more data
	optimprob2 = OptimizationProblem(
		optimf,
		result.minimizer,
		(us[:, 1:60], ts[1:60]),
	)
	result2 = solve(
		optimprob2, DiffEqFlux.ADAM(0.01f0);
		maxiters = 300,
	)

	# Further decreased learning rate with all data
	optimprob3 = OptimizationProblem(
		optimf,
		result2.minimizer,
		(us, ts),
	)
	result3 = solve(
		optimprob3, DiffEqFlux.ADAM(0.005f0);
		maxiters = 300,
	)
	
	# Plot solutions and data
	sol = solve(lotkavolterra_prob)
	plot(
		sol, vars=(0,1);
		label="🐰", ylabel="population", legend=:outertopright,
	)
	plot!(sol, vars=(0,2); label="🦊")

	final_sol = solve(
		prob, Tsit5();
		p=result3.minimizer,
		reltol=1f-6,
	)
	plot!(
		final_sol, vars=(0,1);
		label="🐰 (neural ODE)", linestyle=:dash, color=4,
	)
	plot!(
		final_sol, vars=(0,2);
		label="🦊 (neural ODE)", linestyle=:dash, color=3,
	)

	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 1);
		color=1, label="",
	)
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 2);
		color=2, label="",
	)
end

# ╔═╡ 7ecefca2-0bb4-4513-9a91-5094e209fd3a
md"""
## Example 2

Physics-informed neural ODE model (or rather biology-informed in this case):

$$\begin{align}
\frac{\mathrm{d}}{\mathrm{d}t} \begin{bmatrix} 🐰 \\ 🦊 \end{bmatrix} &= \begin{bmatrix} 🐰 \\ 🦊 \end{bmatrix} \odot \left(\begin{bmatrix} \mathrm{softplus}(c_1) \\ - \mathrm{softplus}(c_2) \end{bmatrix} + \mathrm{NeuralNetwork}\left(\begin{bmatrix} 🐰 \\ 🦊 \end{bmatrix}\right)\right)
\end{align}$$
"""

# ╔═╡ fa37a1be-b38a-4188-a5d4-176d6cf6781e
let
	Random.seed!(100)

	# Define the ODE function
	layers = DiffEqFlux.FastChain(
		DiffEqFlux.FastDense(2, 50, DiffEqFlux.tanh),
		DiffEqFlux.FastDense(50, 2),
	)
	function dudt_(u, p, t)
		u .* (
			[LogExpFunctions.softplus(p[1]), -LogExpFunctions.softplus(p[2])] .+
			layers(u, p[3:end])
		)
	end
	
	# Define the ODE problem
	prob = ODEProblem{false}(
		dudt_, [1f0, 1f0], (0f0, 10f0),
		vcat(0f0, 0f0, DiffEqFlux.initial_params(layers)),
	)
	
	# Define the loss function
	function loss_function(p, (u, t))
		sol = solve(
			prob,
			Tsit5();
			p=p,
			saveat=t,
			reltol=1f-6,
		)

		# Check if numerical solver succeeded
		if (sol.retcode !== :Success && sol.retcode !== :Terminated) || length(sol) != length(t)
			return Inf32
		end
		
		return sum(abs2, u .- Array(sol))
	end
	
	# Use Float32
	us = Float32.(Array(lotkavolterra_data))
	ts = Float32.(lotkavolterra_data.t)

	# Perform gradient descent with initial data
	optimf = OptimizationFunction(loss_function, GalacticOptim.AutoZygote())
	optimprob = OptimizationProblem(
		optimf, prob.p, (us[:, 1:30], ts[1:30]),
	)
	result = solve(
		optimprob, DiffEqFlux.ADAM(0.01f0);
		maxiters = 300,
	)
	
	# Decreased learning rate with more data
	optimprob2 = OptimizationProblem(
		optimf,
		result.minimizer,
		(us[:, 1:60], ts[1:60]),
	)
	result2 = solve(
		optimprob2, DiffEqFlux.ADAM(0.01f0);
		maxiters = 300,
	)

	# Further decreased learning rate with all data
	optimprob3 = OptimizationProblem(
		optimf,
		result2.minimizer,
		(us, ts),
	)
	result3 = solve(
		optimprob3, DiffEqFlux.ADAM(0.005f0);
		maxiters = 300,
	)
	
	# Plot solutions and data
	sol = solve(lotkavolterra_prob)
	plot(
		sol, vars=(0,1);
		label="🐰", ylabel="population", legend=:outertopright,
	)
	plot!(sol, vars=(0,2); label="🦊")

	final_sol = solve(
		prob, Tsit5();
		p=result3.minimizer,
		reltol=1f-6,
	)
	plot!(
		final_sol, vars=(0,1);
		label="🐰 (neural ODE)", linestyle=:dash, color=4,
	)
	plot!(
		final_sol, vars=(0,2);
		label="🦊 (neural ODE)", linestyle=:dash, color=3,
	)

	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 1);
		color=1, label="",
	)
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 2);
		color=2, label="",
	)
end

# ╔═╡ 8223bb89-f5bc-44f1-a3cd-e305e27d9c34
md"""
## Probabilistic modelling

We only know noisy (i.e., slightly incorrect) number of predator and prey for some days but not parameters.

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
- ``\theta``: unknown parameters ``\alpha``, ``\beta``, ``\gamma``, ``\delta``, and ``u(0)`` that we want to infer
- ``y``: number of observed predator and prey

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
  - e.g., ``\alpha``, ``\beta``, ``\gamma``, ``\delta``, and ``u`` are non-negative
- Compute
  ```math
  p_{\Theta|Y}(\theta | y) = \frac{p_{Y|\Theta}(y | \theta) p_{\Theta}(\theta)}{p_Y(y)} = \frac{p_{Y|\Theta}(y | \theta) p_{\Theta}(\theta)}{\int p_{Y|\Theta}(y | \theta') p_{\Theta}(\theta') \,\mathrm{d}\theta'}
  ```
"""

# ╔═╡ 58f93dd6-f7db-4a58-9225-0fbedc6eb460
md"""
!!! danger "⚠️ Issue"
    Often it is not possible to compute ``p_{\Theta|Y}(\theta\, |\, y)`` exactly
"""

# ╔═╡ 1d39a484-ecc1-475d-be15-6a48dcc9eb5b
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

# ╔═╡ 26224476-9063-4803-8f0c-73756923b0af
md"""
number of samples: $(@bind approx_samples Slider(1:10_000; show_value=true, default=500))
"""

# ╔═╡ 9291d064-e049-485e-a6a0-8ef6c47ab89b
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
    LogExpFunctions.softmax!(w)

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
    Plots.vline!(plt2, [w' * x]; label="mean", linewidth=3)

    Plots.plot(plt, plt2)
end

# ╔═╡ fb7ede45-316f-48fc-b5ab-a74080f5999f
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

# ╔═╡ 046212f2-6f6d-421d-8cba-2449997abe56
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

# ╔═╡ 39dc9c40-fa00-40a5-a1d1-b9b2cf207423
md"""
## Bayesian inference of Lotka-Volterra model with Turing

A probabilistic model of the noisy observations of the Lotka-Volterra model:

$$\begin{align}
 \alpha & \sim \mathrm{TruncatedNormal}(1.5, 0.5^2; 0, 5), \\
 \beta & \sim \mathrm{TruncatedNormal}(1.0, 0.5^2; 0, 5), \\
 \gamma & \sim \mathrm{TruncatedNormal}(3.0, 0.5^2; 0, 5), \\
 \delta & \sim \mathrm{TruncatedNormal}(1.0, 0.5^2; 0, 5), \\
 \sigma & \sim \mathrm{InverseGamma}(10, 1) \\
\begin{bmatrix} 🐰_n \\ 🦊_n \end{bmatrix} &\sim \mathrm{Normal}(\mathrm{LotkaVolterra}(t_n; \alpha, \beta, \gamma, \delta), \sigma^2 \mathbf{I}_2) \qquad \text{for all } n = 1,\ldots,N,
\end{align}$$
where $\mathrm{LotkaVolterra}(t; \alpha, \beta, \gamma, \delta)$ is the solution of the Lotka-Volterra IVP at time $t$ with initial value $\begin{bmatrix} 1, 1 \end{bmatrix}^\mathsf{T}$ at time $0$.

It can be implemented in the [Turing probabilistic programming language (PPL)](https://github.com/TuringLang/Turing.jl):
"""

# ╔═╡ 662c239c-9248-4659-937c-e5ddc5fd5d09
@model function bayesian_lotkavolterra(prob, data, t)
	# Priors of the model parameters
    α ~ truncated(Normal(1.5, 0.5), 0, 5)
    β ~ truncated(Normal(1.0, 0.5), 0, 5)
    γ ~ truncated(Normal(3.0, 0.5), 0, 5)
    δ ~ truncated(Normal(1.0, 0.5), 0, 5)
    σ ~ InverseGamma(10, 1)

	# Simulate Lotka-Volterra model
    sol = solve(
		prob,
		Tsit5();
		p=[α, β, γ, δ],
		saveat=t,
		reltol=1e-6,
		maxiters=1_000,
	)
	if (sol.retcode !== :Success && sol.retcode !== :Terminated) || length(sol) != length(t)
		Turing.@addlogprob! -Inf
		return
	end

	# Observations
	for i in 1:length(t)
		data[:, i] ~ MvNormal(sol[i], σ^2 * LinearAlgebra.I)
	end

	return
end

# ╔═╡ c0c5345f-248a-4fe1-b5e9-9164b038e5ca
md"## Prior distribution of trajectories"

# ╔═╡ 85008594-201e-4cbd-90a0-24ee6fa4e09c
prior_chain = let
	Random.seed!(110)
	model = bayesian_lotkavolterra(
		lotkavolterra_prob, Array(lotkavolterra_data), lotkavolterra_data.t
	)
	sample(model, Prior(), MCMCSerial(), 1_000, 4; progress=false)
end;

# ╔═╡ ae9a2dc6-75ec-4931-b3e6-4b8695f5e2d8
let chain = Turing.MCMCChains.pool_chain(prior_chain)
	function prob_func(prob, i, repeat)
		p = (
			α = chain[i, :α, 1],
			β = chain[i, :β, 1],
			γ = chain[i, :γ, 1],
			δ = chain[i, :δ, 1],
		)
		return remake(prob; p=p)
	end
	prob = EnsembleProblem(
		lotkavolterra_prob;
		prob_func = prob_func,
		safetycopy = false,
	)
	simulations = solve(
		prob,
		Tsit5(),
		EnsembleThreads();
		trajectories=length(chain),
	)

	sol = solve(lotkavolterra_prob)
	plot(
		sol, vars=(0,1);
		label="🐰", ylabel="population", legend=:outertopright,
	)
	plot!(sol, vars=(0,2); label="🦊")

	summary = EnsembleSummary(simulations, 0:0.01:10; quantiles=[0.1, 0.9])
	plot!(
		summary;
		idxs=1, label="🐰 (prior predictive)", linestyle=:dash, color=4,
	)
	plot!(
		summary;
		idxs=2, label="🦊 (prior predictive)", linestyle=:dash, color=3,
	)

	# Observations
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 1);
		color=1, label="",
	)
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 2);
		color=2, label="",
	)
end

# ╔═╡ 15d843cb-88b8-452f-a83a-dea0364b0da1
md"""
## Markov chain Monte Carlo
"""

# ╔═╡ 7d6cf54d-2e64-446e-a0b3-7f6d6224f882
chain = let
	Random.seed!(100)
	model = bayesian_lotkavolterra(
		lotkavolterra_prob, Array(lotkavolterra_data), lotkavolterra_data.t
	)

	Turing.setadbackend(:forwarddiff)
	sample(model, NUTS(1_000, 0.65), MCMCSerial(), 1_000, 4; progress=false)
end;

# ╔═╡ 9bfe92a6-82cc-4db9-b4f9-770349cb22d3
plot(chain)

# ╔═╡ c970dc69-7c14-4784-9537-afc114ce895e
md"## Posterior distribution of trajectories"

# ╔═╡ 984dfd8c-b468-4e28-8b1b-58359a28d2f2
let chain=Turing.MCMCChains.pool_chain(chain)
	function prob_func(prob, i, repeat)
		p = (
			α = chain[i, :α, 1],
			β = chain[i, :β, 1],
			γ = chain[i, :γ, 1],
			δ = chain[i, :δ, 1],
		)
		return remake(prob; p=p)
	end
	prob = EnsembleProblem(
		lotkavolterra_prob;
		prob_func = prob_func,
		safetycopy = false,
	)
	simulations = solve(
		prob,
		Tsit5(),
		EnsembleThreads();
		trajectories=length(chain),
	)

	sol = solve(lotkavolterra_prob)
	plot(
		sol, vars=(0,1);
		label="🐰", ylabel="population", legend=:outertopright,
	)
	plot!(sol, vars=(0,2); label="🦊")

	summary = EnsembleSummary(simulations, 0:0.01:10; quantiles=[0.1, 0.9])
	plot!(
		summary;
		idxs=1, label="🐰 (posterior predictive)", linestyle=:dash, color=4,
	)
	plot!(
		summary;
		idxs=2, label="🦊 (posterior predictive)", linestyle=:dash, color=3,
	)

	# Observations
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 1);
		color=1, label="",
	)
	scatter!(
		lotkavolterra_data.t, getindex.(lotkavolterra_data.u, 2);
		color=2, label="",
	)
end

# ╔═╡ b3684cff-a0f8-4600-b23e-11353089d936
md"""
## Other frameworks

Again, the presentation is biased since I am part of the Turing team as well 🙃

However, SciML supports other PPLs (such as Stan) and "manual" (approximate) Bayesian inference with, e.g., [DynamicHMC.jl](https://github.com/tpapp/DynamicHMC.jl) and [ApproxBayes.jl](https://github.com/marcjwilliams1/ApproxBayes.jl) as well.
"""

# ╔═╡ f318a0f8-47b8-4254-8cb2-be6b87b11ff4
md"""
## Example: COVID-19 replication study

$(Resource("https://github.com/cambridge-mlg/Covid19/raw/3b1644701ef32063a65fbbc72332ba0eaa22f82b/figures/imperial-report13/uk-predictive-posterior-Rt.png"))

Links: [Blog post](https://turing.ml/dev/posts/2020-05-04-Imperial-Report13-analysis), [Github repo](https://github.com/cambridge-mlg/Covid19)
"""

# ╔═╡ 4b3def49-04f6-4271-af67-b73fbbd5975d
md"""
## There is a lot more...

Many features of SciML and Turing and background information are not covered in this presentation.

Check out the SciML webpage [https://sciml.ai](https://sciml.ai), the Turing webpage [https://turing.ml](https://turing.ml), and the documentation of the Julia packages.

You can also find a more detailed talks about DelayDiffEq, probabilistic modelling with Turing, and other research with Julia on my webpage: [https://www.widmann.dev](https://www.widmann.dev/research/#talks)
"""

# ╔═╡ bdc07f65-3088-4dbb-96f6-df96486f22c5
 AHL_CC2_steps = [
   0.0000000e+00   2.5000000e-09
   1.7315990e-05   2.5001181e-09
   1.0389594e-04   2.5007088e-09
   5.3679570e-04   2.5036617e-09
   2.7012945e-03   2.5184235e-09
   1.3523788e-02   2.5921521e-09
   6.7636258e-02   2.9588051e-09
   2.9517572e-01   4.4655905e-09
   6.6058137e-01   6.7770851e-09
   1.1256440e+00   9.5554254e-09
   1.5628220e+00   1.2017634e-08
   2.0000000e+00   1.4357938e-08
   2.6095914e+00   1.7475023e-08
   3.2512856e+00   2.0656480e-08
   4.0000000e+00   2.4374649e-08
   4.7157328e+00   2.8093048e-08
   5.3578664e+00   3.1712569e-08
   6.0000000e+00   3.5750955e-08
   6.7192170e+00   4.0980598e-08
   7.4434108e+00   4.7279749e-08
   8.1725347e+00   5.5027924e-08
   8.9084786e+00   6.4736526e-08
   9.6540414e+00   7.7101462e-08
   1.0413442e+01   9.3107255e-08
   1.1193327e+01   1.1421889e-07
   1.2004889e+01   1.4277440e-07
   1.2869024e+01   1.8292137e-07
   1.3788700e+01   2.4029613e-07
   1.4687743e+01   3.1550851e-07
   1.4922419e+01   3.3886874e-07
   1.4960730e+01   3.4284191e-07
   1.4999041e+01   3.4686075e-07
   1.5072399e+01   3.5461176e-07
   1.5439186e+01   3.9427869e-07
   1.6056607e+01   4.6297064e-07
   1.6719975e+01   5.3526532e-07
   1.7787741e+01   6.3194563e-07
   1.8755022e+01   6.8458702e-07
   1.9858885e+01   6.8820618e-07
   2.1022227e+01   6.1679206e-07
   2.1873812e+01   5.2997470e-07
   2.2725397e+01   4.5056003e-07
   2.4053789e+01   3.5699152e-07
   2.6053789e+01   3.0827114e-07
   2.8053789e+01   1.2547053e-07
   2.9382701e+01   6.7209263e-07
   3.0387596e+01  -3.8025862e-07
   3.1392491e+01   1.2130230e-06
   3.2372654e+01  -1.5406212e-06
   3.3164976e+01   1.5880743e-06
   3.3883166e+01  -5.9428464e-07
   3.4635052e+01   7.8319959e-07
   3.5122568e+01   2.1074206e-07
   3.5610084e+01   1.8680082e-07
   3.6281544e+01   1.8079340e-07
   3.6900667e+01   1.7643070e-07
   3.7551510e+01   1.7230933e-07
   3.8725694e+01   1.6538922e-07
   4.0725694e+01   1.5277296e-07
   4.2862847e+01   2.5255795e-07
   4.3990121e+01  -2.3122906e-07
   4.5000000e+01   9.9139629e-07
 ];

# ╔═╡ ae076b1a-6218-4afb-8a02-cee5da2d5c9e
AHL_CC2_interpolation = [
	   0.0000000e+00   2.5000000e-09
   7.2592354e-03   2.5494909e-09
   1.4518471e-02   2.5989217e-09
   2.1777706e-02   2.6482925e-09
   2.9036941e-02   2.6976035e-09
   3.6296177e-02   2.7468548e-09
   4.3555412e-02   2.7960466e-09
   5.0814648e-02   2.8451791e-09
   5.8073883e-02   2.8942524e-09
   6.5333118e-02   2.9432667e-09
   7.2592354e-02   2.9922221e-09
   7.9851589e-02   3.0411189e-09
   8.7110824e-02   3.0899571e-09
   9.4370060e-02   3.1387369e-09
   1.0162930e-01   3.1874586e-09
   1.0888853e-01   3.2361222e-09
   1.1614777e-01   3.2847279e-09
   1.2340700e-01   3.3332759e-09
   1.3066624e-01   3.3817664e-09
   1.3792547e-01   3.4301994e-09
   1.4518471e-01   3.4785753e-09
   1.5244394e-01   3.5268941e-09
   1.5970318e-01   3.5751559e-09
   1.6696241e-01   3.6233611e-09
   1.7422165e-01   3.6715097e-09
   1.8148088e-01   3.7196018e-09
   1.8874012e-01   3.7676378e-09
   1.9599935e-01   3.8156176e-09
   2.0325859e-01   3.8635415e-09
   2.1051783e-01   3.9114096e-09
   2.1777706e-01   3.9592222e-09
   2.2503630e-01   4.0069793e-09
   2.3229553e-01   4.0546812e-09
   2.3955477e-01   4.1023279e-09
   2.4681400e-01   4.1499197e-09
   2.5407324e-01   4.1974568e-09
   2.6133247e-01   4.2449392e-09
   2.6859171e-01   4.2923671e-09
   2.7585094e-01   4.3397408e-09
   2.8311018e-01   4.3870603e-09
   2.9036941e-01   4.4343259e-09
   2.9762865e-01   4.4815376e-09
   3.0488789e-01   4.5286957e-09
   3.1214712e-01   4.5758003e-09
   3.1940636e-01   4.6228516e-09
   3.2666559e-01   4.6698497e-09
   3.3392483e-01   4.7167948e-09
   3.4118406e-01   4.7636870e-09
   3.4844330e-01   4.8105265e-09
   3.5570253e-01   4.8573136e-09
   3.6296177e-01   4.9040483e-09
   3.7022100e-01   4.9507308e-09
   3.7748024e-01   4.9973613e-09
   3.8473947e-01   5.0439400e-09
   3.9199871e-01   5.0904669e-09
   3.9925794e-01   5.1369424e-09
   4.0651718e-01   5.1833665e-09
   4.1377642e-01   5.2297394e-09
   4.2103565e-01   5.2760613e-09
   4.2829489e-01   5.3223323e-09
   4.3555412e-01   5.3685526e-09
   4.4281336e-01   5.4147224e-09
   4.5007259e-01   5.4608419e-09
   4.5733183e-01   5.5069111e-09
   4.6459106e-01   5.5529303e-09
   4.7185030e-01   5.5988997e-09
   4.7910953e-01   5.6448193e-09
   4.8636877e-01   5.6906894e-09
   4.9362800e-01   5.7365101e-09
   5.0088724e-01   5.7822817e-09
   5.0814648e-01   5.8280042e-09
   5.1540571e-01   5.8736778e-09
   5.2266495e-01   5.9193027e-09
   5.2992418e-01   5.9648790e-09
   5.3718342e-01   6.0104070e-09
   5.4444265e-01   6.0558868e-09
   5.5170189e-01   6.1013185e-09
   5.5896112e-01   6.1467023e-09
   5.6622036e-01   6.1920385e-09
   5.7347959e-01   6.2373270e-09
   5.8073883e-01   6.2825682e-09
   5.8799806e-01   6.3277621e-09
   5.9525730e-01   6.3729090e-09
   6.0251653e-01   6.4180091e-09
   6.0977577e-01   6.4630623e-09
   6.1703501e-01   6.5080691e-09
   6.2429424e-01   6.5530294e-09
   6.3155348e-01   6.5979435e-09
   6.3881271e-01   6.6428115e-09
   6.4607195e-01   6.6876336e-09
   6.5333118e-01   6.7324100e-09
   6.6059042e-01   6.7771408e-09
   6.6784965e-01   6.8218274e-09
   6.7510889e-01   6.8664711e-09
   6.8236812e-01   6.9110718e-09
   6.8962736e-01   6.9556296e-09
   6.9688659e-01   7.0001447e-09
   7.0414583e-01   7.0446170e-09
   7.1140507e-01   7.0890466e-09
   7.1866430e-01   7.1334335e-09
   7.2592354e-01   7.1777779e-09
   7.3318277e-01   7.2220797e-09
   7.4044201e-01   7.2663391e-09
   7.4770124e-01   7.3105560e-09
   7.5496048e-01   7.3547306e-09
   7.6221971e-01   7.3988629e-09
   7.6947895e-01   7.4429529e-09
   7.7673818e-01   7.4870007e-09
   7.8399742e-01   7.5310063e-09
   7.9125665e-01   7.5749699e-09
   7.9851589e-01   7.6188914e-09
   8.0577513e-01   7.6627710e-09
   8.1303436e-01   7.7066086e-09
   8.2029360e-01   7.7504044e-09
   8.2755283e-01   7.7941583e-09
   8.3481207e-01   7.8378705e-09
   8.4207130e-01   7.8815410e-09
   8.4933054e-01   7.9251698e-09
   8.5658977e-01   7.9687570e-09
   8.6384901e-01   8.0123027e-09
   8.7110824e-01   8.0558069e-09
   8.7836748e-01   8.0992697e-09
   8.8562671e-01   8.1426911e-09
   8.9288595e-01   8.1860711e-09
   9.0014518e-01   8.2294099e-09
   9.0740442e-01   8.2727075e-09
   9.1466366e-01   8.3159640e-09
   9.2192289e-01   8.3591793e-09
   9.2918213e-01   8.4023536e-09
   9.3644136e-01   8.4454869e-09
   9.4370060e-01   8.4885793e-09
   9.5095983e-01   8.5316307e-09
   9.5821907e-01   8.5746414e-09
   9.6547830e-01   8.6176113e-09
   9.7273754e-01   8.6605405e-09
   9.7999677e-01   8.7034290e-09
   9.8725601e-01   8.7462769e-09
   9.9451524e-01   8.7890842e-09
   1.0017745e+00   8.8318511e-09
   1.0090337e+00   8.8745775e-09
   1.0162930e+00   8.9172635e-09
   1.0235522e+00   8.9599092e-09
   1.0308114e+00   9.0025146e-09
   1.0380707e+00   9.0450798e-09
   1.0453299e+00   9.0876049e-09
   1.0525891e+00   9.1300898e-09
   1.0598484e+00   9.1725346e-09
   1.0671076e+00   9.2149395e-09
   1.0743668e+00   9.2573044e-09
   1.0816261e+00   9.2996294e-09
   1.0888853e+00   9.3419146e-09
   1.0961445e+00   9.3841600e-09
   1.1034038e+00   9.4263657e-09
   1.1106630e+00   9.4685317e-09
   1.1179222e+00   9.5106581e-09
   1.1251815e+00   9.5527450e-09
   1.1324407e+00   9.5947912e-09
   1.1397000e+00   9.6367955e-09
   1.1469592e+00   9.6787582e-09
   1.1542184e+00   9.7206792e-09
   1.1614777e+00   9.7625587e-09
   1.1687369e+00   9.8043969e-09
   1.1759961e+00   9.8461939e-09
   1.1832554e+00   9.8879499e-09
   1.1905146e+00   9.9296650e-09
   1.1977738e+00   9.9713393e-09
   1.2050331e+00   1.0012973e-08
   1.2122923e+00   1.0054566e-08
   1.2195515e+00   1.0096119e-08
   1.2268108e+00   1.0137632e-08
   1.2340700e+00   1.0179104e-08
   1.2413292e+00   1.0220537e-08
   1.2485885e+00   1.0261930e-08
   1.2558477e+00   1.0303283e-08
   1.2631070e+00   1.0344597e-08
   1.2703662e+00   1.0385872e-08
   1.2776254e+00   1.0427107e-08
   1.2848847e+00   1.0468303e-08
   1.2921439e+00   1.0509460e-08
   1.2994031e+00   1.0550579e-08
   1.3066624e+00   1.0591659e-08
   1.3139216e+00   1.0632700e-08
   1.3211808e+00   1.0673703e-08
   1.3284401e+00   1.0714668e-08
   1.3356993e+00   1.0755594e-08
   1.3429585e+00   1.0796483e-08
   1.3502178e+00   1.0837334e-08
   1.3574770e+00   1.0878147e-08
   1.3647362e+00   1.0918923e-08
   1.3719955e+00   1.0959661e-08
   1.3792547e+00   1.1000362e-08
   1.3865140e+00   1.1041026e-08
   1.3937732e+00   1.1081653e-08
   1.4010324e+00   1.1122243e-08
   1.4082917e+00   1.1162797e-08
   1.4155509e+00   1.1203314e-08
   1.4228101e+00   1.1243794e-08
   1.4300694e+00   1.1284238e-08
   1.4373286e+00   1.1324647e-08
   1.4445878e+00   1.1365019e-08
   1.4518471e+00   1.1405355e-08
   1.4591063e+00   1.1445656e-08
   1.4663655e+00   1.1485921e-08
   1.4736248e+00   1.1526151e-08
   1.4808840e+00   1.1566345e-08
   1.4881432e+00   1.1606505e-08
   1.4954025e+00   1.1646629e-08
   1.5026617e+00   1.1686718e-08
   1.5099210e+00   1.1726773e-08
   1.5171802e+00   1.1766793e-08
   1.5244394e+00   1.1806779e-08
   1.5316987e+00   1.1846731e-08
   1.5389579e+00   1.1886648e-08
   1.5462171e+00   1.1926531e-08
   1.5534764e+00   1.1966381e-08
   1.5607356e+00   1.2006197e-08
   1.5679948e+00   1.2045979e-08
   1.5752541e+00   1.2085727e-08
   1.5825133e+00   1.2125442e-08
   1.5897725e+00   1.2165124e-08
   1.5970318e+00   1.2204773e-08
   1.6042910e+00   1.2244388e-08
   1.6115503e+00   1.2283971e-08
   1.6188095e+00   1.2323521e-08
   1.6260687e+00   1.2363038e-08
   1.6333280e+00   1.2402522e-08
   1.6405872e+00   1.2441975e-08
   1.6478464e+00   1.2481395e-08
   1.6551057e+00   1.2520783e-08
   1.6623649e+00   1.2560140e-08
   1.6696241e+00   1.2599464e-08
   1.6768834e+00   1.2638757e-08
   1.6841426e+00   1.2678018e-08
   1.6914018e+00   1.2717248e-08
   1.6986611e+00   1.2756447e-08
   1.7059203e+00   1.2795615e-08
   1.7131795e+00   1.2834752e-08
   1.7204388e+00   1.2873858e-08
   1.7276980e+00   1.2912934e-08
   1.7349573e+00   1.2951979e-08
   1.7422165e+00   1.2990993e-08
   1.7494757e+00   1.3029978e-08
   1.7567350e+00   1.3068932e-08
   1.7639942e+00   1.3107857e-08
   1.7712534e+00   1.3146752e-08
   1.7785127e+00   1.3185617e-08
   1.7857719e+00   1.3224452e-08
   1.7930311e+00   1.3263259e-08
   1.8002904e+00   1.3302036e-08
   1.8075496e+00   1.3340784e-08
   1.8148088e+00   1.3379503e-08
   1.8220681e+00   1.3418194e-08
   1.8293273e+00   1.3456855e-08
   1.8365865e+00   1.3495489e-08
   1.8438458e+00   1.3534094e-08
   1.8511050e+00   1.3572670e-08
   1.8583643e+00   1.3611219e-08
   1.8656235e+00   1.3649740e-08
   1.8728827e+00   1.3688233e-08
   1.8801420e+00   1.3726698e-08
   1.8874012e+00   1.3765136e-08
   1.8946604e+00   1.3803547e-08
   1.9019197e+00   1.3841930e-08
   1.9091789e+00   1.3880287e-08
   1.9164381e+00   1.3918616e-08
   1.9236974e+00   1.3956919e-08
   1.9309566e+00   1.3995195e-08
   1.9382158e+00   1.4033444e-08
   1.9454751e+00   1.4071667e-08
   1.9527343e+00   1.4109864e-08
   1.9599935e+00   1.4148035e-08
   1.9672528e+00   1.4186180e-08
   1.9745120e+00   1.4224299e-08
   1.9817713e+00   1.4262393e-08
   1.9890305e+00   1.4300461e-08
   1.9962897e+00   1.4338504e-08
   2.0035490e+00   1.4376521e-08
   2.0108082e+00   1.4414514e-08
   2.0180674e+00   1.4452480e-08
   2.0253267e+00   1.4490422e-08
   2.0325859e+00   1.4528339e-08
   2.0398451e+00   1.4566230e-08
   2.0471044e+00   1.4604097e-08
   2.0543636e+00   1.4641940e-08
   2.0616228e+00   1.4679758e-08
   2.0688821e+00   1.4717552e-08
   2.0761413e+00   1.4755322e-08
   2.0834005e+00   1.4793067e-08
   2.0906598e+00   1.4830789e-08
   2.0979190e+00   1.4868487e-08
   2.1051783e+00   1.4906162e-08
   2.1124375e+00   1.4943813e-08
   2.1196967e+00   1.4981441e-08
   2.1269560e+00   1.5019046e-08
   2.1342152e+00   1.5056628e-08
   2.1414744e+00   1.5094188e-08
   2.1487337e+00   1.5131724e-08
   2.1559929e+00   1.5169238e-08
   2.1632521e+00   1.5206730e-08
   2.1705114e+00   1.5244200e-08
   2.1777706e+00   1.5281647e-08
   2.1850298e+00   1.5319073e-08
   2.1922891e+00   1.5356476e-08
   2.1995483e+00   1.5393859e-08
   2.2068075e+00   1.5431219e-08
   2.2140668e+00   1.5468559e-08
   2.2213260e+00   1.5505877e-08
   2.2285853e+00   1.5543175e-08
   2.2358445e+00   1.5580451e-08
   2.2431037e+00   1.5617707e-08
   2.2503630e+00   1.5654942e-08
   2.2576222e+00   1.5692156e-08
   2.2648814e+00   1.5729351e-08
   2.2721407e+00   1.5766525e-08
   2.2793999e+00   1.5803679e-08
   2.2866591e+00   1.5840814e-08
   2.2939184e+00   1.5877929e-08
   2.3011776e+00   1.5915024e-08
   2.3084368e+00   1.5952100e-08
   2.3156961e+00   1.5989157e-08
   2.3229553e+00   1.6026194e-08
   2.3302146e+00   1.6063213e-08
   2.3374738e+00   1.6100212e-08
   2.3447330e+00   1.6137194e-08
   2.3519923e+00   1.6174156e-08
   2.3592515e+00   1.6211101e-08
   2.3665107e+00   1.6248027e-08
   2.3737700e+00   1.6284935e-08
   2.3810292e+00   1.6321825e-08
   2.3882884e+00   1.6358697e-08
   2.3955477e+00   1.6395552e-08
   2.4028069e+00   1.6432389e-08
   2.4100661e+00   1.6469209e-08
   2.4173254e+00   1.6506012e-08
   2.4245846e+00   1.6542798e-08
   2.4318438e+00   1.6579567e-08
   2.4391031e+00   1.6616319e-08
   2.4463623e+00   1.6653054e-08
   2.4536216e+00   1.6689774e-08
   2.4608808e+00   1.6726477e-08
   2.4681400e+00   1.6763163e-08
   2.4753993e+00   1.6799834e-08
   2.4826585e+00   1.6836489e-08
   2.4899177e+00   1.6873128e-08
   2.4971770e+00   1.6909752e-08
   2.5044362e+00   1.6946360e-08
   2.5116954e+00   1.6982953e-08
   2.5189547e+00   1.7019531e-08
   2.5262139e+00   1.7056094e-08
   2.5334731e+00   1.7092643e-08
   2.5407324e+00   1.7129176e-08
   2.5479916e+00   1.7165695e-08
   2.5552508e+00   1.7202200e-08
   2.5625101e+00   1.7238690e-08
   2.5697693e+00   1.7275167e-08
   2.5770286e+00   1.7311629e-08
   2.5842878e+00   1.7348078e-08
   2.5915470e+00   1.7384513e-08
   2.5988063e+00   1.7420935e-08
   2.6060655e+00   1.7457343e-08
   2.6133247e+00   1.7493738e-08
   2.6205840e+00   1.7530120e-08
   2.6278432e+00   1.7566488e-08
   2.6351024e+00   1.7602842e-08
   2.6423617e+00   1.7639183e-08
   2.6496209e+00   1.7675511e-08
   2.6568801e+00   1.7711827e-08
   2.6641394e+00   1.7748129e-08
   2.6713986e+00   1.7784419e-08
   2.6786578e+00   1.7820696e-08
   2.6859171e+00   1.7856961e-08
   2.6931763e+00   1.7893214e-08
   2.7004356e+00   1.7929455e-08
   2.7076948e+00   1.7965684e-08
   2.7149540e+00   1.8001901e-08
   2.7222133e+00   1.8038107e-08
   2.7294725e+00   1.8074302e-08
   2.7367317e+00   1.8110485e-08
   2.7439910e+00   1.8146657e-08
   2.7512502e+00   1.8182819e-08
   2.7585094e+00   1.8218969e-08
   2.7657687e+00   1.8255109e-08
   2.7730279e+00   1.8291239e-08
   2.7802871e+00   1.8327359e-08
   2.7875464e+00   1.8363468e-08
   2.7948056e+00   1.8399567e-08
   2.8020648e+00   1.8435657e-08
   2.8093241e+00   1.8471737e-08
   2.8165833e+00   1.8507807e-08
   2.8238426e+00   1.8543869e-08
   2.8311018e+00   1.8579921e-08
   2.8383610e+00   1.8615964e-08
   2.8456203e+00   1.8651998e-08
   2.8528795e+00   1.8688024e-08
   2.8601387e+00   1.8724041e-08
   2.8673980e+00   1.8760049e-08
   2.8746572e+00   1.8796050e-08
   2.8819164e+00   1.8832042e-08
   2.8891757e+00   1.8868027e-08
   2.8964349e+00   1.8904004e-08
   2.9036941e+00   1.8939973e-08
   2.9109534e+00   1.8975935e-08
   2.9182126e+00   1.9011889e-08
   2.9254719e+00   1.9047837e-08
   2.9327311e+00   1.9083777e-08
   2.9399903e+00   1.9119711e-08
   2.9472496e+00   1.9155638e-08
   2.9545088e+00   1.9191559e-08
   2.9617680e+00   1.9227473e-08
   2.9690273e+00   1.9263381e-08
   2.9762865e+00   1.9299283e-08
   2.9835457e+00   1.9335180e-08
   2.9908050e+00   1.9371070e-08
   2.9980642e+00   1.9406955e-08
   3.0053234e+00   1.9442835e-08
   3.0125827e+00   1.9478710e-08
   3.0198419e+00   1.9514579e-08
   3.0271011e+00   1.9550444e-08
   3.0343604e+00   1.9586304e-08
   3.0416196e+00   1.9622159e-08
   3.0488789e+00   1.9658010e-08
   3.0561381e+00   1.9693856e-08
   3.0633973e+00   1.9729699e-08
   3.0706566e+00   1.9765537e-08
   3.0779158e+00   1.9801372e-08
   3.0851750e+00   1.9837203e-08
   3.0924343e+00   1.9873031e-08
   3.0996935e+00   1.9908855e-08
   3.1069527e+00   1.9944677e-08
   3.1142120e+00   1.9980495e-08
   3.1214712e+00   2.0016310e-08
   3.1287304e+00   2.0052123e-08
   3.1359897e+00   2.0087933e-08
   3.1432489e+00   2.0123741e-08
   3.1505081e+00   2.0159546e-08
   3.1577674e+00   2.0195350e-08
   3.1650266e+00   2.0231151e-08
   3.1722859e+00   2.0266951e-08
   3.1795451e+00   2.0302749e-08
   3.1868043e+00   2.0338546e-08
   3.1940636e+00   2.0374342e-08
   3.2013228e+00   2.0410136e-08
   3.2085820e+00   2.0445930e-08
   3.2158413e+00   2.0481722e-08
   3.2231005e+00   2.0517515e-08
   3.2303597e+00   2.0553306e-08
   3.2376190e+00   2.0589097e-08
   3.2448782e+00   2.0624889e-08
   3.2521374e+00   2.0660680e-08
   3.2593967e+00   2.0696470e-08
   3.2666559e+00   2.0732260e-08
   3.2739151e+00   2.0768049e-08
   3.2811744e+00   2.0803837e-08
   3.2884336e+00   2.0839625e-08
   3.2956929e+00   2.0875413e-08
   3.3029521e+00   2.0911201e-08
   3.3102113e+00   2.0946990e-08
   3.3174706e+00   2.0982778e-08
   3.3247298e+00   2.1018567e-08
   3.3319890e+00   2.1054357e-08
   3.3392483e+00   2.1090148e-08
   3.3465075e+00   2.1125940e-08
   3.3537667e+00   2.1161733e-08
   3.3610260e+00   2.1197528e-08
   3.3682852e+00   2.1233324e-08
   3.3755444e+00   2.1269122e-08
   3.3828037e+00   2.1304922e-08
   3.3900629e+00   2.1340724e-08
   3.3973221e+00   2.1376528e-08
   3.4045814e+00   2.1412335e-08
   3.4118406e+00   2.1448145e-08
   3.4190999e+00   2.1483957e-08
   3.4263591e+00   2.1519772e-08
   3.4336183e+00   2.1555591e-08
   3.4408776e+00   2.1591413e-08
   3.4481368e+00   2.1627239e-08
   3.4553960e+00   2.1663068e-08
   3.4626553e+00   2.1698901e-08
   3.4699145e+00   2.1734739e-08
   3.4771737e+00   2.1770580e-08
   3.4844330e+00   2.1806426e-08
   3.4916922e+00   2.1842277e-08
   3.4989514e+00   2.1878132e-08
   3.5062107e+00   2.1913993e-08
   3.5134699e+00   2.1949858e-08
   3.5207291e+00   2.1985729e-08
   3.5279884e+00   2.2021605e-08
   3.5352476e+00   2.2057487e-08
   3.5425069e+00   2.2093375e-08
   3.5497661e+00   2.2129269e-08
   3.5570253e+00   2.2165169e-08
   3.5642846e+00   2.2201076e-08
   3.5715438e+00   2.2236989e-08
   3.5788030e+00   2.2272909e-08
   3.5860623e+00   2.2308836e-08
   3.5933215e+00   2.2344769e-08
   3.6005807e+00   2.2380711e-08
   3.6078400e+00   2.2416659e-08
   3.6150992e+00   2.2452615e-08
   3.6223584e+00   2.2488579e-08
   3.6296177e+00   2.2524551e-08
   3.6368769e+00   2.2560531e-08
   3.6441362e+00   2.2596520e-08
   3.6513954e+00   2.2632517e-08
   3.6586546e+00   2.2668522e-08
   3.6659139e+00   2.2704537e-08
   3.6731731e+00   2.2740560e-08
   3.6804323e+00   2.2776593e-08
   3.6876916e+00   2.2812635e-08
   3.6949508e+00   2.2848687e-08
   3.7022100e+00   2.2884748e-08
   3.7094693e+00   2.2920819e-08
   3.7167285e+00   2.2956901e-08
   3.7239877e+00   2.2992993e-08
   3.7312470e+00   2.3029095e-08
   3.7385062e+00   2.3065207e-08
   3.7457654e+00   2.3101331e-08
   3.7530247e+00   2.3137466e-08
   3.7602839e+00   2.3173611e-08
   3.7675432e+00   2.3209768e-08
   3.7748024e+00   2.3245937e-08
   3.7820616e+00   2.3282117e-08
   3.7893209e+00   2.3318309e-08
   3.7965801e+00   2.3354513e-08
   3.8038393e+00   2.3390730e-08
   3.8110986e+00   2.3426959e-08
   3.8183578e+00   2.3463200e-08
   3.8256170e+00   2.3499454e-08
   3.8328763e+00   2.3535721e-08
   3.8401355e+00   2.3572001e-08
   3.8473947e+00   2.3608295e-08
   3.8546540e+00   2.3644601e-08
   3.8619132e+00   2.3680922e-08
   3.8691724e+00   2.3717256e-08
   3.8764317e+00   2.3753604e-08
   3.8836909e+00   2.3789967e-08
   3.8909502e+00   2.3826344e-08
   3.8982094e+00   2.3862735e-08
   3.9054686e+00   2.3899141e-08
   3.9127279e+00   2.3935562e-08
   3.9199871e+00   2.3971997e-08
   3.9272463e+00   2.4008449e-08
   3.9345056e+00   2.4044915e-08
   3.9417648e+00   2.4081397e-08
   3.9490240e+00   2.4117895e-08
   3.9562833e+00   2.4154409e-08
   3.9635425e+00   2.4190939e-08
   3.9708017e+00   2.4227485e-08
   3.9780610e+00   2.4264047e-08
   3.9853202e+00   2.4300627e-08
   3.9925794e+00   2.4337223e-08
   3.9998387e+00   2.4373836e-08
   4.0070979e+00   2.4410465e-08
   4.0143572e+00   2.4447110e-08
   4.0216164e+00   2.4483771e-08
   4.0288756e+00   2.4520448e-08
   4.0361349e+00   2.4557142e-08
   4.0433941e+00   2.4593851e-08
   4.0506533e+00   2.4630578e-08
   4.0579126e+00   2.4667322e-08
   4.0651718e+00   2.4704082e-08
   4.0724310e+00   2.4740860e-08
   4.0796903e+00   2.4777656e-08
   4.0869495e+00   2.4814469e-08
   4.0942087e+00   2.4851300e-08
   4.1014680e+00   2.4888149e-08
   4.1087272e+00   2.4925016e-08
   4.1159864e+00   2.4961902e-08
   4.1232457e+00   2.4998807e-08
   4.1305049e+00   2.5035731e-08
   4.1377642e+00   2.5072674e-08
   4.1450234e+00   2.5109636e-08
   4.1522826e+00   2.5146618e-08
   4.1595419e+00   2.5183619e-08
   4.1668011e+00   2.5220640e-08
   4.1740603e+00   2.5257682e-08
   4.1813196e+00   2.5294744e-08
   4.1885788e+00   2.5331826e-08
   4.1958380e+00   2.5368929e-08
   4.2030973e+00   2.5406053e-08
   4.2103565e+00   2.5443199e-08
   4.2176157e+00   2.5480365e-08
   4.2248750e+00   2.5517553e-08
   4.2321342e+00   2.5554763e-08
   4.2393935e+00   2.5591995e-08
   4.2466527e+00   2.5629249e-08
   4.2539119e+00   2.5666526e-08
   4.2611712e+00   2.5703825e-08
   4.2684304e+00   2.5741146e-08
   4.2756896e+00   2.5778491e-08
   4.2829489e+00   2.5815859e-08
   4.2902081e+00   2.5853250e-08
   4.2974673e+00   2.5890665e-08
   4.3047266e+00   2.5928104e-08
   4.3119858e+00   2.5965566e-08
   4.3192450e+00   2.6003053e-08
   4.3265043e+00   2.6040564e-08
   4.3337635e+00   2.6078100e-08
   4.3410227e+00   2.6115660e-08
   4.3482820e+00   2.6153246e-08
   4.3555412e+00   2.6190857e-08
   4.3628005e+00   2.6228493e-08
   4.3700597e+00   2.6266155e-08
   4.3773189e+00   2.6303842e-08
   4.3845782e+00   2.6341556e-08
   4.3918374e+00   2.6379295e-08
   4.3990966e+00   2.6417061e-08
   4.4063559e+00   2.6454854e-08
   4.4136151e+00   2.6492674e-08
   4.4208743e+00   2.6530520e-08
   4.4281336e+00   2.6568394e-08
   4.4353928e+00   2.6606295e-08
   4.4426520e+00   2.6644224e-08
   4.4499113e+00   2.6682181e-08
   4.4571705e+00   2.6720166e-08
   4.4644297e+00   2.6758178e-08
   4.4716890e+00   2.6796220e-08
   4.4789482e+00   2.6834290e-08
   4.4862075e+00   2.6872389e-08
   4.4934667e+00   2.6910516e-08
   4.5007259e+00   2.6948673e-08
   4.5079852e+00   2.6986860e-08
   4.5152444e+00   2.7025076e-08
   4.5225036e+00   2.7063322e-08
   4.5297629e+00   2.7101598e-08
   4.5370221e+00   2.7139904e-08
   4.5442813e+00   2.7178241e-08
   4.5515406e+00   2.7216609e-08
   4.5587998e+00   2.7255007e-08
   4.5660590e+00   2.7293436e-08
   4.5733183e+00   2.7331897e-08
   4.5805775e+00   2.7370389e-08
   4.5878367e+00   2.7408912e-08
   4.5950960e+00   2.7447468e-08
   4.6023552e+00   2.7486056e-08
   4.6096145e+00   2.7524675e-08
   4.6168737e+00   2.7563328e-08
   4.6241329e+00   2.7602013e-08
   4.6313922e+00   2.7640731e-08
   4.6386514e+00   2.7679482e-08
   4.6459106e+00   2.7718266e-08
   4.6531699e+00   2.7757084e-08
   4.6604291e+00   2.7795935e-08
   4.6676883e+00   2.7834821e-08
   4.6749476e+00   2.7873740e-08
   4.6822068e+00   2.7912694e-08
   4.6894660e+00   2.7951682e-08
   4.6967253e+00   2.7990705e-08
   4.7039845e+00   2.8029763e-08
   4.7112437e+00   2.8068855e-08
   4.7185030e+00   2.8107983e-08
   4.7257622e+00   2.8147145e-08
   4.7330215e+00   2.8186341e-08
   4.7402807e+00   2.8225571e-08
   4.7475399e+00   2.8264835e-08
   4.7547992e+00   2.8304134e-08
   4.7620584e+00   2.8343468e-08
   4.7693176e+00   2.8382836e-08
   4.7765769e+00   2.8422240e-08
   4.7838361e+00   2.8461679e-08
   4.7910953e+00   2.8501154e-08
   4.7983546e+00   2.8540665e-08
   4.8056138e+00   2.8580212e-08
   4.8128730e+00   2.8619795e-08
   4.8201323e+00   2.8659415e-08
   4.8273915e+00   2.8699072e-08
   4.8346508e+00   2.8738766e-08
   4.8419100e+00   2.8778497e-08
   4.8491692e+00   2.8818266e-08
   4.8564285e+00   2.8858073e-08
   4.8636877e+00   2.8897917e-08
   4.8709469e+00   2.8937800e-08
   4.8782062e+00   2.8977721e-08
   4.8854654e+00   2.9017682e-08
   4.8927246e+00   2.9057681e-08
   4.8999839e+00   2.9097719e-08
   4.9072431e+00   2.9137797e-08
   4.9145023e+00   2.9177914e-08
   4.9217616e+00   2.9218071e-08
   4.9290208e+00   2.9258268e-08
   4.9362800e+00   2.9298506e-08
   4.9435393e+00   2.9338784e-08
   4.9507985e+00   2.9379103e-08
   4.9580578e+00   2.9419464e-08
   4.9653170e+00   2.9459865e-08
   4.9725762e+00   2.9500308e-08
   4.9798355e+00   2.9540793e-08
   4.9870947e+00   2.9581319e-08
   4.9943539e+00   2.9621888e-08
   5.0016132e+00   2.9662500e-08
   5.0088724e+00   2.9703154e-08
   5.0161316e+00   2.9743851e-08
   5.0233909e+00   2.9784591e-08
   5.0306501e+00   2.9825374e-08
   5.0379093e+00   2.9866201e-08
   5.0451686e+00   2.9907072e-08
   5.0524278e+00   2.9947987e-08
   5.0596870e+00   2.9988946e-08
   5.0669463e+00   3.0029950e-08
   5.0742055e+00   3.0070999e-08
   5.0814648e+00   3.0112093e-08
   5.0887240e+00   3.0153231e-08
   5.0959832e+00   3.0194416e-08
   5.1032425e+00   3.0235646e-08
   5.1105017e+00   3.0276922e-08
   5.1177609e+00   3.0318244e-08
   5.1250202e+00   3.0359613e-08
   5.1322794e+00   3.0401028e-08
   5.1395386e+00   3.0442490e-08
   5.1467979e+00   3.0483999e-08
   5.1540571e+00   3.0525556e-08
   5.1613163e+00   3.0567160e-08
   5.1685756e+00   3.0608812e-08
   5.1758348e+00   3.0650512e-08
   5.1830940e+00   3.0692260e-08
   5.1903533e+00   3.0734057e-08
   5.1976125e+00   3.0775903e-08
   5.2048718e+00   3.0817797e-08
   5.2121310e+00   3.0859741e-08
   5.2193902e+00   3.0901734e-08
   5.2266495e+00   3.0943777e-08
   5.2339087e+00   3.0985870e-08
   5.2411679e+00   3.1028012e-08
   5.2484272e+00   3.1070206e-08
   5.2556864e+00   3.1112449e-08
   5.2629456e+00   3.1154744e-08
   5.2702049e+00   3.1197090e-08
   5.2774641e+00   3.1239487e-08
   5.2847233e+00   3.1281935e-08
   5.2919826e+00   3.1324436e-08
   5.2992418e+00   3.1366988e-08
   5.3065010e+00   3.1409593e-08
   5.3137603e+00   3.1452250e-08
   5.3210195e+00   3.1494959e-08
   5.3282788e+00   3.1537722e-08
   5.3355380e+00   3.1580538e-08
   5.3427972e+00   3.1623407e-08
   5.3500565e+00   3.1666330e-08
   5.3573157e+00   3.1709306e-08
   5.3645749e+00   3.1752336e-08
   5.3718342e+00   3.1795418e-08
   5.3790934e+00   3.1838552e-08
   5.3863526e+00   3.1881739e-08
   5.3936119e+00   3.1924979e-08
   5.4008711e+00   3.1968271e-08
   5.4081303e+00   3.2011617e-08
   5.4153896e+00   3.2055017e-08
   5.4226488e+00   3.2098471e-08
   5.4299080e+00   3.2141979e-08
   5.4371673e+00   3.2185541e-08
   5.4444265e+00   3.2229158e-08
   5.4516858e+00   3.2272831e-08
   5.4589450e+00   3.2316558e-08
   5.4662042e+00   3.2360341e-08
   5.4734635e+00   3.2404180e-08
   5.4807227e+00   3.2448075e-08
   5.4879819e+00   3.2492027e-08
   5.4952412e+00   3.2536035e-08
   5.5025004e+00   3.2580100e-08
   5.5097596e+00   3.2624222e-08
   5.5170189e+00   3.2668402e-08
   5.5242781e+00   3.2712640e-08
   5.5315373e+00   3.2756935e-08
   5.5387966e+00   3.2801289e-08
   5.5460558e+00   3.2845701e-08
   5.5533151e+00   3.2890173e-08
   5.5605743e+00   3.2934703e-08
   5.5678335e+00   3.2979293e-08
   5.5750928e+00   3.3023942e-08
   5.5823520e+00   3.3068652e-08
   5.5896112e+00   3.3113421e-08
   5.5968705e+00   3.3158251e-08
   5.6041297e+00   3.3203142e-08
   5.6113889e+00   3.3248094e-08
   5.6186482e+00   3.3293107e-08
   5.6259074e+00   3.3338182e-08
   5.6331666e+00   3.3383318e-08
   5.6404259e+00   3.3428517e-08
   5.6476851e+00   3.3473778e-08
   5.6549443e+00   3.3519102e-08
   5.6622036e+00   3.3564489e-08
   5.6694628e+00   3.3609938e-08
   5.6767221e+00   3.3655452e-08
   5.6839813e+00   3.3701029e-08
   5.6912405e+00   3.3746670e-08
   5.6984998e+00   3.3792375e-08
   5.7057590e+00   3.3838145e-08
   5.7130182e+00   3.3883980e-08
   5.7202775e+00   3.3929880e-08
   5.7275367e+00   3.3975845e-08
   5.7347959e+00   3.4021876e-08
   5.7420552e+00   3.4067973e-08
   5.7493144e+00   3.4114136e-08
   5.7565736e+00   3.4160366e-08
   5.7638329e+00   3.4206662e-08
   5.7710921e+00   3.4253026e-08
   5.7783513e+00   3.4299456e-08
   5.7856106e+00   3.4345954e-08
   5.7928698e+00   3.4392520e-08
   5.8001291e+00   3.4439155e-08
   5.8073883e+00   3.4485857e-08
   5.8146475e+00   3.4532628e-08
   5.8219068e+00   3.4579468e-08
   5.8291660e+00   3.4626378e-08
   5.8364252e+00   3.4673356e-08
   5.8436845e+00   3.4720405e-08
   5.8509437e+00   3.4767523e-08
   5.8582029e+00   3.4814712e-08
   5.8654622e+00   3.4861972e-08
   5.8727214e+00   3.4909302e-08
   5.8799806e+00   3.4956703e-08
   5.8872399e+00   3.5004176e-08
   5.8944991e+00   3.5051720e-08
   5.9017583e+00   3.5099336e-08
   5.9090176e+00   3.5147025e-08
   5.9162768e+00   3.5194786e-08
   5.9235361e+00   3.5242619e-08
   5.9307953e+00   3.5290526e-08
   5.9380545e+00   3.5338506e-08
   5.9453138e+00   3.5386559e-08
   5.9525730e+00   3.5434687e-08
   5.9598322e+00   3.5482888e-08
   5.9670915e+00   3.5531164e-08
   5.9743507e+00   3.5579514e-08
   5.9816099e+00   3.5627940e-08
   5.9888692e+00   3.5676440e-08
   5.9961284e+00   3.5725016e-08
   6.0033876e+00   3.5773668e-08
   6.0106469e+00   3.5822392e-08
   6.0179061e+00   3.5871190e-08
   6.0251653e+00   3.5920061e-08
   6.0324246e+00   3.5969005e-08
   6.0396838e+00   3.6018023e-08
   6.0469431e+00   3.6067116e-08
   6.0542023e+00   3.6116284e-08
   6.0614615e+00   3.6165526e-08
   6.0687208e+00   3.6214843e-08
   6.0759800e+00   3.6264237e-08
   6.0832392e+00   3.6313706e-08
   6.0904985e+00   3.6363251e-08
   6.0977577e+00   3.6412873e-08
   6.1050169e+00   3.6462572e-08
   6.1122762e+00   3.6512348e-08
   6.1195354e+00   3.6562202e-08
   6.1267946e+00   3.6612134e-08
   6.1340539e+00   3.6662144e-08
   6.1413131e+00   3.6712232e-08
   6.1485724e+00   3.6762400e-08
   6.1558316e+00   3.6812646e-08
   6.1630908e+00   3.6862972e-08
   6.1703501e+00   3.6913379e-08
   6.1776093e+00   3.6963865e-08
   6.1848685e+00   3.7014432e-08
   6.1921278e+00   3.7065080e-08
   6.1993870e+00   3.7115809e-08
   6.2066462e+00   3.7166619e-08
   6.2139055e+00   3.7217511e-08
   6.2211647e+00   3.7268486e-08
   6.2284239e+00   3.7319543e-08
   6.2356832e+00   3.7370683e-08
   6.2429424e+00   3.7421906e-08
   6.2502016e+00   3.7473213e-08
   6.2574609e+00   3.7524603e-08
   6.2647201e+00   3.7576078e-08
   6.2719794e+00   3.7627637e-08
   6.2792386e+00   3.7679281e-08
   6.2864978e+00   3.7731010e-08
   6.2937571e+00   3.7782825e-08
   6.3010163e+00   3.7834725e-08
   6.3082755e+00   3.7886712e-08
   6.3155348e+00   3.7938785e-08
   6.3227940e+00   3.7990945e-08
   6.3300532e+00   3.8043192e-08
   6.3373125e+00   3.8095526e-08
   6.3445717e+00   3.8147948e-08
   6.3518309e+00   3.8200459e-08
   6.3590902e+00   3.8253057e-08
   6.3663494e+00   3.8305745e-08
   6.3736086e+00   3.8358522e-08
   6.3808679e+00   3.8411388e-08
   6.3881271e+00   3.8464344e-08
   6.3953864e+00   3.8517390e-08
   6.4026456e+00   3.8570526e-08
   6.4099048e+00   3.8623753e-08
   6.4171641e+00   3.8677071e-08
   6.4244233e+00   3.8730481e-08
   6.4316825e+00   3.8783983e-08
   6.4389418e+00   3.8837576e-08
   6.4462010e+00   3.8891262e-08
   6.4534602e+00   3.8945040e-08
   6.4607195e+00   3.8998912e-08
   6.4679787e+00   3.9052877e-08
   6.4752379e+00   3.9106936e-08
   6.4824972e+00   3.9161089e-08
   6.4897564e+00   3.9215336e-08
   6.4970156e+00   3.9269678e-08
   6.5042749e+00   3.9324114e-08
   6.5115341e+00   3.9378647e-08
   6.5187934e+00   3.9433275e-08
   6.5260526e+00   3.9487999e-08
   6.5333118e+00   3.9542819e-08
   6.5405711e+00   3.9597736e-08
   6.5478303e+00   3.9652750e-08
   6.5550895e+00   3.9707861e-08
   6.5623488e+00   3.9763070e-08
   6.5696080e+00   3.9818377e-08
   6.5768672e+00   3.9873782e-08
   6.5841265e+00   3.9929286e-08
   6.5913857e+00   3.9984889e-08
   6.5986449e+00   4.0040592e-08
   6.6059042e+00   4.0096393e-08
   6.6131634e+00   4.0152295e-08
   6.6204226e+00   4.0208297e-08
   6.6276819e+00   4.0264400e-08
   6.6349411e+00   4.0320604e-08
   6.6422004e+00   4.0376909e-08
   6.6494596e+00   4.0433316e-08
   6.6567188e+00   4.0489824e-08
   6.6639781e+00   4.0546435e-08
   6.6712373e+00   4.0603148e-08
   6.6784965e+00   4.0659965e-08
   6.6857558e+00   4.0716884e-08
   6.6930150e+00   4.0773908e-08
   6.7002742e+00   4.0831035e-08
   6.7075335e+00   4.0888266e-08
   6.7147927e+00   4.0945602e-08
   6.7220519e+00   4.1003043e-08
   6.7293112e+00   4.1060585e-08
   6.7365704e+00   4.1118228e-08
   6.7438296e+00   4.1175973e-08
   6.7510889e+00   4.1233820e-08
   6.7583481e+00   4.1291769e-08
   6.7656074e+00   4.1349821e-08
   6.7728666e+00   4.1407976e-08
   6.7801258e+00   4.1466235e-08
   6.7873851e+00   4.1524598e-08
   6.7946443e+00   4.1583066e-08
   6.8019035e+00   4.1641638e-08
   6.8091628e+00   4.1700315e-08
   6.8164220e+00   4.1759098e-08
   6.8236812e+00   4.1817987e-08
   6.8309405e+00   4.1876983e-08
   6.8381997e+00   4.1936085e-08
   6.8454589e+00   4.1995294e-08
   6.8527182e+00   4.2054612e-08
   6.8599774e+00   4.2114037e-08
   6.8672367e+00   4.2173571e-08
   6.8744959e+00   4.2233213e-08
   6.8817551e+00   4.2292965e-08
   6.8890144e+00   4.2352827e-08
   6.8962736e+00   4.2412798e-08
   6.9035328e+00   4.2472880e-08
   6.9107921e+00   4.2533073e-08
   6.9180513e+00   4.2593378e-08
   6.9253105e+00   4.2653794e-08
   6.9325698e+00   4.2714322e-08
   6.9398290e+00   4.2774962e-08
   6.9470882e+00   4.2835716e-08
   6.9543475e+00   4.2896582e-08
   6.9616067e+00   4.2957563e-08
   6.9688659e+00   4.3018657e-08
   6.9761252e+00   4.3079867e-08
   6.9833844e+00   4.3141191e-08
   6.9906437e+00   4.3202630e-08
   6.9979029e+00   4.3264185e-08
   7.0051621e+00   4.3325856e-08
   7.0124214e+00   4.3387644e-08
   7.0196806e+00   4.3449549e-08
   7.0269398e+00   4.3511571e-08
   7.0341991e+00   4.3573711e-08
   7.0414583e+00   4.3635969e-08
   7.0487175e+00   4.3698346e-08
   7.0559768e+00   4.3760841e-08
   7.0632360e+00   4.3823456e-08
   7.0704952e+00   4.3886191e-08
   7.0777545e+00   4.3949046e-08
   7.0850137e+00   4.4012021e-08
   7.0922729e+00   4.4075118e-08
   7.0995322e+00   4.4138336e-08
   7.1067914e+00   4.4201675e-08
   7.1140507e+00   4.4265137e-08
   7.1213099e+00   4.4328722e-08
   7.1285691e+00   4.4392429e-08
   7.1358284e+00   4.4456260e-08
   7.1430876e+00   4.4520215e-08
   7.1503468e+00   4.4584294e-08
   7.1576061e+00   4.4648497e-08
   7.1648653e+00   4.4712826e-08
   7.1721245e+00   4.4777280e-08
   7.1793838e+00   4.4841860e-08
   7.1866430e+00   4.4906566e-08
   7.1939022e+00   4.4971399e-08
   7.2011615e+00   4.5036359e-08
   7.2084207e+00   4.5101446e-08
   7.2156799e+00   4.5166662e-08
   7.2229392e+00   4.5232005e-08
   7.2301984e+00   4.5297477e-08
   7.2374577e+00   4.5363078e-08
   7.2447169e+00   4.5428809e-08
   7.2519761e+00   4.5494670e-08
   7.2592354e+00   4.5560661e-08
   7.2664946e+00   4.5626782e-08
   7.2737538e+00   4.5693035e-08
   7.2810131e+00   4.5759419e-08
   7.2882723e+00   4.5825935e-08
   7.2955315e+00   4.5892584e-08
   7.3027908e+00   4.5959365e-08
   7.3100500e+00   4.6026279e-08
   7.3173092e+00   4.6093327e-08
   7.3245685e+00   4.6160508e-08
   7.3318277e+00   4.6227824e-08
   7.3390869e+00   4.6295275e-08
   7.3463462e+00   4.6362861e-08
   7.3536054e+00   4.6430583e-08
   7.3608647e+00   4.6498440e-08
   7.3681239e+00   4.6566434e-08
   7.3753831e+00   4.6634564e-08
   7.3826424e+00   4.6702832e-08
   7.3899016e+00   4.6771237e-08
   7.3971608e+00   4.6839780e-08
   7.4044201e+00   4.6908462e-08
   7.4116793e+00   4.6977282e-08
   7.4189385e+00   4.7046242e-08
   7.4261978e+00   4.7115341e-08
   7.4334570e+00   4.7184580e-08
   7.4407162e+00   4.7253960e-08
   7.4479755e+00   4.7323479e-08
   7.4552347e+00   4.7393134e-08
   7.4624940e+00   4.7462926e-08
   7.4697532e+00   4.7532854e-08
   7.4770124e+00   4.7602919e-08
   7.4842717e+00   4.7673121e-08
   7.4915309e+00   4.7743462e-08
   7.4987901e+00   4.7813942e-08
   7.5060494e+00   4.7884560e-08
   7.5133086e+00   4.7955319e-08
   7.5205678e+00   4.8026217e-08
   7.5278271e+00   4.8097256e-08
   7.5350863e+00   4.8168436e-08
   7.5423455e+00   4.8239758e-08
   7.5496048e+00   4.8311222e-08
   7.5568640e+00   4.8382828e-08
   7.5641232e+00   4.8454578e-08
   7.5713825e+00   4.8526472e-08
   7.5786417e+00   4.8598509e-08
   7.5859010e+00   4.8670691e-08
   7.5931602e+00   4.8743019e-08
   7.6004194e+00   4.8815492e-08
   7.6076787e+00   4.8888111e-08
   7.6149379e+00   4.8960877e-08
   7.6221971e+00   4.9033790e-08
   7.6294564e+00   4.9106850e-08
   7.6367156e+00   4.9180059e-08
   7.6439748e+00   4.9253417e-08
   7.6512341e+00   4.9326923e-08
   7.6584933e+00   4.9400580e-08
   7.6657525e+00   4.9474386e-08
   7.6730118e+00   4.9548344e-08
   7.6802710e+00   4.9622452e-08
   7.6875302e+00   4.9696712e-08
   7.6947895e+00   4.9771125e-08
   7.7020487e+00   4.9845690e-08
   7.7093080e+00   4.9920408e-08
   7.7165672e+00   4.9995280e-08
   7.7238264e+00   5.0070306e-08
   7.7310857e+00   5.0145487e-08
   7.7383449e+00   5.0220823e-08
   7.7456041e+00   5.0296315e-08
   7.7528634e+00   5.0371963e-08
   7.7601226e+00   5.0447767e-08
   7.7673818e+00   5.0523729e-08
   7.7746411e+00   5.0599849e-08
   7.7819003e+00   5.0676127e-08
   7.7891595e+00   5.0752563e-08
   7.7964188e+00   5.0829159e-08
   7.8036780e+00   5.0905915e-08
   7.8109372e+00   5.0982830e-08
   7.8181965e+00   5.1059907e-08
   7.8254557e+00   5.1137145e-08
   7.8327150e+00   5.1214544e-08
   7.8399742e+00   5.1292106e-08
   7.8472334e+00   5.1369830e-08
   7.8544927e+00   5.1447718e-08
   7.8617519e+00   5.1525769e-08
   7.8690111e+00   5.1603985e-08
   7.8762704e+00   5.1682366e-08
   7.8835296e+00   5.1760911e-08
   7.8907888e+00   5.1839623e-08
   7.8980481e+00   5.1918501e-08
   7.9053073e+00   5.1997545e-08
   7.9125665e+00   5.2076757e-08
   7.9198258e+00   5.2156136e-08
   7.9270850e+00   5.2235684e-08
   7.9343442e+00   5.2315401e-08
   7.9416035e+00   5.2395287e-08
   7.9488627e+00   5.2475342e-08
   7.9561220e+00   5.2555568e-08
   7.9633812e+00   5.2635965e-08
   7.9706404e+00   5.2716533e-08
   7.9778997e+00   5.2797273e-08
   7.9851589e+00   5.2878185e-08
   7.9924181e+00   5.2959270e-08
   7.9996774e+00   5.3040528e-08
   8.0069366e+00   5.3121960e-08
   8.0141958e+00   5.3203566e-08
   8.0214551e+00   5.3285347e-08
   8.0287143e+00   5.3367304e-08
   8.0359735e+00   5.3449436e-08
   8.0432328e+00   5.3531745e-08
   8.0504920e+00   5.3614230e-08
   8.0577513e+00   5.3696893e-08
   8.0650105e+00   5.3779733e-08
   8.0722697e+00   5.3862752e-08
   8.0795290e+00   5.3945949e-08
   8.0867882e+00   5.4029326e-08
   8.0940474e+00   5.4112883e-08
   8.1013067e+00   5.4196620e-08
   8.1085659e+00   5.4280538e-08
   8.1158251e+00   5.4364637e-08
   8.1230844e+00   5.4448919e-08
   8.1303436e+00   5.4533382e-08
   8.1376028e+00   5.4618028e-08
   8.1448621e+00   5.4702858e-08
   8.1521213e+00   5.4787871e-08
   8.1593805e+00   5.4873069e-08
   8.1666398e+00   5.4958452e-08
   8.1738990e+00   5.5044020e-08
   8.1811583e+00   5.5129769e-08
   8.1884175e+00   5.5215697e-08
   8.1956767e+00   5.5301806e-08
   8.2029360e+00   5.5388095e-08
   8.2101952e+00   5.5474566e-08
   8.2174544e+00   5.5561219e-08
   8.2247137e+00   5.5648054e-08
   8.2319729e+00   5.5735072e-08
   8.2392321e+00   5.5822275e-08
   8.2464914e+00   5.5909661e-08
   8.2537506e+00   5.5997233e-08
   8.2610098e+00   5.6084991e-08
   8.2682691e+00   5.6172935e-08
   8.2755283e+00   5.6261066e-08
   8.2827875e+00   5.6349385e-08
   8.2900468e+00   5.6437892e-08
   8.2973060e+00   5.6526588e-08
   8.3045653e+00   5.6615473e-08
   8.3118245e+00   5.6704549e-08
   8.3190837e+00   5.6793815e-08
   8.3263430e+00   5.6883273e-08
   8.3336022e+00   5.6972923e-08
   8.3408614e+00   5.7062766e-08
   8.3481207e+00   5.7152802e-08
   8.3553799e+00   5.7243032e-08
   8.3626391e+00   5.7333456e-08
   8.3698984e+00   5.7424076e-08
   8.3771576e+00   5.7514891e-08
   8.3844168e+00   5.7605903e-08
   8.3916761e+00   5.7697112e-08
   8.3989353e+00   5.7788519e-08
   8.4061945e+00   5.7880124e-08
   8.4134538e+00   5.7971928e-08
   8.4207130e+00   5.8063932e-08
   8.4279723e+00   5.8156136e-08
   8.4352315e+00   5.8248541e-08
   8.4424907e+00   5.8341147e-08
   8.4497500e+00   5.8433956e-08
   8.4570092e+00   5.8526967e-08
   8.4642684e+00   5.8620182e-08
   8.4715277e+00   5.8713601e-08
   8.4787869e+00   5.8807224e-08
   8.4860461e+00   5.8901053e-08
   8.4933054e+00   5.8995087e-08
   8.5005646e+00   5.9089328e-08
   8.5078238e+00   5.9183777e-08
   8.5150831e+00   5.9278433e-08
   8.5223423e+00   5.9373298e-08
   8.5296015e+00   5.9468371e-08
   8.5368608e+00   5.9563655e-08
   8.5441200e+00   5.9659148e-08
   8.5513793e+00   5.9754853e-08
   8.5586385e+00   5.9850770e-08
   8.5658977e+00   5.9946898e-08
   8.5731570e+00   6.0043239e-08
   8.5804162e+00   6.0139794e-08
   8.5876754e+00   6.0236563e-08
   8.5949347e+00   6.0333547e-08
   8.6021939e+00   6.0430746e-08
   8.6094531e+00   6.0528161e-08
   8.6167124e+00   6.0625793e-08
   8.6239716e+00   6.0723642e-08
   8.6312308e+00   6.0821709e-08
   8.6384901e+00   6.0919995e-08
   8.6457493e+00   6.1018499e-08
   8.6530085e+00   6.1117224e-08
   8.6602678e+00   6.1216169e-08
   8.6675270e+00   6.1315334e-08
   8.6747863e+00   6.1414722e-08
   8.6820455e+00   6.1514332e-08
   8.6893047e+00   6.1614165e-08
   8.6965640e+00   6.1714221e-08
   8.7038232e+00   6.1814502e-08
   8.7110824e+00   6.1915007e-08
   8.7183417e+00   6.2015738e-08
   8.7256009e+00   6.2116695e-08
   8.7328601e+00   6.2217879e-08
   8.7401194e+00   6.2319290e-08
   8.7473786e+00   6.2420929e-08
   8.7546378e+00   6.2522797e-08
   8.7618971e+00   6.2624894e-08
   8.7691563e+00   6.2727221e-08
   8.7764156e+00   6.2829778e-08
   8.7836748e+00   6.2932566e-08
   8.7909340e+00   6.3035587e-08
   8.7981933e+00   6.3138839e-08
   8.8054525e+00   6.3242325e-08
   8.8127117e+00   6.3346044e-08
   8.8199710e+00   6.3449998e-08
   8.8272302e+00   6.3554186e-08
   8.8344894e+00   6.3658611e-08
   8.8417487e+00   6.3763271e-08
   8.8490079e+00   6.3868168e-08
   8.8562671e+00   6.3973302e-08
   8.8635264e+00   6.4078675e-08
   8.8707856e+00   6.4184286e-08
   8.8780448e+00   6.4290137e-08
   8.8853041e+00   6.4396227e-08
   8.8925633e+00   6.4502559e-08
   8.8998226e+00   6.4609131e-08
   8.9070818e+00   6.4715945e-08
   8.9143410e+00   6.4822999e-08
   8.9216003e+00   6.4930288e-08
   8.9288595e+00   6.5037812e-08
   8.9361187e+00   6.5145572e-08
   8.9433780e+00   6.5253568e-08
   8.9506372e+00   6.5361803e-08
   8.9578964e+00   6.5470276e-08
   8.9651557e+00   6.5578988e-08
   8.9724149e+00   6.5687941e-08
   8.9796741e+00   6.5797134e-08
   8.9869334e+00   6.5906569e-08
   8.9941926e+00   6.6016247e-08
   9.0014518e+00   6.6126167e-08
   9.0087111e+00   6.6236332e-08
   9.0159703e+00   6.6346742e-08
   9.0232296e+00   6.6457397e-08
   9.0304888e+00   6.6568299e-08
   9.0377480e+00   6.6679448e-08
   9.0450073e+00   6.6790845e-08
   9.0522665e+00   6.6902491e-08
   9.0595257e+00   6.7014387e-08
   9.0667850e+00   6.7126533e-08
   9.0740442e+00   6.7238930e-08
   9.0813034e+00   6.7351580e-08
   9.0885627e+00   6.7464482e-08
   9.0958219e+00   6.7577637e-08
   9.1030811e+00   6.7691048e-08
   9.1103404e+00   6.7804713e-08
   9.1175996e+00   6.7918635e-08
   9.1248588e+00   6.8032813e-08
   9.1321181e+00   6.8147249e-08
   9.1393773e+00   6.8261943e-08
   9.1466366e+00   6.8376896e-08
   9.1538958e+00   6.8492110e-08
   9.1611550e+00   6.8607584e-08
   9.1684143e+00   6.8723320e-08
   9.1756735e+00   6.8839318e-08
   9.1829327e+00   6.8955580e-08
   9.1901920e+00   6.9072105e-08
   9.1974512e+00   6.9188896e-08
   9.2047104e+00   6.9305951e-08
   9.2119697e+00   6.9423274e-08
   9.2192289e+00   6.9540863e-08
   9.2264881e+00   6.9658720e-08
   9.2337474e+00   6.9776846e-08
   9.2410066e+00   6.9895242e-08
   9.2482658e+00   7.0013908e-08
   9.2555251e+00   7.0132845e-08
   9.2627843e+00   7.0252054e-08
   9.2700436e+00   7.0371536e-08
   9.2773028e+00   7.0491292e-08
   9.2845620e+00   7.0611321e-08
   9.2918213e+00   7.0731626e-08
   9.2990805e+00   7.0852207e-08
   9.3063397e+00   7.0973065e-08
   9.3135990e+00   7.1094200e-08
   9.3208582e+00   7.1215613e-08
   9.3281174e+00   7.1337306e-08
   9.3353767e+00   7.1459278e-08
   9.3426359e+00   7.1581531e-08
   9.3498951e+00   7.1704066e-08
   9.3571544e+00   7.1826883e-08
   9.3644136e+00   7.1949983e-08
   9.3716729e+00   7.2073367e-08
   9.3789321e+00   7.2197036e-08
   9.3861913e+00   7.2320990e-08
   9.3934506e+00   7.2445230e-08
   9.4007098e+00   7.2569758e-08
   9.4079690e+00   7.2694573e-08
   9.4152283e+00   7.2819677e-08
   9.4224875e+00   7.2945071e-08
   9.4297467e+00   7.3070755e-08
   9.4370060e+00   7.3196730e-08
   9.4442652e+00   7.3322997e-08
   9.4515244e+00   7.3449556e-08
   9.4587837e+00   7.3576409e-08
   9.4660429e+00   7.3703556e-08
   9.4733021e+00   7.3830998e-08
   9.4805614e+00   7.3958736e-08
   9.4878206e+00   7.4086771e-08
   9.4950799e+00   7.4215103e-08
   9.5023391e+00   7.4343734e-08
   9.5095983e+00   7.4472663e-08
   9.5168576e+00   7.4601893e-08
   9.5241168e+00   7.4731422e-08
   9.5313760e+00   7.4861254e-08
   9.5386353e+00   7.4991387e-08
   9.5458945e+00   7.5121824e-08
   9.5531537e+00   7.5252564e-08
   9.5604130e+00   7.5383609e-08
   9.5676722e+00   7.5514960e-08
   9.5749314e+00   7.5646616e-08
   9.5821907e+00   7.5778580e-08
   9.5894499e+00   7.5910852e-08
   9.5967091e+00   7.6043432e-08
   9.6039684e+00   7.6176321e-08
   9.6112276e+00   7.6309521e-08
   9.6184869e+00   7.6443031e-08
   9.6257461e+00   7.6576854e-08
   9.6330053e+00   7.6710989e-08
   9.6402646e+00   7.6845437e-08
   9.6475238e+00   7.6980199e-08
   9.6547830e+00   7.7115277e-08
   9.6620423e+00   7.7250664e-08
   9.6693015e+00   7.7386357e-08
   9.6765607e+00   7.7522357e-08
   9.6838200e+00   7.7658665e-08
   9.6910792e+00   7.7795282e-08
   9.6983384e+00   7.7932210e-08
   9.7055977e+00   7.8069448e-08
   9.7128569e+00   7.8206999e-08
   9.7201161e+00   7.8344863e-08
   9.7273754e+00   7.8483042e-08
   9.7346346e+00   7.8621535e-08
   9.7418939e+00   7.8760345e-08
   9.7491531e+00   7.8899472e-08
   9.7564123e+00   7.9038917e-08
   9.7636716e+00   7.9178681e-08
   9.7709308e+00   7.9318766e-08
   9.7781900e+00   7.9459172e-08
   9.7854493e+00   7.9599900e-08
   9.7927085e+00   7.9740952e-08
   9.7999677e+00   7.9882328e-08
   9.8072270e+00   8.0024029e-08
   9.8144862e+00   8.0166057e-08
   9.8217454e+00   8.0308412e-08
   9.8290047e+00   8.0451095e-08
   9.8362639e+00   8.0594108e-08
   9.8435231e+00   8.0737451e-08
   9.8507824e+00   8.0881126e-08
   9.8580416e+00   8.1025133e-08
   9.8653009e+00   8.1169473e-08
   9.8725601e+00   8.1314148e-08
   9.8798193e+00   8.1459158e-08
   9.8870786e+00   8.1604505e-08
   9.8943378e+00   8.1750190e-08
   9.9015970e+00   8.1896212e-08
   9.9088563e+00   8.2042575e-08
   9.9161155e+00   8.2189277e-08
   9.9233747e+00   8.2336322e-08
   9.9306340e+00   8.2483709e-08
   9.9378932e+00   8.2631439e-08
   9.9451524e+00   8.2779514e-08
   9.9524117e+00   8.2927935e-08
   9.9596709e+00   8.3076702e-08
   9.9669302e+00   8.3225817e-08
   9.9741894e+00   8.3375281e-08
   9.9814486e+00   8.3525094e-08
   9.9887079e+00   8.3675257e-08
   9.9959671e+00   8.3825773e-08
   1.0003226e+01   8.3976641e-08
   1.0010486e+01   8.4127863e-08
   1.0017745e+01   8.4279439e-08
   1.0025004e+01   8.4431371e-08
   1.0032263e+01   8.4583660e-08
   1.0039523e+01   8.4736307e-08
   1.0046782e+01   8.4889312e-08
   1.0054041e+01   8.5042678e-08
   1.0061300e+01   8.5196403e-08
   1.0068559e+01   8.5350491e-08
   1.0075819e+01   8.5504942e-08
   1.0083078e+01   8.5659756e-08
   1.0090337e+01   8.5814935e-08
   1.0097596e+01   8.5970480e-08
   1.0104856e+01   8.6126392e-08
   1.0112115e+01   8.6282671e-08
   1.0119374e+01   8.6439320e-08
   1.0126633e+01   8.6596338e-08
   1.0133893e+01   8.6753728e-08
   1.0141152e+01   8.6911489e-08
   1.0148411e+01   8.7069623e-08
   1.0155670e+01   8.7228131e-08
   1.0162930e+01   8.7387014e-08
   1.0170189e+01   8.7546273e-08
   1.0177448e+01   8.7705909e-08
   1.0184707e+01   8.7865923e-08
   1.0191966e+01   8.8026316e-08
   1.0199226e+01   8.8187089e-08
   1.0206485e+01   8.8348242e-08
   1.0213744e+01   8.8509778e-08
   1.0221003e+01   8.8671697e-08
   1.0228263e+01   8.8834000e-08
   1.0235522e+01   8.8996688e-08
   1.0242781e+01   8.9159763e-08
   1.0250040e+01   8.9323224e-08
   1.0257300e+01   8.9487073e-08
   1.0264559e+01   8.9651312e-08
   1.0271818e+01   8.9815940e-08
   1.0279077e+01   8.9980960e-08
   1.0286337e+01   9.0146372e-08
   1.0293596e+01   9.0312177e-08
   1.0300855e+01   9.0478376e-08
   1.0308114e+01   9.0644971e-08
   1.0315373e+01   9.0811961e-08
   1.0322633e+01   9.0979349e-08
   1.0329892e+01   9.1147135e-08
   1.0337151e+01   9.1315321e-08
   1.0344410e+01   9.1483906e-08
   1.0351670e+01   9.1652893e-08
   1.0358929e+01   9.1822282e-08
   1.0366188e+01   9.1992075e-08
   1.0373447e+01   9.2162271e-08
   1.0380707e+01   9.2332873e-08
   1.0387966e+01   9.2503882e-08
   1.0395225e+01   9.2675297e-08
   1.0402484e+01   9.2847121e-08
   1.0409744e+01   9.3019355e-08
   1.0417003e+01   9.3191997e-08
   1.0424262e+01   9.3365040e-08
   1.0431521e+01   9.3538482e-08
   1.0438780e+01   9.3712326e-08
   1.0446040e+01   9.3886572e-08
   1.0453299e+01   9.4061222e-08
   1.0460558e+01   9.4236277e-08
   1.0467817e+01   9.4411738e-08
   1.0475077e+01   9.4587607e-08
   1.0482336e+01   9.4763885e-08
   1.0489595e+01   9.4940573e-08
   1.0496854e+01   9.5117673e-08
   1.0504114e+01   9.5295186e-08
   1.0511373e+01   9.5473112e-08
   1.0518632e+01   9.5651455e-08
   1.0525891e+01   9.5830213e-08
   1.0533151e+01   9.6009390e-08
   1.0540410e+01   9.6188986e-08
   1.0547669e+01   9.6369003e-08
   1.0554928e+01   9.6549441e-08
   1.0562187e+01   9.6730303e-08
   1.0569447e+01   9.6911589e-08
   1.0576706e+01   9.7093301e-08
   1.0583965e+01   9.7275439e-08
   1.0591224e+01   9.7458006e-08
   1.0598484e+01   9.7641003e-08
   1.0605743e+01   9.7824431e-08
   1.0613002e+01   9.8008290e-08
   1.0620261e+01   9.8192583e-08
   1.0627521e+01   9.8377311e-08
   1.0634780e+01   9.8562475e-08
   1.0642039e+01   9.8748077e-08
   1.0649298e+01   9.8934117e-08
   1.0656558e+01   9.9120597e-08
   1.0663817e+01   9.9307518e-08
   1.0671076e+01   9.9494881e-08
   1.0678335e+01   9.9682689e-08
   1.0685594e+01   9.9870941e-08
   1.0692854e+01   1.0005964e-07
   1.0700113e+01   1.0024879e-07
   1.0707372e+01   1.0043838e-07
   1.0714631e+01   1.0062843e-07
   1.0721891e+01   1.0081892e-07
   1.0729150e+01   1.0100987e-07
   1.0736409e+01   1.0120128e-07
   1.0743668e+01   1.0139314e-07
   1.0750928e+01   1.0158545e-07
   1.0758187e+01   1.0177823e-07
   1.0765446e+01   1.0197146e-07
   1.0772705e+01   1.0216516e-07
   1.0779965e+01   1.0235931e-07
   1.0787224e+01   1.0255393e-07
   1.0794483e+01   1.0274901e-07
   1.0801742e+01   1.0294456e-07
   1.0809001e+01   1.0314058e-07
   1.0816261e+01   1.0333706e-07
   1.0823520e+01   1.0353402e-07
   1.0830779e+01   1.0373144e-07
   1.0838038e+01   1.0392934e-07
   1.0845298e+01   1.0412771e-07
   1.0852557e+01   1.0432656e-07
   1.0859816e+01   1.0452588e-07
   1.0867075e+01   1.0472568e-07
   1.0874335e+01   1.0492596e-07
   1.0881594e+01   1.0512671e-07
   1.0888853e+01   1.0532795e-07
   1.0896112e+01   1.0552967e-07
   1.0903372e+01   1.0573188e-07
   1.0910631e+01   1.0593457e-07
   1.0917890e+01   1.0613774e-07
   1.0925149e+01   1.0634141e-07
   1.0932408e+01   1.0654556e-07
   1.0939668e+01   1.0675020e-07
   1.0946927e+01   1.0695534e-07
   1.0954186e+01   1.0716097e-07
   1.0961445e+01   1.0736709e-07
   1.0968705e+01   1.0757370e-07
   1.0975964e+01   1.0778082e-07
   1.0983223e+01   1.0798843e-07
   1.0990482e+01   1.0819654e-07
   1.0997742e+01   1.0840515e-07
   1.1005001e+01   1.0861427e-07
   1.1012260e+01   1.0882388e-07
   1.1019519e+01   1.0903400e-07
   1.1026779e+01   1.0924463e-07
   1.1034038e+01   1.0945576e-07
   1.1041297e+01   1.0966741e-07
   1.1048556e+01   1.0987956e-07
   1.1055815e+01   1.1009222e-07
   1.1063075e+01   1.1030540e-07
   1.1070334e+01   1.1051908e-07
   1.1077593e+01   1.1073329e-07
   1.1084852e+01   1.1094801e-07
   1.1092112e+01   1.1116324e-07
   1.1099371e+01   1.1137900e-07
   1.1106630e+01   1.1159527e-07
   1.1113889e+01   1.1181207e-07
   1.1121149e+01   1.1202939e-07
   1.1128408e+01   1.1224723e-07
   1.1135667e+01   1.1246560e-07
   1.1142926e+01   1.1268449e-07
   1.1150186e+01   1.1290391e-07
   1.1157445e+01   1.1312386e-07
   1.1164704e+01   1.1334434e-07
   1.1171963e+01   1.1356536e-07
   1.1179222e+01   1.1378690e-07
   1.1186482e+01   1.1400898e-07
   1.1193741e+01   1.1423159e-07
   1.1201000e+01   1.1445474e-07
   1.1208259e+01   1.1467840e-07
   1.1215519e+01   1.1490259e-07
   1.1222778e+01   1.1512731e-07
   1.1230037e+01   1.1535256e-07
   1.1237296e+01   1.1557833e-07
   1.1244556e+01   1.1580464e-07
   1.1251815e+01   1.1603148e-07
   1.1259074e+01   1.1625885e-07
   1.1266333e+01   1.1648676e-07
   1.1273593e+01   1.1671521e-07
   1.1280852e+01   1.1694420e-07
   1.1288111e+01   1.1717373e-07
   1.1295370e+01   1.1740380e-07
   1.1302629e+01   1.1763442e-07
   1.1309889e+01   1.1786558e-07
   1.1317148e+01   1.1809729e-07
   1.1324407e+01   1.1832955e-07
   1.1331666e+01   1.1856236e-07
   1.1338926e+01   1.1879573e-07
   1.1346185e+01   1.1902965e-07
   1.1353444e+01   1.1926412e-07
   1.1360703e+01   1.1949915e-07
   1.1367963e+01   1.1973475e-07
   1.1375222e+01   1.1997090e-07
   1.1382481e+01   1.2020761e-07
   1.1389740e+01   1.2044489e-07
   1.1397000e+01   1.2068274e-07
   1.1404259e+01   1.2092115e-07
   1.1411518e+01   1.2116013e-07
   1.1418777e+01   1.2139969e-07
   1.1426036e+01   1.2163981e-07
   1.1433296e+01   1.2188051e-07
   1.1440555e+01   1.2212179e-07
   1.1447814e+01   1.2236364e-07
   1.1455073e+01   1.2260607e-07
   1.1462333e+01   1.2284908e-07
   1.1469592e+01   1.2309268e-07
   1.1476851e+01   1.2333685e-07
   1.1484110e+01   1.2358162e-07
   1.1491370e+01   1.2382697e-07
   1.1498629e+01   1.2407291e-07
   1.1505888e+01   1.2431944e-07
   1.1513147e+01   1.2456656e-07
   1.1520407e+01   1.2481428e-07
   1.1527666e+01   1.2506259e-07
   1.1534925e+01   1.2531150e-07
   1.1542184e+01   1.2556101e-07
   1.1549443e+01   1.2581112e-07
   1.1556703e+01   1.2606183e-07
   1.1563962e+01   1.2631314e-07
   1.1571221e+01   1.2656506e-07
   1.1578480e+01   1.2681759e-07
   1.1585740e+01   1.2707073e-07
   1.1592999e+01   1.2732447e-07
   1.1600258e+01   1.2757883e-07
   1.1607517e+01   1.2783380e-07
   1.1614777e+01   1.2808939e-07
   1.1622036e+01   1.2834559e-07
   1.1629295e+01   1.2860241e-07
   1.1636554e+01   1.2885985e-07
   1.1643814e+01   1.2911792e-07
   1.1651073e+01   1.2937660e-07
   1.1658332e+01   1.2963591e-07
   1.1665591e+01   1.2989585e-07
   1.1672850e+01   1.3015642e-07
   1.1680110e+01   1.3041762e-07
   1.1687369e+01   1.3067944e-07
   1.1694628e+01   1.3094191e-07
   1.1701887e+01   1.3120500e-07
   1.1709147e+01   1.3146874e-07
   1.1716406e+01   1.3173311e-07
   1.1723665e+01   1.3199812e-07
   1.1730924e+01   1.3226377e-07
   1.1738184e+01   1.3253007e-07
   1.1745443e+01   1.3279701e-07
   1.1752702e+01   1.3306459e-07
   1.1759961e+01   1.3333283e-07
   1.1767221e+01   1.3360171e-07
   1.1774480e+01   1.3387125e-07
   1.1781739e+01   1.3414144e-07
   1.1788998e+01   1.3441228e-07
   1.1796257e+01   1.3468378e-07
   1.1803517e+01   1.3495594e-07
   1.1810776e+01   1.3522876e-07
   1.1818035e+01   1.3550224e-07
   1.1825294e+01   1.3577638e-07
   1.1832554e+01   1.3605118e-07
   1.1839813e+01   1.3632665e-07
   1.1847072e+01   1.3660279e-07
   1.1854331e+01   1.3687960e-07
   1.1861591e+01   1.3715708e-07
   1.1868850e+01   1.3743524e-07
   1.1876109e+01   1.3771406e-07
   1.1883368e+01   1.3799357e-07
   1.1890628e+01   1.3827375e-07
   1.1897887e+01   1.3855461e-07
   1.1905146e+01   1.3883615e-07
   1.1912405e+01   1.3911837e-07
   1.1919664e+01   1.3940128e-07
   1.1926924e+01   1.3968487e-07
   1.1934183e+01   1.3996915e-07
   1.1941442e+01   1.4025412e-07
   1.1948701e+01   1.4053979e-07
   1.1955961e+01   1.4082614e-07
   1.1963220e+01   1.4111319e-07
   1.1970479e+01   1.4140093e-07
   1.1977738e+01   1.4168937e-07
   1.1984998e+01   1.4197851e-07
   1.1992257e+01   1.4226835e-07
   1.1999516e+01   1.4255889e-07
   1.2006775e+01   1.4285014e-07
   1.2014035e+01   1.4314208e-07
   1.2021294e+01   1.4343471e-07
   1.2028553e+01   1.4372803e-07
   1.2035812e+01   1.4402205e-07
   1.2043071e+01   1.4431676e-07
   1.2050331e+01   1.4461217e-07
   1.2057590e+01   1.4490829e-07
   1.2064849e+01   1.4520510e-07
   1.2072108e+01   1.4550262e-07
   1.2079368e+01   1.4580085e-07
   1.2086627e+01   1.4609979e-07
   1.2093886e+01   1.4639944e-07
   1.2101145e+01   1.4669980e-07
   1.2108405e+01   1.4700088e-07
   1.2115664e+01   1.4730268e-07
   1.2122923e+01   1.4760519e-07
   1.2130182e+01   1.4790843e-07
   1.2137442e+01   1.4821239e-07
   1.2144701e+01   1.4851708e-07
   1.2151960e+01   1.4882249e-07
   1.2159219e+01   1.4912864e-07
   1.2166478e+01   1.4943552e-07
   1.2173738e+01   1.4974313e-07
   1.2180997e+01   1.5005147e-07
   1.2188256e+01   1.5036056e-07
   1.2195515e+01   1.5067039e-07
   1.2202775e+01   1.5098095e-07
   1.2210034e+01   1.5129227e-07
   1.2217293e+01   1.5160432e-07
   1.2224552e+01   1.5191713e-07
   1.2231812e+01   1.5223069e-07
   1.2239071e+01   1.5254500e-07
   1.2246330e+01   1.5286007e-07
   1.2253589e+01   1.5317589e-07
   1.2260849e+01   1.5349247e-07
   1.2268108e+01   1.5380982e-07
   1.2275367e+01   1.5412792e-07
   1.2282626e+01   1.5444679e-07
   1.2289885e+01   1.5476643e-07
   1.2297145e+01   1.5508684e-07
   1.2304404e+01   1.5540802e-07
   1.2311663e+01   1.5572997e-07
   1.2318922e+01   1.5605270e-07
   1.2326182e+01   1.5637621e-07
   1.2333441e+01   1.5670049e-07
   1.2340700e+01   1.5702556e-07
   1.2347959e+01   1.5735141e-07
   1.2355219e+01   1.5767805e-07
   1.2362478e+01   1.5800547e-07
   1.2369737e+01   1.5833369e-07
   1.2376996e+01   1.5866269e-07
   1.2384256e+01   1.5899250e-07
   1.2391515e+01   1.5932309e-07
   1.2398774e+01   1.5965449e-07
   1.2406033e+01   1.5998669e-07
   1.2413292e+01   1.6031968e-07
   1.2420552e+01   1.6065349e-07
   1.2427811e+01   1.6098810e-07
   1.2435070e+01   1.6132352e-07
   1.2442329e+01   1.6165975e-07
   1.2449589e+01   1.6199679e-07
   1.2456848e+01   1.6233465e-07
   1.2464107e+01   1.6267332e-07
   1.2471366e+01   1.6301281e-07
   1.2478626e+01   1.6335313e-07
   1.2485885e+01   1.6369427e-07
   1.2493144e+01   1.6403623e-07
   1.2500403e+01   1.6437902e-07
   1.2507663e+01   1.6472264e-07
   1.2514922e+01   1.6506709e-07
   1.2522181e+01   1.6541238e-07
   1.2529440e+01   1.6575850e-07
   1.2536699e+01   1.6610546e-07
   1.2543959e+01   1.6645325e-07
   1.2551218e+01   1.6680189e-07
   1.2558477e+01   1.6715138e-07
   1.2565736e+01   1.6750171e-07
   1.2572996e+01   1.6785289e-07
   1.2580255e+01   1.6820491e-07
   1.2587514e+01   1.6855779e-07
   1.2594773e+01   1.6891153e-07
   1.2602033e+01   1.6926612e-07
   1.2609292e+01   1.6962157e-07
   1.2616551e+01   1.6997788e-07
   1.2623810e+01   1.7033505e-07
   1.2631070e+01   1.7069309e-07
   1.2638329e+01   1.7105199e-07
   1.2645588e+01   1.7141176e-07
   1.2652847e+01   1.7177241e-07
   1.2660106e+01   1.7213392e-07
   1.2667366e+01   1.7249632e-07
   1.2674625e+01   1.7285958e-07
   1.2681884e+01   1.7322373e-07
   1.2689143e+01   1.7358876e-07
   1.2696403e+01   1.7395467e-07
   1.2703662e+01   1.7432147e-07
   1.2710921e+01   1.7468916e-07
   1.2718180e+01   1.7505773e-07
   1.2725440e+01   1.7542720e-07
   1.2732699e+01   1.7579756e-07
   1.2739958e+01   1.7616881e-07
   1.2747217e+01   1.7654096e-07
   1.2754477e+01   1.7691402e-07
   1.2761736e+01   1.7728797e-07
   1.2768995e+01   1.7766283e-07
   1.2776254e+01   1.7803860e-07
   1.2783513e+01   1.7841527e-07
   1.2790773e+01   1.7879285e-07
   1.2798032e+01   1.7917135e-07
   1.2805291e+01   1.7955076e-07
   1.2812550e+01   1.7993109e-07
   1.2819810e+01   1.8031233e-07
   1.2827069e+01   1.8069450e-07
   1.2834328e+01   1.8107759e-07
   1.2841587e+01   1.8146160e-07
   1.2848847e+01   1.8184654e-07
   1.2856106e+01   1.8223241e-07
   1.2863365e+01   1.8261921e-07
   1.2870624e+01   1.8300694e-07
   1.2877884e+01   1.8339560e-07
   1.2885143e+01   1.8378517e-07
   1.2892402e+01   1.8417567e-07
   1.2899661e+01   1.8456710e-07
   1.2906920e+01   1.8495946e-07
   1.2914180e+01   1.8535274e-07
   1.2921439e+01   1.8574696e-07
   1.2928698e+01   1.8614212e-07
   1.2935957e+01   1.8653821e-07
   1.2943217e+01   1.8693525e-07
   1.2950476e+01   1.8733323e-07
   1.2957735e+01   1.8773216e-07
   1.2964994e+01   1.8813203e-07
   1.2972254e+01   1.8853286e-07
   1.2979513e+01   1.8893464e-07
   1.2986772e+01   1.8933737e-07
   1.2994031e+01   1.8974107e-07
   1.3001291e+01   1.9014572e-07
   1.3008550e+01   1.9055134e-07
   1.3015809e+01   1.9095793e-07
   1.3023068e+01   1.9136549e-07
   1.3030327e+01   1.9177401e-07
   1.3037587e+01   1.9218351e-07
   1.3044846e+01   1.9259399e-07
   1.3052105e+01   1.9300545e-07
   1.3059364e+01   1.9341788e-07
   1.3066624e+01   1.9383130e-07
   1.3073883e+01   1.9424571e-07
   1.3081142e+01   1.9466111e-07
   1.3088401e+01   1.9507750e-07
   1.3095661e+01   1.9549488e-07
   1.3102920e+01   1.9591326e-07
   1.3110179e+01   1.9633263e-07
   1.3117438e+01   1.9675301e-07
   1.3124698e+01   1.9717440e-07
   1.3131957e+01   1.9759679e-07
   1.3139216e+01   1.9802019e-07
   1.3146475e+01   1.9844460e-07
   1.3153734e+01   1.9887002e-07
   1.3160994e+01   1.9929646e-07
   1.3168253e+01   1.9972392e-07
   1.3175512e+01   2.0015240e-07
   1.3182771e+01   2.0058191e-07
   1.3190031e+01   2.0101244e-07
   1.3197290e+01   2.0144401e-07
   1.3204549e+01   2.0187660e-07
   1.3211808e+01   2.0231023e-07
   1.3219068e+01   2.0274489e-07
   1.3226327e+01   2.0318060e-07
   1.3233586e+01   2.0361734e-07
   1.3240845e+01   2.0405513e-07
   1.3248105e+01   2.0449397e-07
   1.3255364e+01   2.0493386e-07
   1.3262623e+01   2.0537480e-07
   1.3269882e+01   2.0581679e-07
   1.3277141e+01   2.0625984e-07
   1.3284401e+01   2.0670395e-07
   1.3291660e+01   2.0714912e-07
   1.3298919e+01   2.0759535e-07
   1.3306178e+01   2.0804266e-07
   1.3313438e+01   2.0849103e-07
   1.3320697e+01   2.0894047e-07
   1.3327956e+01   2.0939099e-07
   1.3335215e+01   2.0984259e-07
   1.3342475e+01   2.1029526e-07
   1.3349734e+01   2.1074902e-07
   1.3356993e+01   2.1120386e-07
   1.3364252e+01   2.1165979e-07
   1.3371512e+01   2.1211681e-07
   1.3378771e+01   2.1257492e-07
   1.3386030e+01   2.1303412e-07
   1.3393289e+01   2.1349442e-07
   1.3400548e+01   2.1395583e-07
   1.3407808e+01   2.1441833e-07
   1.3415067e+01   2.1488194e-07
   1.3422326e+01   2.1534665e-07
   1.3429585e+01   2.1581248e-07
   1.3436845e+01   2.1627942e-07
   1.3444104e+01   2.1674747e-07
   1.3451363e+01   2.1721664e-07
   1.3458622e+01   2.1768693e-07
   1.3465882e+01   2.1815834e-07
   1.3473141e+01   2.1863088e-07
   1.3480400e+01   2.1910454e-07
   1.3487659e+01   2.1957933e-07
   1.3494919e+01   2.2005526e-07
   1.3502178e+01   2.2053232e-07
   1.3509437e+01   2.2101052e-07
   1.3516696e+01   2.2148986e-07
   1.3523955e+01   2.2197034e-07
   1.3531215e+01   2.2245196e-07
   1.3538474e+01   2.2293474e-07
   1.3545733e+01   2.2341866e-07
   1.3552992e+01   2.2390374e-07
   1.3560252e+01   2.2438997e-07
   1.3567511e+01   2.2487735e-07
   1.3574770e+01   2.2536590e-07
   1.3582029e+01   2.2585561e-07
   1.3589289e+01   2.2634649e-07
   1.3596548e+01   2.2683853e-07
   1.3603807e+01   2.2733175e-07
   1.3611066e+01   2.2782613e-07
   1.3618326e+01   2.2832169e-07
   1.3625585e+01   2.2881843e-07
   1.3632844e+01   2.2931635e-07
   1.3640103e+01   2.2981545e-07
   1.3647362e+01   2.3031574e-07
   1.3654622e+01   2.3081721e-07
   1.3661881e+01   2.3131988e-07
   1.3669140e+01   2.3182373e-07
   1.3676399e+01   2.3232879e-07
   1.3683659e+01   2.3283504e-07
   1.3690918e+01   2.3334249e-07
   1.3698177e+01   2.3385114e-07
   1.3705436e+01   2.3436100e-07
   1.3712696e+01   2.3487206e-07
   1.3719955e+01   2.3538434e-07
   1.3727214e+01   2.3589783e-07
   1.3734473e+01   2.3641254e-07
   1.3741733e+01   2.3692846e-07
   1.3748992e+01   2.3744560e-07
   1.3756251e+01   2.3796397e-07
   1.3763510e+01   2.3848356e-07
   1.3770769e+01   2.3900438e-07
   1.3778029e+01   2.3952643e-07
   1.3785288e+01   2.4004971e-07
   1.3792547e+01   2.4057423e-07
   1.3799806e+01   2.4109997e-07
   1.3807066e+01   2.4162695e-07
   1.3814325e+01   2.4215515e-07
   1.3821584e+01   2.4268459e-07
   1.3828843e+01   2.4321526e-07
   1.3836103e+01   2.4374718e-07
   1.3843362e+01   2.4428034e-07
   1.3850621e+01   2.4481474e-07
   1.3857880e+01   2.4535039e-07
   1.3865140e+01   2.4588729e-07
   1.3872399e+01   2.4642545e-07
   1.3879658e+01   2.4696486e-07
   1.3886917e+01   2.4750553e-07
   1.3894176e+01   2.4804746e-07
   1.3901436e+01   2.4859066e-07
   1.3908695e+01   2.4913512e-07
   1.3915954e+01   2.4968085e-07
   1.3923213e+01   2.5022786e-07
   1.3930473e+01   2.5077614e-07
   1.3937732e+01   2.5132569e-07
   1.3944991e+01   2.5187653e-07
   1.3952250e+01   2.5242865e-07
   1.3959510e+01   2.5298206e-07
   1.3966769e+01   2.5353676e-07
   1.3974028e+01   2.5409275e-07
   1.3981287e+01   2.5465003e-07
   1.3988547e+01   2.5520861e-07
   1.3995806e+01   2.5576849e-07
   1.4003065e+01   2.5632967e-07
   1.4010324e+01   2.5689216e-07
   1.4017583e+01   2.5745596e-07
   1.4024843e+01   2.5802106e-07
   1.4032102e+01   2.5858748e-07
   1.4039361e+01   2.5915522e-07
   1.4046620e+01   2.5972428e-07
   1.4053880e+01   2.6029465e-07
   1.4061139e+01   2.6086635e-07
   1.4068398e+01   2.6143938e-07
   1.4075657e+01   2.6201374e-07
   1.4082917e+01   2.6258943e-07
   1.4090176e+01   2.6316646e-07
   1.4097435e+01   2.6374482e-07
   1.4104694e+01   2.6432452e-07
   1.4111954e+01   2.6490557e-07
   1.4119213e+01   2.6548797e-07
   1.4126472e+01   2.6607171e-07
   1.4133731e+01   2.6665680e-07
   1.4140990e+01   2.6724325e-07
   1.4148250e+01   2.6783106e-07
   1.4155509e+01   2.6842023e-07
   1.4162768e+01   2.6901076e-07
   1.4170027e+01   2.6960265e-07
   1.4177287e+01   2.7019591e-07
   1.4184546e+01   2.7079055e-07
   1.4191805e+01   2.7138655e-07
   1.4199064e+01   2.7198394e-07
   1.4206324e+01   2.7258270e-07
   1.4213583e+01   2.7318284e-07
   1.4220842e+01   2.7378437e-07
   1.4228101e+01   2.7438728e-07
   1.4235361e+01   2.7499159e-07
   1.4242620e+01   2.7559729e-07
   1.4249879e+01   2.7620438e-07
   1.4257138e+01   2.7681287e-07
   1.4264397e+01   2.7742276e-07
   1.4271657e+01   2.7803406e-07
   1.4278916e+01   2.7864676e-07
   1.4286175e+01   2.7926087e-07
   1.4293434e+01   2.7987640e-07
   1.4300694e+01   2.8049333e-07
   1.4307953e+01   2.8111169e-07
   1.4315212e+01   2.8173146e-07
   1.4322471e+01   2.8235266e-07
   1.4329731e+01   2.8297528e-07
   1.4336990e+01   2.8359934e-07
   1.4344249e+01   2.8422482e-07
   1.4351508e+01   2.8485173e-07
   1.4358768e+01   2.8548008e-07
   1.4366027e+01   2.8610988e-07
   1.4373286e+01   2.8674111e-07
   1.4380545e+01   2.8737379e-07
   1.4387804e+01   2.8800791e-07
   1.4395064e+01   2.8864348e-07
   1.4402323e+01   2.8928051e-07
   1.4409582e+01   2.8991899e-07
   1.4416841e+01   2.9055894e-07
   1.4424101e+01   2.9120034e-07
   1.4431360e+01   2.9184320e-07
   1.4438619e+01   2.9248753e-07
   1.4445878e+01   2.9313334e-07
   1.4453138e+01   2.9378061e-07
   1.4460397e+01   2.9442936e-07
   1.4467656e+01   2.9507958e-07
   1.4474915e+01   2.9573129e-07
   1.4482175e+01   2.9638447e-07
   1.4489434e+01   2.9703915e-07
   1.4496693e+01   2.9769531e-07
   1.4503952e+01   2.9835296e-07
   1.4511211e+01   2.9901211e-07
   1.4518471e+01   2.9967275e-07
   1.4525730e+01   3.0033489e-07
   1.4532989e+01   3.0099853e-07
   1.4540248e+01   3.0166368e-07
   1.4547508e+01   3.0233034e-07
   1.4554767e+01   3.0299850e-07
   1.4562026e+01   3.0366818e-07
   1.4569285e+01   3.0433938e-07
   1.4576545e+01   3.0501209e-07
   1.4583804e+01   3.0568632e-07
   1.4591063e+01   3.0636208e-07
   1.4598322e+01   3.0703936e-07
   1.4605582e+01   3.0771817e-07
   1.4612841e+01   3.0839852e-07
   1.4620100e+01   3.0908040e-07
   1.4627359e+01   3.0976381e-07
   1.4634618e+01   3.1044877e-07
   1.4641878e+01   3.1113527e-07
   1.4649137e+01   3.1182332e-07
   1.4656396e+01   3.1251291e-07
   1.4663655e+01   3.1320405e-07
   1.4670915e+01   3.1389675e-07
   1.4678174e+01   3.1459101e-07
   1.4685433e+01   3.1528682e-07
   1.4692692e+01   3.1598420e-07
   1.4699952e+01   3.1668312e-07
   1.4707211e+01   3.1738361e-07
   1.4714470e+01   3.1808565e-07
   1.4721729e+01   3.1878926e-07
   1.4728989e+01   3.1949442e-07
   1.4736248e+01   3.2020116e-07
   1.4743507e+01   3.2090946e-07
   1.4750766e+01   3.2161933e-07
   1.4758025e+01   3.2233078e-07
   1.4765285e+01   3.2304380e-07
   1.4772544e+01   3.2375840e-07
   1.4779803e+01   3.2447458e-07
   1.4787062e+01   3.2519234e-07
   1.4794322e+01   3.2591169e-07
   1.4801581e+01   3.2663262e-07
   1.4808840e+01   3.2735515e-07
   1.4816099e+01   3.2807927e-07
   1.4823359e+01   3.2880498e-07
   1.4830618e+01   3.2953229e-07
   1.4837877e+01   3.3026120e-07
   1.4845136e+01   3.3099171e-07
   1.4852396e+01   3.3172383e-07
   1.4859655e+01   3.3245755e-07
   1.4866914e+01   3.3319289e-07
   1.4874173e+01   3.3392983e-07
   1.4881432e+01   3.3466839e-07
   1.4888692e+01   3.3540857e-07
   1.4895951e+01   3.3615036e-07
   1.4903210e+01   3.3689378e-07
   1.4910469e+01   3.3763882e-07
   1.4917729e+01   3.3838548e-07
   1.4924988e+01   3.3913378e-07
   1.4932247e+01   3.3988370e-07
   1.4939506e+01   3.4063526e-07
   1.4946766e+01   3.4138845e-07
   1.4954025e+01   3.4214327e-07
   1.4961284e+01   3.4289974e-07
   1.4968543e+01   3.4365823e-07
   1.4975803e+01   3.4441869e-07
   1.4983062e+01   3.4518065e-07
   1.4990321e+01   3.4594361e-07
   1.4997580e+01   3.4670710e-07
   1.5004839e+01   3.4747091e-07
   1.5012099e+01   3.4823539e-07
   1.5019358e+01   3.4900056e-07
   1.5026617e+01   3.4976640e-07
   1.5033876e+01   3.5053292e-07
   1.5041136e+01   3.5130012e-07
   1.5048395e+01   3.5206798e-07
   1.5055654e+01   3.5283652e-07
   1.5062913e+01   3.5360571e-07
   1.5070173e+01   3.5437556e-07
   1.5077432e+01   3.5514607e-07
   1.5084691e+01   3.5591723e-07
   1.5091950e+01   3.5668902e-07
   1.5099210e+01   3.5746146e-07
   1.5106469e+01   3.5823452e-07
   1.5113728e+01   3.5900822e-07
   1.5120987e+01   3.5978254e-07
   1.5128246e+01   3.6055748e-07
   1.5135506e+01   3.6133304e-07
   1.5142765e+01   3.6210921e-07
   1.5150024e+01   3.6288599e-07
   1.5157283e+01   3.6366338e-07
   1.5164543e+01   3.6444137e-07
   1.5171802e+01   3.6521996e-07
   1.5179061e+01   3.6599914e-07
   1.5186320e+01   3.6677891e-07
   1.5193580e+01   3.6755926e-07
   1.5200839e+01   3.6834020e-07
   1.5208098e+01   3.6912172e-07
   1.5215357e+01   3.6990381e-07
   1.5222617e+01   3.7068646e-07
   1.5229876e+01   3.7146969e-07
   1.5237135e+01   3.7225347e-07
   1.5244394e+01   3.7303782e-07
   1.5251653e+01   3.7382271e-07
   1.5258913e+01   3.7460816e-07
   1.5266172e+01   3.7539415e-07
   1.5273431e+01   3.7618069e-07
   1.5280690e+01   3.7696776e-07
   1.5287950e+01   3.7775537e-07
   1.5295209e+01   3.7854351e-07
   1.5302468e+01   3.7933217e-07
   1.5309727e+01   3.8012135e-07
   1.5316987e+01   3.8091106e-07
   1.5324246e+01   3.8170127e-07
   1.5331505e+01   3.8249200e-07
   1.5338764e+01   3.8328323e-07
   1.5346024e+01   3.8407497e-07
   1.5353283e+01   3.8486720e-07
   1.5360542e+01   3.8565993e-07
   1.5367801e+01   3.8645314e-07
   1.5375060e+01   3.8724685e-07
   1.5382320e+01   3.8804103e-07
   1.5389579e+01   3.8883570e-07
   1.5396838e+01   3.8963084e-07
   1.5404097e+01   3.9042645e-07
   1.5411357e+01   3.9122252e-07
   1.5418616e+01   3.9201906e-07
   1.5425875e+01   3.9281605e-07
   1.5433134e+01   3.9361350e-07
   1.5440394e+01   3.9441140e-07
   1.5447653e+01   3.9520969e-07
   1.5454912e+01   3.9600833e-07
   1.5462171e+01   3.9680731e-07
   1.5469431e+01   3.9760664e-07
   1.5476690e+01   3.9840630e-07
   1.5483949e+01   3.9920629e-07
   1.5491208e+01   4.0000661e-07
   1.5498467e+01   4.0080726e-07
   1.5505727e+01   4.0160822e-07
   1.5512986e+01   4.0240950e-07
   1.5520245e+01   4.0321109e-07
   1.5527504e+01   4.0401298e-07
   1.5534764e+01   4.0481517e-07
   1.5542023e+01   4.0561766e-07
   1.5549282e+01   4.0642043e-07
   1.5556541e+01   4.0722350e-07
   1.5563801e+01   4.0802684e-07
   1.5571060e+01   4.0883046e-07
   1.5578319e+01   4.0963436e-07
   1.5585578e+01   4.1043852e-07
   1.5592838e+01   4.1124295e-07
   1.5600097e+01   4.1204763e-07
   1.5607356e+01   4.1285257e-07
   1.5614615e+01   4.1365776e-07
   1.5621874e+01   4.1446319e-07
   1.5629134e+01   4.1526886e-07
   1.5636393e+01   4.1607477e-07
   1.5643652e+01   4.1688091e-07
   1.5650911e+01   4.1768727e-07
   1.5658171e+01   4.1849386e-07
   1.5665430e+01   4.1930066e-07
   1.5672689e+01   4.2010768e-07
   1.5679948e+01   4.2091490e-07
   1.5687208e+01   4.2172233e-07
   1.5694467e+01   4.2252995e-07
   1.5701726e+01   4.2333777e-07
   1.5708985e+01   4.2414578e-07
   1.5716245e+01   4.2495398e-07
   1.5723504e+01   4.2576235e-07
   1.5730763e+01   4.2657090e-07
   1.5738022e+01   4.2737962e-07
   1.5745281e+01   4.2818850e-07
   1.5752541e+01   4.2899755e-07
   1.5759800e+01   4.2980676e-07
   1.5767059e+01   4.3061612e-07
   1.5774318e+01   4.3142562e-07
   1.5781578e+01   4.3223527e-07
   1.5788837e+01   4.3304506e-07
   1.5796096e+01   4.3385498e-07
   1.5803355e+01   4.3466503e-07
   1.5810615e+01   4.3547520e-07
   1.5817874e+01   4.3628550e-07
   1.5825133e+01   4.3709591e-07
   1.5832392e+01   4.3790643e-07
   1.5839652e+01   4.3871706e-07
   1.5846911e+01   4.3952779e-07
   1.5854170e+01   4.4033862e-07
   1.5861429e+01   4.4114954e-07
   1.5868688e+01   4.4196055e-07
   1.5875948e+01   4.4277164e-07
   1.5883207e+01   4.4358281e-07
   1.5890466e+01   4.4439405e-07
   1.5897725e+01   4.4520537e-07
   1.5904985e+01   4.4601674e-07
   1.5912244e+01   4.4682818e-07
   1.5919503e+01   4.4763968e-07
   1.5926762e+01   4.4845122e-07
   1.5934022e+01   4.4926281e-07
   1.5941281e+01   4.5007444e-07
   1.5948540e+01   4.5088611e-07
   1.5955799e+01   4.5169782e-07
   1.5963059e+01   4.5250955e-07
   1.5970318e+01   4.5332130e-07
   1.5977577e+01   4.5413308e-07
   1.5984836e+01   4.5494486e-07
   1.5992095e+01   4.5575666e-07
   1.5999355e+01   4.5656846e-07
   1.6006614e+01   4.5738026e-07
   1.6013873e+01   4.5819206e-07
   1.6021132e+01   4.5900385e-07
   1.6028392e+01   4.5981562e-07
   1.6035651e+01   4.6062738e-07
   1.6042910e+01   4.6143911e-07
   1.6050169e+01   4.6225082e-07
   1.6057429e+01   4.6306249e-07
   1.6064688e+01   4.6387395e-07
   1.6071947e+01   4.6468509e-07
   1.6079206e+01   4.6549590e-07
   1.6086466e+01   4.6630638e-07
   1.6093725e+01   4.6711651e-07
   1.6100984e+01   4.6792631e-07
   1.6108243e+01   4.6873576e-07
   1.6115503e+01   4.6954486e-07
   1.6122762e+01   4.7035360e-07
   1.6130021e+01   4.7116198e-07
   1.6137280e+01   4.7197001e-07
   1.6144539e+01   4.7277766e-07
   1.6151799e+01   4.7358494e-07
   1.6159058e+01   4.7439185e-07
   1.6166317e+01   4.7519837e-07
   1.6173576e+01   4.7600451e-07
   1.6180836e+01   4.7681027e-07
   1.6188095e+01   4.7761563e-07
   1.6195354e+01   4.7842059e-07
   1.6202613e+01   4.7922515e-07
   1.6209873e+01   4.8002930e-07
   1.6217132e+01   4.8083305e-07
   1.6224391e+01   4.8163638e-07
   1.6231650e+01   4.8243929e-07
   1.6238910e+01   4.8324178e-07
   1.6246169e+01   4.8404385e-07
   1.6253428e+01   4.8484548e-07
   1.6260687e+01   4.8564668e-07
   1.6267946e+01   4.8644743e-07
   1.6275206e+01   4.8724775e-07
   1.6282465e+01   4.8804761e-07
   1.6289724e+01   4.8884703e-07
   1.6296983e+01   4.8964598e-07
   1.6304243e+01   4.9044448e-07
   1.6311502e+01   4.9124251e-07
   1.6318761e+01   4.9204007e-07
   1.6326020e+01   4.9283716e-07
   1.6333280e+01   4.9363377e-07
   1.6340539e+01   4.9442990e-07
   1.6347798e+01   4.9522554e-07
   1.6355057e+01   4.9602069e-07
   1.6362317e+01   4.9681535e-07
   1.6369576e+01   4.9760950e-07
   1.6376835e+01   4.9840316e-07
   1.6384094e+01   4.9919631e-07
   1.6391353e+01   4.9998894e-07
   1.6398613e+01   5.0078106e-07
   1.6405872e+01   5.0157266e-07
   1.6413131e+01   5.0236374e-07
   1.6420390e+01   5.0315428e-07
   1.6427650e+01   5.0394430e-07
   1.6434909e+01   5.0473377e-07
   1.6442168e+01   5.0552271e-07
   1.6449427e+01   5.0631110e-07
   1.6456687e+01   5.0709894e-07
   1.6463946e+01   5.0788622e-07
   1.6471205e+01   5.0867295e-07
   1.6478464e+01   5.0945912e-07
   1.6485724e+01   5.1024472e-07
   1.6492983e+01   5.1102974e-07
   1.6500242e+01   5.1181419e-07
   1.6507501e+01   5.1259807e-07
   1.6514760e+01   5.1338136e-07
   1.6522020e+01   5.1416406e-07
   1.6529279e+01   5.1494617e-07
   1.6536538e+01   5.1572768e-07
   1.6543797e+01   5.1650859e-07
   1.6551057e+01   5.1728890e-07
   1.6558316e+01   5.1806859e-07
   1.6565575e+01   5.1884768e-07
   1.6572834e+01   5.1962614e-07
   1.6580094e+01   5.2040399e-07
   1.6587353e+01   5.2118121e-07
   1.6594612e+01   5.2195780e-07
   1.6601871e+01   5.2273375e-07
   1.6609131e+01   5.2350906e-07
   1.6616390e+01   5.2428373e-07
   1.6623649e+01   5.2505776e-07
   1.6630908e+01   5.2583113e-07
   1.6638167e+01   5.2660385e-07
   1.6645427e+01   5.2737591e-07
   1.6652686e+01   5.2814730e-07
   1.6659945e+01   5.2891802e-07
   1.6667204e+01   5.2968807e-07
   1.6674464e+01   5.3045745e-07
   1.6681723e+01   5.3122614e-07
   1.6688982e+01   5.3199415e-07
   1.6696241e+01   5.3276147e-07
   1.6703501e+01   5.3352809e-07
   1.6710760e+01   5.3429402e-07
   1.6718019e+01   5.3505924e-07
   1.6725278e+01   5.3582353e-07
   1.6732538e+01   5.3658631e-07
   1.6739797e+01   5.3734754e-07
   1.6747056e+01   5.3810722e-07
   1.6754315e+01   5.3886536e-07
   1.6761574e+01   5.3962196e-07
   1.6768834e+01   5.4037702e-07
   1.6776093e+01   5.4113054e-07
   1.6783352e+01   5.4188253e-07
   1.6790611e+01   5.4263298e-07
   1.6797871e+01   5.4338190e-07
   1.6805130e+01   5.4412929e-07
   1.6812389e+01   5.4487515e-07
   1.6819648e+01   5.4561949e-07
   1.6826908e+01   5.4636230e-07
   1.6834167e+01   5.4710358e-07
   1.6841426e+01   5.4784335e-07
   1.6848685e+01   5.4858160e-07
   1.6855945e+01   5.4931833e-07
   1.6863204e+01   5.5005354e-07
   1.6870463e+01   5.5078724e-07
   1.6877722e+01   5.5151943e-07
   1.6884981e+01   5.5225011e-07
   1.6892241e+01   5.5297928e-07
   1.6899500e+01   5.5370694e-07
   1.6906759e+01   5.5443310e-07
   1.6914018e+01   5.5515775e-07
   1.6921278e+01   5.5588091e-07
   1.6928537e+01   5.5660256e-07
   1.6935796e+01   5.5732272e-07
   1.6943055e+01   5.5804139e-07
   1.6950315e+01   5.5875855e-07
   1.6957574e+01   5.5947423e-07
   1.6964833e+01   5.6018842e-07
   1.6972092e+01   5.6090112e-07
   1.6979352e+01   5.6161233e-07
   1.6986611e+01   5.6232206e-07
   1.6993870e+01   5.6303030e-07
   1.7001129e+01   5.6373707e-07
   1.7008388e+01   5.6444235e-07
   1.7015648e+01   5.6514616e-07
   1.7022907e+01   5.6584849e-07
   1.7030166e+01   5.6654935e-07
   1.7037425e+01   5.6724874e-07
   1.7044685e+01   5.6794665e-07
   1.7051944e+01   5.6864310e-07
   1.7059203e+01   5.6933809e-07
   1.7066462e+01   5.7003160e-07
   1.7073722e+01   5.7072366e-07
   1.7080981e+01   5.7141425e-07
   1.7088240e+01   5.7210339e-07
   1.7095499e+01   5.7279107e-07
   1.7102759e+01   5.7347729e-07
   1.7110018e+01   5.7416206e-07
   1.7117277e+01   5.7484538e-07
   1.7124536e+01   5.7552725e-07
   1.7131795e+01   5.7620767e-07
   1.7139055e+01   5.7688664e-07
   1.7146314e+01   5.7756417e-07
   1.7153573e+01   5.7824026e-07
   1.7160832e+01   5.7891490e-07
   1.7168092e+01   5.7958811e-07
   1.7175351e+01   5.8025988e-07
   1.7182610e+01   5.8093021e-07
   1.7189869e+01   5.8159912e-07
   1.7197129e+01   5.8226659e-07
   1.7204388e+01   5.8293263e-07
   1.7211647e+01   5.8359724e-07
   1.7218906e+01   5.8426042e-07
   1.7226166e+01   5.8492219e-07
   1.7233425e+01   5.8558252e-07
   1.7240684e+01   5.8624144e-07
   1.7247943e+01   5.8689894e-07
   1.7255202e+01   5.8755503e-07
   1.7262462e+01   5.8820969e-07
   1.7269721e+01   5.8886295e-07
   1.7276980e+01   5.8951479e-07
   1.7284239e+01   5.9016522e-07
   1.7291499e+01   5.9081425e-07
   1.7298758e+01   5.9146187e-07
   1.7306017e+01   5.9210808e-07
   1.7313276e+01   5.9275289e-07
   1.7320536e+01   5.9339631e-07
   1.7327795e+01   5.9403832e-07
   1.7335054e+01   5.9467894e-07
   1.7342313e+01   5.9531816e-07
   1.7349573e+01   5.9595598e-07
   1.7356832e+01   5.9659242e-07
   1.7364091e+01   5.9722747e-07
   1.7371350e+01   5.9786113e-07
   1.7378609e+01   5.9849340e-07
   1.7385869e+01   5.9912429e-07
   1.7393128e+01   5.9975380e-07
   1.7400387e+01   6.0038192e-07
   1.7407646e+01   6.0100867e-07
   1.7414906e+01   6.0163404e-07
   1.7422165e+01   6.0225804e-07
   1.7429424e+01   6.0288066e-07
   1.7436683e+01   6.0350191e-07
   1.7443943e+01   6.0412179e-07
   1.7451202e+01   6.0474031e-07
   1.7458461e+01   6.0535746e-07
   1.7465720e+01   6.0597324e-07
   1.7472980e+01   6.0658766e-07
   1.7480239e+01   6.0720073e-07
   1.7487498e+01   6.0781243e-07
   1.7494757e+01   6.0842278e-07
   1.7502016e+01   6.0903177e-07
   1.7509276e+01   6.0963941e-07
   1.7516535e+01   6.1024569e-07
   1.7523794e+01   6.1085063e-07
   1.7531053e+01   6.1145422e-07
   1.7538313e+01   6.1205647e-07
   1.7545572e+01   6.1265737e-07
   1.7552831e+01   6.1325693e-07
   1.7560090e+01   6.1385514e-07
   1.7567350e+01   6.1445202e-07
   1.7574609e+01   6.1504757e-07
   1.7581868e+01   6.1564178e-07
   1.7589127e+01   6.1623465e-07
   1.7596387e+01   6.1682620e-07
   1.7603646e+01   6.1741641e-07
   1.7610905e+01   6.1800530e-07
   1.7618164e+01   6.1859286e-07
   1.7625423e+01   6.1917910e-07
   1.7632683e+01   6.1976402e-07
   1.7639942e+01   6.2034761e-07
   1.7647201e+01   6.2092989e-07
   1.7654460e+01   6.2151085e-07
   1.7661720e+01   6.2209050e-07
   1.7668979e+01   6.2266883e-07
   1.7676238e+01   6.2324585e-07
   1.7683497e+01   6.2382156e-07
   1.7690757e+01   6.2439597e-07
   1.7698016e+01   6.2496907e-07
   1.7705275e+01   6.2554087e-07
   1.7712534e+01   6.2611136e-07
   1.7719794e+01   6.2668056e-07
   1.7727053e+01   6.2724845e-07
   1.7734312e+01   6.2781505e-07
   1.7741571e+01   6.2838036e-07
   1.7748830e+01   6.2894437e-07
   1.7756090e+01   6.2950709e-07
   1.7763349e+01   6.3006852e-07
   1.7770608e+01   6.3062867e-07
   1.7777867e+01   6.3118753e-07
   1.7785127e+01   6.3174510e-07
   1.7792386e+01   6.3230117e-07
   1.7799645e+01   6.3285495e-07
   1.7806904e+01   6.3340635e-07
   1.7814164e+01   6.3395539e-07
   1.7821423e+01   6.3450205e-07
   1.7828682e+01   6.3504634e-07
   1.7835941e+01   6.3558825e-07
   1.7843201e+01   6.3612779e-07
   1.7850460e+01   6.3666496e-07
   1.7857719e+01   6.3719974e-07
   1.7864978e+01   6.3773215e-07
   1.7872237e+01   6.3826218e-07
   1.7879497e+01   6.3878982e-07
   1.7886756e+01   6.3931508e-07
   1.7894015e+01   6.3983796e-07
   1.7901274e+01   6.4035845e-07
   1.7908534e+01   6.4087655e-07
   1.7915793e+01   6.4139227e-07
   1.7923052e+01   6.4190560e-07
   1.7930311e+01   6.4241653e-07
   1.7937571e+01   6.4292508e-07
   1.7944830e+01   6.4343123e-07
   1.7952089e+01   6.4393499e-07
   1.7959348e+01   6.4443635e-07
   1.7966608e+01   6.4493532e-07
   1.7973867e+01   6.4543189e-07
   1.7981126e+01   6.4592606e-07
   1.7988385e+01   6.4641782e-07
   1.7995644e+01   6.4690719e-07
   1.8002904e+01   6.4739415e-07
   1.8010163e+01   6.4787871e-07
   1.8017422e+01   6.4836087e-07
   1.8024681e+01   6.4884061e-07
   1.8031941e+01   6.4931795e-07
   1.8039200e+01   6.4979288e-07
   1.8046459e+01   6.5026540e-07
   1.8053718e+01   6.5073551e-07
   1.8060978e+01   6.5120321e-07
   1.8068237e+01   6.5166849e-07
   1.8075496e+01   6.5213135e-07
   1.8082755e+01   6.5259180e-07
   1.8090015e+01   6.5304983e-07
   1.8097274e+01   6.5350544e-07
   1.8104533e+01   6.5395863e-07
   1.8111792e+01   6.5440940e-07
   1.8119051e+01   6.5485775e-07
   1.8126311e+01   6.5530367e-07
   1.8133570e+01   6.5574717e-07
   1.8140829e+01   6.5618824e-07
   1.8148088e+01   6.5662688e-07
   1.8155348e+01   6.5706309e-07
   1.8162607e+01   6.5749687e-07
   1.8169866e+01   6.5792822e-07
   1.8177125e+01   6.5835714e-07
   1.8184385e+01   6.5878362e-07
   1.8191644e+01   6.5920767e-07
   1.8198903e+01   6.5962928e-07
   1.8206162e+01   6.6004845e-07
   1.8213422e+01   6.6046519e-07
   1.8220681e+01   6.6087948e-07
   1.8227940e+01   6.6129133e-07
   1.8235199e+01   6.6170074e-07
   1.8242458e+01   6.6210770e-07
   1.8249718e+01   6.6251222e-07
   1.8256977e+01   6.6291429e-07
   1.8264236e+01   6.6331392e-07
   1.8271495e+01   6.6371109e-07
   1.8278755e+01   6.6410582e-07
   1.8286014e+01   6.6449809e-07
   1.8293273e+01   6.6488791e-07
   1.8300532e+01   6.6527527e-07
   1.8307792e+01   6.6566018e-07
   1.8315051e+01   6.6604263e-07
   1.8322310e+01   6.6642263e-07
   1.8329569e+01   6.6680016e-07
   1.8336829e+01   6.6717524e-07
   1.8344088e+01   6.6754785e-07
   1.8351347e+01   6.6791800e-07
   1.8358606e+01   6.6828569e-07
   1.8365865e+01   6.6865091e-07
   1.8373125e+01   6.6901366e-07
   1.8380384e+01   6.6937395e-07
   1.8387643e+01   6.6973177e-07
   1.8394902e+01   6.7008711e-07
   1.8402162e+01   6.7043999e-07
   1.8409421e+01   6.7079039e-07
   1.8416680e+01   6.7113831e-07
   1.8423939e+01   6.7148377e-07
   1.8431199e+01   6.7182674e-07
   1.8438458e+01   6.7216724e-07
   1.8445717e+01   6.7250525e-07
   1.8452976e+01   6.7284079e-07
   1.8460236e+01   6.7317385e-07
   1.8467495e+01   6.7350442e-07
   1.8474754e+01   6.7383251e-07
   1.8482013e+01   6.7415811e-07
   1.8489272e+01   6.7448122e-07
   1.8496532e+01   6.7480185e-07
   1.8503791e+01   6.7511999e-07
   1.8511050e+01   6.7543564e-07
   1.8518309e+01   6.7574879e-07
   1.8525569e+01   6.7605946e-07
   1.8532828e+01   6.7636763e-07
   1.8540087e+01   6.7667330e-07
   1.8547346e+01   6.7697648e-07
   1.8554606e+01   6.7727715e-07
   1.8561865e+01   6.7757533e-07
   1.8569124e+01   6.7787101e-07
   1.8576383e+01   6.7816419e-07
   1.8583643e+01   6.7845486e-07
   1.8590902e+01   6.7874303e-07
   1.8598161e+01   6.7902869e-07
   1.8605420e+01   6.7931185e-07
   1.8612679e+01   6.7959250e-07
   1.8619939e+01   6.7987064e-07
   1.8627198e+01   6.8014627e-07
   1.8634457e+01   6.8041939e-07
   1.8641716e+01   6.8068999e-07
   1.8648976e+01   6.8095808e-07
   1.8656235e+01   6.8122366e-07
   1.8663494e+01   6.8148672e-07
   1.8670753e+01   6.8174725e-07
   1.8678013e+01   6.8200528e-07
   1.8685272e+01   6.8226078e-07
   1.8692531e+01   6.8251375e-07
   1.8699790e+01   6.8276421e-07
   1.8707050e+01   6.8301214e-07
   1.8714309e+01   6.8325755e-07
   1.8721568e+01   6.8350042e-07
   1.8728827e+01   6.8374077e-07
   1.8736086e+01   6.8397860e-07
   1.8743346e+01   6.8421389e-07
   1.8750605e+01   6.8444665e-07
   1.8757864e+01   6.8467686e-07
   1.8765123e+01   6.8490443e-07
   1.8772383e+01   6.8512932e-07
   1.8779642e+01   6.8535154e-07
   1.8786901e+01   6.8557109e-07
   1.8794160e+01   6.8578795e-07
   1.8801420e+01   6.8600214e-07
   1.8808679e+01   6.8621366e-07
   1.8815938e+01   6.8642249e-07
   1.8823197e+01   6.8662865e-07
   1.8830457e+01   6.8683212e-07
   1.8837716e+01   6.8703292e-07
   1.8844975e+01   6.8723103e-07
   1.8852234e+01   6.8742646e-07
   1.8859493e+01   6.8761921e-07
   1.8866753e+01   6.8780928e-07
   1.8874012e+01   6.8799666e-07
   1.8881271e+01   6.8818135e-07
   1.8888530e+01   6.8836336e-07
   1.8895790e+01   6.8854268e-07
   1.8903049e+01   6.8871932e-07
   1.8910308e+01   6.8889326e-07
   1.8917567e+01   6.8906452e-07
   1.8924827e+01   6.8923309e-07
   1.8932086e+01   6.8939897e-07
   1.8939345e+01   6.8956215e-07
   1.8946604e+01   6.8972264e-07
   1.8953864e+01   6.8988044e-07
   1.8961123e+01   6.9003555e-07
   1.8968382e+01   6.9018796e-07
   1.8975641e+01   6.9033768e-07
   1.8982900e+01   6.9048470e-07
   1.8990160e+01   6.9062903e-07
   1.8997419e+01   6.9077065e-07
   1.9004678e+01   6.9090958e-07
   1.9011937e+01   6.9104581e-07
   1.9019197e+01   6.9117934e-07
   1.9026456e+01   6.9131017e-07
   1.9033715e+01   6.9143830e-07
   1.9040974e+01   6.9156373e-07
   1.9048234e+01   6.9168645e-07
   1.9055493e+01   6.9180647e-07
   1.9062752e+01   6.9192378e-07
   1.9070011e+01   6.9203840e-07
   1.9077271e+01   6.9215030e-07
   1.9084530e+01   6.9225950e-07
   1.9091789e+01   6.9236599e-07
   1.9099048e+01   6.9246977e-07
   1.9106307e+01   6.9257085e-07
   1.9113567e+01   6.9266921e-07
   1.9120826e+01   6.9276486e-07
   1.9128085e+01   6.9285781e-07
   1.9135344e+01   6.9294804e-07
   1.9142604e+01   6.9303556e-07
   1.9149863e+01   6.9312036e-07
   1.9157122e+01   6.9320245e-07
   1.9164381e+01   6.9328183e-07
   1.9171641e+01   6.9335849e-07
   1.9178900e+01   6.9343243e-07
   1.9186159e+01   6.9350366e-07
   1.9193418e+01   6.9357216e-07
   1.9200678e+01   6.9363795e-07
   1.9207937e+01   6.9370102e-07
   1.9215196e+01   6.9376137e-07
   1.9222455e+01   6.9381900e-07
   1.9229714e+01   6.9387391e-07
   1.9236974e+01   6.9392609e-07
   1.9244233e+01   6.9397555e-07
   1.9251492e+01   6.9402229e-07
   1.9258751e+01   6.9406630e-07
   1.9266011e+01   6.9410759e-07
   1.9273270e+01   6.9414615e-07
   1.9280529e+01   6.9418198e-07
   1.9287788e+01   6.9421508e-07
   1.9295048e+01   6.9424546e-07
   1.9302307e+01   6.9427311e-07
   1.9309566e+01   6.9429802e-07
   1.9316825e+01   6.9432021e-07
   1.9324085e+01   6.9433966e-07
   1.9331344e+01   6.9435638e-07
   1.9338603e+01   6.9437037e-07
   1.9345862e+01   6.9438162e-07
   1.9353121e+01   6.9439014e-07
   1.9360381e+01   6.9439593e-07
   1.9367640e+01   6.9439897e-07
   1.9374899e+01   6.9439928e-07
   1.9382158e+01   6.9439686e-07
   1.9389418e+01   6.9439169e-07
   1.9396677e+01   6.9438379e-07
   1.9403936e+01   6.9437314e-07
   1.9411195e+01   6.9435975e-07
   1.9418455e+01   6.9434363e-07
   1.9425714e+01   6.9432476e-07
   1.9432973e+01   6.9430314e-07
   1.9440232e+01   6.9427879e-07
   1.9447492e+01   6.9425168e-07
   1.9454751e+01   6.9422184e-07
   1.9462010e+01   6.9418924e-07
   1.9469269e+01   6.9415390e-07
   1.9476528e+01   6.9411581e-07
   1.9483788e+01   6.9407498e-07
   1.9491047e+01   6.9403139e-07
   1.9498306e+01   6.9398506e-07
   1.9505565e+01   6.9393597e-07
   1.9512825e+01   6.9388413e-07
   1.9520084e+01   6.9382954e-07
   1.9527343e+01   6.9377220e-07
   1.9534602e+01   6.9371210e-07
   1.9541862e+01   6.9364925e-07
   1.9549121e+01   6.9358364e-07
   1.9556380e+01   6.9351528e-07
   1.9563639e+01   6.9344416e-07
   1.9570899e+01   6.9337028e-07
   1.9578158e+01   6.9329365e-07
   1.9585417e+01   6.9321425e-07
   1.9592676e+01   6.9313210e-07
   1.9599935e+01   6.9304718e-07
   1.9607195e+01   6.9295950e-07
   1.9614454e+01   6.9286906e-07
   1.9621713e+01   6.9277586e-07
   1.9628972e+01   6.9267990e-07
   1.9636232e+01   6.9258117e-07
   1.9643491e+01   6.9247967e-07
   1.9650750e+01   6.9237541e-07
   1.9658009e+01   6.9226838e-07
   1.9665269e+01   6.9215859e-07
   1.9672528e+01   6.9204602e-07
   1.9679787e+01   6.9193069e-07
   1.9687046e+01   6.9181259e-07
   1.9694306e+01   6.9169171e-07
   1.9701565e+01   6.9156807e-07
   1.9708824e+01   6.9144165e-07
   1.9716083e+01   6.9131246e-07
   1.9723342e+01   6.9118050e-07
   1.9730602e+01   6.9104576e-07
   1.9737861e+01   6.9090825e-07
   1.9745120e+01   6.9076796e-07
   1.9752379e+01   6.9062490e-07
   1.9759639e+01   6.9047906e-07
   1.9766898e+01   6.9033044e-07
   1.9774157e+01   6.9017904e-07
   1.9781416e+01   6.9002486e-07
   1.9788676e+01   6.8986790e-07
   1.9795935e+01   6.8970816e-07
   1.9803194e+01   6.8954563e-07
   1.9810453e+01   6.8938033e-07
   1.9817713e+01   6.8921224e-07
   1.9824972e+01   6.8904137e-07
   1.9832231e+01   6.8886771e-07
   1.9839490e+01   6.8869127e-07
   1.9846749e+01   6.8851204e-07
   1.9854009e+01   6.8833002e-07
   1.9861268e+01   6.8814519e-07
   1.9868527e+01   6.8795731e-07
   1.9875786e+01   6.8776630e-07
   1.9883046e+01   6.8757215e-07
   1.9890305e+01   6.8737485e-07
   1.9897564e+01   6.8717442e-07
   1.9904823e+01   6.8697084e-07
   1.9912083e+01   6.8676412e-07
   1.9919342e+01   6.8655425e-07
   1.9926601e+01   6.8634122e-07
   1.9933860e+01   6.8612505e-07
   1.9941120e+01   6.8590572e-07
   1.9948379e+01   6.8568323e-07
   1.9955638e+01   6.8545758e-07
   1.9962897e+01   6.8522877e-07
   1.9970156e+01   6.8499680e-07
   1.9977416e+01   6.8476166e-07
   1.9984675e+01   6.8452336e-07
   1.9991934e+01   6.8428188e-07
   1.9999193e+01   6.8403723e-07
   2.0006453e+01   6.8378941e-07
   2.0013712e+01   6.8353841e-07
   2.0020971e+01   6.8328423e-07
   2.0028230e+01   6.8302687e-07
   2.0035490e+01   6.8276633e-07
   2.0042749e+01   6.8250260e-07
   2.0050008e+01   6.8223569e-07
   2.0057267e+01   6.8196558e-07
   2.0064527e+01   6.8169228e-07
   2.0071786e+01   6.8141579e-07
   2.0079045e+01   6.8113610e-07
   2.0086304e+01   6.8085321e-07
   2.0093563e+01   6.8056712e-07
   2.0100823e+01   6.8027783e-07
   2.0108082e+01   6.7998534e-07
   2.0115341e+01   6.7968963e-07
   2.0122600e+01   6.7939072e-07
   2.0129860e+01   6.7908860e-07
   2.0137119e+01   6.7878326e-07
   2.0144378e+01   6.7847470e-07
   2.0151637e+01   6.7816293e-07
   2.0158897e+01   6.7784794e-07
   2.0166156e+01   6.7752972e-07
   2.0173415e+01   6.7720828e-07
   2.0180674e+01   6.7688361e-07
   2.0187934e+01   6.7655572e-07
   2.0195193e+01   6.7622459e-07
   2.0202452e+01   6.7589023e-07
   2.0209711e+01   6.7555263e-07
   2.0216970e+01   6.7521180e-07
   2.0224230e+01   6.7486772e-07
   2.0231489e+01   6.7452040e-07
   2.0238748e+01   6.7416984e-07
   2.0246007e+01   6.7381603e-07
   2.0253267e+01   6.7345897e-07
   2.0260526e+01   6.7309867e-07
   2.0267785e+01   6.7273510e-07
   2.0275044e+01   6.7236829e-07
   2.0282304e+01   6.7199821e-07
   2.0289563e+01   6.7162488e-07
   2.0296822e+01   6.7124828e-07
   2.0304081e+01   6.7086842e-07
   2.0311341e+01   6.7048530e-07
   2.0318600e+01   6.7009890e-07
   2.0325859e+01   6.6970924e-07
   2.0333118e+01   6.6931630e-07
   2.0340377e+01   6.6892008e-07
   2.0347637e+01   6.6852059e-07
   2.0354896e+01   6.6811782e-07
   2.0362155e+01   6.6771177e-07
   2.0369414e+01   6.6730243e-07
   2.0376674e+01   6.6688981e-07
   2.0383933e+01   6.6647390e-07
   2.0391192e+01   6.6605470e-07
   2.0398451e+01   6.6563221e-07
   2.0405711e+01   6.6520642e-07
   2.0412970e+01   6.6477734e-07
   2.0420229e+01   6.6434496e-07
   2.0427488e+01   6.6390927e-07
   2.0434748e+01   6.6347029e-07
   2.0442007e+01   6.6302799e-07
   2.0449266e+01   6.6258239e-07
   2.0456525e+01   6.6213348e-07
   2.0463784e+01   6.6168126e-07
   2.0471044e+01   6.6122572e-07
   2.0478303e+01   6.6076687e-07
   2.0485562e+01   6.6030469e-07
   2.0492821e+01   6.5983920e-07
   2.0500081e+01   6.5937038e-07
   2.0507340e+01   6.5889824e-07
   2.0514599e+01   6.5842277e-07
   2.0521858e+01   6.5794397e-07
   2.0529118e+01   6.5746184e-07
   2.0536377e+01   6.5697638e-07
   2.0543636e+01   6.5648758e-07
   2.0550895e+01   6.5599544e-07
   2.0558155e+01   6.5549996e-07
   2.0565414e+01   6.5500114e-07
   2.0572673e+01   6.5449897e-07
   2.0579932e+01   6.5399345e-07
   2.0587191e+01   6.5348459e-07
   2.0594451e+01   6.5297237e-07
   2.0601710e+01   6.5245681e-07
   2.0608969e+01   6.5193788e-07
   2.0616228e+01   6.5141560e-07
   2.0623488e+01   6.5088995e-07
   2.0630747e+01   6.5036095e-07
   2.0638006e+01   6.4982858e-07
   2.0645265e+01   6.4929284e-07
   2.0652525e+01   6.4875374e-07
   2.0659784e+01   6.4821126e-07
   2.0667043e+01   6.4766541e-07
   2.0674302e+01   6.4711618e-07
   2.0681562e+01   6.4656358e-07
   2.0688821e+01   6.4600760e-07
   2.0696080e+01   6.4544823e-07
   2.0703339e+01   6.4488548e-07
   2.0710598e+01   6.4431935e-07
   2.0717858e+01   6.4374982e-07
   2.0725117e+01   6.4317691e-07
   2.0732376e+01   6.4260060e-07
   2.0739635e+01   6.4202090e-07
   2.0746895e+01   6.4143780e-07
   2.0754154e+01   6.4085130e-07
   2.0761413e+01   6.4026139e-07
   2.0768672e+01   6.3966809e-07
   2.0775932e+01   6.3907138e-07
   2.0783191e+01   6.3847126e-07
   2.0790450e+01   6.3786773e-07
   2.0797709e+01   6.3726078e-07
   2.0804969e+01   6.3665043e-07
   2.0812228e+01   6.3603665e-07
   2.0819487e+01   6.3541946e-07
   2.0826746e+01   6.3479884e-07
   2.0834005e+01   6.3417480e-07
   2.0841265e+01   6.3354734e-07
   2.0848524e+01   6.3291645e-07
   2.0855783e+01   6.3228212e-07
   2.0863042e+01   6.3164437e-07
   2.0870302e+01   6.3100318e-07
   2.0877561e+01   6.3035855e-07
   2.0884820e+01   6.2971049e-07
   2.0892079e+01   6.2905898e-07
   2.0899339e+01   6.2840403e-07
   2.0906598e+01   6.2774564e-07
   2.0913857e+01   6.2708380e-07
   2.0921116e+01   6.2641851e-07
   2.0928376e+01   6.2574976e-07
   2.0935635e+01   6.2507756e-07
   2.0942894e+01   6.2440191e-07
   2.0950153e+01   6.2372280e-07
   2.0957412e+01   6.2304023e-07
   2.0964672e+01   6.2235419e-07
   2.0971931e+01   6.2166469e-07
   2.0979190e+01   6.2097172e-07
   2.0986449e+01   6.2027528e-07
   2.0993709e+01   6.1957537e-07
   2.1000968e+01   6.1887199e-07
   2.1008227e+01   6.1816513e-07
   2.1015486e+01   6.1745479e-07
   2.1022746e+01   6.1674098e-07
   2.1030005e+01   6.1602512e-07
   2.1037264e+01   6.1530828e-07
   2.1044523e+01   6.1459050e-07
   2.1051783e+01   6.1387177e-07
   2.1059042e+01   6.1315213e-07
   2.1066301e+01   6.1243157e-07
   2.1073560e+01   6.1171012e-07
   2.1080819e+01   6.1098779e-07
   2.1088079e+01   6.1026459e-07
   2.1095338e+01   6.0954054e-07
   2.1102597e+01   6.0881566e-07
   2.1109856e+01   6.0808995e-07
   2.1117116e+01   6.0736343e-07
   2.1124375e+01   6.0663612e-07
   2.1131634e+01   6.0590802e-07
   2.1138893e+01   6.0517917e-07
   2.1146153e+01   6.0444955e-07
   2.1153412e+01   6.0371921e-07
   2.1160671e+01   6.0298814e-07
   2.1167930e+01   6.0225636e-07
   2.1175190e+01   6.0152388e-07
   2.1182449e+01   6.0079073e-07
   2.1189708e+01   6.0005691e-07
   2.1196967e+01   5.9932244e-07
   2.1204226e+01   5.9858733e-07
   2.1211486e+01   5.9785160e-07
   2.1218745e+01   5.9711526e-07
   2.1226004e+01   5.9637833e-07
   2.1233263e+01   5.9564081e-07
   2.1240523e+01   5.9490273e-07
   2.1247782e+01   5.9416410e-07
   2.1255041e+01   5.9342494e-07
   2.1262300e+01   5.9268525e-07
   2.1269560e+01   5.9194505e-07
   2.1276819e+01   5.9120435e-07
   2.1284078e+01   5.9046318e-07
   2.1291337e+01   5.8972154e-07
   2.1298597e+01   5.8897946e-07
   2.1305856e+01   5.8823693e-07
   2.1313115e+01   5.8749398e-07
   2.1320374e+01   5.8675063e-07
   2.1327633e+01   5.8600688e-07
   2.1334893e+01   5.8526275e-07
   2.1342152e+01   5.8451825e-07
   2.1349411e+01   5.8377340e-07
   2.1356670e+01   5.8302822e-07
   2.1363930e+01   5.8228272e-07
   2.1371189e+01   5.8153690e-07
   2.1378448e+01   5.8079080e-07
   2.1385707e+01   5.8004441e-07
   2.1392967e+01   5.7929776e-07
   2.1400226e+01   5.7855086e-07
   2.1407485e+01   5.7780372e-07
   2.1414744e+01   5.7705636e-07
   2.1422004e+01   5.7630879e-07
   2.1429263e+01   5.7556103e-07
   2.1436522e+01   5.7481309e-07
   2.1443781e+01   5.7406498e-07
   2.1451040e+01   5.7331672e-07
   2.1458300e+01   5.7256833e-07
   2.1465559e+01   5.7181982e-07
   2.1472818e+01   5.7107119e-07
   2.1480077e+01   5.7032248e-07
   2.1487337e+01   5.6957368e-07
   2.1494596e+01   5.6882482e-07
   2.1501855e+01   5.6807591e-07
   2.1509114e+01   5.6732697e-07
   2.1516374e+01   5.6657800e-07
   2.1523633e+01   5.6582902e-07
   2.1530892e+01   5.6508005e-07
   2.1538151e+01   5.6433110e-07
   2.1545411e+01   5.6358219e-07
   2.1552670e+01   5.6283333e-07
   2.1559929e+01   5.6208453e-07
   2.1567188e+01   5.6133581e-07
   2.1574447e+01   5.6058718e-07
   2.1581707e+01   5.5983866e-07
   2.1588966e+01   5.5909026e-07
   2.1596225e+01   5.5834199e-07
   2.1603484e+01   5.5759388e-07
   2.1610744e+01   5.5684593e-07
   2.1618003e+01   5.5609816e-07
   2.1625262e+01   5.5535058e-07
   2.1632521e+01   5.5460321e-07
   2.1639781e+01   5.5385606e-07
   2.1647040e+01   5.5310914e-07
   2.1654299e+01   5.5236248e-07
   2.1661558e+01   5.5161608e-07
   2.1668818e+01   5.5086996e-07
   2.1676077e+01   5.5012413e-07
   2.1683336e+01   5.4937861e-07
   2.1690595e+01   5.4863341e-07
   2.1697854e+01   5.4788854e-07
   2.1705114e+01   5.4714403e-07
   2.1712373e+01   5.4639988e-07
   2.1719632e+01   5.4565611e-07
   2.1726891e+01   5.4491273e-07
   2.1734151e+01   5.4416976e-07
   2.1741410e+01   5.4342721e-07
   2.1748669e+01   5.4268510e-07
   2.1755928e+01   5.4194344e-07
   2.1763188e+01   5.4120224e-07
   2.1770447e+01   5.4046152e-07
   2.1777706e+01   5.3972130e-07
   2.1784965e+01   5.3898158e-07
   2.1792225e+01   5.3824239e-07
   2.1799484e+01   5.3750373e-07
   2.1806743e+01   5.3676562e-07
   2.1814002e+01   5.3602808e-07
   2.1821261e+01   5.3529111e-07
   2.1828521e+01   5.3455474e-07
   2.1835780e+01   5.3381898e-07
   2.1843039e+01   5.3308384e-07
   2.1850298e+01   5.3234933e-07
   2.1857558e+01   5.3161548e-07
   2.1864817e+01   5.3088229e-07
   2.1872076e+01   5.3014978e-07
   2.1879335e+01   5.2941786e-07
   2.1886595e+01   5.2868631e-07
   2.1893854e+01   5.2795512e-07
   2.1901113e+01   5.2722432e-07
   2.1908372e+01   5.2649393e-07
   2.1915632e+01   5.2576394e-07
   2.1922891e+01   5.2503439e-07
   2.1930150e+01   5.2430529e-07
   2.1937409e+01   5.2357664e-07
   2.1944668e+01   5.2284847e-07
   2.1951928e+01   5.2212080e-07
   2.1959187e+01   5.2139363e-07
   2.1966446e+01   5.2066698e-07
   2.1973705e+01   5.1994087e-07
   2.1980965e+01   5.1921531e-07
   2.1988224e+01   5.1849032e-07
   2.1995483e+01   5.1776591e-07
   2.2002742e+01   5.1704211e-07
   2.2010002e+01   5.1631891e-07
   2.2017261e+01   5.1559634e-07
   2.2024520e+01   5.1487442e-07
   2.2031779e+01   5.1415316e-07
   2.2039039e+01   5.1343257e-07
   2.2046298e+01   5.1271267e-07
   2.2053557e+01   5.1199348e-07
   2.2060816e+01   5.1127500e-07
   2.2068075e+01   5.1055726e-07
   2.2075335e+01   5.0984027e-07
   2.2082594e+01   5.0912405e-07
   2.2089853e+01   5.0840861e-07
   2.2097112e+01   5.0769396e-07
   2.2104372e+01   5.0698013e-07
   2.2111631e+01   5.0626712e-07
   2.2118890e+01   5.0555495e-07
   2.2126149e+01   5.0484364e-07
   2.2133409e+01   5.0413320e-07
   2.2140668e+01   5.0342365e-07
   2.2147927e+01   5.0271501e-07
   2.2155186e+01   5.0200728e-07
   2.2162446e+01   5.0130048e-07
   2.2169705e+01   5.0059463e-07
   2.2176964e+01   4.9988975e-07
   2.2184223e+01   4.9918584e-07
   2.2191482e+01   4.9848293e-07
   2.2198742e+01   4.9778103e-07
   2.2206001e+01   4.9708015e-07
   2.2213260e+01   4.9638031e-07
   2.2220519e+01   4.9568153e-07
   2.2227779e+01   4.9498382e-07
   2.2235038e+01   4.9428719e-07
   2.2242297e+01   4.9359166e-07
   2.2249556e+01   4.9289725e-07
   2.2256816e+01   4.9220397e-07
   2.2264075e+01   4.9151184e-07
   2.2271334e+01   4.9082086e-07
   2.2278593e+01   4.9013107e-07
   2.2285853e+01   4.8944246e-07
   2.2293112e+01   4.8875507e-07
   2.2300371e+01   4.8806889e-07
   2.2307630e+01   4.8738395e-07
   2.2314889e+01   4.8670027e-07
   2.2322149e+01   4.8601785e-07
   2.2329408e+01   4.8533672e-07
   2.2336667e+01   4.8465688e-07
   2.2343926e+01   4.8397836e-07
   2.2351186e+01   4.8330117e-07
   2.2358445e+01   4.8262532e-07
   2.2365704e+01   4.8195083e-07
   2.2372963e+01   4.8127772e-07
   2.2380223e+01   4.8060599e-07
   2.2387482e+01   4.7993567e-07
   2.2394741e+01   4.7926677e-07
   2.2402000e+01   4.7859931e-07
   2.2409260e+01   4.7793330e-07
   2.2416519e+01   4.7726875e-07
   2.2423778e+01   4.7660568e-07
   2.2431037e+01   4.7594411e-07
   2.2438296e+01   4.7528405e-07
   2.2445556e+01   4.7462552e-07
   2.2452815e+01   4.7396853e-07
   2.2460074e+01   4.7331310e-07
   2.2467333e+01   4.7265924e-07
   2.2474593e+01   4.7200697e-07
   2.2481852e+01   4.7135630e-07
   2.2489111e+01   4.7070725e-07
   2.2496370e+01   4.7005983e-07
   2.2503630e+01   4.6941406e-07
   2.2510889e+01   4.6876995e-07
   2.2518148e+01   4.6812753e-07
   2.2525407e+01   4.6748679e-07
   2.2532667e+01   4.6684777e-07
   2.2539926e+01   4.6621047e-07
   2.2547185e+01   4.6557491e-07
   2.2554444e+01   4.6494111e-07
   2.2561704e+01   4.6430908e-07
   2.2568963e+01   4.6367883e-07
   2.2576222e+01   4.6305038e-07
   2.2583481e+01   4.6242375e-07
   2.2590740e+01   4.6179895e-07
   2.2598000e+01   4.6117600e-07
   2.2605259e+01   4.6055490e-07
   2.2612518e+01   4.5993569e-07
   2.2619777e+01   4.5931837e-07
   2.2627037e+01   4.5870295e-07
   2.2634296e+01   4.5808946e-07
   2.2641555e+01   4.5747790e-07
   2.2648814e+01   4.5686830e-07
   2.2656074e+01   4.5626067e-07
   2.2663333e+01   4.5565501e-07
   2.2670592e+01   4.5505136e-07
   2.2677851e+01   4.5444972e-07
   2.2685111e+01   4.5385012e-07
   2.2692370e+01   4.5325255e-07
   2.2699629e+01   4.5265705e-07
   2.2706888e+01   4.5206361e-07
   2.2714147e+01   4.5147227e-07
   2.2721407e+01   4.5088304e-07
   2.2728666e+01   4.5029557e-07
   2.2735925e+01   4.4970727e-07
   2.2743184e+01   4.4911765e-07
   2.2750444e+01   4.4852675e-07
   2.2757703e+01   4.4793460e-07
   2.2764962e+01   4.4734123e-07
   2.2772221e+01   4.4674669e-07
   2.2779481e+01   4.4615101e-07
   2.2786740e+01   4.4555423e-07
   2.2793999e+01   4.4495637e-07
   2.2801258e+01   4.4435748e-07
   2.2808518e+01   4.4375760e-07
   2.2815777e+01   4.4315676e-07
   2.2823036e+01   4.4255499e-07
   2.2830295e+01   4.4195233e-07
   2.2837554e+01   4.4134883e-07
   2.2844814e+01   4.4074450e-07
   2.2852073e+01   4.4013940e-07
   2.2859332e+01   4.3953355e-07
   2.2866591e+01   4.3892700e-07
   2.2873851e+01   4.3831977e-07
   2.2881110e+01   4.3771191e-07
   2.2888369e+01   4.3710345e-07
   2.2895628e+01   4.3649443e-07
   2.2902888e+01   4.3588487e-07
   2.2910147e+01   4.3527483e-07
   2.2917406e+01   4.3466433e-07
   2.2924665e+01   4.3405342e-07
   2.2931925e+01   4.3344212e-07
   2.2939184e+01   4.3283047e-07
   2.2946443e+01   4.3221851e-07
   2.2953702e+01   4.3160628e-07
   2.2960961e+01   4.3099381e-07
   2.2968221e+01   4.3038113e-07
   2.2975480e+01   4.2976829e-07
   2.2982739e+01   4.2915532e-07
   2.2989998e+01   4.2854225e-07
   2.2997258e+01   4.2792913e-07
   2.3004517e+01   4.2731598e-07
   2.3011776e+01   4.2670285e-07
   2.3019035e+01   4.2608977e-07
   2.3026295e+01   4.2547677e-07
   2.3033554e+01   4.2486390e-07
   2.3040813e+01   4.2425118e-07
   2.3048072e+01   4.2363866e-07
   2.3055332e+01   4.2302637e-07
   2.3062591e+01   4.2241434e-07
   2.3069850e+01   4.2180262e-07
   2.3077109e+01   4.2119124e-07
   2.3084368e+01   4.2058023e-07
   2.3091628e+01   4.1996963e-07
   2.3098887e+01   4.1935947e-07
   2.3106146e+01   4.1874980e-07
   2.3113405e+01   4.1814065e-07
   2.3120665e+01   4.1753206e-07
   2.3127924e+01   4.1692405e-07
   2.3135183e+01   4.1631667e-07
   2.3142442e+01   4.1570996e-07
   2.3149702e+01   4.1510394e-07
   2.3156961e+01   4.1449866e-07
   2.3164220e+01   4.1389416e-07
   2.3171479e+01   4.1329045e-07
   2.3178739e+01   4.1268760e-07
   2.3185998e+01   4.1208562e-07
   2.3193257e+01   4.1148456e-07
   2.3200516e+01   4.1088445e-07
   2.3207775e+01   4.1028532e-07
   2.3215035e+01   4.0968722e-07
   2.3222294e+01   4.0909019e-07
   2.3229553e+01   4.0849424e-07
   2.3236812e+01   4.0789943e-07
   2.3244072e+01   4.0730579e-07
   2.3251331e+01   4.0671335e-07
   2.3258590e+01   4.0612215e-07
   2.3265849e+01   4.0553223e-07
   2.3273109e+01   4.0494362e-07
   2.3280368e+01   4.0435636e-07
   2.3287627e+01   4.0377049e-07
   2.3294886e+01   4.0318603e-07
   2.3302146e+01   4.0260304e-07
   2.3309405e+01   4.0202153e-07
   2.3316664e+01   4.0144155e-07
   2.3323923e+01   4.0086314e-07
   2.3331182e+01   4.0028633e-07
   2.3338442e+01   3.9971116e-07
   2.3345701e+01   3.9913766e-07
   2.3352960e+01   3.9856587e-07
   2.3360219e+01   3.9799583e-07
   2.3367479e+01   3.9742756e-07
   2.3374738e+01   3.9686112e-07
   2.3381997e+01   3.9629652e-07
   2.3389256e+01   3.9573382e-07
   2.3396516e+01   3.9517305e-07
   2.3403775e+01   3.9461423e-07
   2.3411034e+01   3.9405741e-07
   2.3418293e+01   3.9350263e-07
   2.3425553e+01   3.9294992e-07
   2.3432812e+01   3.9239931e-07
   2.3440071e+01   3.9185085e-07
   2.3447330e+01   3.9130456e-07
   2.3454589e+01   3.9076049e-07
   2.3461849e+01   3.9021867e-07
   2.3469108e+01   3.8967914e-07
   2.3476367e+01   3.8914192e-07
   2.3483626e+01   3.8860707e-07
   2.3490886e+01   3.8807461e-07
   2.3498145e+01   3.8754458e-07
   2.3505404e+01   3.8701702e-07
   2.3512663e+01   3.8649197e-07
   2.3519923e+01   3.8596945e-07
   2.3527182e+01   3.8544950e-07
   2.3534441e+01   3.8493217e-07
   2.3541700e+01   3.8441749e-07
   2.3548960e+01   3.8390548e-07
   2.3556219e+01   3.8339620e-07
   2.3563478e+01   3.8288967e-07
   2.3570737e+01   3.8238594e-07
   2.3577996e+01   3.8188503e-07
   2.3585256e+01   3.8138699e-07
   2.3592515e+01   3.8089184e-07
   2.3599774e+01   3.8039964e-07
   2.3607033e+01   3.7991040e-07
   2.3614293e+01   3.7942417e-07
   2.3621552e+01   3.7894099e-07
   2.3628811e+01   3.7846088e-07
   2.3636070e+01   3.7798390e-07
   2.3643330e+01   3.7751006e-07
   2.3650589e+01   3.7703941e-07
   2.3657848e+01   3.7657199e-07
   2.3665107e+01   3.7610783e-07
   2.3672367e+01   3.7564696e-07
   2.3679626e+01   3.7518943e-07
   2.3686885e+01   3.7473527e-07
   2.3694144e+01   3.7428451e-07
   2.3701403e+01   3.7383719e-07
   2.3708663e+01   3.7339335e-07
   2.3715922e+01   3.7295302e-07
   2.3723181e+01   3.7251624e-07
   2.3730440e+01   3.7208305e-07
   2.3737700e+01   3.7165348e-07
   2.3744959e+01   3.7122756e-07
   2.3752218e+01   3.7080534e-07
   2.3759477e+01   3.7038685e-07
   2.3766737e+01   3.6997212e-07
   2.3773996e+01   3.6956120e-07
   2.3781255e+01   3.6915411e-07
   2.3788514e+01   3.6875090e-07
   2.3795774e+01   3.6835160e-07
   2.3803033e+01   3.6795624e-07
   2.3810292e+01   3.6756487e-07
   2.3817551e+01   3.6717751e-07
   2.3824810e+01   3.6679421e-07
   2.3832070e+01   3.6641499e-07
   2.3839329e+01   3.6603991e-07
   2.3846588e+01   3.6566898e-07
   2.3853847e+01   3.6530226e-07
   2.3861107e+01   3.6493977e-07
   2.3868366e+01   3.6458155e-07
   2.3875625e+01   3.6422763e-07
   2.3882884e+01   3.6387806e-07
   2.3890144e+01   3.6353287e-07
   2.3897403e+01   3.6319210e-07
   2.3904662e+01   3.6285577e-07
   2.3911921e+01   3.6252393e-07
   2.3919181e+01   3.6219662e-07
   2.3926440e+01   3.6187386e-07
   2.3933699e+01   3.6155570e-07
   2.3940958e+01   3.6124217e-07
   2.3948217e+01   3.6093331e-07
   2.3955477e+01   3.6062915e-07
   2.3962736e+01   3.6032973e-07
   2.3969995e+01   3.6003509e-07
   2.3977254e+01   3.5974526e-07
   2.3984514e+01   3.5946027e-07
   2.3991773e+01   3.5918017e-07
   2.3999032e+01   3.5890500e-07
   2.4006291e+01   3.5863477e-07
   2.4013551e+01   3.5836954e-07
   2.4020810e+01   3.5810934e-07
   2.4028069e+01   3.5785420e-07
   2.4035328e+01   3.5760416e-07
   2.4042588e+01   3.5735926e-07
   2.4049847e+01   3.5711953e-07
   2.4057106e+01   3.5688470e-07
   2.4064365e+01   3.5665253e-07
   2.4071624e+01   3.5642258e-07
   2.4078884e+01   3.5619482e-07
   2.4086143e+01   3.5596923e-07
   2.4093402e+01   3.5574579e-07
   2.4100661e+01   3.5552448e-07
   2.4107921e+01   3.5530528e-07
   2.4115180e+01   3.5508818e-07
   2.4122439e+01   3.5487315e-07
   2.4129698e+01   3.5466016e-07
   2.4136958e+01   3.5444922e-07
   2.4144217e+01   3.5424028e-07
   2.4151476e+01   3.5403334e-07
   2.4158735e+01   3.5382837e-07
   2.4165995e+01   3.5362535e-07
   2.4173254e+01   3.5342426e-07
   2.4180513e+01   3.5322509e-07
   2.4187772e+01   3.5302781e-07
   2.4195031e+01   3.5283241e-07
   2.4202291e+01   3.5263886e-07
   2.4209550e+01   3.5244714e-07
   2.4216809e+01   3.5225724e-07
   2.4224068e+01   3.5206913e-07
   2.4231328e+01   3.5188279e-07
   2.4238587e+01   3.5169821e-07
   2.4245846e+01   3.5151536e-07
   2.4253105e+01   3.5133423e-07
   2.4260365e+01   3.5115480e-07
   2.4267624e+01   3.5097703e-07
   2.4274883e+01   3.5080093e-07
   2.4282142e+01   3.5062646e-07
   2.4289402e+01   3.5045360e-07
   2.4296661e+01   3.5028234e-07
   2.4303920e+01   3.5011266e-07
   2.4311179e+01   3.4994453e-07
   2.4318438e+01   3.4977794e-07
   2.4325698e+01   3.4961286e-07
   2.4332957e+01   3.4944928e-07
   2.4340216e+01   3.4928718e-07
   2.4347475e+01   3.4912653e-07
   2.4354735e+01   3.4896732e-07
   2.4361994e+01   3.4880953e-07
   2.4369253e+01   3.4865313e-07
   2.4376512e+01   3.4849811e-07
   2.4383772e+01   3.4834445e-07
   2.4391031e+01   3.4819213e-07
   2.4398290e+01   3.4804112e-07
   2.4405549e+01   3.4789142e-07
   2.4412809e+01   3.4774299e-07
   2.4420068e+01   3.4759581e-07
   2.4427327e+01   3.4744988e-07
   2.4434586e+01   3.4730517e-07
   2.4441845e+01   3.4716165e-07
   2.4449105e+01   3.4701931e-07
   2.4456364e+01   3.4687814e-07
   2.4463623e+01   3.4673810e-07
   2.4470882e+01   3.4659918e-07
   2.4478142e+01   3.4646136e-07
   2.4485401e+01   3.4632462e-07
   2.4492660e+01   3.4618894e-07
   2.4499919e+01   3.4605430e-07
   2.4507179e+01   3.4592068e-07
   2.4514438e+01   3.4578806e-07
   2.4521697e+01   3.4565642e-07
   2.4528956e+01   3.4552574e-07
   2.4536216e+01   3.4539600e-07
   2.4543475e+01   3.4526718e-07
   2.4550734e+01   3.4513926e-07
   2.4557993e+01   3.4501223e-07
   2.4565252e+01   3.4488605e-07
   2.4572512e+01   3.4476072e-07
   2.4579771e+01   3.4463621e-07
   2.4587030e+01   3.4451250e-07
   2.4594289e+01   3.4438957e-07
   2.4601549e+01   3.4426740e-07
   2.4608808e+01   3.4414598e-07
   2.4616067e+01   3.4402528e-07
   2.4623326e+01   3.4390528e-07
   2.4630586e+01   3.4378596e-07
   2.4637845e+01   3.4366731e-07
   2.4645104e+01   3.4354930e-07
   2.4652363e+01   3.4343191e-07
   2.4659623e+01   3.4331513e-07
   2.4666882e+01   3.4319893e-07
   2.4674141e+01   3.4308329e-07
   2.4681400e+01   3.4296820e-07
   2.4688659e+01   3.4285363e-07
   2.4695919e+01   3.4273956e-07
   2.4703178e+01   3.4262598e-07
   2.4710437e+01   3.4251287e-07
   2.4717696e+01   3.4240019e-07
   2.4724956e+01   3.4228795e-07
   2.4732215e+01   3.4217610e-07
   2.4739474e+01   3.4206465e-07
   2.4746733e+01   3.4195355e-07
   2.4753993e+01   3.4184281e-07
   2.4761252e+01   3.4173239e-07
   2.4768511e+01   3.4162227e-07
   2.4775770e+01   3.4151244e-07
   2.4783030e+01   3.4140287e-07
   2.4790289e+01   3.4129356e-07
   2.4797548e+01   3.4118446e-07
   2.4804807e+01   3.4107558e-07
   2.4812066e+01   3.4096688e-07
   2.4819326e+01   3.4085835e-07
   2.4826585e+01   3.4074996e-07
   2.4833844e+01   3.4064170e-07
   2.4841103e+01   3.4053355e-07
   2.4848363e+01   3.4042548e-07
   2.4855622e+01   3.4031749e-07
   2.4862881e+01   3.4020954e-07
   2.4870140e+01   3.4010161e-07
   2.4877400e+01   3.3999370e-07
   2.4884659e+01   3.3988577e-07
   2.4891918e+01   3.3977782e-07
   2.4899177e+01   3.3966981e-07
   2.4906437e+01   3.3956173e-07
   2.4913696e+01   3.3945355e-07
   2.4920955e+01   3.3934527e-07
   2.4928214e+01   3.3923686e-07
   2.4935473e+01   3.3912829e-07
   2.4942733e+01   3.3901956e-07
   2.4949992e+01   3.3891063e-07
   2.4957251e+01   3.3880149e-07
   2.4964510e+01   3.3869212e-07
   2.4971770e+01   3.3858251e-07
   2.4979029e+01   3.3847262e-07
   2.4986288e+01   3.3836244e-07
   2.4993547e+01   3.3825195e-07
   2.5000807e+01   3.3814114e-07
   2.5008066e+01   3.3802997e-07
   2.5015325e+01   3.3791844e-07
   2.5022584e+01   3.3780651e-07
   2.5029844e+01   3.3769418e-07
   2.5037103e+01   3.3758142e-07
   2.5044362e+01   3.3746821e-07
   2.5051621e+01   3.3735453e-07
   2.5058880e+01   3.3724036e-07
   2.5066140e+01   3.3712569e-07
   2.5073399e+01   3.3701048e-07
   2.5080658e+01   3.3689473e-07
   2.5087917e+01   3.3677842e-07
   2.5095177e+01   3.3666151e-07
   2.5102436e+01   3.3654400e-07
   2.5109695e+01   3.3642586e-07
   2.5116954e+01   3.3630707e-07
   2.5124214e+01   3.3618761e-07
   2.5131473e+01   3.3606747e-07
   2.5138732e+01   3.3594662e-07
   2.5145991e+01   3.3582505e-07
   2.5153251e+01   3.3570273e-07
   2.5160510e+01   3.3557964e-07
   2.5167769e+01   3.3545577e-07
   2.5175028e+01   3.3533109e-07
   2.5182287e+01   3.3520559e-07
   2.5189547e+01   3.3507924e-07
   2.5196806e+01   3.3495202e-07
   2.5204065e+01   3.3482392e-07
   2.5211324e+01   3.3469492e-07
   2.5218584e+01   3.3456499e-07
   2.5225843e+01   3.3443411e-07
   2.5233102e+01   3.3430227e-07
   2.5240361e+01   3.3416945e-07
   2.5247621e+01   3.3403562e-07
   2.5254880e+01   3.3390077e-07
   2.5262139e+01   3.3376487e-07
   2.5269398e+01   3.3362791e-07
   2.5276658e+01   3.3348987e-07
   2.5283917e+01   3.3335072e-07
   2.5291176e+01   3.3321045e-07
   2.5298435e+01   3.3306903e-07
   2.5305694e+01   3.3292646e-07
   2.5312954e+01   3.3278270e-07
   2.5320213e+01   3.3263773e-07
   2.5327472e+01   3.3249155e-07
   2.5334731e+01   3.3234412e-07
   2.5341991e+01   3.3219543e-07
   2.5349250e+01   3.3204546e-07
   2.5356509e+01   3.3189418e-07
   2.5363768e+01   3.3174159e-07
   2.5371028e+01   3.3158765e-07
   2.5378287e+01   3.3143235e-07
   2.5385546e+01   3.3127567e-07
   2.5392805e+01   3.3111759e-07
   2.5400065e+01   3.3095808e-07
   2.5407324e+01   3.3079714e-07
   2.5414583e+01   3.3063474e-07
   2.5421842e+01   3.3047085e-07
   2.5429101e+01   3.3030546e-07
   2.5436361e+01   3.3013856e-07
   2.5443620e+01   3.2997011e-07
   2.5450879e+01   3.2980011e-07
   2.5458138e+01   3.2962852e-07
   2.5465398e+01   3.2945533e-07
   2.5472657e+01   3.2928053e-07
   2.5479916e+01   3.2910408e-07
   2.5487175e+01   3.2892598e-07
   2.5494435e+01   3.2874620e-07
   2.5501694e+01   3.2856472e-07
   2.5508953e+01   3.2838152e-07
   2.5516212e+01   3.2819658e-07
   2.5523472e+01   3.2800988e-07
   2.5530731e+01   3.2782140e-07
   2.5537990e+01   3.2763113e-07
   2.5545249e+01   3.2743904e-07
   2.5552508e+01   3.2724511e-07
   2.5559768e+01   3.2704932e-07
   2.5567027e+01   3.2685165e-07
   2.5574286e+01   3.2665209e-07
   2.5581545e+01   3.2645061e-07
   2.5588805e+01   3.2624719e-07
   2.5596064e+01   3.2604182e-07
   2.5603323e+01   3.2583447e-07
   2.5610582e+01   3.2562512e-07
   2.5617842e+01   3.2541376e-07
   2.5625101e+01   3.2520036e-07
   2.5632360e+01   3.2498490e-07
   2.5639619e+01   3.2476737e-07
   2.5646879e+01   3.2454774e-07
   2.5654138e+01   3.2432600e-07
   2.5661397e+01   3.2410212e-07
   2.5668656e+01   3.2387608e-07
   2.5675915e+01   3.2364787e-07
   2.5683175e+01   3.2341747e-07
   2.5690434e+01   3.2318485e-07
   2.5697693e+01   3.2294999e-07
   2.5704952e+01   3.2271289e-07
   2.5712212e+01   3.2247350e-07
   2.5719471e+01   3.2223182e-07
   2.5726730e+01   3.2198783e-07
   2.5733989e+01   3.2174151e-07
   2.5741249e+01   3.2149282e-07
   2.5748508e+01   3.2124177e-07
   2.5755767e+01   3.2098832e-07
   2.5763026e+01   3.2073246e-07
   2.5770286e+01   3.2047417e-07
   2.5777545e+01   3.2021342e-07
   2.5784804e+01   3.1995020e-07
   2.5792063e+01   3.1968449e-07
   2.5799322e+01   3.1941626e-07
   2.5806582e+01   3.1914551e-07
   2.5813841e+01   3.1887219e-07
   2.5821100e+01   3.1859631e-07
   2.5828359e+01   3.1831784e-07
   2.5835619e+01   3.1803675e-07
   2.5842878e+01   3.1775303e-07
   2.5850137e+01   3.1746666e-07
   2.5857396e+01   3.1717762e-07
   2.5864656e+01   3.1688589e-07
   2.5871915e+01   3.1659145e-07
   2.5879174e+01   3.1629427e-07
   2.5886433e+01   3.1599435e-07
   2.5893693e+01   3.1569165e-07
   2.5900952e+01   3.1538617e-07
   2.5908211e+01   3.1507787e-07
   2.5915470e+01   3.1476674e-07
   2.5922729e+01   3.1445277e-07
   2.5929989e+01   3.1413592e-07
   2.5937248e+01   3.1381618e-07
   2.5944507e+01   3.1349354e-07
   2.5951766e+01   3.1316796e-07
   2.5959026e+01   3.1283944e-07
   2.5966285e+01   3.1250794e-07
   2.5973544e+01   3.1217346e-07
   2.5980803e+01   3.1183597e-07
   2.5988063e+01   3.1149545e-07
   2.5995322e+01   3.1115188e-07
   2.6002581e+01   3.1080524e-07
   2.6009840e+01   3.1045552e-07
   2.6017100e+01   3.1010268e-07
   2.6024359e+01   3.0974672e-07
   2.6031618e+01   3.0938762e-07
   2.6038877e+01   3.0902534e-07
   2.6046136e+01   3.0865988e-07
   2.6053396e+01   3.0829120e-07
   2.6060655e+01   3.0790919e-07
   2.6067914e+01   3.0750151e-07
   2.6075173e+01   3.0706840e-07
   2.6082433e+01   3.0661011e-07
   2.6089692e+01   3.0612691e-07
   2.6096951e+01   3.0561905e-07
   2.6104210e+01   3.0508679e-07
   2.6111470e+01   3.0453040e-07
   2.6118729e+01   3.0395012e-07
   2.6125988e+01   3.0334623e-07
   2.6133247e+01   3.0271898e-07
   2.6140507e+01   3.0206862e-07
   2.6147766e+01   3.0139543e-07
   2.6155025e+01   3.0069965e-07
   2.6162284e+01   2.9998155e-07
   2.6169543e+01   2.9924138e-07
   2.6176803e+01   2.9847941e-07
   2.6184062e+01   2.9769590e-07
   2.6191321e+01   2.9689110e-07
   2.6198580e+01   2.9606527e-07
   2.6205840e+01   2.9521868e-07
   2.6213099e+01   2.9435157e-07
   2.6220358e+01   2.9346422e-07
   2.6227617e+01   2.9255688e-07
   2.6234877e+01   2.9162981e-07
   2.6242136e+01   2.9068327e-07
   2.6249395e+01   2.8971752e-07
   2.6256654e+01   2.8873281e-07
   2.6263914e+01   2.8772941e-07
   2.6271173e+01   2.8670758e-07
   2.6278432e+01   2.8566757e-07
   2.6285691e+01   2.8460965e-07
   2.6292950e+01   2.8353407e-07
   2.6300210e+01   2.8244110e-07
   2.6307469e+01   2.8133099e-07
   2.6314728e+01   2.8020400e-07
   2.6321987e+01   2.7906039e-07
   2.6329247e+01   2.7790042e-07
   2.6336506e+01   2.7672435e-07
   2.6343765e+01   2.7553244e-07
   2.6351024e+01   2.7432495e-07
   2.6358284e+01   2.7310213e-07
   2.6365543e+01   2.7186426e-07
   2.6372802e+01   2.7061157e-07
   2.6380061e+01   2.6934435e-07
   2.6387321e+01   2.6806284e-07
   2.6394580e+01   2.6676730e-07
   2.6401839e+01   2.6545800e-07
   2.6409098e+01   2.6413519e-07
   2.6416357e+01   2.6279913e-07
   2.6423617e+01   2.6145008e-07
   2.6430876e+01   2.6008830e-07
   2.6438135e+01   2.5871405e-07
   2.6445394e+01   2.5732759e-07
   2.6452654e+01   2.5592918e-07
   2.6459913e+01   2.5451908e-07
   2.6467172e+01   2.5309754e-07
   2.6474431e+01   2.5166483e-07
   2.6481691e+01   2.5022121e-07
   2.6488950e+01   2.4876693e-07
   2.6496209e+01   2.4730225e-07
   2.6503468e+01   2.4582744e-07
   2.6510728e+01   2.4434275e-07
   2.6517987e+01   2.4284844e-07
   2.6525246e+01   2.4134477e-07
   2.6532505e+01   2.3983200e-07
   2.6539764e+01   2.3831039e-07
   2.6547024e+01   2.3678020e-07
   2.6554283e+01   2.3524169e-07
   2.6561542e+01   2.3369512e-07
   2.6568801e+01   2.3214074e-07
   2.6576061e+01   2.3057882e-07
   2.6583320e+01   2.2900962e-07
   2.6590579e+01   2.2743339e-07
   2.6597838e+01   2.2585039e-07
   2.6605098e+01   2.2426089e-07
   2.6612357e+01   2.2266514e-07
   2.6619616e+01   2.2106340e-07
   2.6626875e+01   2.1945593e-07
   2.6634135e+01   2.1784299e-07
   2.6641394e+01   2.1622484e-07
   2.6648653e+01   2.1460174e-07
   2.6655912e+01   2.1297395e-07
   2.6663171e+01   2.1134173e-07
   2.6670431e+01   2.0970533e-07
   2.6677690e+01   2.0806502e-07
   2.6684949e+01   2.0642105e-07
   2.6692208e+01   2.0477369e-07
   2.6699468e+01   2.0312319e-07
   2.6706727e+01   2.0146982e-07
   2.6713986e+01   1.9981383e-07
   2.6721245e+01   1.9815548e-07
   2.6728505e+01   1.9649503e-07
   2.6735764e+01   1.9483274e-07
   2.6743023e+01   1.9316887e-07
   2.6750282e+01   1.9150368e-07
   2.6757542e+01   1.8983742e-07
   2.6764801e+01   1.8817037e-07
   2.6772060e+01   1.8650277e-07
   2.6779319e+01   1.8483489e-07
   2.6786578e+01   1.8316698e-07
   2.6793838e+01   1.8149931e-07
   2.6801097e+01   1.7983213e-07
   2.6808356e+01   1.7816570e-07
   2.6815615e+01   1.7650029e-07
   2.6822875e+01   1.7483614e-07
   2.6830134e+01   1.7317353e-07
   2.6837393e+01   1.7151271e-07
   2.6844652e+01   1.6985394e-07
   2.6851912e+01   1.6819748e-07
   2.6859171e+01   1.6654358e-07
   2.6866430e+01   1.6489251e-07
   2.6873689e+01   1.6324453e-07
   2.6880949e+01   1.6159990e-07
   2.6888208e+01   1.5995887e-07
   2.6895467e+01   1.5832170e-07
   2.6902726e+01   1.5668866e-07
   2.6909985e+01   1.5506000e-07
   2.6917245e+01   1.5343598e-07
   2.6924504e+01   1.5181687e-07
   2.6931763e+01   1.5020291e-07
   2.6939022e+01   1.4859438e-07
   2.6946282e+01   1.4699153e-07
   2.6953541e+01   1.4539461e-07
   2.6960800e+01   1.4380389e-07
   2.6968059e+01   1.4221963e-07
   2.6975319e+01   1.4064209e-07
   2.6982578e+01   1.3907152e-07
   2.6989837e+01   1.3750819e-07
   2.6997096e+01   1.3595235e-07
   2.7004356e+01   1.3440426e-07
   2.7011615e+01   1.3286419e-07
   2.7018874e+01   1.3133239e-07
   2.7026133e+01   1.2980912e-07
   2.7033392e+01   1.2829464e-07
   2.7040652e+01   1.2678922e-07
   2.7047911e+01   1.2529310e-07
   2.7055170e+01   1.2380655e-07
   2.7062429e+01   1.2232983e-07
   2.7069689e+01   1.2086319e-07
   2.7076948e+01   1.1940690e-07
   2.7084207e+01   1.1796122e-07
   2.7091466e+01   1.1652640e-07
   2.7098726e+01   1.1510271e-07
   2.7105985e+01   1.1369040e-07
   2.7113244e+01   1.1228974e-07
   2.7120503e+01   1.1090097e-07
   2.7127763e+01   1.0952437e-07
   2.7135022e+01   1.0816019e-07
   2.7142281e+01   1.0680869e-07
   2.7149540e+01   1.0547012e-07
   2.7156799e+01   1.0414476e-07
   2.7164059e+01   1.0283285e-07
   2.7171318e+01   1.0153467e-07
   2.7178577e+01   1.0025045e-07
   2.7185836e+01   9.8980476e-08
   2.7193096e+01   9.7724994e-08
   2.7200355e+01   9.6484267e-08
   2.7207614e+01   9.5258553e-08
   2.7214873e+01   9.4048112e-08
   2.7222133e+01   9.2853203e-08
   2.7229392e+01   9.1674086e-08
   2.7236651e+01   9.0511019e-08
   2.7243910e+01   8.9364262e-08
   2.7251170e+01   8.8234075e-08
   2.7258429e+01   8.7120716e-08
   2.7265688e+01   8.6024444e-08
   2.7272947e+01   8.4945520e-08
   2.7280206e+01   8.3884203e-08
   2.7287466e+01   8.2840751e-08
   2.7294725e+01   8.1815424e-08
   2.7301984e+01   8.0808481e-08
   2.7309243e+01   7.9820181e-08
   2.7316503e+01   7.8850785e-08
   2.7323762e+01   7.7900550e-08
   2.7331021e+01   7.6969737e-08
   2.7338280e+01   7.6058605e-08
   2.7345540e+01   7.5167412e-08
   2.7352799e+01   7.4296419e-08
   2.7360058e+01   7.3445884e-08
   2.7367317e+01   7.2616067e-08
   2.7374577e+01   7.1807227e-08
   2.7381836e+01   7.1019623e-08
   2.7389095e+01   7.0253515e-08
   2.7396354e+01   6.9509162e-08
   2.7403613e+01   6.8786823e-08
   2.7410873e+01   6.8086757e-08
   2.7418132e+01   6.7409225e-08
   2.7425391e+01   6.6754484e-08
   2.7432650e+01   6.6122794e-08
   2.7439910e+01   6.5514415e-08
   2.7447169e+01   6.4929606e-08
   2.7454428e+01   6.4368626e-08
   2.7461687e+01   6.3831735e-08
   2.7468947e+01   6.3319191e-08
   2.7476206e+01   6.2831254e-08
   2.7483465e+01   6.2368184e-08
   2.7490724e+01   6.1930239e-08
   2.7497984e+01   6.1517679e-08
   2.7505243e+01   6.1130763e-08
   2.7512502e+01   6.0769750e-08
   2.7519761e+01   6.0434901e-08
   2.7527020e+01   6.0126473e-08
   2.7534280e+01   5.9844726e-08
   2.7541539e+01   5.9589920e-08
   2.7548798e+01   5.9362314e-08
   2.7556057e+01   5.9162166e-08
   2.7563317e+01   5.8989738e-08
   2.7570576e+01   5.8845286e-08
   2.7577835e+01   5.8729072e-08
   2.7585094e+01   5.8641354e-08
   2.7592354e+01   5.8582392e-08
   2.7599613e+01   5.8552444e-08
   2.7606872e+01   5.8551770e-08
   2.7614131e+01   5.8580630e-08
   2.7621391e+01   5.8639282e-08
   2.7628650e+01   5.8727987e-08
   2.7635909e+01   5.8847002e-08
   2.7643168e+01   5.8996588e-08
   2.7650427e+01   5.9177004e-08
   2.7657687e+01   5.9388509e-08
   2.7664946e+01   5.9631362e-08
   2.7672205e+01   5.9905822e-08
   2.7679464e+01   6.0212150e-08
   2.7686724e+01   6.0550604e-08
   2.7693983e+01   6.0921443e-08
   2.7701242e+01   6.1324927e-08
   2.7708501e+01   6.1761315e-08
   2.7715761e+01   6.2230866e-08
   2.7723020e+01   6.2733840e-08
   2.7730279e+01   6.3270495e-08
   2.7737538e+01   6.3841092e-08
   2.7744798e+01   6.4445889e-08
   2.7752057e+01   6.5085146e-08
   2.7759316e+01   6.5759122e-08
   2.7766575e+01   6.6468076e-08
   2.7773834e+01   6.7212268e-08
   2.7781094e+01   6.7991957e-08
   2.7788353e+01   6.8807401e-08
   2.7795612e+01   6.9658862e-08
   2.7802871e+01   7.0546596e-08
   2.7810131e+01   7.1470865e-08
   2.7817390e+01   7.2431927e-08
   2.7824649e+01   7.3430042e-08
   2.7831908e+01   7.4465468e-08
   2.7839168e+01   7.5538465e-08
   2.7846427e+01   7.6649293e-08
   2.7853686e+01   7.7798211e-08
   2.7860945e+01   7.8985477e-08
   2.7868205e+01   8.0211352e-08
   2.7875464e+01   8.1476094e-08
   2.7882723e+01   8.2779963e-08
   2.7889982e+01   8.4123217e-08
   2.7897241e+01   8.5506118e-08
   2.7904501e+01   8.6928923e-08
   2.7911760e+01   8.8391891e-08
   2.7919019e+01   8.9895283e-08
   2.7926278e+01   9.1439358e-08
   2.7933538e+01   9.3024374e-08
   2.7940797e+01   9.4650591e-08
   2.7948056e+01   9.6318269e-08
   2.7955315e+01   9.8027666e-08
   2.7962575e+01   9.9779042e-08
   2.7969834e+01   1.0157266e-07
   2.7977093e+01   1.0340877e-07
   2.7984352e+01   1.0528764e-07
   2.7991612e+01   1.0720952e-07
   2.7998871e+01   1.0917468e-07
   2.8006130e+01   1.1118337e-07
   2.8013389e+01   1.1323586e-07
   2.8020648e+01   1.1533240e-07
   2.8027908e+01   1.1747326e-07
   2.8035167e+01   1.1965868e-07
   2.8042426e+01   1.2188894e-07
   2.8049685e+01   1.2416429e-07
   2.8056945e+01   1.2649383e-07
   2.8064204e+01   1.2894685e-07
   2.8071463e+01   1.3153627e-07
   2.8078722e+01   1.3425993e-07
   2.8085982e+01   1.3711565e-07
   2.8093241e+01   1.4010126e-07
   2.8100500e+01   1.4321461e-07
   2.8107759e+01   1.4645351e-07
   2.8115019e+01   1.4981581e-07
   2.8122278e+01   1.5329934e-07
   2.8129537e+01   1.5690193e-07
   2.8136796e+01   1.6062140e-07
   2.8144055e+01   1.6445560e-07
   2.8151315e+01   1.6840236e-07
   2.8158574e+01   1.7245950e-07
   2.8165833e+01   1.7662487e-07
   2.8173092e+01   1.8089629e-07
   2.8180352e+01   1.8527159e-07
   2.8187611e+01   1.8974861e-07
   2.8194870e+01   1.9432518e-07
   2.8202129e+01   1.9899913e-07
   2.8209389e+01   2.0376830e-07
   2.8216648e+01   2.0863051e-07
   2.8223907e+01   2.1358360e-07
   2.8231166e+01   2.1862541e-07
   2.8238426e+01   2.2375376e-07
   2.8245685e+01   2.2896648e-07
   2.8252944e+01   2.3426141e-07
   2.8260203e+01   2.3963638e-07
   2.8267462e+01   2.4508923e-07
   2.8274722e+01   2.5061778e-07
   2.8281981e+01   2.5621987e-07
   2.8289240e+01   2.6189333e-07
   2.8296499e+01   2.6763599e-07
   2.8303759e+01   2.7344569e-07
   2.8311018e+01   2.7932026e-07
   2.8318277e+01   2.8525752e-07
   2.8325536e+01   2.9125532e-07
   2.8332796e+01   2.9731148e-07
   2.8340055e+01   3.0342383e-07
   2.8347314e+01   3.0959022e-07
   2.8354573e+01   3.1580846e-07
   2.8361833e+01   3.2207640e-07
   2.8369092e+01   3.2839187e-07
   2.8376351e+01   3.3475269e-07
   2.8383610e+01   3.4115671e-07
   2.8390869e+01   3.4760175e-07
   2.8398129e+01   3.5408564e-07
   2.8405388e+01   3.6060622e-07
   2.8412647e+01   3.6716132e-07
   2.8419906e+01   3.7374877e-07
   2.8427166e+01   3.8036641e-07
   2.8434425e+01   3.8701206e-07
   2.8441684e+01   3.9368356e-07
   2.8448943e+01   4.0037875e-07
   2.8456203e+01   4.0709545e-07
   2.8463462e+01   4.1383149e-07
   2.8470721e+01   4.2058472e-07
   2.8477980e+01   4.2735295e-07
   2.8485240e+01   4.3413403e-07
   2.8492499e+01   4.4092578e-07
   2.8499758e+01   4.4772604e-07
   2.8507017e+01   4.5453264e-07
   2.8514276e+01   4.6134341e-07
   2.8521536e+01   4.6815619e-07
   2.8528795e+01   4.7496881e-07
   2.8536054e+01   4.8177909e-07
   2.8543313e+01   4.8858488e-07
   2.8550573e+01   4.9538400e-07
   2.8557832e+01   5.0217429e-07
   2.8565091e+01   5.0895358e-07
   2.8572350e+01   5.1571970e-07
   2.8579610e+01   5.2247048e-07
   2.8586869e+01   5.2920376e-07
   2.8594128e+01   5.3591736e-07
   2.8601387e+01   5.4260913e-07
   2.8608647e+01   5.4927689e-07
   2.8615906e+01   5.5591847e-07
   2.8623165e+01   5.6253172e-07
   2.8630424e+01   5.6911445e-07
   2.8637683e+01   5.7566450e-07
   2.8644943e+01   5.8217971e-07
   2.8652202e+01   5.8865791e-07
   2.8659461e+01   5.9509692e-07
   2.8666720e+01   6.0149459e-07
   2.8673980e+01   6.0784874e-07
   2.8681239e+01   6.1415721e-07
   2.8688498e+01   6.2041783e-07
   2.8695757e+01   6.2662842e-07
   2.8703017e+01   6.3278683e-07
   2.8710276e+01   6.3889089e-07
   2.8717535e+01   6.4493842e-07
   2.8724794e+01   6.5092727e-07
   2.8732054e+01   6.5685526e-07
   2.8739313e+01   6.6272022e-07
   2.8746572e+01   6.6851999e-07
   2.8753831e+01   6.7425240e-07
   2.8761090e+01   6.7991528e-07
   2.8768350e+01   6.8550646e-07
   2.8775609e+01   6.9102378e-07
   2.8782868e+01   6.9646507e-07
   2.8790127e+01   7.0182817e-07
   2.8797387e+01   7.0711089e-07
   2.8804646e+01   7.1231109e-07
   2.8811905e+01   7.1742658e-07
   2.8819164e+01   7.2245520e-07
   2.8826424e+01   7.2739478e-07
   2.8833683e+01   7.3224316e-07
   2.8840942e+01   7.3699817e-07
   2.8848201e+01   7.4165763e-07
   2.8855461e+01   7.4621939e-07
   2.8862720e+01   7.5068128e-07
   2.8869979e+01   7.5504112e-07
   2.8877238e+01   7.5929675e-07
   2.8884497e+01   7.6344600e-07
   2.8891757e+01   7.6748671e-07
   2.8899016e+01   7.7141670e-07
   2.8906275e+01   7.7523381e-07
   2.8913534e+01   7.7893587e-07
   2.8920794e+01   7.8252072e-07
   2.8928053e+01   7.8598618e-07
   2.8935312e+01   7.8933009e-07
   2.8942571e+01   7.9255028e-07
   2.8949831e+01   7.9564458e-07
   2.8957090e+01   7.9861083e-07
   2.8964349e+01   8.0144686e-07
   2.8971608e+01   8.0415049e-07
   2.8978868e+01   8.0671957e-07
   2.8986127e+01   8.0915192e-07
   2.8993386e+01   8.1144538e-07
   2.9000645e+01   8.1359777e-07
   2.9007905e+01   8.1560694e-07
   2.9015164e+01   8.1747072e-07
   2.9022423e+01   8.1918692e-07
   2.9029682e+01   8.2075340e-07
   2.9036941e+01   8.2216798e-07
   2.9044201e+01   8.2342849e-07
   2.9051460e+01   8.2453277e-07
   2.9058719e+01   8.2547864e-07
   2.9065978e+01   8.2626394e-07
   2.9073238e+01   8.2688651e-07
   2.9080497e+01   8.2734417e-07
   2.9087756e+01   8.2763476e-07
   2.9095015e+01   8.2775611e-07
   2.9102275e+01   8.2770605e-07
   2.9109534e+01   8.2748241e-07
   2.9116793e+01   8.2708303e-07
   2.9124052e+01   8.2650574e-07
   2.9131312e+01   8.2574837e-07
   2.9138571e+01   8.2480875e-07
   2.9145830e+01   8.2368472e-07
   2.9153089e+01   8.2237411e-07
   2.9160348e+01   8.2087475e-07
   2.9167608e+01   8.1918447e-07
   2.9174867e+01   8.1730110e-07
   2.9182126e+01   8.1522249e-07
   2.9189385e+01   8.1294645e-07
   2.9196645e+01   8.1047082e-07
   2.9203904e+01   8.0779344e-07
   2.9211163e+01   8.0491214e-07
   2.9218422e+01   8.0182475e-07
   2.9225682e+01   7.9852909e-07
   2.9232941e+01   7.9502301e-07
   2.9240200e+01   7.9130434e-07
   2.9247459e+01   7.8737091e-07
   2.9254719e+01   7.8322054e-07
   2.9261978e+01   7.7885108e-07
   2.9269237e+01   7.7426036e-07
   2.9276496e+01   7.6944620e-07
   2.9283755e+01   7.6440644e-07
   2.9291015e+01   7.5913892e-07
   2.9298274e+01   7.5364146e-07
   2.9305533e+01   7.4791190e-07
   2.9312792e+01   7.4194806e-07
   2.9320052e+01   7.3574779e-07
   2.9327311e+01   7.2930892e-07
   2.9334570e+01   7.2262926e-07
   2.9341829e+01   7.1570667e-07
   2.9349089e+01   7.0853897e-07
   2.9356348e+01   7.0112400e-07
   2.9363607e+01   6.9345958e-07
   2.9370866e+01   6.8554354e-07
   2.9378126e+01   6.7737373e-07
   2.9385385e+01   6.6894766e-07
   2.9392644e+01   6.6026233e-07
   2.9399903e+01   6.5132226e-07
   2.9407162e+01   6.4213342e-07
   2.9414422e+01   6.3270177e-07
   2.9421681e+01   6.2303327e-07
   2.9428940e+01   6.1313391e-07
   2.9436199e+01   6.0300963e-07
   2.9443459e+01   5.9266641e-07
   2.9450718e+01   5.8211021e-07
   2.9457977e+01   5.7134700e-07
   2.9465236e+01   5.6038274e-07
   2.9472496e+01   5.4922340e-07
   2.9479755e+01   5.3787495e-07
   2.9487014e+01   5.2634336e-07
   2.9494273e+01   5.1463458e-07
   2.9501533e+01   5.0275459e-07
   2.9508792e+01   4.9070935e-07
   2.9516051e+01   4.7850482e-07
   2.9523310e+01   4.6614698e-07
   2.9530569e+01   4.5364179e-07
   2.9537829e+01   4.4099522e-07
   2.9545088e+01   4.2821323e-07
   2.9552347e+01   4.1530178e-07
   2.9559606e+01   4.0226685e-07
   2.9566866e+01   3.8911440e-07
   2.9574125e+01   3.7585039e-07
   2.9581384e+01   3.6248080e-07
   2.9588643e+01   3.4901159e-07
   2.9595903e+01   3.3544872e-07
   2.9603162e+01   3.2179816e-07
   2.9610421e+01   3.0806587e-07
   2.9617680e+01   2.9425783e-07
   2.9624940e+01   2.8038000e-07
   2.9632199e+01   2.6643835e-07
   2.9639458e+01   2.5243883e-07
   2.9646717e+01   2.3838742e-07
   2.9653976e+01   2.2429009e-07
   2.9661236e+01   2.1015279e-07
   2.9668495e+01   1.9598150e-07
   2.9675754e+01   1.8178218e-07
   2.9683013e+01   1.6756080e-07
   2.9690273e+01   1.5332332e-07
   2.9697532e+01   1.3907572e-07
   2.9704791e+01   1.2482395e-07
   2.9712050e+01   1.1057398e-07
   2.9719310e+01   9.6331776e-08
   2.9726569e+01   8.2103310e-08
   2.9733828e+01   6.7894544e-08
   2.9741087e+01   5.3711444e-08
   2.9748347e+01   3.9559976e-08
   2.9755606e+01   2.5446108e-08
   2.9762865e+01   1.1375804e-08
   2.9770124e+01  -2.6449686e-09
   2.9777383e+01  -1.6610245e-08
   2.9784643e+01  -3.0514057e-08
   2.9791902e+01  -4.4350441e-08
   2.9799161e+01  -5.8113429e-08
   2.9806420e+01  -7.1797056e-08
   2.9813680e+01  -8.5395355e-08
   2.9820939e+01  -9.8902361e-08
   2.9828198e+01  -1.1231211e-07
   2.9835457e+01  -1.2561863e-07
   2.9842717e+01  -1.3881596e-07
   2.9849976e+01  -1.5189813e-07
   2.9857235e+01  -1.6485917e-07
   2.9864494e+01  -1.7769313e-07
   2.9871754e+01  -1.9039403e-07
   2.9879013e+01  -2.0295591e-07
   2.9886272e+01  -2.1537279e-07
   2.9893531e+01  -2.2763873e-07
   2.9900790e+01  -2.3974774e-07
   2.9908050e+01  -2.5169387e-07
   2.9915309e+01  -2.6347114e-07
   2.9922568e+01  -2.7507360e-07
   2.9929827e+01  -2.8649527e-07
   2.9937087e+01  -2.9773018e-07
   2.9944346e+01  -3.0877238e-07
   2.9951605e+01  -3.1961590e-07
   2.9958864e+01  -3.3025477e-07
   2.9966124e+01  -3.4068302e-07
   2.9973383e+01  -3.5089469e-07
   2.9980642e+01  -3.6088382e-07
   2.9987901e+01  -3.7064442e-07
   2.9995161e+01  -3.8017055e-07
   3.0002420e+01  -3.8945623e-07
   3.0009679e+01  -3.9849551e-07
   3.0016938e+01  -4.0728240e-07
   3.0024197e+01  -4.1581094e-07
   3.0031457e+01  -4.2407518e-07
   3.0038716e+01  -4.3206914e-07
   3.0045975e+01  -4.3978686e-07
   3.0053234e+01  -4.4722237e-07
   3.0060494e+01  -4.5436970e-07
   3.0067753e+01  -4.6122289e-07
   3.0075012e+01  -4.6777598e-07
   3.0082271e+01  -4.7402299e-07
   3.0089531e+01  -4.7995796e-07
   3.0096790e+01  -4.8557493e-07
   3.0104049e+01  -4.9086793e-07
   3.0111308e+01  -4.9583098e-07
   3.0118568e+01  -5.0045814e-07
   3.0125827e+01  -5.0474342e-07
   3.0133086e+01  -5.0868087e-07
   3.0140345e+01  -5.1226452e-07
   3.0147604e+01  -5.1548839e-07
   3.0154864e+01  -5.1834654e-07
   3.0162123e+01  -5.2083298e-07
   3.0169382e+01  -5.2294176e-07
   3.0176641e+01  -5.2466690e-07
   3.0183901e+01  -5.2600245e-07
   3.0191160e+01  -5.2694243e-07
   3.0198419e+01  -5.2748088e-07
   3.0205678e+01  -5.2761183e-07
   3.0212938e+01  -5.2732932e-07
   3.0220197e+01  -5.2662738e-07
   3.0227456e+01  -5.2550005e-07
   3.0234715e+01  -5.2394135e-07
   3.0241975e+01  -5.2194533e-07
   3.0249234e+01  -5.1950601e-07
   3.0256493e+01  -5.1661743e-07
   3.0263752e+01  -5.1327363e-07
   3.0271011e+01  -5.0946863e-07
   3.0278271e+01  -5.0519648e-07
   3.0285530e+01  -5.0045120e-07
   3.0292789e+01  -4.9522684e-07
   3.0300048e+01  -4.8951741e-07
   3.0307308e+01  -4.8331697e-07
   3.0314567e+01  -4.7661953e-07
   3.0321826e+01  -4.6941914e-07
   3.0329085e+01  -4.6170983e-07
   3.0336345e+01  -4.5348564e-07
   3.0343604e+01  -4.4474059e-07
   3.0350863e+01  -4.3546872e-07
   3.0358122e+01  -4.2566406e-07
   3.0365382e+01  -4.1532066e-07
   3.0372641e+01  -4.0443254e-07
   3.0379900e+01  -3.9299373e-07
   3.0387159e+01  -3.8099827e-07
   3.0394418e+01  -3.6849269e-07
   3.0401678e+01  -3.5554717e-07
   3.0408937e+01  -3.4217189e-07
   3.0416196e+01  -3.2837685e-07
   3.0423455e+01  -3.1417202e-07
   3.0430715e+01  -2.9956739e-07
   3.0437974e+01  -2.8457294e-07
   3.0445233e+01  -2.6919865e-07
   3.0452492e+01  -2.5345451e-07
   3.0459752e+01  -2.3735051e-07
   3.0467011e+01  -2.2089662e-07
   3.0474270e+01  -2.0410284e-07
   3.0481529e+01  -1.8697913e-07
   3.0488789e+01  -1.6953550e-07
   3.0496048e+01  -1.5178191e-07
   3.0503307e+01  -1.3372836e-07
   3.0510566e+01  -1.1538483e-07
   3.0517825e+01  -9.6761294e-08
   3.0525085e+01  -7.7867747e-08
   3.0532344e+01  -5.8714169e-08
   3.0539603e+01  -3.9310544e-08
   3.0546862e+01  -1.9666854e-08
   3.0554122e+01   2.0691554e-10
   3.0561381e+01   2.0300782e-08
   3.0568640e+01   4.0604761e-08
   3.0575899e+01   6.1108870e-08
   3.0583159e+01   8.1803125e-08
   3.0590418e+01   1.0267754e-07
   3.0597677e+01   1.2372214e-07
   3.0604936e+01   1.4492693e-07
   3.0612196e+01   1.6628193e-07
   3.0619455e+01   1.8777716e-07
   3.0626714e+01   2.0940263e-07
   3.0633973e+01   2.3114837e-07
   3.0641232e+01   2.5300438e-07
   3.0648492e+01   2.7496068e-07
   3.0655751e+01   2.9700730e-07
   3.0663010e+01   3.1913424e-07
   3.0670269e+01   3.4133152e-07
   3.0677529e+01   3.6358916e-07
   3.0684788e+01   3.8589718e-07
   3.0692047e+01   4.0824559e-07
   3.0699306e+01   4.3062440e-07
   3.0706566e+01   4.5302364e-07
   3.0713825e+01   4.7543333e-07
   3.0721084e+01   4.9784346e-07
   3.0728343e+01   5.2024408e-07
   3.0735603e+01   5.4262518e-07
   3.0742862e+01   5.6497678e-07
   3.0750121e+01   5.8728892e-07
   3.0757380e+01   6.0955158e-07
   3.0764639e+01   6.3175481e-07
   3.0771899e+01   6.5388861e-07
   3.0779158e+01   6.7594299e-07
   3.0786417e+01   6.9790798e-07
   3.0793676e+01   7.1977359e-07
   3.0800936e+01   7.4152984e-07
   3.0808195e+01   7.6316674e-07
   3.0815454e+01   7.8467431e-07
   3.0822713e+01   8.0604257e-07
   3.0829973e+01   8.2726153e-07
   3.0837232e+01   8.4832121e-07
   3.0844491e+01   8.6921162e-07
   3.0851750e+01   8.8992279e-07
   3.0859010e+01   9.1044473e-07
   3.0866269e+01   9.3076745e-07
   3.0873528e+01   9.5088097e-07
   3.0880787e+01   9.7077531e-07
   3.0888046e+01   9.9044048e-07
   3.0895306e+01   1.0098665e-06
   3.0902565e+01   1.0290434e-06
   3.0909824e+01   1.0479612e-06
   3.0917083e+01   1.0666098e-06
   3.0924343e+01   1.0849794e-06
   3.0931602e+01   1.1030599e-06
   3.0938861e+01   1.1208414e-06
   3.0946120e+01   1.1383138e-06
   3.0953380e+01   1.1554673e-06
   3.0960639e+01   1.1722917e-06
   3.0967898e+01   1.1887771e-06
   3.0975157e+01   1.2049136e-06
   3.0982417e+01   1.2206911e-06
   3.0989676e+01   1.2360996e-06
   3.0996935e+01   1.2511293e-06
   3.1004194e+01   1.2657700e-06
   3.1011453e+01   1.2800119e-06
   3.1018713e+01   1.2938449e-06
   3.1025972e+01   1.3072590e-06
   3.1033231e+01   1.3202443e-06
   3.1040490e+01   1.3327907e-06
   3.1047750e+01   1.3448884e-06
   3.1055009e+01   1.3565273e-06
   3.1062268e+01   1.3676974e-06
   3.1069527e+01   1.3783887e-06
   3.1076787e+01   1.3885913e-06
   3.1084046e+01   1.3982952e-06
   3.1091305e+01   1.4074904e-06
   3.1098564e+01   1.4161669e-06
   3.1105824e+01   1.4243147e-06
   3.1113083e+01   1.4319238e-06
   3.1120342e+01   1.4389843e-06
   3.1127601e+01   1.4454862e-06
   3.1134860e+01   1.4514195e-06
   3.1142120e+01   1.4567742e-06
   3.1149379e+01   1.4615403e-06
   3.1156638e+01   1.4657078e-06
   3.1163897e+01   1.4692668e-06
   3.1171157e+01   1.4722073e-06
   3.1178416e+01   1.4745192e-06
   3.1185675e+01   1.4761927e-06
   3.1192934e+01   1.4772177e-06
   3.1200194e+01   1.4775842e-06
   3.1207453e+01   1.4772823e-06
   3.1214712e+01   1.4763019e-06
   3.1221971e+01   1.4746332e-06
   3.1229231e+01   1.4722660e-06
   3.1236490e+01   1.4691905e-06
   3.1243749e+01   1.4653966e-06
   3.1251008e+01   1.4608743e-06
   3.1258267e+01   1.4556138e-06
   3.1265527e+01   1.4496049e-06
   3.1272786e+01   1.4428377e-06
   3.1280045e+01   1.4353022e-06
   3.1287304e+01   1.4269885e-06
   3.1294564e+01   1.4178865e-06
   3.1301823e+01   1.4079863e-06
   3.1309082e+01   1.3972778e-06
   3.1316341e+01   1.3857512e-06
   3.1323601e+01   1.3733964e-06
   3.1330860e+01   1.3602034e-06
   3.1338119e+01   1.3461623e-06
   3.1345378e+01   1.3312630e-06
   3.1352638e+01   1.3154956e-06
   3.1359897e+01   1.2988501e-06
   3.1367156e+01   1.2813166e-06
   3.1374415e+01   1.2628849e-06
   3.1381674e+01   1.2435452e-06
   3.1388934e+01   1.2232875e-06
   3.1396193e+01   1.2021146e-06
   3.1403452e+01   1.1801015e-06
   3.1410711e+01   1.1572779e-06
   3.1417971e+01   1.1336626e-06
   3.1425230e+01   1.1092746e-06
   3.1432489e+01   1.0841327e-06
   3.1439748e+01   1.0582559e-06
   3.1447008e+01   1.0316630e-06
   3.1454267e+01   1.0043730e-06
   3.1461526e+01   9.7640472e-07
   3.1468785e+01   9.4777709e-07
   3.1476045e+01   9.1850901e-07
   3.1483304e+01   8.8861938e-07
   3.1490563e+01   8.5812711e-07
   3.1497822e+01   8.2705109e-07
   3.1505081e+01   7.9541022e-07
   3.1512341e+01   7.6322341e-07
   3.1519600e+01   7.3050956e-07
   3.1526859e+01   6.9728756e-07
   3.1534118e+01   6.6357632e-07
   3.1541378e+01   6.2939474e-07
   3.1548637e+01   5.9476172e-07
   3.1555896e+01   5.5969616e-07
   3.1563155e+01   5.2421697e-07
   3.1570415e+01   4.8834303e-07
   3.1577674e+01   4.5209326e-07
   3.1584933e+01   4.1548654e-07
   3.1592192e+01   3.7854180e-07
   3.1599452e+01   3.4127792e-07
   3.1606711e+01   3.0371380e-07
   3.1613970e+01   2.6586836e-07
   3.1621229e+01   2.2776048e-07
   3.1628488e+01   1.8940906e-07
   3.1635748e+01   1.5083302e-07
   3.1643007e+01   1.1205125e-07
   3.1650266e+01   7.3082644e-08
   3.1657525e+01   3.3946113e-08
   3.1664785e+01  -5.3394465e-09
   3.1672044e+01  -4.4755132e-08
   3.1679303e+01  -8.4282045e-08
   3.1686562e+01  -1.2390128e-07
   3.1693822e+01  -1.6359394e-07
   3.1701081e+01  -2.0334113e-07
   3.1708340e+01  -2.4312394e-07
   3.1715599e+01  -2.8292347e-07
   3.1722859e+01  -3.2272082e-07
   3.1730118e+01  -3.6249710e-07
   3.1737377e+01  -4.0223339e-07
   3.1744636e+01  -4.4191080e-07
   3.1751895e+01  -4.8151043e-07
   3.1759155e+01  -5.2101338e-07
   3.1766414e+01  -5.6040074e-07
   3.1773673e+01  -5.9965362e-07
   3.1780932e+01  -6.3875312e-07
   3.1788192e+01  -6.7768033e-07
   3.1795451e+01  -7.1641635e-07
   3.1802710e+01  -7.5494229e-07
   3.1809969e+01  -7.9323924e-07
   3.1817229e+01  -8.3128830e-07
   3.1824488e+01  -8.6907057e-07
   3.1831747e+01  -9.0656715e-07
   3.1839006e+01  -9.4375913e-07
   3.1846266e+01  -9.8062763e-07
   3.1853525e+01  -1.0171537e-06
   3.1860784e+01  -1.0533185e-06
   3.1868043e+01  -1.0891032e-06
   3.1875302e+01  -1.1244887e-06
   3.1882562e+01  -1.1594562e-06
   3.1889821e+01  -1.1939868e-06
   3.1897080e+01  -1.2280617e-06
   3.1904339e+01  -1.2616618e-06
   3.1911599e+01  -1.2947683e-06
   3.1918858e+01  -1.3273624e-06
   3.1926117e+01  -1.3594250e-06
   3.1933376e+01  -1.3909373e-06
   3.1940636e+01  -1.4218804e-06
   3.1947895e+01  -1.4522355e-06
   3.1955154e+01  -1.4819835e-06
   3.1962413e+01  -1.5111056e-06
   3.1969673e+01  -1.5395829e-06
   3.1976932e+01  -1.5673965e-06
   3.1984191e+01  -1.5945275e-06
   3.1991450e+01  -1.6209570e-06
   3.1998709e+01  -1.6466661e-06
   3.2005969e+01  -1.6716359e-06
   3.2013228e+01  -1.6958474e-06
   3.2020487e+01  -1.7192819e-06
   3.2027746e+01  -1.7419203e-06
   3.2035006e+01  -1.7637438e-06
   3.2042265e+01  -1.7847335e-06
   3.2049524e+01  -1.8048705e-06
   3.2056783e+01  -1.8241359e-06
   3.2064043e+01  -1.8425108e-06
   3.2071302e+01  -1.8599762e-06
   3.2078561e+01  -1.8765134e-06
   3.2085820e+01  -1.8921033e-06
   3.2093080e+01  -1.9067271e-06
   3.2100339e+01  -1.9203659e-06
   3.2107598e+01  -1.9330007e-06
   3.2114857e+01  -1.9446128e-06
   3.2122116e+01  -1.9551831e-06
   3.2129376e+01  -1.9646928e-06
   3.2136635e+01  -1.9731229e-06
   3.2143894e+01  -1.9804547e-06
   3.2151153e+01  -1.9866691e-06
   3.2158413e+01  -1.9917473e-06
   3.2165672e+01  -1.9956703e-06
   3.2172931e+01  -1.9984194e-06
   3.2180190e+01  -1.9999755e-06
   3.2187450e+01  -2.0003198e-06
   3.2194709e+01  -1.9994333e-06
   3.2201968e+01  -1.9972972e-06
   3.2209227e+01  -1.9938926e-06
   3.2216487e+01  -1.9892006e-06
   3.2223746e+01  -1.9832022e-06
   3.2231005e+01  -1.9758786e-06
   3.2238264e+01  -1.9672108e-06
   3.2245523e+01  -1.9571800e-06
   3.2252783e+01  -1.9457673e-06
   3.2260042e+01  -1.9329538e-06
   3.2267301e+01  -1.9187205e-06
   3.2274560e+01  -1.9030485e-06
   3.2281820e+01  -1.8859191e-06
   3.2289079e+01  -1.8673131e-06
   3.2296338e+01  -1.8472119e-06
   3.2303597e+01  -1.8255964e-06
   3.2310857e+01  -1.8024478e-06
   3.2318116e+01  -1.7777471e-06
   3.2325375e+01  -1.7514754e-06
   3.2332634e+01  -1.7236140e-06
   3.2339894e+01  -1.6941438e-06
   3.2347153e+01  -1.6630459e-06
   3.2354412e+01  -1.6303015e-06
   3.2361671e+01  -1.5958916e-06
   3.2368930e+01  -1.5597974e-06
   3.2376190e+01  -1.5221143e-06
   3.2383449e+01  -1.4835630e-06
   3.2390708e+01  -1.4442939e-06
   3.2397967e+01  -1.4043323e-06
   3.2405227e+01  -1.3637036e-06
   3.2412486e+01  -1.3224332e-06
   3.2419745e+01  -1.2805464e-06
   3.2427004e+01  -1.2380687e-06
   3.2434264e+01  -1.1950254e-06
   3.2441523e+01  -1.1514418e-06
   3.2448782e+01  -1.1073435e-06
   3.2456041e+01  -1.0627557e-06
   3.2463301e+01  -1.0177039e-06
   3.2470560e+01  -9.7221335e-07
   3.2477819e+01  -9.2630951e-07
   3.2485078e+01  -8.8001773e-07
   3.2492337e+01  -8.3336340e-07
   3.2499597e+01  -7.8637189e-07
   3.2506856e+01  -7.3906859e-07
   3.2514115e+01  -6.9147887e-07
   3.2521374e+01  -6.4362811e-07
   3.2528634e+01  -5.9554169e-07
   3.2535893e+01  -5.4724499e-07
   3.2543152e+01  -4.9876338e-07
   3.2550411e+01  -4.5012224e-07
   3.2557671e+01  -4.0134696e-07
   3.2564930e+01  -3.5246291e-07
   3.2572189e+01  -3.0349547e-07
   3.2579448e+01  -2.5447002e-07
   3.2586708e+01  -2.0541194e-07
   3.2593967e+01  -1.5634660e-07
   3.2601226e+01  -1.0729938e-07
   3.2608485e+01  -5.8295669e-08
   3.2615744e+01  -9.3608359e-09
   3.2623004e+01   3.9479738e-08
   3.2630263e+01   8.8200674e-08
   3.2637522e+01   1.3677659e-07
   3.2644781e+01   1.8518212e-07
   3.2652041e+01   2.3339187e-07
   3.2659300e+01   2.8138047e-07
   3.2666559e+01   3.2912254e-07
   3.2673818e+01   3.7659270e-07
   3.2681078e+01   4.2376558e-07
   3.2688337e+01   4.7061579e-07
   3.2695596e+01   5.1711795e-07
   3.2702855e+01   5.6324670e-07
   3.2710115e+01   6.0897664e-07
   3.2717374e+01   6.5428240e-07
   3.2724633e+01   6.9913861e-07
   3.2731892e+01   7.4351987e-07
   3.2739151e+01   7.8740083e-07
   3.2746411e+01   8.3075609e-07
   3.2753670e+01   8.7356028e-07
   3.2760929e+01   9.1578801e-07
   3.2768188e+01   9.5741392e-07
   3.2775448e+01   9.9841263e-07
   3.2782707e+01   1.0387587e-06
   3.2789966e+01   1.0784269e-06
   3.2797225e+01   1.1173917e-06
   3.2804485e+01   1.1556278e-06
   3.2811744e+01   1.1931098e-06
   3.2819003e+01   1.2298123e-06
   3.2826262e+01   1.2657099e-06
   3.2833522e+01   1.3007774e-06
   3.2840781e+01   1.3349892e-06
   3.2848040e+01   1.3683200e-06
   3.2855299e+01   1.4007444e-06
   3.2862558e+01   1.4322371e-06
   3.2869818e+01   1.4627727e-06
   3.2877077e+01   1.4923257e-06
   3.2884336e+01   1.5208709e-06
   3.2891595e+01   1.5483828e-06
   3.2898855e+01   1.5748361e-06
   3.2906114e+01   1.6002053e-06
   3.2913373e+01   1.6244652e-06
   3.2920632e+01   1.6475903e-06
   3.2927892e+01   1.6695552e-06
   3.2935151e+01   1.6903346e-06
   3.2942410e+01   1.7099031e-06
   3.2949669e+01   1.7282352e-06
   3.2956929e+01   1.7453057e-06
   3.2964188e+01   1.7610892e-06
   3.2971447e+01   1.7755603e-06
   3.2978706e+01   1.7886935e-06
   3.2985965e+01   1.8004635e-06
   3.2993225e+01   1.8108450e-06
   3.3000484e+01   1.8198126e-06
   3.3007743e+01   1.8273408e-06
   3.3015002e+01   1.8334043e-06
   3.3022262e+01   1.8379778e-06
   3.3029521e+01   1.8410358e-06
   3.3036780e+01   1.8425530e-06
   3.3044039e+01   1.8425039e-06
   3.3051299e+01   1.8408633e-06
   3.3058558e+01   1.8376057e-06
   3.3065817e+01   1.8327058e-06
   3.3073076e+01   1.8261381e-06
   3.3080336e+01   1.8178773e-06
   3.3087595e+01   1.8078981e-06
   3.3094854e+01   1.7961749e-06
   3.3102113e+01   1.7826826e-06
   3.3109372e+01   1.7673956e-06
   3.3116632e+01   1.7502887e-06
   3.3123891e+01   1.7313363e-06
   3.3131150e+01   1.7105132e-06
   3.3138409e+01   1.6877940e-06
   3.3145669e+01   1.6631533e-06
   3.3152928e+01   1.6365656e-06
   3.3160187e+01   1.6080057e-06
   3.3167446e+01   1.5775391e-06
   3.3174706e+01   1.5462913e-06
   3.3181965e+01   1.5146197e-06
   3.3189224e+01   1.4825433e-06
   3.3196483e+01   1.4500811e-06
   3.3203743e+01   1.4172522e-06
   3.3211002e+01   1.3840756e-06
   3.3218261e+01   1.3505704e-06
   3.3225520e+01   1.3167555e-06
   3.3232779e+01   1.2826500e-06
   3.3240039e+01   1.2482730e-06
   3.3247298e+01   1.2136435e-06
   3.3254557e+01   1.1787804e-06
   3.3261816e+01   1.1437028e-06
   3.3269076e+01   1.1084299e-06
   3.3276335e+01   1.0729805e-06
   3.3283594e+01   1.0373737e-06
   3.3290853e+01   1.0016286e-06
   3.3298113e+01   9.6576412e-07
   3.3305372e+01   9.2979939e-07
   3.3312631e+01   8.9375340e-07
   3.3319890e+01   8.5764518e-07
   3.3327150e+01   8.2149377e-07
   3.3334409e+01   7.8531819e-07
   3.3341668e+01   7.4913748e-07
   3.3348927e+01   7.1297066e-07
   3.3356186e+01   6.7683677e-07
   3.3363446e+01   6.4075484e-07
   3.3370705e+01   6.0474390e-07
   3.3377964e+01   5.6882298e-07
   3.3385223e+01   5.3301111e-07
   3.3392483e+01   4.9732732e-07
   3.3399742e+01   4.6179065e-07
   3.3407001e+01   4.2642011e-07
   3.3414260e+01   3.9123476e-07
   3.3421520e+01   3.5625360e-07
   3.3428779e+01   3.2149569e-07
   3.3436038e+01   2.8698004e-07
   3.3443297e+01   2.5272568e-07
   3.3450557e+01   2.1875166e-07
   3.3457816e+01   1.8507699e-07
   3.3465075e+01   1.5172072e-07
   3.3472334e+01   1.1870186e-07
   3.3479593e+01   8.6039459e-08
   3.3486853e+01   5.3752539e-08
   3.3494112e+01   2.1860132e-08
   3.3501371e+01  -9.6187311e-09
   3.3508630e+01  -4.0665019e-08
   3.3515890e+01  -7.1259701e-08
   3.3523149e+01  -1.0138375e-07
   3.3530408e+01  -1.3101812e-07
   3.3537667e+01  -1.6014380e-07
   3.3544927e+01  -1.8874175e-07
   3.3552186e+01  -2.1679294e-07
   3.3559445e+01  -2.4427834e-07
   3.3566704e+01  -2.7117892e-07
   3.3573964e+01  -2.9747565e-07
   3.3581223e+01  -3.2314949e-07
   3.3588482e+01  -3.4818141e-07
   3.3595741e+01  -3.7255240e-07
   3.3603000e+01  -3.9624340e-07
   3.3610260e+01  -4.1923540e-07
   3.3617519e+01  -4.4150937e-07
   3.3624778e+01  -4.6304626e-07
   3.3632037e+01  -4.8382706e-07
   3.3639297e+01  -5.0383272e-07
   3.3646556e+01  -5.2304422e-07
   3.3653815e+01  -5.4144254e-07
   3.3661074e+01  -5.5900863e-07
   3.3668334e+01  -5.7572346e-07
   3.3675593e+01  -5.9156801e-07
   3.3682852e+01  -6.0652325e-07
   3.3690111e+01  -6.2057014e-07
   3.3697371e+01  -6.3368966e-07
   3.3704630e+01  -6.4586276e-07
   3.3711889e+01  -6.5707043e-07
   3.3719148e+01  -6.6729363e-07
   3.3726407e+01  -6.7651333e-07
   3.3733667e+01  -6.8471050e-07
   3.3740926e+01  -6.9186611e-07
   3.3748185e+01  -6.9796112e-07
   3.3755444e+01  -7.0297651e-07
   3.3762704e+01  -7.0689325e-07
   3.3769963e+01  -7.0969230e-07
   3.3777222e+01  -7.1135464e-07
   3.3784481e+01  -7.1186123e-07
   3.3791741e+01  -7.1119304e-07
   3.3799000e+01  -7.0933104e-07
   3.3806259e+01  -7.0625620e-07
   3.3813518e+01  -7.0194950e-07
   3.3820778e+01  -6.9639189e-07
   3.3828037e+01  -6.8956435e-07
   3.3835296e+01  -6.8144785e-07
   3.3842555e+01  -6.7202336e-07
   3.3849814e+01  -6.6127184e-07
   3.3857074e+01  -6.4917426e-07
   3.3864333e+01  -6.3571160e-07
   3.3871592e+01  -6.2086483e-07
   3.3878851e+01  -6.0461490e-07
   3.3886111e+01  -5.8703266e-07
   3.3893370e+01  -5.6891879e-07
   3.3900629e+01  -5.5047684e-07
   3.3907888e+01  -5.3171933e-07
   3.3915148e+01  -5.1265880e-07
   3.3922407e+01  -4.9330778e-07
   3.3929666e+01  -4.7367882e-07
   3.3936925e+01  -4.5378444e-07
   3.3944185e+01  -4.3363717e-07
   3.3951444e+01  -4.1324955e-07
   3.3958703e+01  -3.9263412e-07
   3.3965962e+01  -3.7180340e-07
   3.3973221e+01  -3.5076994e-07
   3.3980481e+01  -3.2954626e-07
   3.3987740e+01  -3.0814491e-07
   3.3994999e+01  -2.8657840e-07
   3.4002258e+01  -2.6485929e-07
   3.4009518e+01  -2.4300009e-07
   3.4016777e+01  -2.2101335e-07
   3.4024036e+01  -1.9891160e-07
   3.4031295e+01  -1.7670737e-07
   3.4038555e+01  -1.5441319e-07
   3.4045814e+01  -1.3204161e-07
   3.4053073e+01  -1.0960515e-07
   3.4060332e+01  -8.7116348e-08
   3.4067592e+01  -6.4587738e-08
   3.4074851e+01  -4.2031855e-08
   3.4082110e+01  -1.9461231e-08
   3.4089369e+01   3.1116001e-09
   3.4096628e+01   2.5674103e-08
   3.4103888e+01   4.8213746e-08
   3.4111147e+01   7.0717993e-08
   3.4118406e+01   9.3174312e-08
   3.4125665e+01   1.1557017e-07
   3.4132925e+01   1.3789303e-07
   3.4140184e+01   1.6013036e-07
   3.4147443e+01   1.8226962e-07
   3.4154702e+01   2.0429829e-07
   3.4161962e+01   2.2620382e-07
   3.4169221e+01   2.4797369e-07
   3.4176480e+01   2.6959536e-07
   3.4183739e+01   2.9105629e-07
   3.4190999e+01   3.1234396e-07
   3.4198258e+01   3.3344583e-07
   3.4205517e+01   3.5434936e-07
   3.4212776e+01   3.7504202e-07
   3.4220035e+01   3.9551129e-07
   3.4227295e+01   4.1574461e-07
   3.4234554e+01   4.3572946e-07
   3.4241813e+01   4.5545331e-07
   3.4249072e+01   4.7490362e-07
   3.4256332e+01   4.9406786e-07
   3.4263591e+01   5.1293349e-07
   3.4270850e+01   5.3148798e-07
   3.4278109e+01   5.4971880e-07
   3.4285369e+01   5.6761342e-07
   3.4292628e+01   5.8515929e-07
   3.4299887e+01   6.0234388e-07
   3.4307146e+01   6.1915467e-07
   3.4314406e+01   6.3557911e-07
   3.4321665e+01   6.5160468e-07
   3.4328924e+01   6.6721883e-07
   3.4336183e+01   6.8240905e-07
   3.4343442e+01   6.9716278e-07
   3.4350702e+01   7.1146750e-07
   3.4357961e+01   7.2531067e-07
   3.4365220e+01   7.3867977e-07
   3.4372479e+01   7.5156225e-07
   3.4379739e+01   7.6394559e-07
   3.4386998e+01   7.7581724e-07
   3.4394257e+01   7.8716468e-07
   3.4401516e+01   7.9797536e-07
   3.4408776e+01   8.0823677e-07
   3.4416035e+01   8.1793636e-07
   3.4423294e+01   8.2706159e-07
   3.4430553e+01   8.3559995e-07
   3.4437813e+01   8.4353888e-07
   3.4445072e+01   8.5086587e-07
   3.4452331e+01   8.5756836e-07
   3.4459590e+01   8.6363384e-07
   3.4466849e+01   8.6904976e-07
   3.4474109e+01   8.7380360e-07
   3.4481368e+01   8.7788281e-07
   3.4488627e+01   8.8127487e-07
   3.4495886e+01   8.8396724e-07
   3.4503146e+01   8.8594738e-07
   3.4510405e+01   8.8720277e-07
   3.4517664e+01   8.8772087e-07
   3.4524923e+01   8.8748914e-07
   3.4532183e+01   8.8649506e-07
   3.4539442e+01   8.8472608e-07
   3.4546701e+01   8.8216967e-07
   3.4553960e+01   8.7881331e-07
   3.4561220e+01   8.7464445e-07
   3.4568479e+01   8.6965057e-07
   3.4575738e+01   8.6381912e-07
   3.4582997e+01   8.5713758e-07
   3.4590256e+01   8.4959341e-07
   3.4597516e+01   8.4117407e-07
   3.4604775e+01   8.3186704e-07
   3.4612034e+01   8.2165978e-07
   3.4619293e+01   8.1053975e-07
   3.4626553e+01   7.9849442e-07
   3.4633812e+01   7.8551126e-07
   3.4641071e+01   7.7192929e-07
   3.4648330e+01   7.5840114e-07
   3.4655590e+01   7.4494550e-07
   3.4662849e+01   7.3156622e-07
   3.4670108e+01   7.1826715e-07
   3.4677367e+01   7.0505214e-07
   3.4684627e+01   6.9192506e-07
   3.4691886e+01   6.7888975e-07
   3.4699145e+01   6.6595007e-07
   3.4706404e+01   6.5310987e-07
   3.4713663e+01   6.4037300e-07
   3.4720923e+01   6.2774333e-07
   3.4728182e+01   6.1522469e-07
   3.4735441e+01   6.0282095e-07
   3.4742700e+01   5.9053595e-07
   3.4749960e+01   5.7837356e-07
   3.4757219e+01   5.6633762e-07
   3.4764478e+01   5.5443200e-07
   3.4771737e+01   5.4266053e-07
   3.4778997e+01   5.3102709e-07
   3.4786256e+01   5.1953551e-07
   3.4793515e+01   5.0818965e-07
   3.4800774e+01   4.9699337e-07
   3.4808034e+01   4.8595052e-07
   3.4815293e+01   4.7506496e-07
   3.4822552e+01   4.6434053e-07
   3.4829811e+01   4.5378110e-07
   3.4837070e+01   4.4339050e-07
   3.4844330e+01   4.3317261e-07
   3.4851589e+01   4.2313127e-07
   3.4858848e+01   4.1327033e-07
   3.4866107e+01   4.0359365e-07
   3.4873367e+01   3.9410508e-07
   3.4880626e+01   3.8480848e-07
   3.4887885e+01   3.7570770e-07
   3.4895144e+01   3.6680659e-07
   3.4902404e+01   3.5810901e-07
   3.4909663e+01   3.4961880e-07
   3.4916922e+01   3.4133983e-07
   3.4924181e+01   3.3327595e-07
   3.4931441e+01   3.2543101e-07
   3.4938700e+01   3.1780886e-07
   3.4945959e+01   3.1041336e-07
   3.4953218e+01   3.0324835e-07
   3.4960477e+01   2.9631771e-07
   3.4967737e+01   2.8962527e-07
   3.4974996e+01   2.8317489e-07
   3.4982255e+01   2.7697043e-07
   3.4989514e+01   2.7101574e-07
   3.4996774e+01   2.6531466e-07
   3.5004033e+01   2.5987107e-07
   3.5011292e+01   2.5468880e-07
   3.5018551e+01   2.4977172e-07
   3.5025811e+01   2.4512367e-07
   3.5033070e+01   2.4074851e-07
   3.5040329e+01   2.3665010e-07
   3.5047588e+01   2.3283228e-07
   3.5054848e+01   2.2929891e-07
   3.5062107e+01   2.2605385e-07
   3.5069366e+01   2.2310094e-07
   3.5076625e+01   2.2044405e-07
   3.5083884e+01   2.1808702e-07
   3.5091144e+01   2.1603370e-07
   3.5098403e+01   2.1428796e-07
   3.5105662e+01   2.1285365e-07
   3.5112921e+01   2.1173461e-07
   3.5120181e+01   2.1093470e-07
   3.5127440e+01   2.1038497e-07
   3.5134699e+01   2.0985454e-07
   3.5141958e+01   2.0932619e-07
   3.5149218e+01   2.0880004e-07
   3.5156477e+01   2.0827627e-07
   3.5163736e+01   2.0775502e-07
   3.5170995e+01   2.0723644e-07
   3.5178255e+01   2.0672070e-07
   3.5185514e+01   2.0620794e-07
   3.5192773e+01   2.0569832e-07
   3.5200032e+01   2.0519199e-07
   3.5207291e+01   2.0468911e-07
   3.5214551e+01   2.0418982e-07
   3.5221810e+01   2.0369429e-07
   3.5229069e+01   2.0320266e-07
   3.5236328e+01   2.0271510e-07
   3.5243588e+01   2.0223175e-07
   3.5250847e+01   2.0175276e-07
   3.5258106e+01   2.0127830e-07
   3.5265365e+01   2.0080851e-07
   3.5272625e+01   2.0034355e-07
   3.5279884e+01   1.9988358e-07
   3.5287143e+01   1.9942874e-07
   3.5294402e+01   1.9897919e-07
   3.5301662e+01   1.9853508e-07
   3.5308921e+01   1.9809657e-07
   3.5316180e+01   1.9766381e-07
   3.5323439e+01   1.9723696e-07
   3.5330698e+01   1.9681616e-07
   3.5337958e+01   1.9640158e-07
   3.5345217e+01   1.9599336e-07
   3.5352476e+01   1.9559166e-07
   3.5359735e+01   1.9519664e-07
   3.5366995e+01   1.9480844e-07
   3.5374254e+01   1.9442722e-07
   3.5381513e+01   1.9405314e-07
   3.5388772e+01   1.9368634e-07
   3.5396032e+01   1.9332699e-07
   3.5403291e+01   1.9297523e-07
   3.5410550e+01   1.9263122e-07
   3.5417809e+01   1.9229512e-07
   3.5425069e+01   1.9196707e-07
   3.5432328e+01   1.9164723e-07
   3.5439587e+01   1.9133575e-07
   3.5446846e+01   1.9103279e-07
   3.5454106e+01   1.9073851e-07
   3.5461365e+01   1.9045305e-07
   3.5468624e+01   1.9017656e-07
   3.5475883e+01   1.8990921e-07
   3.5483142e+01   1.8965115e-07
   3.5490402e+01   1.8940253e-07
   3.5497661e+01   1.8916350e-07
   3.5504920e+01   1.8893421e-07
   3.5512179e+01   1.8871483e-07
   3.5519439e+01   1.8850550e-07
   3.5526698e+01   1.8830639e-07
   3.5533957e+01   1.8811763e-07
   3.5541216e+01   1.8793939e-07
   3.5548476e+01   1.8777182e-07
   3.5555735e+01   1.8761507e-07
   3.5562994e+01   1.8746930e-07
   3.5570253e+01   1.8733466e-07
   3.5577513e+01   1.8721130e-07
   3.5584772e+01   1.8709938e-07
   3.5592031e+01   1.8699906e-07
   3.5599290e+01   1.8691048e-07
   3.5606549e+01   1.8683380e-07
   3.5613809e+01   1.8676755e-07
   3.5621068e+01   1.8670264e-07
   3.5628327e+01   1.8663762e-07
   3.5635586e+01   1.8657250e-07
   3.5642846e+01   1.8650727e-07
   3.5650105e+01   1.8644194e-07
   3.5657364e+01   1.8637652e-07
   3.5664623e+01   1.8631100e-07
   3.5671883e+01   1.8624540e-07
   3.5679142e+01   1.8617971e-07
   3.5686401e+01   1.8611394e-07
   3.5693660e+01   1.8604809e-07
   3.5700920e+01   1.8598217e-07
   3.5708179e+01   1.8591618e-07
   3.5715438e+01   1.8585013e-07
   3.5722697e+01   1.8578401e-07
   3.5729956e+01   1.8571783e-07
   3.5737216e+01   1.8565160e-07
   3.5744475e+01   1.8558531e-07
   3.5751734e+01   1.8551898e-07
   3.5758993e+01   1.8545260e-07
   3.5766253e+01   1.8538618e-07
   3.5773512e+01   1.8531972e-07
   3.5780771e+01   1.8525323e-07
   3.5788030e+01   1.8518671e-07
   3.5795290e+01   1.8512016e-07
   3.5802549e+01   1.8505360e-07
   3.5809808e+01   1.8498701e-07
   3.5817067e+01   1.8492040e-07
   3.5824327e+01   1.8485379e-07
   3.5831586e+01   1.8478716e-07
   3.5838845e+01   1.8472054e-07
   3.5846104e+01   1.8465391e-07
   3.5853363e+01   1.8458728e-07
   3.5860623e+01   1.8452066e-07
   3.5867882e+01   1.8445405e-07
   3.5875141e+01   1.8438746e-07
   3.5882400e+01   1.8432088e-07
   3.5889660e+01   1.8425432e-07
   3.5896919e+01   1.8418779e-07
   3.5904178e+01   1.8412128e-07
   3.5911437e+01   1.8405481e-07
   3.5918697e+01   1.8398838e-07
   3.5925956e+01   1.8392198e-07
   3.5933215e+01   1.8385562e-07
   3.5940474e+01   1.8378932e-07
   3.5947734e+01   1.8372306e-07
   3.5954993e+01   1.8365685e-07
   3.5962252e+01   1.8359071e-07
   3.5969511e+01   1.8352462e-07
   3.5976770e+01   1.8345860e-07
   3.5984030e+01   1.8339265e-07
   3.5991289e+01   1.8332677e-07
   3.5998548e+01   1.8326096e-07
   3.6005807e+01   1.8319524e-07
   3.6013067e+01   1.8312960e-07
   3.6020326e+01   1.8306404e-07
   3.6027585e+01   1.8299858e-07
   3.6034844e+01   1.8293320e-07
   3.6042104e+01   1.8286793e-07
   3.6049363e+01   1.8280276e-07
   3.6056622e+01   1.8273769e-07
   3.6063881e+01   1.8267273e-07
   3.6071141e+01   1.8260788e-07
   3.6078400e+01   1.8254315e-07
   3.6085659e+01   1.8247854e-07
   3.6092918e+01   1.8241405e-07
   3.6100177e+01   1.8234969e-07
   3.6107437e+01   1.8228546e-07
   3.6114696e+01   1.8222136e-07
   3.6121955e+01   1.8215740e-07
   3.6129214e+01   1.8209358e-07
   3.6136474e+01   1.8202990e-07
   3.6143733e+01   1.8196638e-07
   3.6150992e+01   1.8190300e-07
   3.6158251e+01   1.8183979e-07
   3.6165511e+01   1.8177673e-07
   3.6172770e+01   1.8171383e-07
   3.6180029e+01   1.8165110e-07
   3.6187288e+01   1.8158855e-07
   3.6194548e+01   1.8152616e-07
   3.6201807e+01   1.8146396e-07
   3.6209066e+01   1.8140193e-07
   3.6216325e+01   1.8134009e-07
   3.6223584e+01   1.8127844e-07
   3.6230844e+01   1.8121698e-07
   3.6238103e+01   1.8115572e-07
   3.6245362e+01   1.8109465e-07
   3.6252621e+01   1.8103379e-07
   3.6259881e+01   1.8097314e-07
   3.6267140e+01   1.8091270e-07
   3.6274399e+01   1.8085247e-07
   3.6281658e+01   1.8079246e-07
   3.6288918e+01   1.8073269e-07
   3.6296177e+01   1.8067320e-07
   3.6303436e+01   1.8061397e-07
   3.6310695e+01   1.8055501e-07
   3.6317955e+01   1.8049631e-07
   3.6325214e+01   1.8043787e-07
   3.6332473e+01   1.8037969e-07
   3.6339732e+01   1.8032176e-07
   3.6346991e+01   1.8026409e-07
   3.6354251e+01   1.8020667e-07
   3.6361510e+01   1.8014950e-07
   3.6368769e+01   1.8009257e-07
   3.6376028e+01   1.8003589e-07
   3.6383288e+01   1.7997945e-07
   3.6390547e+01   1.7992325e-07
   3.6397806e+01   1.7986728e-07
   3.6405065e+01   1.7981155e-07
   3.6412325e+01   1.7975605e-07
   3.6419584e+01   1.7970079e-07
   3.6426843e+01   1.7964575e-07
   3.6434102e+01   1.7959093e-07
   3.6441362e+01   1.7953634e-07
   3.6448621e+01   1.7948196e-07
   3.6455880e+01   1.7942781e-07
   3.6463139e+01   1.7937387e-07
   3.6470398e+01   1.7932014e-07
   3.6477658e+01   1.7926663e-07
   3.6484917e+01   1.7921332e-07
   3.6492176e+01   1.7916022e-07
   3.6499435e+01   1.7910733e-07
   3.6506695e+01   1.7905463e-07
   3.6513954e+01   1.7900214e-07
   3.6521213e+01   1.7894984e-07
   3.6528472e+01   1.7889773e-07
   3.6535732e+01   1.7884582e-07
   3.6542991e+01   1.7879410e-07
   3.6550250e+01   1.7874256e-07
   3.6557509e+01   1.7869121e-07
   3.6564769e+01   1.7864004e-07
   3.6572028e+01   1.7858906e-07
   3.6579287e+01   1.7853825e-07
   3.6586546e+01   1.7848761e-07
   3.6593805e+01   1.7843715e-07
   3.6601065e+01   1.7838686e-07
   3.6608324e+01   1.7833674e-07
   3.6615583e+01   1.7828679e-07
   3.6622842e+01   1.7823700e-07
   3.6630102e+01   1.7818737e-07
   3.6637361e+01   1.7813789e-07
   3.6644620e+01   1.7808858e-07
   3.6651879e+01   1.7803942e-07
   3.6659139e+01   1.7799041e-07
   3.6666398e+01   1.7794155e-07
   3.6673657e+01   1.7789284e-07
   3.6680916e+01   1.7784428e-07
   3.6688176e+01   1.7779585e-07
   3.6695435e+01   1.7774757e-07
   3.6702694e+01   1.7769943e-07
   3.6709953e+01   1.7765142e-07
   3.6717212e+01   1.7760354e-07
   3.6724472e+01   1.7755579e-07
   3.6731731e+01   1.7750818e-07
   3.6738990e+01   1.7746069e-07
   3.6746249e+01   1.7741332e-07
   3.6753509e+01   1.7736607e-07
   3.6760768e+01   1.7731894e-07
   3.6768027e+01   1.7727193e-07
   3.6775286e+01   1.7722504e-07
   3.6782546e+01   1.7717825e-07
   3.6789805e+01   1.7713158e-07
   3.6797064e+01   1.7708501e-07
   3.6804323e+01   1.7703855e-07
   3.6811583e+01   1.7699219e-07
   3.6818842e+01   1.7694593e-07
   3.6826101e+01   1.7689977e-07
   3.6833360e+01   1.7685370e-07
   3.6840619e+01   1.7680773e-07
   3.6847879e+01   1.7676184e-07
   3.6855138e+01   1.7671605e-07
   3.6862397e+01   1.7667034e-07
   3.6869656e+01   1.7662471e-07
   3.6876916e+01   1.7657917e-07
   3.6884175e+01   1.7653371e-07
   3.6891434e+01   1.7648832e-07
   3.6898693e+01   1.7644300e-07
   3.6905953e+01   1.7639774e-07
   3.6913212e+01   1.7635247e-07
   3.6920471e+01   1.7630718e-07
   3.6927730e+01   1.7626188e-07
   3.6934990e+01   1.7621657e-07
   3.6942249e+01   1.7617124e-07
   3.6949508e+01   1.7612590e-07
   3.6956767e+01   1.7608055e-07
   3.6964026e+01   1.7603518e-07
   3.6971286e+01   1.7598980e-07
   3.6978545e+01   1.7594441e-07
   3.6985804e+01   1.7589900e-07
   3.6993063e+01   1.7585358e-07
   3.7000323e+01   1.7580815e-07
   3.7007582e+01   1.7576270e-07
   3.7014841e+01   1.7571723e-07
   3.7022100e+01   1.7567175e-07
   3.7029360e+01   1.7562626e-07
   3.7036619e+01   1.7558075e-07
   3.7043878e+01   1.7553523e-07
   3.7051137e+01   1.7548970e-07
   3.7058397e+01   1.7544414e-07
   3.7065656e+01   1.7539858e-07
   3.7072915e+01   1.7535300e-07
   3.7080174e+01   1.7530740e-07
   3.7087433e+01   1.7526179e-07
   3.7094693e+01   1.7521616e-07
   3.7101952e+01   1.7517052e-07
   3.7109211e+01   1.7512486e-07
   3.7116470e+01   1.7507918e-07
   3.7123730e+01   1.7503349e-07
   3.7130989e+01   1.7498779e-07
   3.7138248e+01   1.7494207e-07
   3.7145507e+01   1.7489633e-07
   3.7152767e+01   1.7485057e-07
   3.7160026e+01   1.7480480e-07
   3.7167285e+01   1.7475902e-07
   3.7174544e+01   1.7471321e-07
   3.7181804e+01   1.7466739e-07
   3.7189063e+01   1.7462155e-07
   3.7196322e+01   1.7457570e-07
   3.7203581e+01   1.7452983e-07
   3.7210840e+01   1.7448394e-07
   3.7218100e+01   1.7443804e-07
   3.7225359e+01   1.7439211e-07
   3.7232618e+01   1.7434617e-07
   3.7239877e+01   1.7430022e-07
   3.7247137e+01   1.7425424e-07
   3.7254396e+01   1.7420825e-07
   3.7261655e+01   1.7416224e-07
   3.7268914e+01   1.7411621e-07
   3.7276174e+01   1.7407016e-07
   3.7283433e+01   1.7402410e-07
   3.7290692e+01   1.7397802e-07
   3.7297951e+01   1.7393191e-07
   3.7305211e+01   1.7388579e-07
   3.7312470e+01   1.7383966e-07
   3.7319729e+01   1.7379350e-07
   3.7326988e+01   1.7374732e-07
   3.7334247e+01   1.7370113e-07
   3.7341507e+01   1.7365492e-07
   3.7348766e+01   1.7360868e-07
   3.7356025e+01   1.7356243e-07
   3.7363284e+01   1.7351616e-07
   3.7370544e+01   1.7346987e-07
   3.7377803e+01   1.7342356e-07
   3.7385062e+01   1.7337723e-07
   3.7392321e+01   1.7333088e-07
   3.7399581e+01   1.7328452e-07
   3.7406840e+01   1.7323813e-07
   3.7414099e+01   1.7319172e-07
   3.7421358e+01   1.7314529e-07
   3.7428618e+01   1.7309884e-07
   3.7435877e+01   1.7305237e-07
   3.7443136e+01   1.7300588e-07
   3.7450395e+01   1.7295937e-07
   3.7457654e+01   1.7291284e-07
   3.7464914e+01   1.7286629e-07
   3.7472173e+01   1.7281972e-07
   3.7479432e+01   1.7277312e-07
   3.7486691e+01   1.7272651e-07
   3.7493951e+01   1.7267988e-07
   3.7501210e+01   1.7263322e-07
   3.7508469e+01   1.7258654e-07
   3.7515728e+01   1.7253984e-07
   3.7522988e+01   1.7249312e-07
   3.7530247e+01   1.7244638e-07
   3.7537506e+01   1.7239961e-07
   3.7544765e+01   1.7235283e-07
   3.7552025e+01   1.7230602e-07
   3.7559284e+01   1.7225926e-07
   3.7566543e+01   1.7221259e-07
   3.7573802e+01   1.7216603e-07
   3.7581061e+01   1.7211956e-07
   3.7588321e+01   1.7207318e-07
   3.7595580e+01   1.7202690e-07
   3.7602839e+01   1.7198072e-07
   3.7610098e+01   1.7193463e-07
   3.7617358e+01   1.7188862e-07
   3.7624617e+01   1.7184271e-07
   3.7631876e+01   1.7179689e-07
   3.7639135e+01   1.7175116e-07
   3.7646395e+01   1.7170552e-07
   3.7653654e+01   1.7165996e-07
   3.7660913e+01   1.7161449e-07
   3.7668172e+01   1.7156911e-07
   3.7675432e+01   1.7152381e-07
   3.7682691e+01   1.7147859e-07
   3.7689950e+01   1.7143346e-07
   3.7697209e+01   1.7138840e-07
   3.7704468e+01   1.7134343e-07
   3.7711728e+01   1.7129854e-07
   3.7718987e+01   1.7125373e-07
   3.7726246e+01   1.7120900e-07
   3.7733505e+01   1.7116434e-07
   3.7740765e+01   1.7111976e-07
   3.7748024e+01   1.7107525e-07
   3.7755283e+01   1.7103082e-07
   3.7762542e+01   1.7098646e-07
   3.7769802e+01   1.7094218e-07
   3.7777061e+01   1.7089796e-07
   3.7784320e+01   1.7085382e-07
   3.7791579e+01   1.7080975e-07
   3.7798839e+01   1.7076575e-07
   3.7806098e+01   1.7072181e-07
   3.7813357e+01   1.7067794e-07
   3.7820616e+01   1.7063414e-07
   3.7827875e+01   1.7059040e-07
   3.7835135e+01   1.7054673e-07
   3.7842394e+01   1.7050312e-07
   3.7849653e+01   1.7045957e-07
   3.7856912e+01   1.7041609e-07
   3.7864172e+01   1.7037266e-07
   3.7871431e+01   1.7032930e-07
   3.7878690e+01   1.7028599e-07
   3.7885949e+01   1.7024275e-07
   3.7893209e+01   1.7019956e-07
   3.7900468e+01   1.7015642e-07
   3.7907727e+01   1.7011334e-07
   3.7914986e+01   1.7007032e-07
   3.7922246e+01   1.7002735e-07
   3.7929505e+01   1.6998443e-07
   3.7936764e+01   1.6994156e-07
   3.7944023e+01   1.6989874e-07
   3.7951282e+01   1.6985598e-07
   3.7958542e+01   1.6981326e-07
   3.7965801e+01   1.6977059e-07
   3.7973060e+01   1.6972796e-07
   3.7980319e+01   1.6968539e-07
   3.7987579e+01   1.6964285e-07
   3.7994838e+01   1.6960037e-07
   3.8002097e+01   1.6955792e-07
   3.8009356e+01   1.6951552e-07
   3.8016616e+01   1.6947316e-07
   3.8023875e+01   1.6943084e-07
   3.8031134e+01   1.6938856e-07
   3.8038393e+01   1.6934632e-07
   3.8045653e+01   1.6930412e-07
   3.8052912e+01   1.6926195e-07
   3.8060171e+01   1.6921982e-07
   3.8067430e+01   1.6917772e-07
   3.8074689e+01   1.6913566e-07
   3.8081949e+01   1.6909364e-07
   3.8089208e+01   1.6905164e-07
   3.8096467e+01   1.6900968e-07
   3.8103726e+01   1.6896774e-07
   3.8110986e+01   1.6892584e-07
   3.8118245e+01   1.6888396e-07
   3.8125504e+01   1.6884212e-07
   3.8132763e+01   1.6880030e-07
   3.8140023e+01   1.6875850e-07
   3.8147282e+01   1.6871673e-07
   3.8154541e+01   1.6867499e-07
   3.8161800e+01   1.6863327e-07
   3.8169060e+01   1.6859157e-07
   3.8176319e+01   1.6854989e-07
   3.8183578e+01   1.6850823e-07
   3.8190837e+01   1.6846659e-07
   3.8198096e+01   1.6842498e-07
   3.8205356e+01   1.6838337e-07
   3.8212615e+01   1.6834179e-07
   3.8219874e+01   1.6830022e-07
   3.8227133e+01   1.6825867e-07
   3.8234393e+01   1.6821713e-07
   3.8241652e+01   1.6817560e-07
   3.8248911e+01   1.6813409e-07
   3.8256170e+01   1.6809259e-07
   3.8263430e+01   1.6805109e-07
   3.8270689e+01   1.6800961e-07
   3.8277948e+01   1.6796814e-07
   3.8285207e+01   1.6792667e-07
   3.8292467e+01   1.6788521e-07
   3.8299726e+01   1.6784376e-07
   3.8306985e+01   1.6780231e-07
   3.8314244e+01   1.6776086e-07
   3.8321503e+01   1.6771942e-07
   3.8328763e+01   1.6767798e-07
   3.8336022e+01   1.6763655e-07
   3.8343281e+01   1.6759511e-07
   3.8350540e+01   1.6755367e-07
   3.8357800e+01   1.6751223e-07
   3.8365059e+01   1.6747079e-07
   3.8372318e+01   1.6742934e-07
   3.8379577e+01   1.6738790e-07
   3.8386837e+01   1.6734644e-07
   3.8394096e+01   1.6730498e-07
   3.8401355e+01   1.6726351e-07
   3.8408614e+01   1.6722204e-07
   3.8415874e+01   1.6718056e-07
   3.8423133e+01   1.6713906e-07
   3.8430392e+01   1.6709756e-07
   3.8437651e+01   1.6705604e-07
   3.8444910e+01   1.6701452e-07
   3.8452170e+01   1.6697297e-07
   3.8459429e+01   1.6693142e-07
   3.8466688e+01   1.6688985e-07
   3.8473947e+01   1.6684826e-07
   3.8481207e+01   1.6680666e-07
   3.8488466e+01   1.6676504e-07
   3.8495725e+01   1.6672340e-07
   3.8502984e+01   1.6668174e-07
   3.8510244e+01   1.6664006e-07
   3.8517503e+01   1.6659836e-07
   3.8524762e+01   1.6655663e-07
   3.8532021e+01   1.6651488e-07
   3.8539281e+01   1.6647311e-07
   3.8546540e+01   1.6643131e-07
   3.8553799e+01   1.6638949e-07
   3.8561058e+01   1.6634764e-07
   3.8568317e+01   1.6630576e-07
   3.8575577e+01   1.6626386e-07
   3.8582836e+01   1.6622192e-07
   3.8590095e+01   1.6617995e-07
   3.8597354e+01   1.6613795e-07
   3.8604614e+01   1.6609592e-07
   3.8611873e+01   1.6605386e-07
   3.8619132e+01   1.6601176e-07
   3.8626391e+01   1.6596962e-07
   3.8633651e+01   1.6592745e-07
   3.8640910e+01   1.6588524e-07
   3.8648169e+01   1.6584300e-07
   3.8655428e+01   1.6580071e-07
   3.8662688e+01   1.6575839e-07
   3.8669947e+01   1.6571602e-07
   3.8677206e+01   1.6567362e-07
   3.8684465e+01   1.6563117e-07
   3.8691724e+01   1.6558868e-07
   3.8698984e+01   1.6554614e-07
   3.8706243e+01   1.6550356e-07
   3.8713502e+01   1.6546093e-07
   3.8720761e+01   1.6541825e-07
   3.8728021e+01   1.6537550e-07
   3.8735280e+01   1.6533223e-07
   3.8742539e+01   1.6528832e-07
   3.8749798e+01   1.6524377e-07
   3.8757058e+01   1.6519859e-07
   3.8764317e+01   1.6515278e-07
   3.8771576e+01   1.6510636e-07
   3.8778835e+01   1.6505933e-07
   3.8786095e+01   1.6501169e-07
   3.8793354e+01   1.6496346e-07
   3.8800613e+01   1.6491464e-07
   3.8807872e+01   1.6486523e-07
   3.8815131e+01   1.6481525e-07
   3.8822391e+01   1.6476470e-07
   3.8829650e+01   1.6471359e-07
   3.8836909e+01   1.6466192e-07
   3.8844168e+01   1.6460970e-07
   3.8851428e+01   1.6455694e-07
   3.8858687e+01   1.6450365e-07
   3.8865946e+01   1.6444983e-07
   3.8873205e+01   1.6439548e-07
   3.8880465e+01   1.6434063e-07
   3.8887724e+01   1.6428526e-07
   3.8894983e+01   1.6422940e-07
   3.8902242e+01   1.6417304e-07
   3.8909502e+01   1.6411619e-07
   3.8916761e+01   1.6405887e-07
   3.8924020e+01   1.6400107e-07
   3.8931279e+01   1.6394281e-07
   3.8938538e+01   1.6388408e-07
   3.8945798e+01   1.6382491e-07
   3.8953057e+01   1.6376529e-07
   3.8960316e+01   1.6370523e-07
   3.8967575e+01   1.6364474e-07
   3.8974835e+01   1.6358382e-07
   3.8982094e+01   1.6352249e-07
   3.8989353e+01   1.6346075e-07
   3.8996612e+01   1.6339860e-07
   3.9003872e+01   1.6333605e-07
   3.9011131e+01   1.6327312e-07
   3.9018390e+01   1.6320980e-07
   3.9025649e+01   1.6314610e-07
   3.9032909e+01   1.6308203e-07
   3.9040168e+01   1.6301761e-07
   3.9047427e+01   1.6295282e-07
   3.9054686e+01   1.6288769e-07
   3.9061945e+01   1.6282221e-07
   3.9069205e+01   1.6275640e-07
   3.9076464e+01   1.6269026e-07
   3.9083723e+01   1.6262380e-07
   3.9090982e+01   1.6255702e-07
   3.9098242e+01   1.6248994e-07
   3.9105501e+01   1.6242255e-07
   3.9112760e+01   1.6235488e-07
   3.9120019e+01   1.6228691e-07
   3.9127279e+01   1.6221866e-07
   3.9134538e+01   1.6215014e-07
   3.9141797e+01   1.6208136e-07
   3.9149056e+01   1.6201231e-07
   3.9156316e+01   1.6194301e-07
   3.9163575e+01   1.6187347e-07
   3.9170834e+01   1.6180369e-07
   3.9178093e+01   1.6173367e-07
   3.9185352e+01   1.6166343e-07
   3.9192612e+01   1.6159297e-07
   3.9199871e+01   1.6152230e-07
   3.9207130e+01   1.6145142e-07
   3.9214389e+01   1.6138035e-07
   3.9221649e+01   1.6130909e-07
   3.9228908e+01   1.6123764e-07
   3.9236167e+01   1.6116601e-07
   3.9243426e+01   1.6109422e-07
   3.9250686e+01   1.6102226e-07
   3.9257945e+01   1.6095014e-07
   3.9265204e+01   1.6087788e-07
   3.9272463e+01   1.6080547e-07
   3.9279723e+01   1.6073293e-07
   3.9286982e+01   1.6066026e-07
   3.9294241e+01   1.6058746e-07
   3.9301500e+01   1.6051455e-07
   3.9308759e+01   1.6044153e-07
   3.9316019e+01   1.6036842e-07
   3.9323278e+01   1.6029520e-07
   3.9330537e+01   1.6022190e-07
   3.9337796e+01   1.6014852e-07
   3.9345056e+01   1.6007506e-07
   3.9352315e+01   1.6000154e-07
   3.9359574e+01   1.5992796e-07
   3.9366833e+01   1.5985432e-07
   3.9374093e+01   1.5978064e-07
   3.9381352e+01   1.5970691e-07
   3.9388611e+01   1.5963316e-07
   3.9395870e+01   1.5955938e-07
   3.9403130e+01   1.5948558e-07
   3.9410389e+01   1.5941176e-07
   3.9417648e+01   1.5933795e-07
   3.9424907e+01   1.5926413e-07
   3.9432166e+01   1.5919033e-07
   3.9439426e+01   1.5911653e-07
   3.9446685e+01   1.5904277e-07
   3.9453944e+01   1.5896903e-07
   3.9461203e+01   1.5889532e-07
   3.9468463e+01   1.5882166e-07
   3.9475722e+01   1.5874805e-07
   3.9482981e+01   1.5867450e-07
   3.9490240e+01   1.5860101e-07
   3.9497500e+01   1.5852759e-07
   3.9504759e+01   1.5845425e-07
   3.9512018e+01   1.5838099e-07
   3.9519277e+01   1.5830782e-07
   3.9526537e+01   1.5823475e-07
   3.9533796e+01   1.5816179e-07
   3.9541055e+01   1.5808894e-07
   3.9548314e+01   1.5801621e-07
   3.9555573e+01   1.5794360e-07
   3.9562833e+01   1.5787112e-07
   3.9570092e+01   1.5779879e-07
   3.9577351e+01   1.5772660e-07
   3.9584610e+01   1.5765456e-07
   3.9591870e+01   1.5758269e-07
   3.9599129e+01   1.5751098e-07
   3.9606388e+01   1.5743944e-07
   3.9613647e+01   1.5736809e-07
   3.9620907e+01   1.5729692e-07
   3.9628166e+01   1.5722594e-07
   3.9635425e+01   1.5715517e-07
   3.9642684e+01   1.5708461e-07
   3.9649944e+01   1.5701426e-07
   3.9657203e+01   1.5694413e-07
   3.9664462e+01   1.5687423e-07
   3.9671721e+01   1.5680457e-07
   3.9678980e+01   1.5673515e-07
   3.9686240e+01   1.5666598e-07
   3.9693499e+01   1.5659707e-07
   3.9700758e+01   1.5652841e-07
   3.9708017e+01   1.5646003e-07
   3.9715277e+01   1.5639193e-07
   3.9722536e+01   1.5632411e-07
   3.9729795e+01   1.5625658e-07
   3.9737054e+01   1.5618935e-07
   3.9744314e+01   1.5612242e-07
   3.9751573e+01   1.5605580e-07
   3.9758832e+01   1.5598950e-07
   3.9766091e+01   1.5592353e-07
   3.9773351e+01   1.5585789e-07
   3.9780610e+01   1.5579259e-07
   3.9787869e+01   1.5572763e-07
   3.9795128e+01   1.5566302e-07
   3.9802387e+01   1.5559878e-07
   3.9809647e+01   1.5553490e-07
   3.9816906e+01   1.5547140e-07
   3.9824165e+01   1.5540827e-07
   3.9831424e+01   1.5534553e-07
   3.9838684e+01   1.5528319e-07
   3.9845943e+01   1.5522125e-07
   3.9853202e+01   1.5515971e-07
   3.9860461e+01   1.5509859e-07
   3.9867721e+01   1.5503789e-07
   3.9874980e+01   1.5497762e-07
   3.9882239e+01   1.5491778e-07
   3.9889498e+01   1.5485838e-07
   3.9896758e+01   1.5479944e-07
   3.9904017e+01   1.5474095e-07
   3.9911276e+01   1.5468292e-07
   3.9918535e+01   1.5462536e-07
   3.9925794e+01   1.5456828e-07
   3.9933054e+01   1.5451168e-07
   3.9940313e+01   1.5445558e-07
   3.9947572e+01   1.5439997e-07
   3.9954831e+01   1.5434486e-07
   3.9962091e+01   1.5429026e-07
   3.9969350e+01   1.5423618e-07
   3.9976609e+01   1.5418263e-07
   3.9983868e+01   1.5412961e-07
   3.9991128e+01   1.5407712e-07
   3.9998387e+01   1.5402518e-07
   4.0005646e+01   1.5397380e-07
   4.0012905e+01   1.5392297e-07
   4.0020165e+01   1.5387271e-07
   4.0027424e+01   1.5382302e-07
   4.0034683e+01   1.5377391e-07
   4.0041942e+01   1.5372539e-07
   4.0049201e+01   1.5367746e-07
   4.0056461e+01   1.5363013e-07
   4.0063720e+01   1.5358340e-07
   4.0070979e+01   1.5353729e-07
   4.0078238e+01   1.5349181e-07
   4.0085498e+01   1.5344695e-07
   4.0092757e+01   1.5340272e-07
   4.0100016e+01   1.5335914e-07
   4.0107275e+01   1.5331620e-07
   4.0114535e+01   1.5327392e-07
   4.0121794e+01   1.5323230e-07
   4.0129053e+01   1.5319136e-07
   4.0136312e+01   1.5315108e-07
   4.0143572e+01   1.5311149e-07
   4.0150831e+01   1.5307259e-07
   4.0158090e+01   1.5303439e-07
   4.0165349e+01   1.5299689e-07
   4.0172608e+01   1.5296010e-07
   4.0179868e+01   1.5292402e-07
   4.0187127e+01   1.5288867e-07
   4.0194386e+01   1.5285406e-07
   4.0201645e+01   1.5282018e-07
   4.0208905e+01   1.5278704e-07
   4.0216164e+01   1.5275466e-07
   4.0223423e+01   1.5272303e-07
   4.0230682e+01   1.5269217e-07
   4.0237942e+01   1.5266208e-07
   4.0245201e+01   1.5263277e-07
   4.0252460e+01   1.5260425e-07
   4.0259719e+01   1.5257652e-07
   4.0266979e+01   1.5254959e-07
   4.0274238e+01   1.5252347e-07
   4.0281497e+01   1.5249815e-07
   4.0288756e+01   1.5247366e-07
   4.0296015e+01   1.5245000e-07
   4.0303275e+01   1.5242717e-07
   4.0310534e+01   1.5240519e-07
   4.0317793e+01   1.5238405e-07
   4.0325052e+01   1.5236376e-07
   4.0332312e+01   1.5234434e-07
   4.0339571e+01   1.5232578e-07
   4.0346830e+01   1.5230810e-07
   4.0354089e+01   1.5229131e-07
   4.0361349e+01   1.5227540e-07
   4.0368608e+01   1.5226039e-07
   4.0375867e+01   1.5224628e-07
   4.0383126e+01   1.5223308e-07
   4.0390386e+01   1.5222080e-07
   4.0397645e+01   1.5220944e-07
   4.0404904e+01   1.5219901e-07
   4.0412163e+01   1.5218952e-07
   4.0419422e+01   1.5218097e-07
   4.0426682e+01   1.5217337e-07
   4.0433941e+01   1.5216674e-07
   4.0441200e+01   1.5216106e-07
   4.0448459e+01   1.5215636e-07
   4.0455719e+01   1.5215264e-07
   4.0462978e+01   1.5214990e-07
   4.0470237e+01   1.5214816e-07
   4.0477496e+01   1.5214741e-07
   4.0484756e+01   1.5214767e-07
   4.0492015e+01   1.5214894e-07
   4.0499274e+01   1.5215124e-07
   4.0506533e+01   1.5215456e-07
   4.0513793e+01   1.5215891e-07
   4.0521052e+01   1.5216430e-07
   4.0528311e+01   1.5217074e-07
   4.0535570e+01   1.5217824e-07
   4.0542829e+01   1.5218680e-07
   4.0550089e+01   1.5219642e-07
   4.0557348e+01   1.5220712e-07
   4.0564607e+01   1.5221890e-07
   4.0571866e+01   1.5223177e-07
   4.0579126e+01   1.5224574e-07
   4.0586385e+01   1.5226081e-07
   4.0593644e+01   1.5227698e-07
   4.0600903e+01   1.5229428e-07
   4.0608163e+01   1.5231269e-07
   4.0615422e+01   1.5233224e-07
   4.0622681e+01   1.5235292e-07
   4.0629940e+01   1.5237475e-07
   4.0637200e+01   1.5239773e-07
   4.0644459e+01   1.5242186e-07
   4.0651718e+01   1.5244716e-07
   4.0658977e+01   1.5247363e-07
   4.0666236e+01   1.5250128e-07
   4.0673496e+01   1.5253011e-07
   4.0680755e+01   1.5256014e-07
   4.0688014e+01   1.5259136e-07
   4.0695273e+01   1.5262379e-07
   4.0702533e+01   1.5265743e-07
   4.0709792e+01   1.5269230e-07
   4.0717051e+01   1.5272838e-07
   4.0724310e+01   1.5276570e-07
   4.0731570e+01   1.5281128e-07
   4.0738829e+01   1.5287903e-07
   4.0746088e+01   1.5296912e-07
   4.0753347e+01   1.5308135e-07
   4.0760607e+01   1.5321550e-07
   4.0767866e+01   1.5337136e-07
   4.0775125e+01   1.5354873e-07
   4.0782384e+01   1.5374739e-07
   4.0789643e+01   1.5396714e-07
   4.0796903e+01   1.5420775e-07
   4.0804162e+01   1.5446903e-07
   4.0811421e+01   1.5475075e-07
   4.0818680e+01   1.5505271e-07
   4.0825940e+01   1.5537470e-07
   4.0833199e+01   1.5571651e-07
   4.0840458e+01   1.5607793e-07
   4.0847717e+01   1.5645873e-07
   4.0854977e+01   1.5685873e-07
   4.0862236e+01   1.5727770e-07
   4.0869495e+01   1.5771543e-07
   4.0876754e+01   1.5817171e-07
   4.0884014e+01   1.5864634e-07
   4.0891273e+01   1.5913909e-07
   4.0898532e+01   1.5964977e-07
   4.0905791e+01   1.6017816e-07
   4.0913050e+01   1.6072404e-07
   4.0920310e+01   1.6128721e-07
   4.0927569e+01   1.6186746e-07
   4.0934828e+01   1.6246458e-07
   4.0942087e+01   1.6307835e-07
   4.0949347e+01   1.6370856e-07
   4.0956606e+01   1.6435501e-07
   4.0963865e+01   1.6501748e-07
   4.0971124e+01   1.6569577e-07
   4.0978384e+01   1.6638965e-07
   4.0985643e+01   1.6709893e-07
   4.0992902e+01   1.6782339e-07
   4.1000161e+01   1.6856281e-07
   4.1007421e+01   1.6931700e-07
   4.1014680e+01   1.7008573e-07
   4.1021939e+01   1.7086880e-07
   4.1029198e+01   1.7166599e-07
   4.1036457e+01   1.7247710e-07
   4.1043717e+01   1.7330192e-07
   4.1050976e+01   1.7414022e-07
   4.1058235e+01   1.7499182e-07
   4.1065494e+01   1.7585648e-07
   4.1072754e+01   1.7673401e-07
   4.1080013e+01   1.7762418e-07
   4.1087272e+01   1.7852680e-07
   4.1094531e+01   1.7944164e-07
   4.1101791e+01   1.8036850e-07
   4.1109050e+01   1.8130718e-07
   4.1116309e+01   1.8225744e-07
   4.1123568e+01   1.8321910e-07
   4.1130828e+01   1.8419192e-07
   4.1138087e+01   1.8517572e-07
   4.1145346e+01   1.8617026e-07
   4.1152605e+01   1.8717535e-07
   4.1159864e+01   1.8819078e-07
   4.1167124e+01   1.8921632e-07
   4.1174383e+01   1.9025177e-07
   4.1181642e+01   1.9129693e-07
   4.1188901e+01   1.9235157e-07
   4.1196161e+01   1.9341549e-07
   4.1203420e+01   1.9448848e-07
   4.1210679e+01   1.9557032e-07
   4.1217938e+01   1.9666081e-07
   4.1225198e+01   1.9775974e-07
   4.1232457e+01   1.9886689e-07
   4.1239716e+01   1.9998205e-07
   4.1246975e+01   2.0110502e-07
   4.1254235e+01   2.0223558e-07
   4.1261494e+01   2.0337352e-07
   4.1268753e+01   2.0451863e-07
   4.1276012e+01   2.0567070e-07
   4.1283271e+01   2.0682952e-07
   4.1290531e+01   2.0799487e-07
   4.1297790e+01   2.0916656e-07
   4.1305049e+01   2.1034436e-07
   4.1312308e+01   2.1152806e-07
   4.1319568e+01   2.1271747e-07
   4.1326827e+01   2.1391235e-07
   4.1334086e+01   2.1511251e-07
   4.1341345e+01   2.1631773e-07
   4.1348605e+01   2.1752781e-07
   4.1355864e+01   2.1874252e-07
   4.1363123e+01   2.1996167e-07
   4.1370382e+01   2.2118503e-07
   4.1377642e+01   2.2241241e-07
   4.1384901e+01   2.2364358e-07
   4.1392160e+01   2.2487834e-07
   4.1399419e+01   2.2611647e-07
   4.1406678e+01   2.2735777e-07
   4.1413938e+01   2.2860203e-07
   4.1421197e+01   2.2984903e-07
   4.1428456e+01   2.3109856e-07
   4.1435715e+01   2.3235042e-07
   4.1442975e+01   2.3360439e-07
   4.1450234e+01   2.3486026e-07
   4.1457493e+01   2.3611782e-07
   4.1464752e+01   2.3737686e-07
   4.1472012e+01   2.3863716e-07
   4.1479271e+01   2.3989853e-07
   4.1486530e+01   2.4116074e-07
   4.1493789e+01   2.4242359e-07
   4.1501049e+01   2.4368686e-07
   4.1508308e+01   2.4495035e-07
   4.1515567e+01   2.4621385e-07
   4.1522826e+01   2.4747713e-07
   4.1530085e+01   2.4874000e-07
   4.1537345e+01   2.5000224e-07
   4.1544604e+01   2.5126365e-07
   4.1551863e+01   2.5252400e-07
   4.1559122e+01   2.5378309e-07
   4.1566382e+01   2.5504071e-07
   4.1573641e+01   2.5629665e-07
   4.1580900e+01   2.5755069e-07
   4.1588159e+01   2.5880263e-07
   4.1595419e+01   2.6005226e-07
   4.1602678e+01   2.6129936e-07
   4.1609937e+01   2.6254372e-07
   4.1617196e+01   2.6378514e-07
   4.1624456e+01   2.6502340e-07
   4.1631715e+01   2.6625830e-07
   4.1638974e+01   2.6748961e-07
   4.1646233e+01   2.6871713e-07
   4.1653492e+01   2.6994065e-07
   4.1660752e+01   2.7115997e-07
   4.1668011e+01   2.7237485e-07
   4.1675270e+01   2.7358511e-07
   4.1682529e+01   2.7479052e-07
   4.1689789e+01   2.7599088e-07
   4.1697048e+01   2.7718597e-07
   4.1704307e+01   2.7837559e-07
   4.1711566e+01   2.7955951e-07
   4.1718826e+01   2.8073755e-07
   4.1726085e+01   2.8190947e-07
   4.1733344e+01   2.8307507e-07
   4.1740603e+01   2.8423414e-07
   4.1747863e+01   2.8538648e-07
   4.1755122e+01   2.8653186e-07
   4.1762381e+01   2.8767008e-07
   4.1769640e+01   2.8880092e-07
   4.1776899e+01   2.8992418e-07
   4.1784159e+01   2.9103965e-07
   4.1791418e+01   2.9214711e-07
   4.1798677e+01   2.9324635e-07
   4.1805936e+01   2.9433717e-07
   4.1813196e+01   2.9541935e-07
   4.1820455e+01   2.9649268e-07
   4.1827714e+01   2.9755696e-07
   4.1834973e+01   2.9861196e-07
   4.1842233e+01   2.9965748e-07
   4.1849492e+01   3.0069331e-07
   4.1856751e+01   3.0171923e-07
   4.1864010e+01   3.0273505e-07
   4.1871270e+01   3.0374054e-07
   4.1878529e+01   3.0473549e-07
   4.1885788e+01   3.0571970e-07
   4.1893047e+01   3.0669295e-07
   4.1900307e+01   3.0765504e-07
   4.1907566e+01   3.0860575e-07
   4.1914825e+01   3.0954486e-07
   4.1922084e+01   3.1047218e-07
   4.1929343e+01   3.1138749e-07
   4.1936603e+01   3.1229058e-07
   4.1943862e+01   3.1318124e-07
   4.1951121e+01   3.1405925e-07
   4.1958380e+01   3.1492441e-07
   4.1965640e+01   3.1577651e-07
   4.1972899e+01   3.1661533e-07
   4.1980158e+01   3.1744066e-07
   4.1987417e+01   3.1825230e-07
   4.1994677e+01   3.1905003e-07
   4.2001936e+01   3.1983365e-07
   4.2009195e+01   3.2060293e-07
   4.2016454e+01   3.2135768e-07
   4.2023714e+01   3.2209767e-07
   4.2030973e+01   3.2282271e-07
   4.2038232e+01   3.2353257e-07
   4.2045491e+01   3.2422705e-07
   4.2052750e+01   3.2490594e-07
   4.2060010e+01   3.2556902e-07
   4.2067269e+01   3.2621608e-07
   4.2074528e+01   3.2684693e-07
   4.2081787e+01   3.2746133e-07
   4.2089047e+01   3.2805909e-07
   4.2096306e+01   3.2863999e-07
   4.2103565e+01   3.2920382e-07
   4.2110824e+01   3.2975037e-07
   4.2118084e+01   3.3027943e-07
   4.2125343e+01   3.3079078e-07
   4.2132602e+01   3.3128423e-07
   4.2139861e+01   3.3175955e-07
   4.2147121e+01   3.3221654e-07
   4.2154380e+01   3.3265499e-07
   4.2161639e+01   3.3307468e-07
   4.2168898e+01   3.3347541e-07
   4.2176157e+01   3.3385695e-07
   4.2183417e+01   3.3421911e-07
   4.2190676e+01   3.3456168e-07
   4.2197935e+01   3.3488443e-07
   4.2205194e+01   3.3518716e-07
   4.2212454e+01   3.3546967e-07
   4.2219713e+01   3.3573173e-07
   4.2226972e+01   3.3597314e-07
   4.2234231e+01   3.3619369e-07
   4.2241491e+01   3.3639316e-07
   4.2248750e+01   3.3657135e-07
   4.2256009e+01   3.3672804e-07
   4.2263268e+01   3.3686303e-07
   4.2270528e+01   3.3697610e-07
   4.2277787e+01   3.3706704e-07
   4.2285046e+01   3.3713565e-07
   4.2292305e+01   3.3718170e-07
   4.2299564e+01   3.3720500e-07
   4.2306824e+01   3.3720533e-07
   4.2314083e+01   3.3718247e-07
   4.2321342e+01   3.3713622e-07
   4.2328601e+01   3.3706637e-07
   4.2335861e+01   3.3697270e-07
   4.2343120e+01   3.3685501e-07
   4.2350379e+01   3.3671309e-07
   4.2357638e+01   3.3654672e-07
   4.2364898e+01   3.3635569e-07
   4.2372157e+01   3.3613980e-07
   4.2379416e+01   3.3589882e-07
   4.2386675e+01   3.3563256e-07
   4.2393935e+01   3.3534079e-07
   4.2401194e+01   3.3502332e-07
   4.2408453e+01   3.3467993e-07
   4.2415712e+01   3.3431040e-07
   4.2422971e+01   3.3391453e-07
   4.2430231e+01   3.3349210e-07
   4.2437490e+01   3.3304291e-07
   4.2444749e+01   3.3256675e-07
   4.2452008e+01   3.3206340e-07
   4.2459268e+01   3.3153265e-07
   4.2466527e+01   3.3097429e-07
   4.2473786e+01   3.3038812e-07
   4.2481045e+01   3.2977392e-07
   4.2488305e+01   3.2913147e-07
   4.2495564e+01   3.2846058e-07
   4.2502823e+01   3.2776102e-07
   4.2510082e+01   3.2703259e-07
   4.2517342e+01   3.2627508e-07
   4.2524601e+01   3.2548828e-07
   4.2531860e+01   3.2467196e-07
   4.2539119e+01   3.2382594e-07
   4.2546378e+01   3.2294999e-07
   4.2553638e+01   3.2204390e-07
   4.2560897e+01   3.2110746e-07
   4.2568156e+01   3.2014046e-07
   4.2575415e+01   3.1914270e-07
   4.2582675e+01   3.1811395e-07
   4.2589934e+01   3.1705402e-07
   4.2597193e+01   3.1596268e-07
   4.2604452e+01   3.1483973e-07
   4.2611712e+01   3.1368495e-07
   4.2618971e+01   3.1249815e-07
   4.2626230e+01   3.1127909e-07
   4.2633489e+01   3.1002759e-07
   4.2640749e+01   3.0874341e-07
   4.2648008e+01   3.0742636e-07
   4.2655267e+01   3.0607622e-07
   4.2662526e+01   3.0469278e-07
   4.2669785e+01   3.0327583e-07
   4.2677045e+01   3.0182516e-07
   4.2684304e+01   3.0034056e-07
   4.2691563e+01   2.9882182e-07
   4.2698822e+01   2.9726873e-07
   4.2706082e+01   2.9568107e-07
   4.2713341e+01   2.9405864e-07
   4.2720600e+01   2.9240122e-07
   4.2727859e+01   2.9070861e-07
   4.2735119e+01   2.8898059e-07
   4.2742378e+01   2.8721696e-07
   4.2749637e+01   2.8541749e-07
   4.2756896e+01   2.8358199e-07
   4.2764156e+01   2.8171024e-07
   4.2771415e+01   2.7980202e-07
   4.2778674e+01   2.7785714e-07
   4.2785933e+01   2.7587537e-07
   4.2793192e+01   2.7385651e-07
   4.2800452e+01   2.7180035e-07
   4.2807711e+01   2.6970668e-07
   4.2814970e+01   2.6757527e-07
   4.2822229e+01   2.6540594e-07
   4.2829489e+01   2.6319845e-07
   4.2836748e+01   2.6095261e-07
   4.2844007e+01   2.5866820e-07
   4.2851266e+01   2.5634501e-07
   4.2858526e+01   2.5398284e-07
   4.2865785e+01   2.5157104e-07
   4.2873044e+01   2.4901624e-07
   4.2880303e+01   2.4629873e-07
   4.2887563e+01   2.4342159e-07
   4.2894822e+01   2.4038784e-07
   4.2902081e+01   2.3720054e-07
   4.2909340e+01   2.3386274e-07
   4.2916599e+01   2.3037749e-07
   4.2923859e+01   2.2674784e-07
   4.2931118e+01   2.2297683e-07
   4.2938377e+01   2.1906753e-07
   4.2945636e+01   2.1502296e-07
   4.2952896e+01   2.1084619e-07
   4.2960155e+01   2.0654027e-07
   4.2967414e+01   2.0210823e-07
   4.2974673e+01   1.9755314e-07
   4.2981933e+01   1.9287804e-07
   4.2989192e+01   1.8808598e-07
   4.2996451e+01   1.8318001e-07
   4.3003710e+01   1.7816318e-07
   4.3010970e+01   1.7303853e-07
   4.3018229e+01   1.6780912e-07
   4.3025488e+01   1.6247800e-07
   4.3032747e+01   1.5704821e-07
   4.3040006e+01   1.5152281e-07
   4.3047266e+01   1.4590484e-07
   4.3054525e+01   1.4019735e-07
   4.3061784e+01   1.3440339e-07
   4.3069043e+01   1.2852602e-07
   4.3076303e+01   1.2256827e-07
   4.3083562e+01   1.1653320e-07
   4.3090821e+01   1.1042386e-07
   4.3098080e+01   1.0424330e-07
   4.3105340e+01   9.7994565e-08
   4.3112599e+01   9.1680705e-08
   4.3119858e+01   8.5304769e-08
   4.3127117e+01   7.8869808e-08
   4.3134377e+01   7.2378869e-08
   4.3141636e+01   6.5835002e-08
   4.3148895e+01   5.9241256e-08
   4.3156154e+01   5.2600681e-08
   4.3163413e+01   4.5916325e-08
   4.3170673e+01   3.9191238e-08
   4.3177932e+01   3.2428468e-08
   4.3185191e+01   2.5631066e-08
   4.3192450e+01   1.8802079e-08
   4.3199710e+01   1.1944558e-08
   4.3206969e+01   5.0615513e-09
   4.3214228e+01  -1.8438921e-09
   4.3221487e+01  -8.7687229e-09
   4.3228747e+01  -1.5709892e-08
   4.3236006e+01  -2.2664350e-08
   4.3243265e+01  -2.9629048e-08
   4.3250524e+01  -3.6600937e-08
   4.3257784e+01  -4.3576967e-08
   4.3265043e+01  -5.0554090e-08
   4.3272302e+01  -5.7529256e-08
   4.3279561e+01  -6.4499417e-08
   4.3286820e+01  -7.1461523e-08
   4.3294080e+01  -7.8412524e-08
   4.3301339e+01  -8.5349373e-08
   4.3308598e+01  -9.2269019e-08
   4.3315857e+01  -9.9168413e-08
   4.3323117e+01  -1.0604451e-07
   4.3330376e+01  -1.1289425e-07
   4.3337635e+01  -1.1971460e-07
   4.3344894e+01  -1.2650249e-07
   4.3352154e+01  -1.3325489e-07
   4.3359413e+01  -1.3996875e-07
   4.3366672e+01  -1.4664101e-07
   4.3373931e+01  -1.5326862e-07
   4.3381191e+01  -1.5984854e-07
   4.3388450e+01  -1.6637772e-07
   4.3395709e+01  -1.7285310e-07
   4.3402968e+01  -1.7927164e-07
   4.3410227e+01  -1.8563030e-07
   4.3417487e+01  -1.9192601e-07
   4.3424746e+01  -1.9815574e-07
   4.3432005e+01  -2.0431642e-07
   4.3439264e+01  -2.1040502e-07
   4.3446524e+01  -2.1641849e-07
   4.3453783e+01  -2.2235377e-07
   4.3461042e+01  -2.2820781e-07
   4.3468301e+01  -2.3397757e-07
   4.3475561e+01  -2.3966000e-07
   4.3482820e+01  -2.4525205e-07
   4.3490079e+01  -2.5075067e-07
   4.3497338e+01  -2.5615280e-07
   4.3504598e+01  -2.6145541e-07
   4.3511857e+01  -2.6665544e-07
   4.3519116e+01  -2.7174984e-07
   4.3526375e+01  -2.7673556e-07
   4.3533634e+01  -2.8160956e-07
   4.3540894e+01  -2.8636879e-07
   4.3548153e+01  -2.9101019e-07
   4.3555412e+01  -2.9553071e-07
   4.3562671e+01  -2.9992732e-07
   4.3569931e+01  -3.0419695e-07
   4.3577190e+01  -3.0833656e-07
   4.3584449e+01  -3.1234311e-07
   4.3591708e+01  -3.1621353e-07
   4.3598968e+01  -3.1994479e-07
   4.3606227e+01  -3.2353382e-07
   4.3613486e+01  -3.2697760e-07
   4.3620745e+01  -3.3027305e-07
   4.3628005e+01  -3.3341714e-07
   4.3635264e+01  -3.3640682e-07
   4.3642523e+01  -3.3923904e-07
   4.3649782e+01  -3.4191074e-07
   4.3657041e+01  -3.4441888e-07
   4.3664301e+01  -3.4676042e-07
   4.3671560e+01  -3.4893229e-07
   4.3678819e+01  -3.5093145e-07
   4.3686078e+01  -3.5275486e-07
   4.3693338e+01  -3.5439946e-07
   4.3700597e+01  -3.5586220e-07
   4.3707856e+01  -3.5714004e-07
   4.3715115e+01  -3.5822992e-07
   4.3722375e+01  -3.5912880e-07
   4.3729634e+01  -3.5983363e-07
   4.3736893e+01  -3.6034136e-07
   4.3744152e+01  -3.6064893e-07
   4.3751412e+01  -3.6075330e-07
   4.3758671e+01  -3.6065143e-07
   4.3765930e+01  -3.6034026e-07
   4.3773189e+01  -3.5981674e-07
   4.3780448e+01  -3.5907782e-07
   4.3787708e+01  -3.5812046e-07
   4.3794967e+01  -3.5694160e-07
   4.3802226e+01  -3.5553820e-07
   4.3809485e+01  -3.5390721e-07
   4.3816745e+01  -3.5204557e-07
   4.3824004e+01  -3.4995024e-07
   4.3831263e+01  -3.4761817e-07
   4.3838522e+01  -3.4504631e-07
   4.3845782e+01  -3.4223162e-07
   4.3853041e+01  -3.3917103e-07
   4.3860300e+01  -3.3586151e-07
   4.3867559e+01  -3.3230000e-07
   4.3874819e+01  -3.2848346e-07
   4.3882078e+01  -3.2440883e-07
   4.3889337e+01  -3.2007306e-07
   4.3896596e+01  -3.1547312e-07
   4.3903855e+01  -3.1060594e-07
   4.3911115e+01  -3.0546848e-07
   4.3918374e+01  -3.0005769e-07
   4.3925633e+01  -2.9437052e-07
   4.3932892e+01  -2.8840393e-07
   4.3940152e+01  -2.8215485e-07
   4.3947411e+01  -2.7562025e-07
   4.3954670e+01  -2.6879707e-07
   4.3961929e+01  -2.6168227e-07
   4.3969189e+01  -2.5427279e-07
   4.3976448e+01  -2.4656559e-07
   4.3983707e+01  -2.3855762e-07
   4.3990966e+01  -2.3024516e-07
   4.3998226e+01  -2.2156869e-07
   4.4005485e+01  -2.1249715e-07
   4.4012744e+01  -2.0303915e-07
   4.4020003e+01  -1.9320332e-07
   4.4027262e+01  -1.8299828e-07
   4.4034522e+01  -1.7243262e-07
   4.4041781e+01  -1.6151498e-07
   4.4049040e+01  -1.5025396e-07
   4.4056299e+01  -1.3865819e-07
   4.4063559e+01  -1.2673627e-07
   4.4070818e+01  -1.1449683e-07
   4.4078077e+01  -1.0194847e-07
   4.4085336e+01  -8.9099819e-08
   4.4092596e+01  -7.5959485e-08
   4.4099855e+01  -6.2536085e-08
   4.4107114e+01  -4.8838235e-08
   4.4114373e+01  -3.4874551e-08
   4.4121633e+01  -2.0653647e-08
   4.4128892e+01  -6.1841387e-09
   4.4136151e+01   8.5253576e-09
   4.4143410e+01   2.3466227e-08
   4.4150669e+01   3.8629854e-08
   4.4157929e+01   5.4007622e-08
   4.4165188e+01   6.9590918e-08
   4.4172447e+01   8.5371124e-08
   4.4179706e+01   1.0133963e-07
   4.4186966e+01   1.1748781e-07
   4.4194225e+01   1.3380706e-07
   4.4201484e+01   1.5028875e-07
   4.4208743e+01   1.6692428e-07
   4.4216003e+01   1.8370503e-07
   4.4223262e+01   2.0062239e-07
   4.4230521e+01   2.1766773e-07
   4.4237780e+01   2.3483244e-07
   4.4245040e+01   2.5210791e-07
   4.4252299e+01   2.6948552e-07
   4.4259558e+01   2.8695665e-07
   4.4266817e+01   3.0451270e-07
   4.4274076e+01   3.2214504e-07
   4.4281336e+01   3.3984506e-07
   4.4288595e+01   3.5760414e-07
   4.4295854e+01   3.7541368e-07
   4.4303113e+01   3.9326504e-07
   4.4310373e+01   4.1114963e-07
   4.4317632e+01   4.2905881e-07
   4.4324891e+01   4.4698399e-07
   4.4332150e+01   4.6491653e-07
   4.4339410e+01   4.8284783e-07
   4.4346669e+01   5.0076927e-07
   4.4353928e+01   5.1867224e-07
   4.4361187e+01   5.3654811e-07
   4.4368447e+01   5.5438828e-07
   4.4375706e+01   5.7218413e-07
   4.4382965e+01   5.8992704e-07
   4.4390224e+01   6.0760840e-07
   4.4397483e+01   6.2521959e-07
   4.4404743e+01   6.4275200e-07
   4.4412002e+01   6.6019701e-07
   4.4419261e+01   6.7754601e-07
   4.4426520e+01   6.9479037e-07
   4.4433780e+01   7.1192149e-07
   4.4441039e+01   7.2893075e-07
   4.4448298e+01   7.4580954e-07
   4.4455557e+01   7.6254923e-07
   4.4462817e+01   7.7914122e-07
   4.4470076e+01   7.9557689e-07
   4.4477335e+01   8.1184761e-07
   4.4484594e+01   8.2794479e-07
   4.4491854e+01   8.4385979e-07
   4.4499113e+01   8.5958401e-07
   4.4506372e+01   8.7510884e-07
   4.4513631e+01   8.9042565e-07
   4.4520890e+01   9.0552582e-07
   4.4528150e+01   9.2040075e-07
   4.4535409e+01   9.3504183e-07
   4.4542668e+01   9.4944042e-07
   4.4549927e+01   9.6358792e-07
   4.4557187e+01   9.7747572e-07
   4.4564446e+01   9.9109519e-07
   4.4571705e+01   1.0044377e-06
   4.4578964e+01   1.0174947e-06
   4.4586224e+01   1.0302575e-06
   4.4593483e+01   1.0427175e-06
   4.4600742e+01   1.0548662e-06
   4.4608001e+01   1.0666948e-06
   4.4615261e+01   1.0781947e-06
   4.4622520e+01   1.0893575e-06
   4.4629779e+01   1.1001743e-06
   4.4637038e+01   1.1106367e-06
   4.4644297e+01   1.1207360e-06
   4.4651557e+01   1.1304636e-06
   4.4658816e+01   1.1398109e-06
   4.4666075e+01   1.1487692e-06
   4.4673334e+01   1.1573300e-06
   4.4680594e+01   1.1654846e-06
   4.4687853e+01   1.1732244e-06
   4.4695112e+01   1.1805408e-06
   4.4702371e+01   1.1874252e-06
   4.4709631e+01   1.1938690e-06
   4.4716890e+01   1.1998635e-06
   4.4724149e+01   1.2054002e-06
   4.4731408e+01   1.2104704e-06
   4.4738668e+01   1.2150655e-06
   4.4745927e+01   1.2191768e-06
   4.4753186e+01   1.2227959e-06
   4.4760445e+01   1.2259140e-06
   4.4767704e+01   1.2285226e-06
   4.4774964e+01   1.2306129e-06
   4.4782223e+01   1.2321765e-06
   4.4789482e+01   1.2332047e-06
   4.4796741e+01   1.2336889e-06
   4.4804001e+01   1.2336205e-06
   4.4811260e+01   1.2329908e-06
   4.4818519e+01   1.2317912e-06
   4.4825778e+01   1.2300132e-06
   4.4833038e+01   1.2276480e-06
   4.4840297e+01   1.2246872e-06
   4.4847556e+01   1.2211220e-06
   4.4854815e+01   1.2169439e-06
   4.4862075e+01   1.2121442e-06
   4.4869334e+01   1.2067144e-06
   4.4876593e+01   1.2006458e-06
   4.4883852e+01   1.1939297e-06
   4.4891111e+01   1.1865577e-06
   4.4898371e+01   1.1785210e-06
   4.4905630e+01   1.1698111e-06
   4.4912889e+01   1.1604193e-06
   4.4920148e+01   1.1503370e-06
   4.4927408e+01   1.1395556e-06
   4.4934667e+01   1.1280666e-06
   4.4941926e+01   1.1158611e-06
   4.4949185e+01   1.1029308e-06
   4.4956445e+01   1.0892669e-06
   4.4963704e+01   1.0748608e-06
   4.4970963e+01   1.0597039e-06
   4.4978222e+01   1.0437877e-06
   4.4985482e+01   1.0271034e-06
   4.4992741e+01   1.0096425e-06
   4.5000000e+01   9.9139629e-07
];

# ╔═╡ b17ec7bc-479f-4d68-aaba-2027e9e8602a
let
	plot(
        AHL_CC2_interpolation[:, 1], AHL_CC2_interpolation[:, 2];
        xlabel="t [h]",
        ylabel="A(t) [mol/l]",
        legend=false,
    )
    scatter!(AHL_CC2_steps[:, 1], AHL_CC2_steps[:, 2])
end

# ╔═╡ a6919d15-e10c-4986-8b0b-c8f43ed60a41
chaos_ode = let
	Random.seed!(1234)
	g = 2.0
	T = 200.0
	N = 100
	J = g * randn(N, N) / sqrt(N)

	r = Array{Float64}(undef, N)
	function f(dh, h, p, t)
   		dh .= h
   		map!(tanh, r, h)
   		LinearAlgebra.BLAS.gemv!('N', 1.0, J, r, -1.0, dh)
	end
	
	ODEProblem(f, randn(N), (0.0, T))
end;

# ╔═╡ e26e4937-f9d9-4fdc-97a9-5719bc6da700
let
	sol = solve(
		chaos_ode,
		Vern9(),
		abstol=1/10^14,
		reltol=1/10^14,
		maxiters=10000000,
	)
	plot(sol, vars=(0, 1); label=false)
end

# ╔═╡ b4540eb8-20b8-47fb-8bd8-f03ee37fe8f1
let
	plt = plot(legend=:outertopright)
	for (name, alg, opts) in chaos_methods
		sol = solve(chaos_ode, alg; opts...)
		plot!(plt, sol, vars = (0, 1), label=name)
	end
	plt
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BlackBoxOptim = "a134a8b2-14d6-55f6-9291-3336d3ab0209"
DiffEqFlux = "aae7a2af-3d4f-5e19-a356-7da93b79d9d0"
DiffEqProblemLibrary = "a077e3f3-b75c-5d7f-a0c6-6bc4c8ec64a9"
DifferentialEquations = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
GalacticOptim = "a75be94c-b780-496d-a8a9-0878b188d577"
GraphRecipes = "bd48cda9-67a9-57be-86fa-5b3c104eda73"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
Turing = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"

[compat]
BlackBoxOptim = "~0.6.1"
DiffEqFlux = "~1.45.1"
DiffEqProblemLibrary = "~4.15.0"
DifferentialEquations = "~7.1.0"
GalacticOptim = "~2.3.1"
GraphRecipes = "~0.5.9"
Graphs = "~1.6.0"
LogExpFunctions = "~0.3.6"
PlutoUI = "~0.7.34"
StatsBase = "~0.33.16"
StatsPlots = "~0.14.33"
Turing = "~0.20.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.AbstractAlgebra]]
deps = ["GroupsCore", "InteractiveUtils", "LinearAlgebra", "MacroTools", "Markdown", "Random", "RandomExtensions", "SparseArrays", "Test"]
git-tree-sha1 = "c0750f99036c12a14c93a7b10609cb892ffbd092"
uuid = "c3fe647b-3220-5bb0-a1ea-a7954cac585d"
version = "0.24.1"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "6f1d9bc1c08f9f4a8fa92e3ea3cb50153a1b40d4"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.1.0"

[[deps.AbstractMCMC]]
deps = ["BangBang", "ConsoleProgressMonitor", "Distributed", "Logging", "LoggingExtras", "ProgressLogging", "Random", "StatsBase", "TerminalLoggers", "Transducers"]
git-tree-sha1 = "db0a7ff3fbd987055c43b4e12d2fa30aaae8749c"
uuid = "80f14c24-f653-4e6a-9b94-39d6b0f70001"
version = "3.2.1"

[[deps.AbstractPPL]]
deps = ["AbstractMCMC", "DensityInterface", "Setfield"]
git-tree-sha1 = "ca54027a17ca3133b36166191b5faa8a404e92d3"
uuid = "7a57a42e-76ec-4ea3-a279-07e840d6d9cf"
version = "0.4.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.AdvancedHMC]]
deps = ["AbstractMCMC", "ArgCheck", "DocStringExtensions", "InplaceOps", "LinearAlgebra", "ProgressMeter", "Random", "Requires", "Setfield", "Statistics", "StatsBase", "StatsFuns", "UnPack"]
git-tree-sha1 = "189473a73d664fe2496675775b6c8a732b8dfe26"
uuid = "0bf59076-c3b1-5ca4-86bd-e02cd72cde3d"
version = "0.3.3"

[[deps.AdvancedMH]]
deps = ["AbstractMCMC", "Distributions", "Random", "Requires"]
git-tree-sha1 = "8ad8bfddf8bb627d689ecb91599c349cbf15e971"
uuid = "5b7e9947-ddc0-4b3f-9b55-0d8042f74170"
version = "0.6.6"

[[deps.AdvancedPS]]
deps = ["AbstractMCMC", "Distributions", "Libtask", "Random", "StatsFuns"]
git-tree-sha1 = "59c47e9525d5a807a950d8b79b5d6e60b2f6de82"
uuid = "576499cb-2369-40b2-a588-c64705576edc"
version = "0.3.3"

[[deps.AdvancedVI]]
deps = ["Bijectors", "Distributions", "DistributionsAD", "DocStringExtensions", "ForwardDiff", "LinearAlgebra", "ProgressMeter", "Random", "Requires", "StatsBase", "StatsFuns", "Tracker"]
git-tree-sha1 = "130d6b17a3a9d420d9a6b37412cae03ffd6a64ff"
uuid = "b5ca4192-6429-45e5-a2d9-87aec30a685c"
version = "0.1.3"

[[deps.ArgCheck]]
git-tree-sha1 = "a3a402a35a2f7e0b87828ccabbd5ebfbebe356b4"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "91ca22c4b8437da89b030f08d71db55a379ce958"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.3"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "1ee88c4c76caa995a885dc2f22a5d548dfbbc0ba"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.2.2"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "e1ba79094cae97b688fb42d31cbbfd63a69706e4"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "0.7.8"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AutoHashEquals]]
git-tree-sha1 = "45bb6705d93be619b81451bb2006b7ee5d4e4453"
uuid = "15f4f7f2-30c1-5605-9d31-71845cf9641f"
version = "0.2.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "d127d5e4d86c7680b20c35d40b503c74b9a39b5e"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.4"

[[deps.BFloat16s]]
deps = ["LinearAlgebra", "Printf", "Random", "Test"]
git-tree-sha1 = "a598ecb0d717092b5539dbbe890c98bac842b072"
uuid = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
version = "0.2.0"

[[deps.BandedMatrices]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "ce68f8c2162062733f9b4c9e3700d5efc4a8ec47"
uuid = "aae01518-5342-5314-be14-df237901396f"
version = "0.16.11"

[[deps.BangBang]]
deps = ["Compat", "ConstructionBase", "Future", "InitialValues", "LinearAlgebra", "Requires", "Setfield", "Tables", "ZygoteRules"]
git-tree-sha1 = "d648adb5e01b77358511fb95ea2e4d384109fac9"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.3.35"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[deps.Bijections]]
git-tree-sha1 = "705e7822597b432ebe152baa844b49f8026df090"
uuid = "e2ed5e7c-b2de-5872-ae92-c73ca462fb04"
version = "0.1.3"

[[deps.Bijectors]]
deps = ["ArgCheck", "ChainRulesCore", "Compat", "Distributions", "Functors", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "MappedArrays", "Random", "Reexport", "Requires", "Roots", "SparseArrays", "Statistics"]
git-tree-sha1 = "369af32fcb9be65d496dc43ad0bb713705d4e859"
uuid = "76274a88-744f-5084-9051-94815aaf08c4"
version = "0.9.11"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "5e98d6a6aa92e5758c4d58501b7bf23732699fa3"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.2"

[[deps.BlackBoxOptim]]
deps = ["CPUTime", "Compat", "Distributed", "Distributions", "HTTP", "JSON", "LinearAlgebra", "Printf", "Random", "SpatialIndexing", "StatsBase"]
git-tree-sha1 = "41e347c63757dde7d22b2665b4efe835571983d4"
uuid = "a134a8b2-14d6-55f6-9291-3336d3ab0209"
version = "0.6.1"

[[deps.BlockArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra"]
git-tree-sha1 = "5524e27323cf4c4505699c3fb008c3f772269945"
uuid = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
version = "0.16.9"

[[deps.BlockBandedMatrices]]
deps = ["ArrayLayouts", "BandedMatrices", "BlockArrays", "FillArrays", "LinearAlgebra", "MatrixFactorizations", "SparseArrays", "Statistics"]
git-tree-sha1 = "b1db5b5daca19070297580e1c5b5095e7ada6792"
uuid = "ffab5731-97b5-5995-9138-79e8c1846df0"
version = "0.11.1"

[[deps.BoundaryValueDiffEq]]
deps = ["BandedMatrices", "DiffEqBase", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "NLsolve", "Reexport", "SparseArrays"]
git-tree-sha1 = "fe34902ac0c3a35d016617ab7032742865756d7d"
uuid = "764a87c0-6b3e-53db-9096-fe964310641d"
version = "2.7.1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[deps.CPUSummary]]
deps = ["Hwloc", "IfElse", "Static"]
git-tree-sha1 = "849799453de85b55e78550fc7b0c8f442eb497ab"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.1.8"

[[deps.CPUTime]]
git-tree-sha1 = "2dcc50ea6a0a1ef6440d6eecd0fe3813e5671f45"
uuid = "a9c8d775-2e2e-55fc-8582-045d282d599e"
version = "1.0.0"

[[deps.CSTParser]]
deps = ["Tokenize"]
git-tree-sha1 = "6cc1759204bed5a4e2a5c2f00901fd5d90bc7a62"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.3.1"

[[deps.CUDA]]
deps = ["AbstractFFTs", "Adapt", "BFloat16s", "CEnum", "CompilerSupportLibraries_jll", "ExprTools", "GPUArrays", "GPUCompiler", "LLVM", "LazyArtifacts", "Libdl", "LinearAlgebra", "Logging", "Printf", "Random", "Random123", "RandomNumbers", "Reexport", "Requires", "SparseArrays", "SpecialFunctions", "TimerOutputs"]
git-tree-sha1 = "200a493fcffb79c1bdb52d92df7a980aebc0b0a6"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "3.8.1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.Cassette]]
git-tree-sha1 = "6ce3cd755d4130d43bab24ea5181e77b89b51839"
uuid = "7057c7e9-c182-5462-911a-8362d720325c"
version = "0.3.9"

[[deps.Catalyst]]
deps = ["AbstractAlgebra", "DataStructures", "DiffEqBase", "DiffEqJump", "DocStringExtensions", "Graphs", "Latexify", "MacroTools", "ModelingToolkit", "Parameters", "Reexport", "Requires", "SparseArrays", "Symbolics"]
git-tree-sha1 = "5046c6ba75bb35d4818555cfa8e437550edd6271"
uuid = "479239e8-5488-4da2-87a7-35f2df7eef83"
version = "10.5.1"

[[deps.ChainRules]]
deps = ["ChainRulesCore", "Compat", "IrrationalConstants", "LinearAlgebra", "Random", "RealDot", "SparseArrays", "Statistics"]
git-tree-sha1 = "af66b25d30651591758ed540c203481f8003f4e9"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.26.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "f9982ef575e19b0e5c7a98c6e75ee496c0f73a93"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.12.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.CloseOpenIntervals]]
deps = ["ArrayInterface", "Static"]
git-tree-sha1 = "03dc838350fbd448fca0b99285ed4d60fc229b72"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.5"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "12fc73e5e0af68ad3137b886e3f7c1eacfca2640"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.17.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonMark]]
deps = ["Crayons", "JSON", "URIs"]
git-tree-sha1 = "4cd7063c9bdebdbd55ede1af70f3c2f48fab4215"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.6"

[[deps.CommonSolve]]
git-tree-sha1 = "68a0743f578349ada8bc911a5cbd5a2ef6ed6d1f"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.0"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.CompositeTypes]]
git-tree-sha1 = "d5b014b216dc891e81fea299638e4c10c657b582"
uuid = "b152e2b5-7a66-4b01-a709-34e65c35f657"
version = "0.1.2"

[[deps.CompositionsBase]]
git-tree-sha1 = "455419f7e328a1a2493cabc6428d79e951349769"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.1"

[[deps.ConsoleProgressMonitor]]
deps = ["Logging", "ProgressMeter"]
git-tree-sha1 = "3ab7b2136722890b9af903859afcf457fa3059e8"
uuid = "88cd18e8-d9cc-4ea6-8889-5259c0d15c8b"
version = "0.1.2"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f74e9d5388b8620b4cee35d4c5a618dd4dc547f4"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.3.0"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DEDataArrays]]
deps = ["ArrayInterface", "DocStringExtensions", "LinearAlgebra", "RecursiveArrayTools", "SciMLBase", "StaticArrays"]
git-tree-sha1 = "31186e61936fbbccb41d809ad4338c9f7addf7ae"
uuid = "754358af-613d-5f8d-9788-280bf1605d4c"
version = "0.2.0"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataInterpolations]]
deps = ["ChainRulesCore", "LinearAlgebra", "Optim", "RecipesBase", "RecursiveArrayTools", "Reexport", "RegularizationTools", "Symbolics"]
git-tree-sha1 = "cb2e29b3361e3b5b503c34c33965abc3209c1007"
uuid = "82cc6244-b520-54b8-b5a6-8a565e85f1d0"
version = "3.8.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DefineSingletons]]
git-tree-sha1 = "0fba8b706d0178b4dc7fd44a96a92382c9065c2c"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.2"

[[deps.DelayDiffEq]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "LinearAlgebra", "Logging", "NonlinearSolve", "OrdinaryDiffEq", "Printf", "RecursiveArrayTools", "Reexport", "UnPack"]
git-tree-sha1 = "ceb3463f2913eec2f0af5f0d8e1386fb546fdd32"
uuid = "bcd4f6db-9728-5f36-b5f7-82caef46ccdb"
version = "5.34.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffEqBase]]
deps = ["ArrayInterface", "ChainRulesCore", "DEDataArrays", "DataStructures", "Distributions", "DocStringExtensions", "FastBroadcast", "ForwardDiff", "FunctionWrappers", "IterativeSolvers", "LabelledArrays", "LinearAlgebra", "Logging", "MuladdMacro", "NonlinearSolve", "Parameters", "PreallocationTools", "Printf", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "Requires", "SciMLBase", "Setfield", "SparseArrays", "StaticArrays", "Statistics", "SuiteSparse", "ZygoteRules"]
git-tree-sha1 = "433291c9e63dcfc1a0e42c6aeb6bb5d3e5ab1789"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.81.4"

[[deps.DiffEqCallbacks]]
deps = ["DataStructures", "DiffEqBase", "ForwardDiff", "LinearAlgebra", "NLsolve", "OrdinaryDiffEq", "Parameters", "RecipesBase", "RecursiveArrayTools", "SciMLBase", "StaticArrays"]
git-tree-sha1 = "e57ecaf9f7875714c164ccca3c802711589127cf"
uuid = "459566f4-90b8-5000-8ac3-15dfb0a30def"
version = "2.20.1"

[[deps.DiffEqFlux]]
deps = ["Adapt", "Cassette", "ConsoleProgressMonitor", "DataInterpolations", "DiffEqBase", "DiffEqSensitivity", "DiffResults", "Distributions", "DistributionsAD", "Flux", "ForwardDiff", "GalacticOptim", "LinearAlgebra", "Logging", "LoggingExtras", "NNlib", "Optim", "Printf", "ProgressLogging", "Random", "RecursiveArrayTools", "Reexport", "Requires", "SciMLBase", "StaticArrays", "TerminalLoggers", "Zygote", "ZygoteRules"]
git-tree-sha1 = "7ae7fd3976654164d7107973847a4a0339d7c3f7"
uuid = "aae7a2af-3d4f-5e19-a356-7da93b79d9d0"
version = "1.45.1"

[[deps.DiffEqJump]]
deps = ["ArrayInterface", "Compat", "DataStructures", "DiffEqBase", "FunctionWrappers", "Graphs", "LinearAlgebra", "PoissonRandom", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "StaticArrays", "TreeViews", "UnPack"]
git-tree-sha1 = "628ddc7e2b44e214232e747b22f1a1d9a8f14467"
uuid = "c894b116-72e5-5b58-be3c-e6d8d4ac2b12"
version = "8.1.0"

[[deps.DiffEqNoiseProcess]]
deps = ["DiffEqBase", "Distributions", "LinearAlgebra", "Optim", "PoissonRandom", "QuadGK", "Random", "Random123", "RandomNumbers", "RecipesBase", "RecursiveArrayTools", "Requires", "ResettableStacks", "SciMLBase", "StaticArrays", "Statistics"]
git-tree-sha1 = "d6839a44a268c69ef0ed927b22a6f43c8a4c2e73"
uuid = "77a26b50-5914-5dd7-bc55-306e6241c503"
version = "5.9.0"

[[deps.DiffEqOperators]]
deps = ["BandedMatrices", "BlockBandedMatrices", "DiffEqBase", "DomainSets", "ForwardDiff", "LazyArrays", "LazyBandedMatrices", "LinearAlgebra", "LoopVectorization", "NNlib", "NonlinearSolve", "Requires", "RuntimeGeneratedFunctions", "SciMLBase", "SparseArrays", "SparseDiffTools", "StaticArrays", "SuiteSparse"]
git-tree-sha1 = "46432abd7a503624d69b0c3bef809676eb5357f2"
uuid = "9fdde737-9c7f-55bf-ade8-46b3f136cc48"
version = "4.40.0"

[[deps.DiffEqProblemLibrary]]
deps = ["Catalyst", "DiffEqBase", "DiffEqOperators", "Latexify", "LinearAlgebra", "Markdown", "ModelingToolkit", "Random"]
git-tree-sha1 = "f59be8332ebd86785bd4c4b2ffca89b17c41466a"
uuid = "a077e3f3-b75c-5d7f-a0c6-6bc4c8ec64a9"
version = "4.15.0"

[[deps.DiffEqSensitivity]]
deps = ["Adapt", "ArrayInterface", "Cassette", "ChainRulesCore", "DiffEqBase", "DiffEqCallbacks", "DiffEqNoiseProcess", "DiffEqOperators", "DiffRules", "Distributions", "Enzyme", "FFTW", "FiniteDiff", "ForwardDiff", "GlobalSensitivity", "LinearAlgebra", "LinearSolve", "OrdinaryDiffEq", "Parameters", "QuadGK", "QuasiMonteCarlo", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "Requires", "ReverseDiff", "SciMLBase", "SharedArrays", "Statistics", "StochasticDiffEq", "Tracker", "Zygote", "ZygoteRules"]
git-tree-sha1 = "5854a06aa8c8f2b987e3dcef73130a2ef3850c98"
uuid = "41bf760c-e81c-5289-8e54-58b1f1f8abe2"
version = "6.69.1"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "dd933c4ef7b4c270aacd4eb88fa64c147492acf0"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.10.0"

[[deps.DifferentialEquations]]
deps = ["BoundaryValueDiffEq", "DelayDiffEq", "DiffEqBase", "DiffEqCallbacks", "DiffEqJump", "DiffEqNoiseProcess", "LinearAlgebra", "LinearSolve", "OrdinaryDiffEq", "Random", "RecursiveArrayTools", "Reexport", "SteadyStateDiffEq", "StochasticDiffEq", "Sundials"]
git-tree-sha1 = "3f3db9365fedd5fdbecebc3cce86dfdfe5c43c50"
uuid = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
version = "7.1.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "38012bf3553d01255e83928eec9c998e19adfddf"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.48"

[[deps.DistributionsAD]]
deps = ["Adapt", "ChainRules", "ChainRulesCore", "Compat", "DiffRules", "Distributions", "FillArrays", "LinearAlgebra", "NaNMath", "PDMats", "Random", "Requires", "SpecialFunctions", "StaticArrays", "StatsBase", "StatsFuns", "ZygoteRules"]
git-tree-sha1 = "61805bf57113a52435a13ca0bb588daf8848784d"
uuid = "ced4e74d-a319-5a8a-b0ac-84af2272839c"
version = "0.6.37"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.DomainSets]]
deps = ["CompositeTypes", "IntervalSets", "LinearAlgebra", "StaticArrays", "Statistics"]
git-tree-sha1 = "5f5f0b750ac576bcf2ab1d7782959894b304923e"
uuid = "5b8099bc-c8ec-5219-889f-1d9e522a28bf"
version = "0.5.9"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.DynamicPPL]]
deps = ["AbstractMCMC", "AbstractPPL", "BangBang", "Bijectors", "ChainRulesCore", "Distributions", "LinearAlgebra", "MacroTools", "Random", "Setfield", "Test", "ZygoteRules"]
git-tree-sha1 = "3c6dbd56684cefce53756f7078f16fc281e4f3ee"
uuid = "366bfd00-2699-11ea-058f-f148b4cae6d8"
version = "0.17.5"

[[deps.DynamicPolynomials]]
deps = ["DataStructures", "Future", "LinearAlgebra", "MultivariatePolynomials", "MutableArithmetics", "Pkg", "Reexport", "Test"]
git-tree-sha1 = "74e63cbb0fda19eb0e69fbe622447f1100cd8690"
uuid = "7c1d4256-1411-5781-91ec-d7bc3513ac07"
version = "0.4.3"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "d7ab55febfd0907b285fbf8dc0c73c0825d9d6aa"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.3.0"

[[deps.EllipticalSliceSampling]]
deps = ["AbstractMCMC", "ArrayInterface", "Distributions", "Random", "Statistics"]
git-tree-sha1 = "c25a7254cf745720ddf9051cd0d2792b3baaca0e"
uuid = "cad2338a-1db2-11e9-3401-43bc07c9ede2"
version = "0.4.6"

[[deps.Enzyme]]
deps = ["Adapt", "CEnum", "Enzyme_jll", "GPUCompiler", "LLVM", "Libdl", "ObjectFile", "Test"]
git-tree-sha1 = "c7b2d2602edf60ac75f65c99d65ab0ea610e71f5"
uuid = "7da242da-08ed-463a-9acd-ee780be4f1d9"
version = "0.8.5"

[[deps.Enzyme_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "80a854ec5f97162bbae8e21b18c5e09d19b2fe98"
uuid = "7cc45869-7501-5eee-bdea-0790c847d4ef"
version = "0.0.25+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ae13fcbc7ab8f16b0856729b050ef0c446aa3492"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.4+0"

[[deps.ExponentialUtilities]]
deps = ["ArrayInterface", "LinearAlgebra", "Printf", "Requires", "SparseArrays"]
git-tree-sha1 = "3e1289d9a6a54791c1ee60da0850f4fd71188da6"
uuid = "d4d017d3-3776-5f7e-afef-a10c40355c18"
version = "1.11.0"

[[deps.ExprTools]]
git-tree-sha1 = "56559bbef6ca5ea0c0818fa5c90320398a6fbf8d"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.8"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "463cb335fa22c4ebacfd1faba5fde14edb80d96c"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.5"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FastBroadcast]]
deps = ["LinearAlgebra", "Polyester", "Static"]
git-tree-sha1 = "0f8ef5dcb040dbb9edd98b1763ac10882ee1ff03"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.1.12"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "deed294cde3de20ae0b2e0355a6c4e1c6a5ceffc"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.8"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "ec299fdc8f49ae450807b0cb1d161c6b76fd2b60"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.10.1"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Flux]]
deps = ["AbstractTrees", "Adapt", "ArrayInterface", "CUDA", "CodecZlib", "Colors", "DelimitedFiles", "Functors", "Juno", "LinearAlgebra", "MacroTools", "NNlib", "NNlibCUDA", "Pkg", "Printf", "Random", "Reexport", "SHA", "SparseArrays", "Statistics", "StatsBase", "Test", "ZipFile", "Zygote"]
git-tree-sha1 = "983271b47332fd3d9488d6f2d724570290971794"
uuid = "587475ba-b771-5e3f-ad9e-33799f191a9c"
version = "0.12.9"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "1bd6fc0c344fc0cbee1f42f8d2e7ec8253dda2d2"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.25"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.FunctionWrappers]]
git-tree-sha1 = "241552bc2209f0fa068b6415b1942cc0aa486bcc"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.2"

[[deps.Functors]]
git-tree-sha1 = "223fffa49ca0ff9ce4f875be001ffe173b2b7de4"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.2.8"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "51d2dfe8e590fbd74e7a842cf6d13d8a2f45dc01"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.6+0"

[[deps.GPUArrays]]
deps = ["Adapt", "LLVM", "LinearAlgebra", "Printf", "Random", "Serialization", "Statistics"]
git-tree-sha1 = "cf91e6e9213b9190dc0511d6fff862a86652a94a"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "8.2.1"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "abd824e1f2ecd18d33811629c781441e94a24e81"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "0.13.11"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "9f836fb62492f4b0f0d3b06f55983f2704ed0883"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.64.0"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "a6c850d77ad5118ad3be4bd188919ce97fffac47"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.64.0+0"

[[deps.GalacticOptim]]
deps = ["ArrayInterface", "ConsoleProgressMonitor", "DiffResults", "DocStringExtensions", "Logging", "LoggingExtras", "Pkg", "Printf", "ProgressLogging", "Reexport", "Requires", "SciMLBase", "TerminalLoggers"]
git-tree-sha1 = "e15a7020d538887c65a8584804b218fc768091cd"
uuid = "a75be94c-b780-496d-a8a9-0878b188d577"
version = "2.3.1"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[deps.GeometryTypes]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "d796f7be0383b5416cd403420ce0af083b0f9b28"
uuid = "4d00f742-c7ba-57c2-abde-4428a4b178cb"
version = "0.8.5"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.GlobalSensitivity]]
deps = ["Distributions", "FFTW", "ForwardDiff", "KernelDensity", "LinearAlgebra", "Parameters", "QuasiMonteCarlo", "Random", "RecursiveArrayTools", "Statistics", "StatsBase", "Trapz"]
git-tree-sha1 = "f7255ac54f458dd26d718ed832d48fd80bfd5305"
uuid = "af5da776-676b-467e-8baf-acd8249e4f0f"
version = "1.3.1"

[[deps.GraphRecipes]]
deps = ["AbstractTrees", "GeometryTypes", "Graphs", "InteractiveUtils", "Interpolations", "LinearAlgebra", "NaNMath", "NetworkLayout", "PlotUtils", "RecipesBase", "SparseArrays", "Statistics"]
git-tree-sha1 = "1735085e3a8dd0e14020bdcbf8da9893a5508a3f"
uuid = "bd48cda9-67a9-57be-86fa-5b3c104eda73"
version = "0.5.9"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "57c021de207e234108a6f1454003120a1bf350c4"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.6.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.GroupsCore]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "9e1a5e9f3b81ad6a5c613d181664a0efc6fe6dd7"
uuid = "d5909c97-4eac-4ecc-a3dc-fdd0858a4120"
version = "0.4.0"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "3965a3216446a6b020f0d48f1ba94ef9ec01720d"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.6"

[[deps.Hwloc]]
deps = ["Hwloc_jll"]
git-tree-sha1 = "92d99146066c5c6888d5a3abc871e6a214388b91"
uuid = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
version = "2.0.0"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d8bccde6fc8300703673ef9e1383b11403ac1313"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.7.0+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IRTools]]
deps = ["InteractiveUtils", "MacroTools", "Test"]
git-tree-sha1 = "7f43342f8d5fd30ead0ba1b49ab1a3af3b787d24"
uuid = "7869d1d1-7146-5819-86e3-90919afe41df"
version = "0.4.5"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[deps.InitialValues]]
git-tree-sha1 = "4da0f88e9a39111c2fa3add390ab15f3a44f3ca3"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.3.1"

[[deps.InplaceOps]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "50b41d59e7164ab6fda65e71049fee9d890731ff"
uuid = "505f98c9-085e-5b2c-8e89-488be7bf1f34"
version = "0.3.0"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b15fc0a95c564ca2e0a7ae12c1f095ca848ceb31"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.5"

[[deps.IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IterativeSolvers]]
deps = ["LinearAlgebra", "Printf", "Random", "RecipesBase", "SparseArrays"]
git-tree-sha1 = "1169632f425f79429f245113b775a0e3d121457c"
uuid = "42fd0dbc-a981-5370-80f2-aaf504508153"
version = "0.9.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.JuliaFormatter]]
deps = ["CSTParser", "CommonMark", "DataStructures", "Pkg", "Tokenize"]
git-tree-sha1 = "fcfaddc61f766211b2c835d3eceaf999b6ea9555"
uuid = "98e50ef6-434e-11e9-1051-2b60c6c9e899"
version = "0.22.4"

[[deps.Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "cae5e3dfd89b209e01bcd65b3a25e74462c67ee0"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.3.0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "6333cc5b848295895f3b23eb763d020fc8e05867"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.7.12"

[[deps.KrylovKit]]
deps = ["LinearAlgebra", "Printf"]
git-tree-sha1 = "0328ad9966ae29ccefb4e1b9bfd8c8867e4360df"
uuid = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
version = "0.5.3"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Printf", "Unicode"]
git-tree-sha1 = "f8dcd7adfda0dddaf944e62476d823164cccc217"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "4.7.1"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "62115afed394c016c2d3096c5b85c407b48be96b"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.13+1"

[[deps.LRUCache]]
git-tree-sha1 = "d64a0aff6691612ab9fb0117b0995270871c5dfc"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.3.0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LabelledArrays]]
deps = ["ArrayInterface", "ChainRulesCore", "LinearAlgebra", "MacroTools", "StaticArrays"]
git-tree-sha1 = "3696fdc1d3ef6e4d19551c92626066702a5db91c"
uuid = "2ee39098-c373-598a-b85f-a56591580800"
version = "1.7.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a8f4f279b6fa3c3c4f1adadd78a621b13a506bce"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.9"

[[deps.LatinHypercubeSampling]]
deps = ["Random", "StableRNGs", "StatsBase", "Test"]
git-tree-sha1 = "42938ab65e9ed3c3029a8d2c58382ca75bdab243"
uuid = "a5e1c1ea-c99a-51d3-a14d-a9a37257b02d"
version = "1.8.0"

[[deps.LatticeRules]]
deps = ["Random"]
git-tree-sha1 = "7f5b02258a3ca0221a6a9710b0a0a2e8fb4957fe"
uuid = "73f95e8e-ec14-4e6a-8b18-0d2e271c4e55"
version = "0.0.1"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static"]
git-tree-sha1 = "6dd77ee76188b0365f7d882d674b95796076fa2c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.5"

[[deps.Lazy]]
deps = ["MacroTools"]
git-tree-sha1 = "1370f8202dac30758f3c345f9909b97f53d87d3f"
uuid = "50d2b5c4-7a5e-59d5-8109-a42b560f39c0"
version = "0.15.1"

[[deps.LazyArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "MacroTools", "MatrixFactorizations", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "6dfb5dc9426e0cb7e237a71aa78c6b8c3e78a7fc"
uuid = "5078a376-72f3-5289-bfd5-ec5146d43c02"
version = "0.22.4"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyBandedMatrices]]
deps = ["ArrayLayouts", "BandedMatrices", "BlockArrays", "BlockBandedMatrices", "FillArrays", "LazyArrays", "LinearAlgebra", "MatrixFactorizations", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "8f4c427f6b505294dfefd343c8373b8c74e09973"
uuid = "d7e5e226-e90b-4449-9968-0f923699bf6f"
version = "0.7.6"

[[deps.LeastSquaresOptim]]
deps = ["FiniteDiff", "ForwardDiff", "LinearAlgebra", "Optim", "Printf", "SparseArrays", "Statistics", "SuiteSparse"]
git-tree-sha1 = "06ea4a7c438f434dc0dc8d03c72e61ee0bf3629d"
uuid = "0fc2ff8b-aaa3-5acd-a817-1944a5e08891"
version = "0.8.3"

[[deps.LeftChildRightSiblingTrees]]
deps = ["AbstractTrees"]
git-tree-sha1 = "b864cb409e8e445688bc478ef87c0afe4f6d1f8d"
uuid = "1d6d02ad-be62-4b6b-8a6d-2f90e265016e"
version = "0.1.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtask]]
deps = ["IRTools", "LRUCache", "LinearAlgebra", "MacroTools", "Statistics"]
git-tree-sha1 = "0688ada7ad4ea13c6088e3597931bab2e3e6fcd5"
uuid = "6f1fad26-d15e-5dc8-ae53-837a1d7b8c9f"
version = "0.6.8"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "f27132e551e959b3667d8c93eae90973225032dd"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.1.1"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearSolve]]
deps = ["ArrayInterface", "DocStringExtensions", "IterativeSolvers", "KLU", "Krylov", "KrylovKit", "LinearAlgebra", "RecursiveFactorization", "Reexport", "Requires", "SciMLBase", "Setfield", "SparseArrays", "SuiteSparse", "UnPack"]
git-tree-sha1 = "55e98c887e31f5c7a1901328e3f8ccd806024f45"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "1.11.3"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "e5718a00af0ab9756305a0392832c8952c7426c1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.6"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "dfeda1c1130990428720de0024d4516b1902ce98"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.7"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "ChainRulesCore", "CloseOpenIntervals", "DocStringExtensions", "ForwardDiff", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "SIMDDualNumbers", "SLEEFPirates", "SpecialFunctions", "Static", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "67c0dfeae307972b50009ce220aae5684ea852d1"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.101"

[[deps.MCMCChains]]
deps = ["AbstractMCMC", "AxisArrays", "Compat", "Dates", "Distributions", "Formatting", "IteratorInterfaceExtensions", "KernelDensity", "LinearAlgebra", "MCMCDiagnosticTools", "MLJModelInterface", "NaturalSort", "OrderedCollections", "PrettyTables", "Random", "RecipesBase", "Serialization", "Statistics", "StatsBase", "StatsFuns", "TableTraits", "Tables"]
git-tree-sha1 = "ddafbd2a95114d13721f2b6ddeeaee9529d6bc2b"
uuid = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
version = "5.0.3"

[[deps.MCMCDiagnosticTools]]
deps = ["AbstractFFTs", "DataAPI", "Distributions", "LinearAlgebra", "MLJModelInterface", "Random", "SpecialFunctions", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "058d08594e91ba1d98dcc3669f9421a76824aa95"
uuid = "be115224-59cd-429b-ad48-344e309966f0"
version = "0.1.3"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "5455aef09b40e5020e1520f551fa3135040d4ed0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+2"

[[deps.MLJModelInterface]]
deps = ["Random", "ScientificTypesBase", "StatisticalTraits"]
git-tree-sha1 = "8da86dcf5a9ea48413c7e920a990f0ea1869f9cb"
uuid = "e80e1ace-859a-464e-9ed9-23947d8ae3ea"
version = "1.3.6"

[[deps.MLStyle]]
git-tree-sha1 = "594e189325f66e23a8818e5beb11c43bb0141bcd"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.10"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MatrixFactorizations]]
deps = ["ArrayLayouts", "LinearAlgebra", "Printf", "Random"]
git-tree-sha1 = "1a0358d0283b84c3ccf9537843e3583c3b896c59"
uuid = "a3b82374-2e81-5b9e-98ce-41277c0e4c87"
version = "0.8.5"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[deps.Memoize]]
deps = ["MacroTools"]
git-tree-sha1 = "2b1dfcba103de714d31c033b5dacc2e4a12c7caa"
uuid = "c03570c3-d221-55d1-a50c-7939bbd78826"
version = "0.4.4"

[[deps.Metatheory]]
deps = ["AutoHashEquals", "DataStructures", "Dates", "DocStringExtensions", "Parameters", "Reexport", "TermInterface", "ThreadsX", "TimerOutputs"]
git-tree-sha1 = "0886d229caaa09e9f56bcf1991470bd49758a69f"
uuid = "e9d8d322-4543-424a-9be4-0cc815abe26c"
version = "1.3.3"

[[deps.MicroCollections]]
deps = ["BangBang", "InitialValues", "Setfield"]
git-tree-sha1 = "6bb7786e4f24d44b4e29df03c69add1b63d88f01"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.1.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.ModelingToolkit]]
deps = ["AbstractTrees", "ArrayInterface", "ConstructionBase", "DataStructures", "DiffEqBase", "DiffEqCallbacks", "DiffEqJump", "DiffRules", "Distributed", "Distributions", "DocStringExtensions", "DomainSets", "Graphs", "IfElse", "InteractiveUtils", "JuliaFormatter", "LabelledArrays", "Latexify", "Libdl", "LinearAlgebra", "MacroTools", "NaNMath", "NonlinearSolve", "RecursiveArrayTools", "Reexport", "Requires", "RuntimeGeneratedFunctions", "SafeTestsets", "SciMLBase", "Serialization", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicUtils", "Symbolics", "UnPack", "Unitful"]
git-tree-sha1 = "44388e28a039b4424ada5fba7463b31a1ee75d7b"
uuid = "961ee093-0014-501f-94e3-6117800e7a78"
version = "8.4.1"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MuladdMacro]]
git-tree-sha1 = "c6190f9a7fc5d9d5915ab29f2134421b12d24a68"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.2"

[[deps.MultivariatePolynomials]]
deps = ["DataStructures", "LinearAlgebra", "MutableArithmetics"]
git-tree-sha1 = "fa6ce8c91445e7cd54de662064090b14b1089a6d"
uuid = "102ac46a-7ee4-5c85-9060-abc95bfdeaa3"
version = "0.4.2"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "6d019f5a0465522bbfdd68ecfad7f86b535d6935"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.9.0"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "842b5ccd156e432f369b204bb704fd4020e383ac"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "0.3.3"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "50310f934e55e5ca3912fb941dec199b49ca9b68"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.2"

[[deps.NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[deps.NNlib]]
deps = ["Adapt", "ChainRulesCore", "Compat", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "996a3dca9893cb0741bbd08e48b2e2aa0d551898"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.8.2"

[[deps.NNlibCUDA]]
deps = ["CUDA", "LinearAlgebra", "NNlib", "Random", "Statistics"]
git-tree-sha1 = "26aeaa5338d7f288e7670268f56ccd7ab4697f66"
uuid = "a00861dc-f156-4864-bf3c-e6376f28a68d"
version = "0.2.1"

[[deps.NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[deps.NaturalSort]]
git-tree-sha1 = "eda490d06b9f7c00752ee81cfa451efe55521e21"
uuid = "c020b1a1-e9b0-503a-9c33-f039bfc54a85"
version = "1.0.0"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[deps.NetworkLayout]]
deps = ["GeometryBasics", "LinearAlgebra", "Random", "Requires", "SparseArrays"]
git-tree-sha1 = "cac8fc7ba64b699c678094fa630f49b80618f625"
uuid = "46757867-2c16-5918-afeb-47bfcb05e46a"
version = "0.4.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.NonlinearSolve]]
deps = ["ArrayInterface", "FiniteDiff", "ForwardDiff", "IterativeSolvers", "LinearAlgebra", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "SciMLBase", "Setfield", "StaticArrays", "UnPack"]
git-tree-sha1 = "b61c51cd5b9d8b197dfcbbf2077a0a4e1505278d"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "0.3.14"

[[deps.ObjectFile]]
deps = ["Reexport", "StructIO"]
git-tree-sha1 = "55ce61d43409b1fb0279d1781bf3b0f22c83ab3b"
uuid = "d8793406-e978-5875-9003-1fc021f44a92"
version = "0.3.7"

[[deps.Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "043017e0bdeff61cfbb7afeb558ab29536bbb5ed"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "648107615c15d4e09f7eca16307bc821c1f718d8"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.13+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "045d10789f5daff18deb454d5923c6996017c2f3"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.6.1"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.OrdinaryDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "ExponentialUtilities", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "LinearSolve", "Logging", "LoopVectorization", "MacroTools", "MuladdMacro", "NLsolve", "NonlinearSolve", "Polyester", "PreallocationTools", "RecursiveArrayTools", "Reexport", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "df82fa0f9f90f669cc3cf9e3f0400e431e0704ac"
uuid = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
version = "6.6.6"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ee26b350276c51697c9c2d88a072b339f9f03d73"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.5"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "13468f237353112a01b2d6b32f3d0f80219944aa"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "6f1b25e8ea06279b5689263cc538f51331d7ca17"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.1.3"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "d9c49967b9948635152edaa6a91ca4f43be8d24c"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.25.10"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8979e9802b4ac3d58c503a20f2824ad67f9074dd"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.34"

[[deps.PoissonRandom]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "44d018211a56626288b5d3f8c6497d28c26dc850"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.0"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Requires", "Static", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "de33c49a06d7eb1eef40b83fe873c1c2cba25623"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.6.4"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "0bc9e1a21ba066335a5207ac031ee41f72615181"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.1.3"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterface", "ForwardDiff", "LabelledArrays"]
git-tree-sha1 = "e4cb8d4a2edf9b3804c1fb2c2de57d634ff3f36e"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.2.3"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.QuasiMonteCarlo]]
deps = ["Distributions", "LatinHypercubeSampling", "LatticeRules", "Sobol"]
git-tree-sha1 = "bc69c718a83951dcb999404ff267a7b8c39c1c63"
uuid = "8a4e6c94-4038-4cdc-81c3-7e6ffdb2a71b"
version = "0.2.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Libdl", "Random", "RandomNumbers"]
git-tree-sha1 = "0e8b146557ad1c6deb1367655e052276690e71a3"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.4.2"

[[deps.RandomExtensions]]
deps = ["Random", "SparseArrays"]
git-tree-sha1 = "062986376ce6d394b23d5d90f01d81426113a3c9"
uuid = "fb686558-2515-59ef-acaa-46db3789a887"
version = "0.4.3"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "01d341f502250e81f6fec0afe662aa861392a3aa"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.2"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "37c1631cb3cc36a535105e6d5557864c82cd8c2b"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.5.0"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "ChainRulesCore", "DocStringExtensions", "FillArrays", "LinearAlgebra", "RecipesBase", "Requires", "StaticArrays", "Statistics", "ZygoteRules"]
git-tree-sha1 = "736699f42935a2b19b37a6c790e2355ca52a12ee"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.24.2"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "7ad4c2ef15b7aecd767b3921c0d255d39b3603ea"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.9"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Referenceables]]
deps = ["Adapt"]
git-tree-sha1 = "e681d3bfa49cd46c3c161505caddf20f0e62aaa9"
uuid = "42d2dcc6-99eb-4e98-b66c-637b7d73030e"
version = "0.1.2"

[[deps.RegularizationTools]]
deps = ["Calculus", "Lazy", "LeastSquaresOptim", "LinearAlgebra", "MLStyle", "Memoize", "Optim", "Random", "Underscores"]
git-tree-sha1 = "ab1d6d815e85c8aa57e27456339931ee02a9ab5f"
uuid = "29dad682-9a27-4bc3-9c72-016788665182"
version = "0.5.3"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.ResettableStacks]]
deps = ["StaticArrays"]
git-tree-sha1 = "256eeeec186fa7f26f2801732774ccf277f05db9"
uuid = "ae5879a3-cd67-5da8-be7f-38c6eb64a37b"
version = "1.1.1"

[[deps.ReverseDiff]]
deps = ["ChainRulesCore", "DiffResults", "DiffRules", "ForwardDiff", "FunctionWrappers", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NaNMath", "Random", "SpecialFunctions", "StaticArrays", "Statistics"]
git-tree-sha1 = "8d85c98fc33d4d37d88c8f9ccee4f1f3f98e56f4"
uuid = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
version = "1.12.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.Roots]]
deps = ["CommonSolve", "Printf", "Setfield"]
git-tree-sha1 = "0abe7fc220977da88ad86d339335a4517944fea2"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "1.3.14"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "cdc1e4278e91a6ad530770ebb327f9ed83cf10c4"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.3"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SIMDDualNumbers]]
deps = ["ForwardDiff", "IfElse", "SLEEFPirates", "VectorizationBase"]
git-tree-sha1 = "62c2da6eb66de8bb88081d20528647140d4daa0e"
uuid = "3cdde19b-5bb0-4aaf-8931-af3e248e098b"
version = "0.1.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "3a5ae1db486e4ce3ccd2b392389943481e20401f"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.29"

[[deps.SafeTestsets]]
deps = ["Test"]
git-tree-sha1 = "36ebc5622c82eb9324005cc75e7e2cc51181d181"
uuid = "1bc83da4-3b8d-516f-aca4-4fe02f6d838f"
version = "0.0.1"

[[deps.SciMLBase]]
deps = ["ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "RecipesBase", "RecursiveArrayTools", "StaticArrays", "Statistics", "Tables", "TreeViews"]
git-tree-sha1 = "f4862c0cb4e34ed182718221028ba1bf50742108"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "1.26.1"

[[deps.ScientificTypesBase]]
git-tree-sha1 = "a8e18eb383b5ecf1b5e6fc237eb39255044fd92b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "3.0.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "6a2f7d70512d205ca8c7ee31bfa9f142fe74310c"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.12"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "0afd9e6c623e379f593da01f20590bacc26d1d14"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.8.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sobol]]
deps = ["DelimitedFiles", "Random"]
git-tree-sha1 = "5a74ac22a9daef23705f010f72c81d6925b19df8"
uuid = "ed01d8cd-4d21-5b2a-85b4-cc3bdc58bad4"
version = "1.5.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SparseDiffTools]]
deps = ["Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays", "VertexSafeGraphs"]
git-tree-sha1 = "87efd1676d87706f4079e8e717a7a5f02b6ea1ad"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "1.20.2"

[[deps.SpatialIndexing]]
git-tree-sha1 = "fb7041e6bd266266fa7cdeb80427579e55275e4f"
uuid = "d4ead438-fe20-5cc5-a293-4fd39a41b74c"
version = "0.1.3"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "8d0c8e3d0ff211d9ff4a0c2307d876c99d10bdf1"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.2"

[[deps.SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "39c9f91521de844bad65049efd4f9223e7ed43f9"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.14"

[[deps.StableRNGs]]
deps = ["Random", "Test"]
git-tree-sha1 = "3be7d49667040add7ee151fefaf1f8c04c8c8276"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.0"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "7f5a513baec6f122401abfc8e9c074fdac54f6c1"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.4.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "95c6a5d0e8c69555842fc4a927fc485040ccc31c"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.3.5"

[[deps.StatisticalTraits]]
deps = ["ScientificTypesBase"]
git-tree-sha1 = "271a7fea12d319f23d55b785c51f6876aadb9ac0"
uuid = "64bff920-2084-43da-a3e6-9bb72801c0c9"
version = "3.0.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c3d8ba7f3fa0625b062b82853a7d5229cb728b6b"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.1"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "8977b17906b0a1cc74ab2e3a05faa16cf08a8291"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.16"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f35e1879a71cca95f4826a14cdbf0b9e253ed918"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.15"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "4d9c69d65f1b270ad092de0abe13e859b8c55cad"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.14.33"

[[deps.SteadyStateDiffEq]]
deps = ["DiffEqBase", "DiffEqCallbacks", "LinearAlgebra", "NLsolve", "Reexport", "SciMLBase"]
git-tree-sha1 = "3e057e1f9f12d18cac32011aed9e61eef6c1c0ce"
uuid = "9672c7b4-1e72-59bd-8a11-6ac3964bc41f"
version = "1.6.6"

[[deps.StochasticDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DiffEqJump", "DiffEqNoiseProcess", "DocStringExtensions", "FillArrays", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "Logging", "MuladdMacro", "NLsolve", "OrdinaryDiffEq", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "5f88440e7470baad99f559eed674a46d2b6b96f7"
uuid = "789caeaf-c7a9-5a7d-9973-96adeb23e2a0"
version = "6.44.0"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "ManualMemory", "Requires", "SIMDTypes", "Static", "ThreadingUtilities"]
git-tree-sha1 = "fdbb530d433413e5ec8e274d2971786731ef82e9"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.2.10"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "d21f2c564b21a202f4677c0fba5b5ee431058544"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.4"

[[deps.StructIO]]
deps = ["Test"]
git-tree-sha1 = "010dc73c7146869c042b49adcdb6bf528c12e859"
uuid = "53d494c1-5632-5724-8f4c-31dff12d585f"
version = "0.3.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"

[[deps.Sundials]]
deps = ["CEnum", "DataStructures", "DiffEqBase", "Libdl", "LinearAlgebra", "Logging", "Reexport", "SparseArrays", "Sundials_jll"]
git-tree-sha1 = "76d881c22a2f3f879ad74b5a9018c609969149ab"
uuid = "c3572dad-4567-51f8-b174-8c6c989267f4"
version = "4.9.2"

[[deps.Sundials_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg", "SuiteSparse_jll"]
git-tree-sha1 = "04777432d74ec5bc91ca047c9e0e0fd7f81acdb6"
uuid = "fb77eaff-e24c-56d4-86b1-d163f2edb164"
version = "5.2.1+0"

[[deps.SymbolicUtils]]
deps = ["AbstractTrees", "Bijections", "ChainRulesCore", "Combinatorics", "ConstructionBase", "DataStructures", "DocStringExtensions", "DynamicPolynomials", "IfElse", "LabelledArrays", "LinearAlgebra", "Metatheory", "MultivariatePolynomials", "NaNMath", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "TermInterface", "TimerOutputs"]
git-tree-sha1 = "bfa211c9543f8c062143f2a48e5bcbb226fd790b"
uuid = "d1185830-fcd6-423d-90d6-eec64667417b"
version = "0.19.7"

[[deps.Symbolics]]
deps = ["ArrayInterface", "ConstructionBase", "DataStructures", "DiffRules", "Distributions", "DocStringExtensions", "DomainSets", "IfElse", "Latexify", "Libdl", "LinearAlgebra", "MacroTools", "Metatheory", "NaNMath", "RecipesBase", "Reexport", "Requires", "RuntimeGeneratedFunctions", "SciMLBase", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicUtils", "TermInterface", "TreeViews"]
git-tree-sha1 = "074e08aea1c745664da5c4b266f50b840e528b1c"
uuid = "0c5d862f-8b57-4792-8d23-62f2024744c7"
version = "4.3.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TermInterface]]
git-tree-sha1 = "7aa601f12708243987b88d1b453541a75e3d8c7a"
uuid = "8ea1fca8-c5ef-4a55-8b96-4e9afe9c9a3c"
version = "0.2.3"

[[deps.TerminalLoggers]]
deps = ["LeftChildRightSiblingTrees", "Logging", "Markdown", "Printf", "ProgressLogging", "UUIDs"]
git-tree-sha1 = "62846a48a6cd70e63aa29944b8c4ef704360d72f"
uuid = "5d786b92-1e48-4d6f-9151-6b4477ca9bed"
version = "0.1.5"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "884539ba8c4584a3a8173cb4ee7b61049955b79c"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.4.7"

[[deps.ThreadsX]]
deps = ["ArgCheck", "BangBang", "ConstructionBase", "InitialValues", "MicroCollections", "Referenceables", "Setfield", "SplittablesBase", "Transducers"]
git-tree-sha1 = "6dad289fe5fc1d8e907fa855135f85fb03c8fa7a"
uuid = "ac1d9e8a-700a-412c-b207-f0111f4b6c0d"
version = "0.1.9"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "97e999be94a7147d0609d0b9fc9feca4bf24d76b"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.15"

[[deps.Tokenize]]
git-tree-sha1 = "0952c9cee34988092d73a5708780b3917166a0dd"
uuid = "0796e94c-ce3b-5d07-9a54-7f471281c624"
version = "0.5.21"

[[deps.Tracker]]
deps = ["Adapt", "DiffRules", "ForwardDiff", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NNlib", "NaNMath", "Printf", "Random", "Requires", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "7b00adbe4216b919d487d82a852c48f378c6ed37"
uuid = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
version = "0.2.18"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Transducers]]
deps = ["Adapt", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "Setfield", "SplittablesBase", "Tables"]
git-tree-sha1 = "1cda71cc967e3ef78aa2593319f6c7379376f752"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.72"

[[deps.Trapz]]
git-tree-sha1 = "79eb0ed763084a3e7de81fe1838379ac6a23b6a0"
uuid = "592b5752-818d-11e9-1e9a-2b8ca4a44cd1"
version = "2.0.3"

[[deps.TreeViews]]
deps = ["Test"]
git-tree-sha1 = "8d0d7a3fe2f30d6a7f833a5f19f7c7a5b396eae6"
uuid = "a2a6695c-b41b-5b7d-aed9-dbfdeacea5d7"
version = "0.3.0"

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "c3ab8b77b82fd92e2b6eea8a275a794d5a6e4011"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.1.9"

[[deps.Turing]]
deps = ["AbstractMCMC", "AdvancedHMC", "AdvancedMH", "AdvancedPS", "AdvancedVI", "BangBang", "Bijectors", "DataStructures", "Distributions", "DistributionsAD", "DocStringExtensions", "DynamicPPL", "EllipticalSliceSampling", "ForwardDiff", "Libtask", "LinearAlgebra", "MCMCChains", "NamedArrays", "Printf", "Random", "Reexport", "Requires", "SciMLBase", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Tracker", "ZygoteRules"]
git-tree-sha1 = "ce8198b3ac6bfa709f7c066ee0db13be52b2cbf8"
uuid = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"
version = "0.20.1"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Underscores]]
git-tree-sha1 = "6e6de5a5e7116dcff8effc99f6f55230c61f6862"
uuid = "d9a01c3f-67ce-4d8c-9b55-35f6e4050bb1"
version = "3.0.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["ConstructionBase", "Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "b649200e887a487468b71821e2644382699f1b0f"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.11.0"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "Hwloc", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static"]
git-tree-sha1 = "e9a35d501b24c127af57ca5228bcfb806eda7507"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.24"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "66d72dc6fcc86352f01676e8f0f698562e60510f"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.23.0+0"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "505c31f585405fc375d99d02588f6ceaba791241"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.5"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.Zygote]]
deps = ["AbstractFFTs", "ChainRules", "ChainRulesCore", "DiffRules", "Distributed", "FillArrays", "ForwardDiff", "IRTools", "InteractiveUtils", "LinearAlgebra", "MacroTools", "NaNMath", "Random", "Requires", "SpecialFunctions", "Statistics", "ZygoteRules"]
git-tree-sha1 = "88a4d79f4e389456d5a90d79d53d1738860ef0a5"
uuid = "e88e6eb3-aa80-5325-afca-941959d7151f"
version = "0.6.34"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─1aab1648-ae1a-46b5-af7c-3db839eda775
# ╟─dc9484dc-3d5b-4edd-b8e6-50e9a9384ccf
# ╠═4cf10ace-aa9e-4c83-b766-3c8ec0ac88af
# ╟─44a14e5e-8f8b-11ec-1a0d-e1f4fd89bbc9
# ╟─d186ea33-ae8c-452d-bd35-05b02770078c
# ╟─7961a64e-24a2-4184-87ae-ee5362c94524
# ╟─3db082dd-7663-43fc-a84e-25c9cafa9bee
# ╟─25284a37-6c21-4b67-9c1f-5222e4b7c890
# ╟─27b8fc94-eef0-41a8-bff1-c83577216a1d
# ╟─2baccd93-9524-47d7-a99d-29567cde10b0
# ╟─874c1c27-77f9-4651-85d5-5136d85b50df
# ╠═4963b2fd-f1a3-457f-b5c8-ed87efd45b41
# ╠═87dc589b-7951-4c48-ab1f-a59b969c84af
# ╟─4d4f219d-cfa3-4dd5-bfbf-ce3a485508bb
# ╠═f55c3c79-24fa-4c88-aeca-84ee77a99d43
# ╟─3417db1e-476e-4ec2-8e26-bd28762bab72
# ╟─91272182-913b-4cfd-9594-f09d0ffdb02e
# ╟─be1f53cf-a001-4712-b0c8-466abb503495
# ╟─c61bc310-117d-4f1b-922a-4e761dd47916
# ╠═7b01dced-84d1-405c-81ca-da8558c6301b
# ╟─1314ea89-8f18-454d-afb9-edd92f6799cf
# ╠═1031c4ff-0021-47a6-9b40-6d050bcbe72f
# ╟─002ebd6b-115c-400d-a35c-b6eaa1844553
# ╠═78b0bf4f-6ac6-47b3-abd2-c3366730f45a
# ╠═ca014089-13cb-436c-8422-416368897a9a
# ╠═2a48707c-a9e5-4267-a5bf-47e9ee877133
# ╠═3a9ebd39-b5b2-4605-9f99-6cd993bc0c25
# ╟─7274b0ae-0ab8-42ea-bb87-63108cdb6677
# ╠═e748a9c8-f50c-422c-a0ee-9c4c363b06fa
# ╠═9444f2bb-d2c4-4d08-914f-63161db4ee50
# ╟─40f29b3a-fe04-42b2-99fb-07875e9b76fb
# ╟─a97f083a-9eb5-49de-8be8-ff82da8d50d0
# ╟─e26e4937-f9d9-4fdc-97a9-5719bc6da700
# ╠═1a6e99db-6a42-485b-a100-e23574c17dda
# ╟─b4540eb8-20b8-47fb-8bd8-f03ee37fe8f1
# ╟─d354e9b2-9566-490b-9faf-6fcde3e56ac4
# ╟─8fcf8bdb-3119-43f2-9abf-44dced28d31a
# ╟─afd160a1-74da-41a7-990d-c9981e9f5f5b
# ╟─30c3f022-b0fb-4df7-a292-e1a190829b3b
# ╟─bea72389-f73b-4c5c-87a5-3d240346e3f7
# ╟─df7f2ec7-9981-417e-b2cb-315fb4e51b84
# ╟─b17ec7bc-479f-4d68-aaba-2027e9e8602a
# ╟─8d2a0997-e5f7-4141-bd66-8167b160068b
# ╟─5e88a3b7-00e8-43aa-8469-beaabe79eb46
# ╟─3bb8c4ba-897c-4b51-b6dc-377b239760b7
# ╟─242b55bd-bbda-4cc5-88e6-cba81acbb672
# ╟─511c9a1e-7c61-45f6-87c6-87a68c6c8cbe
# ╟─a4d90951-5051-4bab-a6c5-1641596effa3
# ╟─bf4c1e64-f7a8-45cd-9345-7bb1ec3e889e
# ╟─b6a5aa0f-2334-414e-a206-ade905997c26
# ╠═c44a7e31-723b-4c72-b845-f8fce0c4979b
# ╠═1a1f0444-deec-48cc-9a61-22d0a3ebb03c
# ╠═eedc301a-ab50-4e7e-8d6f-63052ad852eb
# ╟─679fa6cd-029d-494d-9ccc-67a5a7c79b99
# ╟─b373c5c7-c45c-4161-90ae-3ab4c6bedcd3
# ╟─21802542-35fd-4034-9ddd-9f783bf59ccb
# ╟─b7354aa0-d242-462e-9c94-9cd1a3d0298d
# ╟─19d90bc8-f566-4da7-af5c-333e9d2f73cc
# ╠═1d6500d0-109e-42f3-a469-870d7bbf621a
# ╟─56591331-ed74-443e-9f23-6b636c47eb29
# ╠═6ca7370f-5ac4-4179-9192-2c836cc3af73
# ╟─9a440f90-2535-4203-87c1-0cd16cc43fbf
# ╟─b0ce4ad8-94b8-4c07-990c-4d1735d5b81a
# ╟─1fa0638a-99d0-4eda-8684-9b93c07095d6
# ╟─5dd8d9f7-3272-46f6-ac82-8f81440dc575
# ╟─7ecefca2-0bb4-4513-9a91-5094e209fd3a
# ╟─fa37a1be-b38a-4188-a5d4-176d6cf6781e
# ╟─8223bb89-f5bc-44f1-a3cd-e305e27d9c34
# ╟─58f93dd6-f7db-4a58-9225-0fbedc6eb460
# ╟─1d39a484-ecc1-475d-be15-6a48dcc9eb5b
# ╟─26224476-9063-4803-8f0c-73756923b0af
# ╟─9291d064-e049-485e-a6a0-8ef6c47ab89b
# ╟─fb7ede45-316f-48fc-b5ab-a74080f5999f
# ╟─046212f2-6f6d-421d-8cba-2449997abe56
# ╟─39dc9c40-fa00-40a5-a1d1-b9b2cf207423
# ╠═662c239c-9248-4659-937c-e5ddc5fd5d09
# ╟─c0c5345f-248a-4fe1-b5e9-9164b038e5ca
# ╟─ae9a2dc6-75ec-4931-b3e6-4b8695f5e2d8
# ╠═85008594-201e-4cbd-90a0-24ee6fa4e09c
# ╟─15d843cb-88b8-452f-a83a-dea0364b0da1
# ╟─9bfe92a6-82cc-4db9-b4f9-770349cb22d3
# ╠═7d6cf54d-2e64-446e-a0b3-7f6d6224f882
# ╟─c970dc69-7c14-4784-9537-afc114ce895e
# ╟─984dfd8c-b468-4e28-8b1b-58359a28d2f2
# ╟─b3684cff-a0f8-4600-b23e-11353089d936
# ╟─f318a0f8-47b8-4254-8cb2-be6b87b11ff4
# ╟─4b3def49-04f6-4271-af67-b73fbbd5975d
# ╟─bdc07f65-3088-4dbb-96f6-df96486f22c5
# ╟─ae076b1a-6218-4afb-8a02-cee5da2d5c9e
# ╟─a6919d15-e10c-4986-8b0b-c8f43ed60a41
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
