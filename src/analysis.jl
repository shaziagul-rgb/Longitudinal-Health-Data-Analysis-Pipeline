module Analysis

using DataFrames
using Statistics
using HypothesisTests

export summarize_assessments
export summarize_by_wave
export participant_trajectories
export paired_endpoint_analysis


# ---------------------------------------------------------
# Overall assessment summary
# ---------------------------------------------------------

function summarize_assessments(df::DataFrame)

    result = DataFrame(
        variable = String[],
        n = Int[],
        missing = Int[],
        mean = Float64[],
        median = Float64[]
    )

    for column in [
        :bmi,
        :systolic_bp,
        :questionnaire_score
    ]

        values = collect(skipmissing(df[!, column]))

        n = length(values)
        missing_count = count(ismissing, df[!, column])

        if n == 0
            mean_value = NaN
            median_value = NaN
        else
            mean_value = mean(values)
            median_value = median(values)
        end

        push!(
            result,
            (
                String(column),
                n,
                missing_count,
                mean_value,
                median_value
            )
        )
    end

    return result
end


# ---------------------------------------------------------
# Summary by assessment wave
# ---------------------------------------------------------

function summarize_by_wave(df::DataFrame)

    grouped = groupby(df, :wave)

    result = combine(
        grouped,
        :bmi => (x -> mean(skipmissing(x))) => :mean_bmi,
        :systolic_bp => (x -> mean(skipmissing(x))) =>
            :mean_systolic_bp,
        :questionnaire_score => (x -> mean(skipmissing(x))) =>
            :mean_questionnaire_score,
        nrow => :n_assessments
    )

    sort!(result, :wave)

    return result
end


# ---------------------------------------------------------
# Participant longitudinal trajectories
# ---------------------------------------------------------

function participant_trajectories(df::DataFrame)

    result = select(
        df,
        :participant_id,
        :wave,
        :assessment_date,
        :bmi,
        :systolic_bp,
        :questionnaire_score
    )

    sort!(
        result,
        [:participant_id, :wave]
    )

    return result
end


# ---------------------------------------------------------
# Paired Wave 1 vs Wave 4 analysis
# ---------------------------------------------------------

function paired_endpoint_analysis(df::DataFrame)

    variables = [
        ("BMI", :bmi),
        ("Systolic BP", :systolic_bp),
        ("Questionnaire", :questionnaire_score)
    ]

    result = DataFrame(
        outcome = String[],
        n = Int[],
        mean_change = Float64[],
        sd_change = Float64[],
        ci_lower = Float64[],
        ci_upper = Float64[],
        t_statistic = Float64[],
        df = Int[],
        paired_t_p = Float64[],
        wilcoxon_p = Float64[]
    )

    for (label, column) in variables

        # -------------------------------------------------
        # Wave 1
        # -------------------------------------------------

        wave1 = filter(
            row -> row.wave == 1,
            df
        )

        wave1 = DataFrame(
            participant_id = wave1.participant_id,
            wave_1 = wave1[!, column]
        )


        # -------------------------------------------------
        # Wave 4
        # -------------------------------------------------

        wave4 = filter(
            row -> row.wave == 4,
            df
        )

        wave4 = DataFrame(
            participant_id = wave4.participant_id,
            wave_4 = wave4[!, column]
        )


        # -------------------------------------------------
        # Match participants at both endpoints
        # -------------------------------------------------

        paired = innerjoin(
            wave1,
            wave4,
            on = :participant_id
        )


        # -------------------------------------------------
        # Remove missing endpoint measurements
        # -------------------------------------------------

        complete = dropmissing(
            paired,
            [:wave_1, :wave_4]
        )


        # -------------------------------------------------
        # Calculate individual change
        # Wave 4 - Wave 1
        # -------------------------------------------------

        changes = Float64.(
            complete.wave_4 .- complete.wave_1
        )

        n = length(changes)

        if n < 2
            error(
                "Not enough complete Wave 1/Wave 4 observations for $label"
            )
        end


        # -------------------------------------------------
        # Mean change
        # -------------------------------------------------

        mean_change = sum(changes) / n


        # -------------------------------------------------
        # Sample standard deviation
        # -------------------------------------------------

        variance = sum(
            (changes .- mean_change).^2
        ) / (n - 1)

        sd_change = sqrt(variance)


        # -------------------------------------------------
        # Paired t-test
        # -------------------------------------------------

        test = OneSampleTTest(changes)

        ci = confint(test)

        t_statistic = test.t

        degrees_freedom = test.df

        paired_t_p = pvalue(test)


        # -------------------------------------------------
        # Wilcoxon signed-rank sensitivity analysis
        # -------------------------------------------------

        wilcoxon = SignedRankTest(changes)

        wilcoxon_p = pvalue(wilcoxon)


        # -------------------------------------------------
        # Store result
        # -------------------------------------------------

        push!(
            result,
            (
                label,
                n,
                mean_change,
                sd_change,
                ci[1],
                ci[2],
                t_statistic,
                degrees_freedom,
                paired_t_p,
                wilcoxon_p
            )
        )
    end

    return result
end


end