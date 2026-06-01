using CSV
using DataFrames
using Statistics
using CairoMakie

println()
println("Creating publication-style figures...")
println("-------------------------------------")

# ---------------------------------------------------------
# Paths
# ---------------------------------------------------------

project_root = normpath(joinpath(@__DIR__, ".."))
raw_dir = joinpath(project_root, "data", "raw")
processed_dir = joinpath(project_root, "data", "processed")
figures_dir = joinpath(project_root, "figures")

mkpath(figures_dir)

# ---------------------------------------------------------
# Load data
# ---------------------------------------------------------

assessments = CSV.read(
    joinpath(raw_dir, "assessments.csv"),
    DataFrame
)

println("Loaded ", nrow(assessments), " assessment records.")

# ---------------------------------------------------------
# Helper: paired Wave 1 / Wave 4 data
# ---------------------------------------------------------

function paired_data(df, column)

    rows = DataFrame(
        participant_id = Int[],
        wave1 = Float64[],
        wave4 = Float64[],
        change = Float64[]
    )

    grouped = groupby(df, :participant_id)

    for g in grouped

        w1_values = g[g.wave .== 1, column]
        w4_values = g[g.wave .== 4, column]

        w1 = isempty(w1_values) ? missing : w1_values[1]
        w4 = isempty(w4_values) ? missing : w4_values[1]

        if !ismissing(w1) && !ismissing(w4)

            push!(
                rows,
                (
                    g.participant_id[1],
                    Float64(w1),
                    Float64(w4),
                    Float64(w4 - w1)
                )
            )

        end
    end

    return rows
end

# ---------------------------------------------------------
# Helper: confidence interval
# ---------------------------------------------------------

function mean_ci(values)

    n = length(values)
    m = mean(values)

    sd_value = std(values)

    se = sd_value / sqrt(n)

    # Approximate 95% CI using normal critical value.
    margin = 1.96 * se

    return m, m - margin, m + margin
end

# ---------------------------------------------------------
# Prepare paired datasets
# ---------------------------------------------------------

bmi = paired_data(assessments, :bmi)
sbp = paired_data(assessments, :systolic_bp)
questionnaire = paired_data(
    assessments,
    :questionnaire_score
)

println("Complete paired observations:")
println("  BMI: ", nrow(bmi))
println("  Systolic BP: ", nrow(sbp))
println("  Questionnaire: ", nrow(questionnaire))

# ---------------------------------------------------------
# Figure 1: Mean change with 95% CI
# ---------------------------------------------------------

outcomes = [
    ("BMI", bmi),
    ("Systolic BP", sbp),
    ("Questionnaire", questionnaire)
]

means = Float64[]
lower = Float64[]
upper = Float64[]

for (_, data) in outcomes

    m, lo, hi = mean_ci(data.change)

    push!(means, m)
    push!(lower, lo)
    push!(upper, hi)

end

fig = Figure(
    size = (1000, 650),
    fontsize = 20
)

ax = Axis(
    fig[1, 1],
    title = "Mean Change from Wave 1 to Wave 4",
    ylabel = "Mean change",
    xticks = (
        1:3,
        ["BMI", "Systolic BP", "Questionnaire"]
    )
)

x = 1:3

errorbars!(
    ax,
    x,
    means,
    means .- lower,
    upper .- means,
    whiskerwidth = 18,
    linewidth = 4
)

scatter!(
    ax,
    x,
    means,
    markersize = 22
)

hlines!(
    ax,
    [0],
    linestyle = :dash,
    linewidth = 2
)

save(
    joinpath(
        figures_dir,
        "mean_change_95ci.png"
    ),
    fig
)

println(
    "Created figures/mean_change_95ci.png"
)

# ---------------------------------------------------------
# Figure 2: Paired trajectories
# ---------------------------------------------------------

fig = Figure(
    size = (1100, 700),
    fontsize = 20
)

ax = Axis(
    fig[1, 1],
    title = "Individual Wave 1 → Wave 4 Trajectories",
    xlabel = "Assessment wave",
    ylabel = "Value",
    xticks = ([1, 4], ["Wave 1", "Wave 4"])
)

function add_trajectories!(ax, data)

    for row in eachrow(data)

        lines!(
            ax,
            [1, 4],
            [row.wave1, row.wave4],
            linewidth = 1,
            alpha = 0.08
        )

    end

    scatter!(
        ax,
        fill(1, nrow(data)),
        data.wave1,
        markersize = 4,
        alpha = 0.35
    )

    scatter!(
        ax,
        fill(4, nrow(data)),
        data.wave4,
        markersize = 4,
        alpha = 0.35
    )
end

add_trajectories!(ax, bmi)

save(
    joinpath(
        figures_dir,
        "bmi_individual_trajectories.png"
    ),
    fig
)

println(
    "Created figures/bmi_individual_trajectories.png"
)

# ---------------------------------------------------------
# Figure 3: Distribution of individual changes
# ---------------------------------------------------------

fig = Figure(
    size = (1100, 700),
    fontsize = 20
)

ax = Axis(
    fig[1, 1],
    title = "Distribution of Individual Changes",
    xlabel = "Change from Wave 1 to Wave 4",
    ylabel = "Number of participants"
)

hist!(
    ax,
    bmi.change,
    bins = 30,
    strokewidth = 1
)

vlines!(
    ax,
    [0],
    linestyle = :dash,
    linewidth = 3
)

save(
    joinpath(
        figures_dir,
        "bmi_change_distribution.png"
    ),
    fig
)

println(
    "Created figures/bmi_change_distribution.png"
)

# ---------------------------------------------------------
# Figure 4: All three outcome changes
# ---------------------------------------------------------

fig = Figure(
    size = (1100, 700),
    fontsize = 20
)

ax = Axis(
    fig[1, 1],
    title = "Individual Change Distributions",
    ylabel = "Change from Wave 1 to Wave 4",
    xticks = (
        1:3,
        ["BMI", "Systolic BP", "Questionnaire"]
    )
)

boxplot!(
    ax,
    vcat(
        fill(1, nrow(bmi)),
        fill(2, nrow(sbp)),
        fill(3, nrow(questionnaire))
    ),
    vcat(
        bmi.change,
        sbp.change,
        questionnaire.change
    )
)

hlines!(
    ax,
    [0],
    linestyle = :dash,
    linewidth = 2
)

save(
    joinpath(
        figures_dir,
        "change_distributions.png"
    ),
    fig
)

println(
    "Created figures/change_distributions.png"
)

println()
println("All figures created successfully.")
println("Output directory: ", figures_dir)