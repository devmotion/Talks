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

# ╔═╡ 019c66f4-b354-4d56-a9cf-7eefad5eb205
begin
    using AbstractGPs
    using AbstractGPsMakie
    using AlgebraOfGraphics
    using CairoMakie
    using CalibrationErrors
    using CalibrationErrorsDistributions
    using CalibrationTests
    using DataFrames
    using MLJ
    using MLJNaiveBayesInterface
    using Luxor
    using PalmerPenguins
    using PlutoUI
    using ReliabilityDiagrams
    using StatsBase

    using Random

    # plotting settings
    CairoMakie.activate!(; type="svg")
    set_theme!(; AlgebraOfGraphics.aog_theme()..., resolution=(800, 400))
end

# ╔═╡ 1e1089e5-20ea-43a6-beaa-2c955aec85e6
html"<button onclick='present()'>present</button>"

# ╔═╡ 301bd6d5-4309-4b58-8b20-b09eb7ffe4a1
md"##### Package initialization"

# ╔═╡ cff7084e-c9b5-11eb-33b6-81c95ee6c900
md"""
# Calibration analysis of probabilistic models in Julia

$(Resource("https://widmann.dev/assets/profile_small.jpg", :width=>75, :align=>"right"))
**David Widmann
(@devmotion $(Resource("https://raw.githubusercontent.com/edent/SuperTinyIcons/bed6907f8e4f5cb5bb21299b9070f4d7c51098c0/images/svg/github.svg", :width=>10)))**

Uppsala University, Sweden

*JuliaCon, July 2021*
"""

# ╔═╡ d7ab458e-e27c-4637-aeb3-2afda37b6e5f
md"""
## Probabilistic predictive models

> A probabilistic predictive model **predicts a probability distribution** over a set of targets for a given feature.

One can express the uncertainty in the prediction, which might be inherent to the prediction task or caused by insufficient knowledge of the underlying relation between feature and target.
"""

# ╔═╡ 3445b353-d975-4416-8a78-41681da6d046
md"""
### Example: Prediction of penguin species

*Gorman KB, Williams TD, Fraser WR (2014). [Ecological sexual dimorphism and environmental variability within a community of Antarctic penguins (genus Pygoscelis)](doi.org/10.1371/journal.pone.0090081). PLoS ONE 9(3):e90081*
"""

# ╔═╡ 458ec313-ddbb-4edb-b6a6-ae5cb3a0b5b5
penguins = withenv("DATADEPS_ALWAYS_ACCEPT" => true) do
    dropmissing(DataFrame(PalmerPenguins.load()))
end

# ╔═╡ 5e63dd4f-d7b1-41f8-81c7-85df389241b9
md"""
$(Resource(
	"https://allisonhorst.github.io/palmerpenguins/reference/figures/lter_penguins.png",
	"width" => 300
))
$(Resource(
	"https://www.researchgate.net/profile/Meg-Gravley/publication/306376388/figure/fig1/AS:619788535615488@1524780510336/a-The-marine-ecosystem-west-of-the-Antarctic-Peninsula-extends-from-northern-Alexander_W640.jpg",
	"width" => 300
))
"""

# ╔═╡ 562ddf0e-1131-4aca-8189-8f4d2c0040d8
let
    plt =
        data(penguins) *
        mapping(
            :bill_length_mm => "bill length (mm)",
            :flipper_length_mm => "flipper length (mm)",
        ) *
        mapping(; color=:species) *
        visual(; alpha=0.7)
    draw(plt)
end

# ╔═╡ 24e81bfb-b4d3-4454-8100-a19fe1bce410
md"""
We split the Palmer penguin dataset randomly into a training (70%) and validation (30%) dataset.
"""

# ╔═╡ 68e437eb-81dd-4371-b855-761e4be50db2
md"""
We learn a [Gaussian naive Bayes classifier](https://en.wikipedia.org/wiki/Naive_Bayes_classifier#Gaussian_na%C3%AFve_Bayes) that is able to predict the probability of the penguin species from the bill length and the flipper length.

> We denote the features by ``X`` and the target by ``Y``.
"""

# ╔═╡ 42b12f2e-9ffd-48f8-b9c8-bb5d709fa340
md"""
The predictions are **distributions** of the penguin species.

> We let ``P_X`` denote the distribution predicted by a model ``P`` for features ``X``.
"""

# ╔═╡ e3f2755c-f8e1-4b31-9fb1-3b1c5e96c7a6
md"""
There exist many different probabilistic predictive models for this task.

> Ideally, we would like that
> ```math
> P_X = \operatorname{law}(Y ∣ X)
> ```
> almost surely.

Of course, usually it is not possible to achieve this in practice.
"""

# ╔═╡ 135fc588-3ea5-4c74-81af-09937ff79222
y, X = unpack(
    penguins,
    ==(:species),
    x -> x === :bill_length_mm || x === :flipper_length_mm;
    :species => Multiclass,
    :bill_length_mm => MLJ.Continuous,
    :flipper_length_mm => MLJ.Continuous,
);

# ╔═╡ 06ecd271-baa4-4d7b-88fc-43384f67d98b
penguins_train = let
    n = nrow(penguins)
    k = floor(Int, 0.7 * n)
    Random.seed!(100)
    hcat(DataFrame(; train=shuffle!(vcat(trues(k), falses(n - k)))), penguins)
end;

# ╔═╡ b7f20fd4-356c-4e5b-a79e-5b8de2d2fc6a
let
    dataset = :train => renamer(true => "training", false => "validation") => "Dataset"
    plt =
        data(penguins_train) *
        mapping(
            :bill_length_mm => "bill length (mm)",
            :flipper_length_mm => "flipper length (mm)",
        ) *
        mapping(; color=:species, col=dataset) *
        visual(; alpha=0.7)
    draw(plt; axis=(height=200,))
end

# ╔═╡ 5c60d82e-6a3a-475c-9947-2db8e057a978
penguins_model = fit!(machine(GaussianNBClassifier(), X, y); rows=penguins_train.train);

