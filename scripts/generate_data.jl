using Random
using Dates
using CSV
using DataFrames

# ---------------------------------------------------------
# Synthetic Longitudinal Research Dataset
# ---------------------------------------------------------

Random.seed!(20261002)

mkpath("data/raw")

# ---------------------------------------------------------
# 1. Create participants
# ---------------------------------------------------------

n = 1000

participant_id = collect(100001:(100000 + n))

sex = [
    rand() < 0.51 ? "F" : "M"
    for _ in 1:n
]

birth_year = fill(1977, n)

participants = DataFrame(
    participant_id = participant_id,
    sex = sex,
    birth_year = birth_year
)

CSV.write(
    "data/raw/participants.csv",
    participants
)

# ---------------------------------------------------------
# 2. Define longitudinal assessment waves
# ---------------------------------------------------------

waves = [
    (1, Date(1995, 7, 1), 18),
    (2, Date(2005, 7, 1), 28),
    (3, Date(2015, 7, 1), 38),
    (4, Date(2025, 7, 1), 48)
]

# Approximate probability of appearing in each wave.
retention = Dict(
    1 => 0.98,
    2 => 0.93,
    3 => 0.87,
    4 => 0.80
)

# Store assessment records here.
records = NamedTuple[]

# ---------------------------------------------------------
# 3. Generate repeated measurements
# ---------------------------------------------------------

for participant in eachrow(participants)

    for (wave, base_date, age) in waves

        # Simulate longitudinal participant retention.
        if rand() > retention[wave]
            continue
        end

        # Synthetic BMI.
        bmi = clamp(
            23.5 +
            0.08 * (age - 18) +
            (participant.sex == "M" ? 0.8 : 0.0) +
            randn() * 3.2,
            15,
            45
        )

        # Synthetic systolic blood pressure.
        systolic_bp = clamp(
            112 +
            0.65 * (age - 18) +
            (participant.sex == "M" ? 3 : 0) +
            randn() * 11,
            80,
            210
        )

        # Synthetic questionnaire score.
        questionnaire_score = clamp(
            50 + randn() * 10,
            0,
            100
        )

        # Introduce a small amount of missing data.
        bmi_value =
            rand() < 0.035 ? missing : round(bmi, digits=1)

        bp_value =
            rand() < 0.055 ? missing : round(systolic_bp, digits=1)

        questionnaire_value =
            rand() < 0.04 ? missing : round(questionnaire_score, digits=1)

        # Slightly randomise assessment date.
        assessment_date =
            base_date + Day(rand(0:180))

        push!(
            records,
            (
                participant_id = participant.participant_id,
                wave = wave,
                assessment_date = assessment_date,
                bmi = bmi_value,
                systolic_bp = bp_value,
                questionnaire_score = questionnaire_value
            )
        )
    end
end

# ---------------------------------------------------------
# 4. Create assessment DataFrame
# ---------------------------------------------------------

assessments = DataFrame(records)

CSV.write(
    "data/raw/assessments.csv",
    assessments
)

println()
println("Synthetic research dataset created.")
println("-----------------------------------")
println("Participants: ", nrow(participants))
println("Assessment records: ", nrow(assessments))
println("Assessment waves: ", length(waves))
println()