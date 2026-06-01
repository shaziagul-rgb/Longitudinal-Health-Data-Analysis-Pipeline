
module Validation

using DataFrames
using Dates

export validate_participants
export validate_assessments
export missingness_report


# ---------------------------------------------------------
# Validate participant data
# ---------------------------------------------------------

function validate_participants(df::DataFrame)

    errors = String[]

    required_columns = [
        :participant_id,
        :sex,
        :birth_year
    ]

    # Check required columns.
    for column in required_columns
        if !(column in propertynames(df))
            push!(
                errors,
                "Missing required column: $(column)"
            )
        end
    end

    # Stop if essential columns don't exist.
    if !(:participant_id in propertynames(df))
        return errors
    end

    # Check missing participant IDs.
    if any(ismissing, df.participant_id)
        push!(
            errors,
            "participant_id contains missing values"
        )
    end

    # Check duplicate participant IDs.
    unique_ids = length(unique(skipmissing(df.participant_id)))

    if unique_ids != nrow(df)
        push!(
            errors,
            "participant_id contains duplicates"
        )
    end

    # Validate birth year.
    if :birth_year in propertynames(df)

        invalid_birth_years = findall(
            x -> !ismissing(x) &&
                 (x < 1900 || x > year(today())),
            df.birth_year
        )

        if !isempty(invalid_birth_years)
            push!(
                errors,
                "birth_year contains invalid values"
            )
        end
    end

    return errors
end


# ---------------------------------------------------------
# Validate longitudinal assessment data
# ---------------------------------------------------------

function validate_assessments(df::DataFrame)

    errors = String[]

    required_columns = [
        :participant_id,
        :wave,
        :assessment_date,
        :bmi,
        :systolic_bp,
        :questionnaire_score
    ]

    # Check required columns.
    for column in required_columns
        if !(column in propertynames(df))
            push!(
                errors,
                "Missing required column: $(column)"
            )
        end
    end

    # BMI validation.
    if :bmi in propertynames(df)

        invalid_bmi = findall(
            x -> !ismissing(x) &&
                 (x < 10 || x > 80),
            df.bmi
        )

        if !isempty(invalid_bmi)
            push!(
                errors,
                "bmi contains values outside 10–80 kg/m²"
            )
        end
    end

    # Blood pressure validation.
    if :systolic_bp in propertynames(df)

        invalid_bp = findall(
            x -> !ismissing(x) &&
                 (x < 60 || x > 250),
            df.systolic_bp
        )

        if !isempty(invalid_bp)
            push!(
                errors,
                "systolic_bp contains values outside 60–250 mmHg"
            )
        end
    end

    # Questionnaire validation.
    if :questionnaire_score in propertynames(df)

        invalid_scores = findall(
            x -> !ismissing(x) &&
                 (x < 0 || x > 100),
            df.questionnaire_score
        )

        if !isempty(invalid_scores)
            push!(
                errors,
                "questionnaire_score contains values outside 0–100"
            )
        end
    end

    return errors
end


# ---------------------------------------------------------
# Generate missing-data report
# ---------------------------------------------------------

function missingness_report(df::DataFrame)

    result = DataFrame(
        variable = String[],
        missing_count = Int[],
        total_count = Int[],
        missing_percent = Float64[]
    )

    for column in names(df)

        missing_count = count(
            ismissing,
            df[!, column]
        )

        total_count = nrow(df)

        percentage =
            total_count == 0 ?
            0.0 :
            100 * missing_count / total_count

        push!(
            result,
            (
                String(column),
                missing_count,
                total_count,
                percentage
            )
        )
    end

    return result
end


end