# ╔═╡ d85cf93c-24d0-4af1-a97e-85d6e6306099
let
    # plot datasets
    dataset = :train => renamer(true => "training", false => "validation") => "Dataset"
    plt =
        data(penguins_train) *
        mapping(
            :bill_length_mm => "bill length (mm)",
            :flipper_length_mm => "flipper length (mm)",
        ) *
        mapping(; color=:species, col=dataset) *
        visual(; alpha=0.7)
    fg = draw(plt)

    # plot Gaussian distributions
    xgrid = range(extrema(penguins.bill_length_mm)...; length=100)
    ygrid = range(extrema(penguins.flipper_length_mm)...; length=100)
    f(x, y, dist) = pdf(dist, [x, y])
    for (class, color) in zip(classes(y), Makie.wong_colors())
        pdfs = f.(xgrid, ygrid', Ref(penguins_model.fitresult.gaussians[class]))
        contour!(fg.figure[1, 1], xgrid, ygrid, pdfs; color=color)
        contour!(fg.figure[1, 2], xgrid, ygrid, pdfs; color=color)
    end

    fg
end

# ╔═╡ 020b339d-33fc-424a-8d36-a90c2eb66999
only(MLJ.predict(penguins_model, [43.0 140.0]))

# ╔═╡ d3c0ebbb-f62e-472b-a1f9-c19808f3d274
let
    # plot datasets
    dataset = :train => renamer(true => "training", false => "validation") => "Dataset"
    plt =
        data(penguins_train) *
        mapping(
            :bill_length_mm => "bill length (mm)",
            :flipper_length_mm => "flipper length (mm)",
        ) *
        mapping(; color=:species, col=dataset) *
        visual(; alpha=0.7)
    fg = draw(plt)

    # plot predictions
    xgrid = range(extrema(penguins.bill_length_mm)...; length=100)
    ygrid = range(extrema(penguins.flipper_length_mm)...; length=100)
    predictions = reshape(
        MLJ.predict(penguins_model, reduce(hcat, vcat.(xgrid, ygrid'))'),
        length(xgrid),
        length(ygrid),
    )
    for (class, color) in zip(classes(y), Makie.wong_colors())
        single_predictions = pdf.(predictions, class)
        contour!(fg.figure[1, 1], xgrid, ygrid, single_predictions; color=color)
        contour!(fg.figure[1, 2], xgrid, ygrid, single_predictions; color=color)
    end

    fg
end

# ╔═╡ 3007eeeb-19f6-409b-be66-f3cbcbeb5bea
md"""
## Calibration

!!! danger "Motivation"
	Predictions should express involved uncertainties "correctly" and not be arbitrary
	probability distributions.

	In particular, predictions should be consistent: if forecasts predict an 80%
    probability of rain for an infinite sequence of days, then ideally on 80% of the
    days it rains.

> A probabilistic predictive model ``P_X`` of the conditional distributions
> ``\operatorname{law}(Y \,|\, X)`` is calibrated if
> ```math
> P_X = \operatorname{law}(Y \,|\, P_X)
> ```
> almost surely.

It is not relevant how the model was obtained. In particular it does not matter if
one uses a maximum likelihood approach or performs Bayesian inference.
"""

# ╔═╡ 665b98bc-7191-47ae-a9c8-90ac0403f7b6
@drawsvg begin
    plts = map((("prediction", 1), ("empirical frequencies", 0.7))) do (title, alpha)
        return readsvg(
            repr(
                MIME("image/svg+xml"),
                barplot(
                    1:3,
                    [0.8, 0.1, 0.1];
                    color=Makie.wong_colors(alpha)[1:3],
                    axis=(xticks=(1:3, ["Adelie", "Chinstrap", "Gentoo"]), title=title),
                    figure=(resolution=(300, 200),),
                ),
            ),
        )
    end

    for (plt, (pos, n)) in zip(plts, Tiler(600, 200, 1, 2))
        placeimage(plt, pos; centered=true)
    end

    @layer begin
        sethue("red")
        fontsize(60)
        fontface("DejaVu Sans Mono")
        Luxor.text("≟", Luxor.Point(0, 0); halign=:center, valign=:middle)
    end
end 600 200

# ╔═╡ dc77c91d-ad9a-4d25-a2ca-ac9a9f0f1067
md"""
> Often weaker conditions are investigated, corresponding to less informative models.

E.g., "confidence calibration" only considers the most-confident class: This corresponds to a binary classification model
"""

# ╔═╡ 4ed069a5-29e2-4de1-9ea3-2e1b3589d681
@drawsvg begin
    fontsize(12)
    fontface("DejaVu Sans")
    Luxor.text(
        "(features, most-confident class)",
        Luxor.Point(-30, 0);
        halign=:right,
        valign=:middle,
    )
    arrow(Luxor.Point(-25, 0), Luxor.Point(25, 0))
    Luxor.text(
        "[class correct, class incorrect]", Luxor.Point(30, 0); halign=:left, valign=:middle
    )
end 500 20

# ╔═╡ edfd6f59-5b6d-4a1c-8f26-c95ce7485792
let plts = map((("prediction", 1), ("empirical frequencies", 0.7))) do (title, alpha)
        return readsvg(
            repr(
                MIME("image/svg+xml"),
                barplot(
                    1:2,
                    [0.8, 0.2];
                    color=Makie.wong_colors(alpha)[1:2],
                    axis=(xticks=(1:2, ["correct", "incorrect"]), title=title),
                    figure=(resolution=(300, 200),),
                ),
            ),
        )
    end
    @drawsvg begin
        for (plt, (pos, n)) in zip(plts, Tiler(600, 200, 1, 2))
            placeimage(plt, pos; centered=true)
        end

        @layer begin
            sethue("red")
            fontsize(60)
            fontface("DejaVu Sans Mono")
            Luxor.text("≟", Luxor.Point(0, 0); halign=:center, valign=:middle)
        end
    end 600 200
end

# ╔═╡ fb8bff06-b321-4775-a042-567693b87407
md"""
> Other target spaces can be considered as well.
"""

# ╔═╡ 9f7f5fbf-aa52-49ef-b59e-a528f3e8be16
let
    Random.seed!(100)

    # Poisson regression
    fig, _, _ = barplot(
        range(-20, 60; length=20) + 0.1 * (2 .* rand(20) .- 1),
        round.(Int, 50 * rand(20));
        axis=(xlabel="X", ylabel="Y"),
    )

    # regression
    lines(fig[1, 2], [-20, 60], [3, 11]; axis=(xlabel="X", ylabel="Y"))
    scatter!(
        range(-20, 60; length=70) + 0.1 * (2 .* rand(70) .- 1),
        5 .+ 0.1 * range(-20, 60; length=70) + 3 * (2 .* rand(70) .- 1);
        color=Makie.wong_colors()[2],
    )

    fig
end

# ╔═╡ 42fb6be5-9886-45f2-805b-098f0bba9353
let
    Random.seed!(100)
    xs = 150 * (2 .* rand(25) .- 1)
    ys = 150 * (2 .* rand(25) .- 1)
    color = Makie.wong_colors()[1]

    @drawsvg begin
        sethue("black")
        setopacity(0.4)
        setline(1)
        for i in 1:length(xs), j in (i + 1):length(xs)
            rand() < 0.3 || continue
            line(Luxor.Point(xs[i], ys[i]), Luxor.Point(xs[j], ys[j]), :stroke)
        end

        setopacity(1)
        sethue(color)
        for (x, y) in zip(xs, ys)
            circle(Luxor.Point(x, y), 3, :fill)
        end
    end 600 306
end

# ╔═╡ 9b67bf9f-7255-4a96-bf47-3766fd74d49e
md"""
### Calibrated models

*Bröcker, J. (2009). [Reliability, sufficiency, and the decomposition of proper scores](https://doi.org/10.1002/qj.456). Q.J.R. Meteorol. Soc., 135: 1512-1519.*

> Any model of the form
> ```math
> P_X := \operatorname{law}\big(Y \,|\, \phi(X)\big) \quad \text{almost surely},
> ```
> where ``\phi`` is some measurable function, is calibrated.

Function ``\phi`` corresponds to the amount/loss of information about ``X``:
- Identity function yields the ideal model ``P_X := \operatorname{law}(Y \,|\, X)``
- Every constant function yields the baseline model ``P_X := \operatorname{law}(Y)`` ("climatology")
"""

# ╔═╡ 2c2b01a1-7e93-4f41-b182-a35dd7b4c097
md"""
## Reliability diagrams

*Murphy, A., & Winkler, R. (1977). [Reliability of Subjective Probability Forecasts of Precipitation and Temperature](https://doi.org/10.2307/2346866). Journal of the Royal Statistical Society. Series C (Applied Statistics), 26(1), 41-47.*

*Bröcker, J., & Smith, L. A. (2007). [Increasing the reliability of reliability diagrams](https://doi.org/10.1175/WAF993.1). Weather and forecasting, 22(3), 651-661.*

*Vaicenavicius, J., Widmann, D., Andersson, C., Lindsten, F., Roll, J. & Schön, T. B. (2019). [Evaluating model calibration in classification](http://proceedings.mlr.press/v89/vaicenavicius19a.html). Proceedings of Machine Learning Research, in Proceedings of Machine Learning Research 89:3459-3467 (AISTATS 2019).*

> [Reliability diagrams](https://doi.org/10.2307/2346866) are used to visually inspect calibration of binary classification models.
> They show binned averages of empirical frequencies versus confidence.
"""

# ╔═╡ f1e05791-3e0a-4baa-ae2f-940f745e7e3a
md"""
### Visualizations with ReliabilityDiagrams.jl

- Supports Plots.jl and Makie.jl
- Allows to plot deviation, i.e., empirical frequency minus confidence.
- Includes [consistency bars](https://doi.org/10.1175/WAF993.1)

Bins: $(@bind binning_algorithm Select(["mass" => "equal mass", "size" => "equal size"])) $(@bind nbins PlutoUI.Slider(1:20; default=10, show_value=true))

Deviation: $(@bind deviation CheckBox(true))

Consistency bars: $(@bind consistencybars CheckBox(false))
"""

# ╔═╡ c40fcd96-fbd3-4322-8973-9b99ded0505e
predictions_val, y_val, confidence_val, outcomes_val = let rows = .!penguins_train.train
    predictions = MLJ.predict(penguins_model; rows=rows)
    yrows = y[rows]
    modes = MLJ.predict_mode(penguins_model; rows=rows)
    confidence = map(pdf, predictions, modes)
    outcomes = map(==, modes, yrows)
    predictions, yrows, confidence, outcomes
end;

# ╔═╡ 962de9ec-c675-4329-bab7-b466d2446700
let
    fig = Figure()

    ax = Axis(
        fig[1, 1];
        ylabel=deviation ? "outcomes - confidence" : "outcomes",
        xscale=binning_algorithm == "mass" ? CairoMakie.Makie.logit : identity,
        xticklabelsvisible=false,
    )

    # plot line of perfect calibration
    edges = if binning_algorithm == "mass"
        nquantile(confidence_val, nbins + 1)
    else
        min_confidence, max_confidence = extrema(confidence_val)
        (floor(Int, min_confidence * nbins):ceil(Int, max_confidence * nbins)) ./ nbins
    end
    xrange = range(extrema(edges)...; length=100)
    lines!(
        xrange,
        deviation ? zeros(length(xrange)) : xrange;
        color=:black,
        linestyle=:dot,
        label="ideal",
    )

    # plot reliability diagram
    reliability!(
        confidence_val,
        outcomes_val;
        binning=binning_algorithm == "mass" ? EqualMass(; n=nbins) : EqualSize(; n=nbins),
        consistencybars=consistencybars ? ConsistencyBars() : nothing,
        deviation=deviation,
        label="data",
    )
    axislegend(; position=:rb)

    # plot histogram of predictions
    ax2 = Axis(
        fig[2, 1];
        xlabel="confidence",
        ylabel="density",
        height=100,
        xscale=binning_algorithm == "mass" ? CairoMakie.Makie.logit : identity,
    )
    hist!(
        ax2,
        confidence_val;
        bins=edges,
        normalization=:probability,
        color=Makie.wong_colors(0.8)[1],
    )

    # link axes
    linkxaxes!(ax, ax2)

    fig
end

# ╔═╡ 5de4999e-d050-4a79-87b9-f61e5eae6f20
md"""
## Expected calibration error

> The **expected calibration error (ECE)**
> ```math
> \operatorname{ECE}_d := \mathbb{E}_{P_X} d\big(P_X, \operatorname{law}(Y \,|\, P_X)\big)
> ```
> measures the expected deviation of the predictions ``P_X`` and empirical frequencies ``\operatorname{law}(Y \,|\, P_X)``
> with respect to distance measure ``d``.

- For (multi-class) classification models, common choices for ``d`` are (semi-)metrics on the probability simplex such as Euclidean or squared Euclidean distance
- For general probabilistic models **statistical divergences** can be chosen for ``d``, e.g.,
  - ``f``-divergences such as the Kullback-Leibler divergence,
  - Wasserstein distance,
  - maximum mean discrepancy (MMD).
"""

# ╔═╡ 4b521ee4-9a5b-418a-b2bb-7e0de5421a27
md"""
!!! danger "⚠️ Challenges"
	For general models, the distribution ``\operatorname{law}(Y \,|\, P_X)`` can be **arbitrarily complex**.

	The empirical frequencies ``\operatorname{law}(Y \,|\, P_X)`` are **difficult to estimate**.

    Common histogram binning based approaches lead to **biased and inconsistent estimators**.
"""

# ╔═╡ ee2b5be3-2f96-42aa-a637-95af97bd6948
md"""
### Estimation with CalibrationErrors.jl

Supports
- different distance measures ``d`` (default: total variation distance),
- different binning algorithms (bins of uniform size and bins that minimize variance within bins)
"""

# ╔═╡ a146e89e-7272-432f-a65f-1d1d513edd29
probs_val, yint_val = let
    probs = pdf(predictions_val, MLJ.classes(y_val))
    yint = map(MLJ.levelcode, y_val)
    probs, yint
end;

# ╔═╡ 4e9e72ce-e1a6-45a2-8625-d3e5cef7642d
md"""
Distance: $(@bind ece_distance_str Select([
	"Euclidean", "Cityblock", "Total variation", "Squared Euclidean"
]))
Number of bins: $(@bind ece_nbins PlutoUI.Slider(1:20; show_value=true, default=10))
"""

# ╔═╡ 4b4b0910-c0bd-48ba-8b8a-d09eb6c56578
ece_distance = if ece_distance_str == "Cityblock"
    Cityblock()
elseif ece_distance_str == "Total variation"
    TotalVariation()
elseif ece_distance_str == "Euclidean"
    Euclidean()
elseif ece_distance_str == "Squared Euclidean"
    SqEuclidean()
end;

# ╔═╡ 9f773aa3-a4de-4728-8afd-734a113668e1
let
    ece = ECE(UniformBinning(ece_nbins), ece_distance)
    ece(RowVecs(probs_val), yint_val)
end

# ╔═╡ 7d7739e0-92b4-42bc-b3c5-071d168163a9
let distance = ece_distance, probs = probs_val, yint = yint_val
    function f(x)
        ece = ECE(UniformBinning(x), distance)
        return ece(RowVecs(probs), yint)
    end
    barplot(1:20, f; axis=(xlabel="number of bins", ylabel="ECE"))
end

# ╔═╡ 255ec00b-663d-4b76-9376-65ee3b8ed235
md"""
### Why scoring rules are not sufficient

*Bröcker, J. (2009). [Reliability, sufficiency, and the decomposition of proper scores](https://doi.org/10.1002/qj.456). Q.J.R. Meteorol. Soc., 135: 1512-1519.*

> Probabilistic predictive models can be evaluated by the expected score
> ```math
> \mathbb{E}_{P_X, Y} s(P_X, Y)
> ```
> where **scoring rule ``s(P, \omega)``** is the reward of prediction ``P`` if the true
> outcome is ``\omega``.

*Examples:* Brier score, logarithmic score
"""

# ╔═╡ ecaf1f70-52ad-4f32-806b-0ab29901d337
mean(brier_score(predictions_val, y_val))

# ╔═╡ 65a9fa62-7873-4c13-be6a-c7c37dbdc26c
mean(-log_loss(predictions_val, y_val))

# ╔═╡ 8fcfa900-c051-439a-8dc2-f21bb17a4896
md"""
Proper scoring rules can be decomposed as
```math
\begin{aligned}
\mathbb{E}_{P_X, Y} s(P_X, Y) ={}& \underbrace{\mathbb{E}_{P_X} d\big(\operatorname{law}(Y), \operatorname{law}(Y \,|\, P_X)\big)}_{\text{resolution}} \\
&- \underbrace{\mathbb{E}_{P_X} d\big(P_X, \operatorname{law}(Y\,|\,P_X)\big)}_{\text{ECE}} - \underbrace{S\big(\operatorname{law}(Y), \operatorname{law}(Y)\big)}_{\text{uncertainty of } Y}
\end{aligned}
```
where ``S(P, Q) := \int_{\Omega} s(P, \omega) \,Q(\mathrm{d}\omega)`` is the expected score of ``P`` under ``Q`` and ``d(P, Q) := S(Q, Q) - S(P, P)`` is the score divergence.

- **resolution**:
  minimized for uninformative models with ``\operatorname{law}(Y \,|\, P_X) = \operatorname{law}(Y)`` such as constant models
- **ECE**:
  minimized for calibrated models
- **uncertainty of ``Y``**:
  does not dependend on the model

!!! info
    Models can trade off calibration for resolution!
"""

# ╔═╡ 8a6e52a1-ea81-4cf3-91d4-6e6e8f08d068
md"""
## Alternatives to ECE

*Widmann, D., Lindsten, F., & Zachariah, D. (2021).
[Calibration tests beyond classification](https://openreview.net/forum?id=-bxf89v3Nx).
ICLR 2021.*

> A probabilistic predictive model is calibrated if
> ```math
> (P_X, Y) \stackrel{d}{=} (P_X, Z_X),
> ```
> where ``Z_X \,|\, P_X \sim P_X``.

- No explicit conditional distributions ``\operatorname{law}(Y \,|\, P_X)``
- Suggests discrepancy of ``\operatorname{law}(P_X, Y)`` and ``\operatorname{law}(P_X, Z_X)`` as calibration measure
"""

# ╔═╡ a2282804-0f33-47cd-af63-7b040e801e04
md"""
### Kernel calibration error (KCE)

*Widmann, D., Lindsten, F., & Zachariah, D. (2019). [Calibration tests in multi-class
classification: A unifying framework](https://proceedings.neurips.cc/paper/2019/hash/1c336b8080f82bcc2cd2499b4c57261d-Abstract.html). In
Advances in Neural Information Processing Systems 32 (NeurIPS 2019) (pp. 12257–12267).*

*Widmann, D., Lindsten, F., & Zachariah, D. (2021).
[Calibration tests beyond classification](https://openreview.net/forum?id=-bxf89v3Nx).
ICLR 2021.*

Integral probability metrics can be used to define a general class of probability metrics with minimal assumptions about the involved distributions. The kernel calibration error (KCE) is an example of this class:

> The kernel calibration error (KCE) with respect to a real-valued kernel ``k`` is defined
> as
> ```math
> \operatorname{KCE}_k := \operatorname{MMD}_k\big(\operatorname{law}(P_X, Y), \operatorname{law}(P_X, Z_X)\big),
> ```
> where ``\operatorname{MMD}_k`` is the maximum mean discrepancy with respect to ``k``.

- Applies to **all probabilistic predictive models**
- Existing **(un)biased and consistent estimators** of the MMD **without challenging estimation of ``\operatorname{law}(Y \,|\,P_X)``**
- Variance of estimators can be reduced by marginalizing out ``Z_X``
"""

# ╔═╡ c8ef77dd-7620-4e15-aa23-06517bb30086
md"""
### Estimation with CalibrationErrors.jl

Supports
- biased and unbiased estimators
- estimators with quadratic and subquadratic sample complexity
- kernels from [KernelFunctions.jl](https://github.com/JuliaGaussianProcesses/KernelFunctions.jl)
"""

# ╔═╡ 6bf8ec8a-0fc4-41f5-81a3-d2ec474ae90d
md"""
Here we choose a tensor product kernel of the form
```math
k\big((p, y), (\tilde{p}, \tilde{y})\big) := k_1(p, \tilde{p}) \delta(y - \tilde{y}).
```

Kernel ``k_1``: $(@bind skce_kernel1_str Select(["Exponential", "Squared exponential", "Matérn 3/2", "Matérn 5/2"]))
Length scale: $(@bind skce_lengthscale PlutoUI.Slider(0.01:0.01:5; show_value=true, default=1))

Estimator: $(@bind skce_estimator_str Select(["Unbiased (quadratic)", "Unbiased (subquadratic)", "Unbiased (linear)", "Biased"]))
"""

# ╔═╡ 17220237-bfc1-4393-90fb-b0a3191de924
md"""
!!! info
	One possible approach for selecting the length scale is to maximize the KCE on a held-out dataset (cf. approach for MMD proposed by Fukumizu et al. in [Kernel Choice and Classifiability for RKHS Embeddings of Probability Distributions](https://papers.nips.cc/paper/2009/hash/685ac8cadc1be5ac98da9556bc1c8d9e-Abstract.html) (2009)).
"""

# ╔═╡ 30a37d5e-6bcb-4f02-92c3-a66d2f1f03f4
begin
    function skce_kernel(name, x)
        kernel = if name == "Exponential"
            ExponentialKernel()
        elseif name == "Squared exponential"
            SqExponentialKernel()
        elseif name == "Matérn 3/2"
            Matern32Kernel()
        elseif name == "Matérn 5/2"
            Matern52Kernel()
        end
        return (kernel ∘ ScaleTransform(inv(x))) ⊗ WhiteKernel()
    end
    function skce_estimator(name, x)
        estimator = if name == "Unbiased (quadratic)"
            UnbiasedSKCE(x)
        elseif name == "Unbiased (subquadratic)"
            BlockUnbiasedSKCE(x, floor(Int, sqrt(length(yint_val))))
        elseif name == "Unbiased (linear)"
            BlockUnbiasedSKCE(x)
        elseif name == "Biased"
            BiasedSKCE(x)
        end
        return estimator
    end
end;

# ╔═╡ 380321e4-67b4-46d5-9d9c-24474b52bd90
let
    f =
        let estimator =
                Base.Fix1(skce_estimator, skce_estimator_str) ∘
                Base.Fix1(skce_kernel, skce_kernel1_str),
            probs = RowVecs(probs_val),
            yint = yint_val

            x -> estimator(x)(probs, yint)
        end
    lines(
        10 .^ range(-2, 2; length=1_000),
        f;
        axis=(xlabel="length scale", xscale=log10, ylabel="squared KCE"),
    )
end

# ╔═╡ 621cbd71-1a42-4273-9c97-b3c7ffb7a572
skce = skce_estimator(skce_estimator_str, skce_kernel(skce_kernel1_str, skce_lengthscale));

# ╔═╡ 755f19e0-5b8b-4acd-843e-0117db51e7c3
skce

# ╔═╡ 5c0bac01-e491-4b93-8174-4abaa421ea41
skce(RowVecs(probs_val), yint_val)

# ╔═╡ 768ff473-1a20-4562-870a-86919e498eba
md"""
### Estimation with CalibrationErrorsDistributions.jl

Closed-form expressions for predictions of Gaussian and Laplace distributions in [Distributions.jl](https://github.com/JuliaStats/Distributions.jl)
"""

# ╔═╡ 68e07e05-2aaf-4215-98a5-c3739bed5661
md"""
#### Example: Gaussian process

1. We sample from a Gaussian process (GP) with zero mean and a squared exponential kernel at 40 random locations in the interval ``[0, 10]``.
"""

# ╔═╡ f8a4304c-888b-4c21-a4c9-52b7c94b25bf
md"""
2. We split the data randomly in a training (75%) and validation (25%) dataset, and compute the GP posterior from the training data.
"""

# ╔═╡ af85eec3-6e28-423a-a3c0-53b4ab12892d
md"""
3. We compute the predicted normal distributions on the validation data.
"""

# ╔═╡ efdb962e-adf5-4222-b8f5-990690489c61
md"""
4. We estimate the squared KCE with a tensor product kernel of the form
   ```math
   k\big((\mu, y), (\tilde{\mu}, \tilde{y})\big) := \exp{\big(-W_2(\mu, \tilde{\mu})\big)} \exp{\bigg(- \frac{(y - \tilde{y})^2}{2 \ell^2}\bigg)},
   ```
   where ``W_2(\mu, \tilde{\mu})`` is the 2-Wasserstein distance of the Gaussian distributions ``\mu`` and ``\tilde{\mu}``.
"""

# ╔═╡ 779564a9-62c4-4d4a-9fe2-9a8041d19649
md"""
Length scale ``\ell``: $(@bind gp_lengthscale PlutoUI.Slider(0.01:0.01:10; show_value=true, default=1))

Estimator: $(@bind gp_estimator_str Select(["Unbiased (quadratic)", "Unbiased (subquadratic)", "Unbiased (linear)", "Biased"]))
"""

# ╔═╡ b0fc768f-b269-4526-826f-752bbafcbe93
begin
    Random.seed!(100)
    gp = GP(SqExponentialKernel())
    gp_x = 10 * rand(40)
    gp_y = rand(gp(gp_x, 0.01))
end;

# ╔═╡ 63678255-0d09-4a88-9eb9-e980a25acee5
begin
    Random.seed!(100)
    gp_train = shuffle!(vcat(trues(30), falses(10)))
    gp_x_val = gp_x[.!gp_train]
    gp_y_val = gp_y[.!gp_train]
    gp_posterior = posterior(gp(gp_x[gp_train], 0.01), gp_y[gp_train])
end;

# ╔═╡ 0dcb5ff4-96c5-4a1e-a31e-658f7e919731
let
    plot(
        0:0.01:10,
        gp_posterior;
        bandscale=3,
        color=Makie.wong_colors(0.3)[1],
        label="GP posterior (mean ± 3 stddev)",
        axis=(xlabel="x", ylabel="y"),
    )
    scatter!(gp_x[gp_train], gp_y[gp_train]; label="training", color=Makie.wong_colors()[2])
    scatter!(
        gp_x[.!gp_train], gp_y[.!gp_train]; label="validation", color=Makie.wong_colors()[3]
    )
    axislegend(; position=:rb)
    xlims!(0, 10)
    current_figure()
end

# ╔═╡ aabd36b5-fc89-45f9-bc26-62f96a9c7adc
gp_predictions = marginals(gp_posterior(gp_x_val, 0))

# ╔═╡ 91f10eb1-9fef-4db5-8c3b-a4e9195e318b
function gp_kernel(x)
    return WassersteinExponentialKernel() ⊗ (SqExponentialKernel() ∘ ScaleTransform(inv(x)))
end;

# ╔═╡ ec5f6d4c-dd84-44b3-a961-613090302410
let
    f =
        let estimator = Base.Fix1(skce_estimator, gp_estimator_str) ∘ gp_kernel,
            predictions = gp_predictions,
            y = gp_y_val

            x -> estimator(x)(predictions, y)
        end
    lines(
        10 .^ range(-2, 2; length=1_000),
        f;
        axis=(xlabel="length scale", xscale=log10, ylabel="squared KCE"),
    )
end

# ╔═╡ c963b0d4-fece-486b-b81e-aeedf8a6d330
gp_skce = skce_estimator(gp_estimator_str, gp_kernel(gp_lengthscale));

# ╔═╡ 01fda3bf-42dd-47a0-8c89-bd138c19fcc3
gp_skce

# ╔═╡ 91d0a38b-087d-464a-9741-59f509c6ffd1
gp_skce(gp_predictions, gp_y_val)

# ╔═╡ a39d0830-1165-43e1-91be-d7d136601ade
md"""
## Calibration tests

*Vaicenavicius, J., Widmann, D., Andersson, C., Lindsten, F., Roll, J. & Schön, T. B. (2019). [Evaluating model calibration in classification](http://proceedings.mlr.press/v89/vaicenavicius19a.html). Proceedings of Machine Learning Research, in Proceedings of Machine Learning Research 89:3459-3467 (AISTATS 2019).*

*Widmann, D., Lindsten, F., & Zachariah, D. (2019). [Calibration tests in multi-class
classification: A unifying framework](https://proceedings.neurips.cc/paper/2019/hash/1c336b8080f82bcc2cd2499b4c57261d-Abstract.html). In
Advances in Neural Information Processing Systems 32 (NeurIPS 2019) (pp. 12257–12267).*

*Widmann, D., Lindsten, F., & Zachariah, D. (2021).
[Calibration tests beyond classification](https://openreview.net/forum?id=-bxf89v3Nx).
ICLR 2021.*

!!! danger "⚠️ Problem"
    It is difficult to interpret an estimated non-zero calibration error.

- Calibration errors have no meaningful unit or scale.
- Different calibration errors rank models differently.
- Estimators of calibration errors are random variables.
"""

# ╔═╡ 111761a7-39a6-4c38-84e5-f5c5c5d9133d
md"""
> Perform a statistical test of the null hypothesis
> ``H_0 := \text{"model is calibrated"}``.
"""

# ╔═╡ 6efd7166-06bc-4404-bb4b-d268c89ed5b5
let
    dist = MixtureModel([Normal(-0.05, 0.01), Normal(0.05, 0.03)], [0.5, 0.5])

    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel="calibration error estimate", ylabel="density")
    vlines!(ax, 0.07; label="observed")
    vlines!(ax, 0; label="calibrated")
    lines!(
        ax,
        -0.1:0.001:0.2,
        dist;
        label="distribution under H₀",
        color=Makie.wong_colors()[3],
    )
    x = 0.07:0.001:0.2
    band!(ax, x, zero(x), pdf.(dist, x); label="p-value", color=Makie.wong_colors(0.3)[3])
    axislegend(ax)
    fig
end

# ╔═╡ 827b3ef2-de7c-459f-842c-1ed465888f62
md"""
- Hypothesis testing of calibration is a **special two-sample problem**
- Applies to **all probabilistic predictive models**
- Existing two-sample tests based on the MMD can be improved by marginalizing out ``Z_X``
"""

# ╔═╡ db3ab9ef-089d-4ffb-ac92-41f21f05598f
md"""
### Calibration tests with CalibrationTests.jl

Supports
- tests based on consistency resampling
- tests based on distribution-free bounds and asymptotic properties of KCE
- tests with quadratic and subquadratic sample complexity
- interface of [HypothesisTests.jl](https://github.com/JuliaStats/HypothesisTests.jl)
"""

# ╔═╡ 473a7634-adfd-45ab-adfa-65e28111ee98
md"""
Test: $(@bind test_str PlutoUI.Select([
	"Asymptotic", "Asymptotic (subquadratic)", "Asymptotic (linear)",
	"Distribution-free (biased)", "Distribution-free (unbiased)"
]))
"""

# ╔═╡ 6dbf213c-245e-414c-af70-bb3e92f99ad5
begin
    function calibration_test(name, kernel, predictions, y)
        return if name == "Asymptotic"
            AsymptoticSKCETest(kernel, predictions, y)
        elseif name == "Asymptotic (subquadratic)"
            AsymptoticBlockSKCETest(kernel, floor(Int, sqrt(length(y))), predictions, y)
        elseif name == "Asymptotic (linear)"
            AsymptoticBlockSKCETest(kernel, 2, predictions, y)
        elseif name == "Distribution-free (biased)"
            DistributionFreeSKCETest(BiasedSKCE(kernel), predictions, y)
        elseif name == "Distribution-free (unbiased)"
            DistributionFreeSKCETest(UnbiasedSKCE(kernel), predictions, y)
        end
    end
end;

# ╔═╡ 04cbeb0d-1545-4237-bed0-2b89f1bae71a
skce_test = calibration_test(
    test_str, skce_kernel(skce_kernel1_str, skce_lengthscale), RowVecs(probs_val), yint_val
);

# ╔═╡ 875bcec7-20f8-4038-96f4-b6f56d5239e7
skce_test

# ╔═╡ 552576c8-30ef-45fd-a230-acdcd006978c
pvalue(skce_test)

# ╔═╡ 37ceded9-edf8-4077-af19-d6caac831204
md"""
## [pycalibration](https://github.com/devmotion/pycalibration/)

- Python interface for CalibrationErrors, CalibrationErrorsDistributions, and CalibrationTests
- Inspired by [diffeqpy](https://github.com/SciML/diffeqpy)
- Uses [PyJulia interface](https://github.com/JuliaPy/pyjulia)
"""

# ╔═╡ ab3e5ce8-b354-443c-a68a-7bdbfe434442
md"""
### Usage

- Load package and install Julia dependencies:
  ```python
  >>> import pycalibration
  >>> pycalibration.install()
  ```

- Define estimator of the SKCE with kernel
  ```math
  k\big((\mu, y), (\hat{\mu}, \hat{y})\big) = \exp{\big(- \|\mu - \hat{\mu}\|\big)} \delta(y - \hat{y}):
  ```
  ```python
  >>> from pycalibration import calerrors as ce
  >>> skce = ce.UnbiasedSKCE(ce.tensor(ce.ExponentialKernel(), ce.WhiteKernel()))
  ```

- Estimate the SKCE for some random predictions and outcomes:
  ```python
  >>> import numpy as np
  >>> from pycalibration import calerrors as ce
  >>> rng = np.random.default_rng(1234)
  >>> predictions = rng.random(100)
  >>> outcomes = rng.choice([True, False], 100)
  >>> skce(predictions, outcomes)
  0.03320398246523166
  ```

- Perform a calibration test with some random predictions and outcomes:
  ```python
  >>> from pycalibration import caltests as ct
  >>> import numpy as np
  >>> rng = np.random.default_rng(1234)
  >>> predictions = rng.dirichlet((3, 2, 5), 100)
  >>> outcomes = rng.integers(low=1, high=4, size=100)
  >>> kernel = ct.tensor(ct.ExponentialKernel(metric=ct.TotalVariation()), ct.WhiteKernel())
  >>> test = ct.AsymptoticSKCETest(kernel, predictions, outcomes)
  >>> print(test)
  <PyCall.jlwrap Asymptotic SKCE test
  --------------------
  Population details:
      parameter of interest:   SKCE
      value under h_0:         0.0
      point estimate:          6.07887e-5

  Test summary:
      outcome with 95% confidence: fail to reject h_0
      one-sided p-value:           0.4330

  Details:
      test statistic: -4.955380469272125
  >>> ct.pvalue(test)
  0.435
  ```

More examples can be found in the [documentation](https://github.com/devmotion/pycalibration).
"""

# ╔═╡ a21804f0-1dc3-4f0a-933d-eb03f9132027
md"""
## [rcalibration](https://github.com/devmotion/rcalibration/)

- R interface for CalibrationErrors, CalibrationErrorsDistributions, and CalibrationTests
- Inspired by [diffeqr](https://github.com/SciML/diffeqr)
- Based on [JuliaCall](https://github.com/Non-Contradiction/JuliaCall)
"""

# ╔═╡ 06b01285-4a75-4883-bac2-c24d2d57065e
md"""
### Usage

- Load package and install Julia dependencies:
  ```r
  > library(rcalibration)
  > rcalibration::install()
  ```

- Define estimator of the SKCE with kernel
  ```math
  k\big((\mu, y), (\hat{\mu}, \hat{y})\big) = \exp{\big(- \|\mu - \hat{\mu}\|\big)} \delta(y - \hat{y}):
  ```
  ```r
  > ce <- calerrors()
  > skce <- ce$UnbiasedSKCE(ce$tensor(ce$ExponentialKernel(), ce$WhiteKernel()))
  ```

- Estimate the SKCE for some random predictions and outcomes:
  ```r
  > ce <- calerrors()
  > set.seed(1234)
  > predictions <- runif(100)
  > outcomes <- sample(c(TRUE, FALSE), 100, replace=TRUE)
  > skce$.(predictions, outcomes)
  [1] 0.01518318
  ```

- Perform a calibration test with some random predictions and outcomes:
  ```r
  > library(extraDistr)
  > ct <- caltests()
  > set.seed(1234)
  > predictions <- rdirichlet(100, c(3, 2, 5))
  > outcomes <- sample(1:3, 100, replace=TRUE)
  > kernel <- ct$tensor(ct$ExponentialKernel(metric=ct$TotalVariation()), ct$WhiteKernel())
  > test <- ct$AsymptoticSKCETest(kernel, ce$RowVecs(predictions), outcomes)
  > print(test)
  Julia Object of type AsymptoticSKCETest{KernelTensorProduct{Tuple{ExponentialKernel{TotalVariation}, WhiteKernel}}, Float64, Float64, Matrix{Float64}}.
  Asymptotic SKCE test
  --------------------
  Population details:
      parameter of interest:   SKCE
      value under h_0:         0.0
      point estimate:          0.0259434

  Test summary:
      outcome with 95% confidence: reject h_0
      one-sided p-value:           0.0100

  Details:
      test statistic: -0.007291403994633658
  > ct$pvalue(test)
  [1] 0.004
  ```

More examples can be found in the [documentation](https://github.com/devmotion/rcalibration).
"""

# ╔═╡ aece0eb4-7672-43a0-8cd0-c5db2b80cbbf
md"""
## Take home messages

- **Calibration** is an **important aspect** of probabilistic predictive models
- **Reliability diagrams** with **consistency bars** help to visually inspect calibration
- There exist **alternatives** to the ECE such as the **KCE** with favourable theoretical properties
- **Calibration tests** can be used to deal with the randomness of calibration error estimates
- **Python** and **R** interfaces if you do not use Julia
"""

# ╔═╡ 4ea0159b-c71b-4adb-9b46-205ce6a85b06
html"""
<h3><center>See you at JuliaCon!</center></h3>

<img src="https://juliacon.org/assets/2021/img/world_1400.png"/>
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractGPs = "99985d1d-32ba-4be9-9821-2ec096f28918"
AbstractGPsMakie = "7834405d-1089-4985-bd30-732a30b92057"
AlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
CalibrationErrors = "33913031-fe46-5864-950f-100836f47845"
CalibrationErrorsDistributions = "20087e1a-bb94-462b-b900-33d17a750383"
CalibrationTests = "2818745e-0823-50c7-bc2d-405ac343d48b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Luxor = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
MLJ = "add582a8-e3ab-11e8-2d5e-e98b27df1bc7"
MLJNaiveBayesInterface = "33e4bacb-b9e2-458e-9a13-5d9a90b235fa"
PalmerPenguins = "8b842266-38fa-440a-9b57-31493939ab85"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
ReliabilityDiagrams = "e5f51471-6270-49e4-a15a-f1cfbff4f856"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
AbstractGPs = "~0.3.6"
AbstractGPsMakie = "~0.2.1"
AlgebraOfGraphics = "~0.4.6"
CairoMakie = "~0.6.2"
CalibrationErrors = "~0.5.20"
CalibrationErrorsDistributions = "~0.2.4"
CalibrationTests = "~0.5.4"
DataFrames = "~1.1.1"
Luxor = "~2.12.0"
MLJ = "~0.16.7"
MLJNaiveBayesInterface = "~0.1.3"
PalmerPenguins = "~0.1.2"
PlutoUI = "~0.7.9"
ReliabilityDiagrams = "~0.2.2"
StatsBase = "~0.33.8"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AMD]]
deps = ["Libdl", "LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "fc66ffc5cff568936649445f58a55b81eaf9592c"
uuid = "14f7f29c-3bd6-536c-9a0b-7339e30b5a3e"
version = "0.4.0"

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

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

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

[[BSON]]
git-tree-sha1 = "92b8a8479128367aaab2620b8e73dff632f5ae69"
uuid = "fbb218c0-5317-5bc6-957e-2ee96dd4b1f0"
version = "0.3.3"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Statistics", "UUIDs"]
git-tree-sha1 = "ffabdf5297c9038973a0a3724132aa269f38c448"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.1.0"

[[BinaryProvider]]
deps = ["Libdl", "Logging", "SHA"]
git-tree-sha1 = "ecdec412a9abc8db54c0efc5548c64dfce072058"
uuid = "b99e7846-7c00-51b0-8f62-c81ae34c0232"
version = "0.5.10"

[[Blosc]]
deps = ["Blosc_jll"]
git-tree-sha1 = "84cf7d0f8fd46ca6f1b3e0305b4b4a37afe50fd6"
uuid = "a74b3585-a348-5f62-a45c-50e91977d574"
version = "0.7.0"

[[Blosc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Lz4_jll", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "e747dac84f39c62aff6956651ec359686490134e"
uuid = "0b7ba130-8d10-5ba8-a3d6-c5182647fed9"
version = "1.21.0+0"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[CSV]]
deps = ["Dates", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode"]
git-tree-sha1 = "b83aa3f513be680454437a0eee21001607e5d983"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.8.5"

[[Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "StaticArrays"]
git-tree-sha1 = "68628add03c2c7c2235834902aad96876f07756a"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.6.2"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f2202b55d816427cd385a9a4f3ffb226bee80f99"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+0"

[[CalibrationErrors]]
deps = ["DataStructures", "Distances", "KernelFunctions", "LinearAlgebra", "Reexport", "Statistics", "StatsBase", "UnPack"]
git-tree-sha1 = "9a365acc72027b060a01269f78dd5521e9dd7509"
uuid = "33913031-fe46-5864-950f-100836f47845"
version = "0.5.20"

[[CalibrationErrorsDistributions]]
deps = ["CalibrationErrors", "Distances", "Distributions", "KernelFunctions", "LinearAlgebra", "OptimalTransport", "PDMats", "Reexport", "Tulip"]
git-tree-sha1 = "39e17fb67733f21e74249beeb52773365478f037"
uuid = "20087e1a-bb94-462b-b900-33d17a750383"
version = "0.2.4"

[[CalibrationTests]]
deps = ["CalibrationErrors", "ConsistencyResampling", "HypothesisTests", "KernelFunctions", "LinearAlgebra", "Random", "Reexport", "Statistics", "StatsFuns", "StructArrays"]
git-tree-sha1 = "92ed7e41f462bfd65ad2cf52c9988d72f327560f"
uuid = "2818745e-0823-50c7-bc2d-405ac343d48b"
version = "0.5.4"

[[CategoricalArrays]]
deps = ["DataAPI", "Future", "JSON", "Missings", "Printf", "RecipesBase", "Statistics", "StructTypes", "Unicode"]
git-tree-sha1 = "1562002780515d2573a4fb0c3715e4e57481075e"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.0"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "be770c08881f7bb928dfd86d1ba83798f76cf62a"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "0.10.9"

[[CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

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

[[ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[ConsistencyResampling]]
deps = ["Random", "StatsBase"]
git-tree-sha1 = "c4c14f80c199c7e3cb594a62cd06e524cb0ec57f"
uuid = "4937dc1f-c7a3-5772-9d42-4a8277f2eb51"
version = "0.3.1"

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

[[DataDeps]]
deps = ["BinaryProvider", "HTTP", "Libdl", "Reexport", "SHA", "p7zip_jll"]
git-tree-sha1 = "4f0e41ff461d42cfc62ff0de4f1cd44c6e6b3771"
uuid = "124859b0-ceae-595e-8997-d05f6a7a8dfe"
version = "0.7.7"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "66ee4fe515a9294a8836ef18eea7239c6ac3db5e"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.1.1"

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

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

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
git-tree-sha1 = "a837fdf80f333415b69684ba8e8ae6ba76de6aaa"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.24.18"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[EarlyStopping]]
deps = ["Dates", "Statistics"]
git-tree-sha1 = "9427bc7a6c186d892f71b1c36ee7619e440c9e06"
uuid = "792122b4-ca99-40de-a6bc-6742525f08b6"
version = "0.1.8"

[[EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "8041575f021cba5a099a456b4163c9a08b566a02"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.1.0"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[ExprTools]]
git-tree-sha1 = "10407a39b87f29d47ebaca8edbc75d7c302ff93e"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.3"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

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

[[FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "256d8e6188f3f1ebfa1a5d17e072a0efafa8c5bf"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.10.1"

[[FilePathsBase]]
deps = ["Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "0f5e8d0cb91a6386ba47bd1527b240bd5725fbae"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.10"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "a603e79b71bb3c1efdb58f0ee32286efe2d1a255"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.11.8"

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
git-tree-sha1 = "05565be014da070422fc422463ced65fbcf13311"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.5.5"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HDF5]]
deps = ["Blosc", "Compat", "HDF5_jll", "Libdl", "Mmap", "Random", "Requires"]
git-tree-sha1 = "1d18a48a037b14052ca462ea9d05dee3ac607d23"
uuid = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f"
version = "0.15.5"

[[HDF5_jll]]
deps = ["Artifacts", "JLLWrappers", "LibCURL_jll", "Libdl", "OpenSSL_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "fd83fa0bde42e01952757f01149dd968c06c4dba"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "1.12.0+1"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "c6a1fff2fd4b1da29d3dccaffb1e1001244d844e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.12"

[[HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "8a954fed8ac097d5be04921d595f741115c1b2ad"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+0"

[[HypothesisTests]]
deps = ["Combinatorics", "Distributions", "LinearAlgebra", "Random", "Rmath", "Roots", "Statistics", "StatsBase"]
git-tree-sha1 = "a82a0c7e790fc16be185ce8d6d9edc7e62d5685a"
uuid = "09f84164-cd44-5f33-b23f-e6b0d136a0d5"
version = "0.10.4"

[[IfElse]]
git-tree-sha1 = "28e837ff3e7a6c3cdb252ce49fb412c8eb3caeef"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.0"

[[ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "75f7fea2b3601b58f24ee83617b528e57160cbfd"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.1"

[[ImageIO]]
deps = ["FileIO", "Netpbm", "PNGFiles", "TiffImages", "UUIDs"]
git-tree-sha1 = "d067570b4d4870a942b19d9ceacaea4fb39b69a1"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.5.6"

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

[[Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

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

[[Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IterationControl]]
deps = ["EarlyStopping", "InteractiveUtils"]
git-tree-sha1 = "f61d5d4d0e433b3fab03ca5a1bfa2d7dcbb8094c"
uuid = "b3c1a2ee-3fec-4384-bf48-272ea71de57c"
version = "0.4.0"

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

[[JLSO]]
deps = ["BSON", "CodecZlib", "FilePathsBase", "Memento", "Pkg", "Serialization"]
git-tree-sha1 = "e00feb9d56e9e8518e0d60eef4d1040b282771e2"
uuid = "9da8a3cd-07a3-59c0-a743-3fdc52c30d11"
version = "2.6.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "81690084b6198a2e1da36fcfda16eeca9f9f24e4"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.1"

[[JSONSchema]]
deps = ["HTTP", "JSON", "ZipFile"]
git-tree-sha1 = "b84ab8139afde82c7c65ba2b792fe12e01dd7307"
uuid = "7d188eb4-7ad8-530c-ae41-71a32a6d4692"
version = "0.3.3"

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
git-tree-sha1 = "e8b5ba31b6d18695fd46bfcd8557682839023195"
uuid = "ec8451be-7e33-11e9-00cf-bbf324bd1392"
version = "0.10.6"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LDLFactorizations]]
deps = ["AMD", "LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "399bbe845e06e1c2d44ebb241f554d45eaf66788"
uuid = "40e66cde-538c-5869-a4ad-c39174c6795b"
version = "0.8.1"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LatinHypercubeSampling]]
deps = ["Random", "StableRNGs", "StatsBase", "Test"]
git-tree-sha1 = "42938ab65e9ed3c3029a8d2c58382ca75bdab243"
uuid = "a5e1c1ea-c99a-51d3-a14d-a9a37257b02d"
version = "1.8.0"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[LearnBase]]
git-tree-sha1 = "a0d90569edd490b82fdc4dc078ea54a5a800d30a"
uuid = "7f8f8fb0-2700-5f03-b4bd-41f8cfc144b6"
version = "0.4.1"

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

[[LinearOperators]]
deps = ["FastClosures", "LinearAlgebra", "Printf", "SparseArrays", "TimerOutputs"]
git-tree-sha1 = "ef4aa84f530247dff7422b2f6259bdf6a708a63d"
uuid = "5c8ed15e-5a4c-59e4-a42b-c7e8811fb125"
version = "2.0.0"

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

[[LossFunctions]]
deps = ["InteractiveUtils", "LearnBase", "Markdown", "RecipesBase", "StatsBase"]
git-tree-sha1 = "0f057f6ea90a84e73a8ef6eebb4dc7b5c330020f"
uuid = "30fc2ffe-d236-52d8-8643-a9d8f7c094a7"
version = "0.7.2"

[[Luxor]]
deps = ["Base64", "Cairo", "Colors", "Dates", "FFMPEG", "FileIO", "ImageMagick", "Juno", "QuartzImageIO", "Random", "Rsvg"]
git-tree-sha1 = "3c5b13bb6f50b3fcb86c6cf43fe5c9356dc54eb6"
uuid = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
version = "2.12.0"

[[Lz4_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "5d494bc6e85c4c9b626ee0cab05daa4085486ab1"
uuid = "5ced341a-0733-55b8-9ab6-a4889d929147"
version = "1.9.3+0"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "c253236b0ed414624b083e6b72bfe891fbd2c7af"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+1"

[[MLJ]]
deps = ["CategoricalArrays", "ComputationalResources", "Distributed", "Distributions", "LinearAlgebra", "MLJBase", "MLJEnsembles", "MLJIteration", "MLJModels", "MLJOpenML", "MLJSerialization", "MLJTuning", "Pkg", "ProgressMeter", "Random", "ScientificTypes", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "7cbd651e39fd3f3aa37e8a4d8beaccfa8d13b1cd"
uuid = "add582a8-e3ab-11e8-2d5e-e98b27df1bc7"
version = "0.16.7"

[[MLJBase]]
deps = ["CategoricalArrays", "ComputationalResources", "Dates", "DelimitedFiles", "Distributed", "Distributions", "InteractiveUtils", "InvertedIndices", "LinearAlgebra", "LossFunctions", "MLJModelInterface", "Missings", "OrderedCollections", "Parameters", "PrettyTables", "ProgressMeter", "Random", "ScientificTypes", "StatisticalTraits", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "e1996657b66ba5c3a1bdbf73835640460958712d"
uuid = "a7f614a8-145f-11e9-1d2a-a57a1082229d"
version = "0.18.13"

[[MLJEnsembles]]
deps = ["CategoricalArrays", "ComputationalResources", "Distributed", "Distributions", "MLJBase", "MLJModelInterface", "ProgressMeter", "Random", "ScientificTypesBase", "StatsBase"]
git-tree-sha1 = "b9ce7bbc4bba927d52c26a3446ac2913777072c8"
uuid = "50ed68f4-41fd-4504-931a-ed422449fee0"
version = "0.1.1"

[[MLJIteration]]
deps = ["IterationControl", "MLJBase", "Random"]
git-tree-sha1 = "f927564f7e295b3205f37186191c82720a3d93a5"
uuid = "614be32b-d00c-4edb-bd02-1eb411ab5e55"
version = "0.3.1"

[[MLJModelInterface]]
deps = ["Random", "ScientificTypesBase", "StatisticalTraits"]
git-tree-sha1 = "55c785a68d71c5fd7b64b490e0d9ab18cf13a04c"
uuid = "e80e1ace-859a-464e-9ed9-23947d8ae3ea"
version = "1.1.1"

[[MLJModels]]
deps = ["CategoricalArrays", "Dates", "Distances", "Distributions", "InteractiveUtils", "LinearAlgebra", "MLJBase", "MLJModelInterface", "OrderedCollections", "Parameters", "Pkg", "REPL", "Random", "Requires", "ScientificTypes", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "0b8b6edb9076fb237cdedec9a62b8512397a520f"
uuid = "d491faf4-2d78-11e9-2867-c94bc002c0b7"
version = "0.14.8"

[[MLJNaiveBayesInterface]]
deps = ["MLJModelInterface", "NaiveBayes"]
git-tree-sha1 = "39cd0bdbbaad3f7539ba69a1d6056614ac71cc96"
uuid = "33e4bacb-b9e2-458e-9a13-5d9a90b235fa"
version = "0.1.3"

[[MLJOpenML]]
deps = ["HTTP", "JSON"]
git-tree-sha1 = "2903e9ef92ac5f390ca2a420fb0dbe3361ab57d7"
uuid = "cbea4545-8c96-4583-ad3a-44078d60d369"
version = "1.0.0"

[[MLJSerialization]]
deps = ["IterationControl", "JLSO", "MLJBase", "MLJModelInterface"]
git-tree-sha1 = "cd6285f95948fe1047b7d6fd346c172e247c1188"
uuid = "17bed46d-0ab5-4cd4-b792-a5c4b8547c6d"
version = "1.1.2"

[[MLJTuning]]
deps = ["ComputationalResources", "Distributed", "Distributions", "LatinHypercubeSampling", "MLJBase", "MLJModelInterface", "ProgressMeter", "Random", "RecipesBase"]
git-tree-sha1 = "516187c8578e5a33897f0c8963ccc548e38daa8b"
uuid = "03970b2e-30c4-11ea-3135-d1576263f10f"
version = "0.6.8"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "6a8a2a625ab0dea913aba95c11370589e0239ff0"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.6"

[[Makie]]
deps = ["Animations", "Artifacts", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "IntervalSets", "Isoband", "KernelDensity", "LinearAlgebra", "MakieCore", "Markdown", "Match", "Observables", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "Serialization", "Showoff", "SignedDistanceFields", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "UnicodeFun"]
git-tree-sha1 = "82f9d9de6892e5470372720d23913d14a08991fd"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.14.2"

[[MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "7bcc8323fb37523a6a51ade2234eee27a11114c8"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.1.3"

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

[[MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "JSON", "JSONSchema", "LinearAlgebra", "MutableArithmetics", "OrderedCollections", "SparseArrays", "Test", "Unicode"]
git-tree-sha1 = "575644e3c05b258250bb599e57cf73bbf1062901"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "0.9.22"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[Memento]]
deps = ["Dates", "Distributed", "JSON", "Serialization", "Sockets", "Syslogs", "Test", "TimeZones", "UUIDs"]
git-tree-sha1 = "19650888f97362a2ae6c84f0f5f6cda84c30ac38"
uuid = "f28f55f0-a522-5efc-85c2-fe41dfb9b2d9"
version = "1.2.0"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "4ea90bd5d3985ae1f9a908bd4500ae88921c5ce7"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[Mocking]]
deps = ["ExprTools"]
git-tree-sha1 = "916b850daad0d46b8c71f65f719c49957e9513ed"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.1"

[[MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "3927848ccebcc165952dc0d9ac9aa274a87bfe01"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "0.2.20"

[[NNlib]]
deps = ["Adapt", "ChainRulesCore", "Compat", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "7e6f31cfa39b1ff1c541cc8580b14b0ff4ba22d0"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.7.23"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NaiveBayes]]
deps = ["Distributions", "HDF5", "Interpolations", "KernelDensity", "LinearAlgebra", "Random", "StatsBase"]
git-tree-sha1 = "e7bd30f7fe8547dd065016132f3255445c546fac"
uuid = "9bbee03b-0db5-5f46-924f-b5c9c21b8c60"
version = "0.5.1"

[[Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

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

[[OptimalTransport]]
deps = ["Distances", "Distributions", "IterativeSolvers", "LinearAlgebra", "LogExpFunctions", "MathOptInterface", "NNlib", "PDMats", "QuadGK", "SparseArrays", "StatsBase"]
git-tree-sha1 = "30a693e358ffa6a6441847e177e01a18c619b5fc"
uuid = "7e02d93a-ae51-4f58-b602-d97af76e3b33"
version = "0.3.12"

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

[[PalmerPenguins]]
deps = ["CSV", "DataDeps"]
git-tree-sha1 = "d2a467f75b4dba118a5fe7ae574bd9c72e7fc56b"
uuid = "8b842266-38fa-440a-9b57-31493939ab85"
version = "0.1.2"

[[Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9bc1871464b12ed19297fbc56c4fb4ba84988b0d"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.47.0+0"

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

[[PersistenceDiagramsBase]]
deps = ["Compat", "Tables"]
git-tree-sha1 = "ec6eecbfae1c740621b5d903a69ec10e30f3f4bc"
uuid = "b1ad91c1-539c-4ace-90bd-ea06abc420fa"
version = "0.1.1"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

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

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[QPSReader]]
deps = ["Logging", "Pkg"]
git-tree-sha1 = "7d5d7a3d45e4c53b80dd7eb1e423d3a822192c77"
uuid = "10f199a5-22af-520b-b891-7ce84a7b1bd0"
version = "0.2.0"

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

[[Ratios]]
git-tree-sha1 = "37d210f612d70f3f7d57d488cb3b6eff56ad4e41"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.0"

[[RecipesBase]]
git-tree-sha1 = "b3fb709f3c97bfc6e948be68beeecb55a0b340ae"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.1"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[ReliabilityDiagrams]]
deps = ["ConsistencyResampling", "DataStructures", "Makie", "Random", "RecipesBase", "Statistics", "StatsBase", "StructArrays"]
git-tree-sha1 = "1f3d8850732224da24dc95f2632e1c0e04a59567"
uuid = "e5f51471-6270-49e4-a15a-f1cfbff4f856"
version = "0.2.2"

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

[[Roots]]
deps = ["CommonSolve", "Printf"]
git-tree-sha1 = "4d64e7c43eca16edee87219b0b11f167f09c2d84"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "1.0.9"

[[Rsvg]]
deps = ["Cairo", "Glib_jll", "Librsvg_jll"]
git-tree-sha1 = "3d3dc66eb46568fb3a5259034bfc752a0eb0c686"
uuid = "c4c386cf-5103-5370-be45-f3a111cca3b8"
version = "1.0.0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[ScientificTypes]]
deps = ["CategoricalArrays", "ColorTypes", "Dates", "PersistenceDiagramsBase", "PrettyTables", "ScientificTypesBase", "StatisticalTraits", "Tables"]
git-tree-sha1 = "345e33061ad7c49c6e860e42a04c62ecbea3eabf"
uuid = "321657f4-b219-11e9-178b-2701a2544e81"
version = "2.0.0"

[[ScientificTypesBase]]
git-tree-sha1 = "3f7ddb0cf0c3a4cff06d9df6f01135fa5442c99b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "1.0.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "ffae887d0f0222a19c406a11c3831776d1383e3d"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.3"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

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

[[StableRNGs]]
deps = ["Random", "Test"]
git-tree-sha1 = "3be7d49667040add7ee151fefaf1f8c04c8c8276"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.0"

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

[[StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "dfdf16cc1e531e154c7e62cd42d531e00f8d100e"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.23"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "Tables"]
git-tree-sha1 = "44b3afd37b17422a62aea25f04c1f7e09ce6b07f"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.5.1"

[[StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "e36adc471280e8b346ea24c5c87ba0571204be7a"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.7.2"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[Syslogs]]
deps = ["Printf", "Sockets"]
git-tree-sha1 = "46badfcc7c6e74535cc7d833a91f4ac4f805f86d"
uuid = "cea106d9-e007-5e6c-ad93-58fe2094e9c4"
version = "0.3.0"

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

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TiffImages]]
deps = ["ColorTypes", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "OffsetArrays", "OrderedCollections", "PkgVersion", "ProgressMeter"]
git-tree-sha1 = "03fb246ac6e6b7cb7abac3b3302447d55b43270e"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.4.1"

[[TimeZones]]
deps = ["Dates", "EzXML", "LazyArtifacts", "Mocking", "Pkg", "Printf", "RecipesBase", "Serialization", "Unicode"]
git-tree-sha1 = "960099aed321e05ac649c90d583d59c9309faee1"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.5.5"

[[TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "9f494bc54b4c31404a9eff449235836615929de1"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.10"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "7c53c35547de1c5b9d46a4797cf6d8253807108c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.5"

[[Tulip]]
deps = ["CodecBzip2", "CodecZlib", "LDLFactorizations", "LinearAlgebra", "LinearOperators", "Logging", "MathOptInterface", "Printf", "QPSReader", "SparseArrays", "SuiteSparse", "Test", "TimerOutputs"]
git-tree-sha1 = "e381662f7d351defc05ebbc75c228c38501901f4"
uuid = "6dd1b50a-3aae-11e9-10b5-ef983d2400fa"
version = "0.7.5"

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

[[UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

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

[[ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "c3a5637e27e914a7a445b8d0ad063d701931e9f7"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.3"

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
# ╟─1e1089e5-20ea-43a6-beaa-2c955aec85e6
# ╟─301bd6d5-4309-4b58-8b20-b09eb7ffe4a1
# ╠═019c66f4-b354-4d56-a9cf-7eefad5eb205
# ╟─cff7084e-c9b5-11eb-33b6-81c95ee6c900
# ╟─d7ab458e-e27c-4637-aeb3-2afda37b6e5f
# ╟─3445b353-d975-4416-8a78-41681da6d046
# ╟─458ec313-ddbb-4edb-b6a6-ae5cb3a0b5b5
# ╟─5e63dd4f-d7b1-41f8-81c7-85df389241b9
# ╟─562ddf0e-1131-4aca-8189-8f4d2c0040d8
# ╟─24e81bfb-b4d3-4454-8100-a19fe1bce410
# ╟─b7f20fd4-356c-4e5b-a79e-5b8de2d2fc6a
# ╟─68e437eb-81dd-4371-b855-761e4be50db2
# ╟─d85cf93c-24d0-4af1-a97e-85d6e6306099
# ╟─42b12f2e-9ffd-48f8-b9c8-bb5d709fa340
# ╠═020b339d-33fc-424a-8d36-a90c2eb66999
# ╟─d3c0ebbb-f62e-472b-a1f9-c19808f3d274
# ╟─e3f2755c-f8e1-4b31-9fb1-3b1c5e96c7a6
# ╟─135fc588-3ea5-4c74-81af-09937ff79222
# ╟─06ecd271-baa4-4d7b-88fc-43384f67d98b
# ╟─5c60d82e-6a3a-475c-9947-2db8e057a978
# ╟─3007eeeb-19f6-409b-be66-f3cbcbeb5bea
# ╟─665b98bc-7191-47ae-a9c8-90ac0403f7b6
# ╟─dc77c91d-ad9a-4d25-a2ca-ac9a9f0f1067
# ╟─4ed069a5-29e2-4de1-9ea3-2e1b3589d681
# ╟─edfd6f59-5b6d-4a1c-8f26-c95ce7485792
# ╟─fb8bff06-b321-4775-a042-567693b87407
# ╟─9f7f5fbf-aa52-49ef-b59e-a528f3e8be16
# ╟─42fb6be5-9886-45f2-805b-098f0bba9353
# ╟─9b67bf9f-7255-4a96-bf47-3766fd74d49e
# ╟─2c2b01a1-7e93-4f41-b182-a35dd7b4c097
# ╟─f1e05791-3e0a-4baa-ae2f-940f745e7e3a
# ╟─962de9ec-c675-4329-bab7-b466d2446700
# ╟─c40fcd96-fbd3-4322-8973-9b99ded0505e
# ╟─5de4999e-d050-4a79-87b9-f61e5eae6f20
# ╟─4b521ee4-9a5b-418a-b2bb-7e0de5421a27
# ╟─ee2b5be3-2f96-42aa-a637-95af97bd6948
# ╠═a146e89e-7272-432f-a65f-1d1d513edd29
# ╟─4e9e72ce-e1a6-45a2-8625-d3e5cef7642d
# ╠═9f773aa3-a4de-4728-8afd-734a113668e1
# ╟─7d7739e0-92b4-42bc-b3c5-071d168163a9
# ╟─4b4b0910-c0bd-48ba-8b8a-d09eb6c56578
# ╟─255ec00b-663d-4b76-9376-65ee3b8ed235
# ╠═ecaf1f70-52ad-4f32-806b-0ab29901d337
# ╠═65a9fa62-7873-4c13-be6a-c7c37dbdc26c
# ╟─8fcfa900-c051-439a-8dc2-f21bb17a4896
# ╟─8a6e52a1-ea81-4cf3-91d4-6e6e8f08d068
# ╟─a2282804-0f33-47cd-af63-7b040e801e04
# ╟─c8ef77dd-7620-4e15-aa23-06517bb30086
# ╟─6bf8ec8a-0fc4-41f5-81a3-d2ec474ae90d
# ╟─755f19e0-5b8b-4acd-843e-0117db51e7c3
# ╠═5c0bac01-e491-4b93-8174-4abaa421ea41
# ╟─380321e4-67b4-46d5-9d9c-24474b52bd90
# ╟─17220237-bfc1-4393-90fb-b0a3191de924
# ╟─30a37d5e-6bcb-4f02-92c3-a66d2f1f03f4
# ╟─621cbd71-1a42-4273-9c97-b3c7ffb7a572
# ╟─768ff473-1a20-4562-870a-86919e498eba
# ╟─68e07e05-2aaf-4215-98a5-c3739bed5661
# ╟─f8a4304c-888b-4c21-a4c9-52b7c94b25bf
# ╟─0dcb5ff4-96c5-4a1e-a31e-658f7e919731
# ╟─af85eec3-6e28-423a-a3c0-53b4ab12892d
# ╟─aabd36b5-fc89-45f9-bc26-62f96a9c7adc
# ╟─efdb962e-adf5-4222-b8f5-990690489c61
# ╟─779564a9-62c4-4d4a-9fe2-9a8041d19649
# ╠═01fda3bf-42dd-47a0-8c89-bd138c19fcc3
# ╠═91d0a38b-087d-464a-9741-59f509c6ffd1
# ╟─ec5f6d4c-dd84-44b3-a961-613090302410
# ╟─b0fc768f-b269-4526-826f-752bbafcbe93
# ╟─63678255-0d09-4a88-9eb9-e980a25acee5
# ╟─91f10eb1-9fef-4db5-8c3b-a4e9195e318b
# ╟─c963b0d4-fece-486b-b81e-aeedf8a6d330
# ╟─a39d0830-1165-43e1-91be-d7d136601ade
# ╟─111761a7-39a6-4c38-84e5-f5c5c5d9133d
# ╟─6efd7166-06bc-4404-bb4b-d268c89ed5b5
# ╟─827b3ef2-de7c-459f-842c-1ed465888f62
# ╟─db3ab9ef-089d-4ffb-ac92-41f21f05598f
# ╟─473a7634-adfd-45ab-adfa-65e28111ee98
# ╠═875bcec7-20f8-4038-96f4-b6f56d5239e7
# ╠═552576c8-30ef-45fd-a230-acdcd006978c
# ╟─6dbf213c-245e-414c-af70-bb3e92f99ad5
# ╟─04cbeb0d-1545-4237-bed0-2b89f1bae71a
# ╟─37ceded9-edf8-4077-af19-d6caac831204
# ╟─ab3e5ce8-b354-443c-a68a-7bdbfe434442
# ╟─a21804f0-1dc3-4f0a-933d-eb03f9132027
# ╟─06b01285-4a75-4883-bac2-c24d2d57065e
# ╟─aece0eb4-7672-43a0-8cd0-c5db2b80cbbf
# ╟─4ea0159b-c71b-4adb-9b46-205ce6a85b06
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
