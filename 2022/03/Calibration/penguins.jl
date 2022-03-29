# Load packages
using AlgebraOfGraphics
using CairoMakie
using CalibrationAnalysis
using DataFrames
using MLJ
using PalmerPenguins

using Random

const AoG = AlgebraOfGraphics

# Set seed
Random.seed!(1234);

# Plot settings
set_aog_theme!()
figpath(names...) = joinpath(@__DIR__, "figures", "penguins", names...)
mkpath(figpath())
savefig(name, fig=current_figure()) = save(figpath(name), fig)

# Load penguin data
penguins = dropmissing(DataFrame(PalmerPenguins.load()))
y, X = unpack(
    penguins,
    ==(:species),
    x ->
        x === :bill_length_mm ||
            x === :bill_depth_mm ||
            x === :flipper_length_mm ||
            x == :body_mass_g;
    :species => Multiclass,
    :bill_length_mm => MLJ.Continuous,
    :bill_depth_mm => MLJ.Continuous,
    :flipper_length_mm => MLJ.Continuous,
    :body_mass_g => MLJ.Continuous,
)

# Create training and validation datasets
trainidxs, validxs = partition(1:nrow(X), 0.7; stratify=y, shuffle=true)
penguins.train = let
    train = trues(nrow(X))
    train[validxs] .= false
    train
end

# Plot datasets
dataset = :train => renamer(true => "training", false => "validation") => "Dataset"
penguins_mapping =
    data(penguins) * mapping(
        :bill_length_mm => "bill length (mm)", :flipper_length_mm => "flipper length (mm)"
    )
draw(
    penguins_mapping * mapping(; color=:species, col=dataset) * visual(; alpha=0.7);
    figure=(resolution=(800, 300),),
)
savefig("penguins.pdf")

# Train logistic regression model
LR = @load MultinomialClassifier pkg = MLJLinearModels
model = fit!(machine(LR(), X, y); rows=penguins.train)

# Compute confidence and corresponding outcomes
predictions_confidence = let
    predictions = MLJ.predict(model, X)
    mode = MLJ.predict_mode(model, X)
    confidence = pdf.(predictions, mode)

    DataFrame(
        :id => 1:nrow(penguins),
        :train => penguins.train,
        :confidence => confidence,
        :outcomes => mode .== penguins.species,
    )
end

# Plot confidence
draw(
    data(predictions_confidence) *
    histogram(; closed=:right, bins=0.305:0.05:1.005, normalization=:probability) *
    mapping(:confidence) *
    mapping(; col=dataset);
    figure=(resolution=(800, 300),),
)
savefig("confidence.pdf")

#

# Plot reliability diagram
xscale(x) = cbrt(x - 1)
CairoMakie.Makie.inverse_transform(::typeof(xscale)) = x -> 1 + x^3
CairoMakie.Makie.MakieLayout.defaultlimits(::typeof(xscale)) = (0.5, 1.5)
function CairoMakie.Makie.MakieLayout.defined_interval(::typeof(xscale))
    return CairoMakie.Makie.OpenInterval(-Inf, Inf)
end
function plot_reliabilitydiagram(predictions)
    fig = Figure(; resolution=(400, 300))
    ax = Axis(
        fig[1, 1];
        xlabel="confidence",
        ylabel="deviation",
        xscale=xscale,
        xticks=[0.5, 0.75, 0.9, 0.99, 1],
    )
    reliability!(
        ax,
        predictions.confidence,
        predictions.outcomes;
        binning=EqualMass(; n=15),
        deviation=true,
        consistencybars=ConsistencyBars(),
        label="data",
    )
    hlines!(ax, 0; color=:black, linestyle=:dash, label="ideal")
    axislegend()
    return fig
end
Random.seed!(100)
plot_reliabilitydiagram(predictions_confidence[validxs, :])
savefig("reliability_diagram.pdf")

# Extract confidence, predictions, etc. on validation dataset
confidence = predictions_confidence.confidence[validxs]
outcomes = predictions_confidence.outcomes[validxs]
predictions = ColVecs(Float64.(pdf(MLJ.predict(model, X[validxs, :]), levels(y))'))
observations = int(y[validxs])

# Compute ECE estimates
ece = ECE(UniformBinning(5), TotalVariation())
@show ece(confidence, outcomes)
@show ece(predictions, observations)

# Compute SKCE estimates
kernel = GaussianKernel() ⊗ WhiteKernel()
skce = SKCE(kernel)
@show skce(predictions, observations)

skce = SKCE(kernel; unbiased=false)
@show skce(predictions, observations)

skce = SKCE(kernel; blocksize=5)
@show skce(predictions, observations)

# Calibration tests
Random.seed!(876)
@show AsymptoticSKCETest(kernel, predictions, observations)

test = ConsistencyTest(ece, predictions, observations)
@show pvalue(test; bootstrap_iters=10_000)
