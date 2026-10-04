## Figures

The analysis produces figures showing mean changes, individual participant trajectories, and distributions of change.

### Mean change from Wave 1 to Wave 4

<p align="center">
  <img src="figures/mean_change_95ci.png" alt="Mean change from Wave 1 to Wave 4" width="750">
</p>

The figure above summarises the mean change between Wave 1 and Wave 4 for BMI, systolic blood pressure, and questionnaire score, with 95% confidence intervals.

### Supporting figures

| Individual BMI trajectories | BMI change distribution |
|---|---|
| <img src="figures/bmi_individual_trajectories.png" alt="Individual BMI trajectories" width="400"> | <img src="figures/bmi_change_distribution.png" alt="BMI change distribution" width="400"> |

| Change distributions across outcomes |
|---|
| <img src="figures/change_distributions.png" alt="Change distributions across outcomes" width="500"> |

All figures are generated automatically by:

```bash
julia --project=. scripts/create_figures.jl
```
