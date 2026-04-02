using Test
using DataFrames
using Dates
using CSV

include(
    joinpath(
        @__DIR__,
        "..",
        "src",
        "validation.jl"
    )
)

using .Validation


include(
    joinpath(
        @__DIR__,
        "..",
        "src",
        "analysis.jl"
    )
)

using .Analysis


# ---------------------------------------------------------
# Participant validation
# ---------------------------------------------------------

@testset "Participant validation" begin

    participants = DataFrame(
        participant_id = [1, 2, 3],
        sex = ["F", "M", "F"],
        birth_year = [1977, 1977, 1977]
    )

    errors = validate_participants(
        participants
    )

    @test isempty(errors)
end


# ---------------------------------------------------------
# Duplicate participant IDs
# ---------------------------------------------------------

@testset "Duplicate participant IDs" begin

    participants = DataFrame(
        participant_id = [1, 1],
        sex = ["F", "M"],
        birth_year = [1977, 1977]
    )

    errors = validate_participants(
        participants
    )

    @test !isempty(errors)
end


# ---------------------------------------------------------
# Assessment validation
# ---------------------------------------------------------

@testset "Assessment validation" begin

    assessments = DataFrame(
        participant_id = [1],
        wave = [1],
        assessment_date = [Date(1995, 1, 1)],
        bmi = [22.0],
        systolic_bp = [120.0],
        questionnaire_score = [55.0]
    )

    errors = validate_assessments(
        assessments
    )

    @test isempty(errors)
end


# ---------------------------------------------------------
# Invalid BMI
# ---------------------------------------------------------

@testset "Invalid BMI" begin

    assessments = DataFrame(
        participant_id = [1],
        wave = [1],
        assessment_date = [Date(1995, 1, 1)],
        bmi = [100.0],
        systolic_bp = [120.0],
        questionnaire_score = [55.0]
    )

    errors = validate_assessments(
        assessments
    )

    @test !isempty(errors)
end


# ---------------------------------------------------------
# Generated CSV validation
# ---------------------------------------------------------

@testset "Generated CSV validation" begin

    participants = CSV.read(
        joinpath(
            @__DIR__,
            "..",
            "data",
            "raw",
            "participants.csv"
        ),
        DataFrame
    )

    assessments = CSV.read(
        joinpath(
            @__DIR__,
            "..",
            "data",
            "raw",
            "assessments.csv"
        ),
        DataFrame
    )

    participant_errors = validate_participants(
        participants
    )

    assessment_errors = validate_assessments(
        assessments
    )

    @test isempty(participant_errors)
    @test isempty(assessment_errors)

    @test nrow(participants) == 1000
    @test nrow(assessments) == 3586
end


# ---------------------------------------------------------
# Longitudinal statistical analysis
# ---------------------------------------------------------

@testset "Paired endpoint analysis" begin

    assessments = CSV.read(
        joinpath(
            @__DIR__,
            "..",
            "data",
            "raw",
            "assessments.csv"
        ),
        DataFrame
    )

    results = paired_endpoint_analysis(
        assessments
    )

    @test nrow(results) == 3

    @test results.outcome == [
        "BMI",
        "Systolic BP",
        "Questionnaire"
    ]

    @test results.n == [
        717,
        682,
        707
    ]

    @test isapprox(
        results.mean_change[1],
        2.323291492329149;
        atol = 1e-10
    )

    @test isapprox(
        results.mean_change[2],
        20.452199413489737;
        atol = 1e-10
    )

    @test isapprox(
        results.mean_change[3],
        -0.01272984441301279;
        atol = 1e-10
    )

    @test results.paired_t_p[1] < 0.001
    @test results.paired_t_p[2] < 0.001
    @test results.paired_t_p[3] > 0.05

    @test results.wilcoxon_p[1] < 0.001
    @test results.wilcoxon_p[2] < 0.001
    @test results.wilcoxon_p[3] > 0.05
end