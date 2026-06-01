using CSV
using DataFrames

include(joinpath(@__DIR__, "..", "src", "validation.jl"))
using .Validation

include(joinpath(@__DIR__, "..", "src", "analysis.jl"))
using .Analysis


# ---------------------------------------------------------
# Project paths
# ---------------------------------------------------------

project_root = normpath(joinpath(@__DIR__, ".."))

raw_dir = joinpath(project_root, "data", "raw")
processed_dir = joinpath(project_root, "data", "processed")

mkpath(processed_dir)


# ---------------------------------------------------------
# Input files
# ---------------------------------------------------------

participants_file = joinpath(
    raw_dir,
    "participants.csv"
)

assessments_file = joinpath(
    raw_dir,
    "assessments.csv"
)


# ---------------------------------------------------------
# Load raw data
# ---------------------------------------------------------

println()
println("Loading raw data...")
println("-------------------")

participants = CSV.read(
    participants_file,
    DataFrame
)

assessments = CSV.read(
    assessments_file,
    DataFrame
)

println("Participants: ", nrow(participants))
println("Assessments: ", nrow(assessments))


# ---------------------------------------------------------
# Validate data
# ---------------------------------------------------------

println()
println("Validating data...")
println("------------------")

participant_errors = validate_participants(participants)
assessment_errors = validate_assessments(assessments)

if !isempty(participant_errors)

    println("Participant validation errors:")

    for error in participant_errors
        println("  - ", error)
    end

    error("Participant validation failed.")
end


if !isempty(assessment_errors)

    println("Assessment validation errors:")

    for error in assessment_errors
        println("  - ", error)
    end

    error("Assessment validation failed.")
end

println("Validation passed.")


# ---------------------------------------------------------
# Generate analysis outputs
# ---------------------------------------------------------

println()
println("Running analysis...")
println("-------------------")

overall_summary = summarize_assessments(
    assessments
)

wave_summary = summarize_by_wave(
    assessments
)

trajectories = participant_trajectories(
    assessments
)

statistical_results = paired_endpoint_analysis(
    assessments
)


# ---------------------------------------------------------
# Write processed outputs
# ---------------------------------------------------------

CSV.write(
    joinpath(
        processed_dir,
        "assessment_summary.csv"
    ),
    overall_summary
)

CSV.write(
    joinpath(
        processed_dir,
        "wave_summary.csv"
    ),
    wave_summary
)

CSV.write(
    joinpath(
        processed_dir,
        "participant_trajectories.csv"
    ),
    trajectories
)

CSV.write(
    joinpath(
        processed_dir,
        "statistical_results.csv"
    ),
    statistical_results
)


# ---------------------------------------------------------
# Pipeline summary
# ---------------------------------------------------------

println()
println("Pipeline completed successfully.")
println("--------------------------------")
println(
    "Assessment summary: ",
    joinpath(
        processed_dir,
        "assessment_summary.csv"
    )
)

println(
    "Wave summary: ",
    joinpath(
        processed_dir,
        "wave_summary.csv"
    )
)

println(
    "Participant trajectories: ",
    joinpath(
        processed_dir,
        "participant_trajectories.csv"
    )
)


println(
    "Statistical results: ",
    joinpath(
        processed_dir,
        "statistical_results.csv"
    )
)

println()