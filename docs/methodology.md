# 🧠 ColdIQ — Methodology

This document explains **how ColdIQ turns the collected data into decision scores and recommendations**.

It focuses on the analytical logic behind the project rather than repeating the data sources or dashboard description.

ColdIQ uses three main decision models:

1. **District Commodity Investment**
2. **Intrastate Storage Location**
3. **Interstate Trade Opportunity**

---

# 1. Overall Method

The basic idea is to avoid making a decision from a single metric such as price.

Instead, ColdIQ follows this process:

```text
Historical Data
      ↓
Derived Metrics
      ↓
Economic & Operational Factors
      ↓
Component Scores
      ↓
Weighted Overall Score
      ↓
Eligibility / Business Rules
      ↓
Ranked Recommendation
```

This allows a commodity or location to perform well only when multiple relevant factors support the opportunity.

---

# 2. District Commodity Investment

## Business Question

> **For a particular district, which commodities provide the most attractive storage-investment opportunity?**

For each district and commodity, ColdIQ first identifies a potential storage cycle:

```text
Buy
 ↓
Store
 ↓
Sell
```

The model evaluates the price opportunity and then checks whether the storage period is compatible with the commodity.

---

## 2.1 Storage Timing

The holding period is compared with the commodity's shelf-life information.

The model uses:

```text
Holding Period × 30 days
```

and compares it with the minimum and maximum shelf-life limits.

The scoring logic is:

| Condition | Storage Timing Score |
|---|---:|
| Holding period ≤ minimum shelf life | 100 |
| Holding period ≤ maximum shelf life | 70 |
| Holding period > maximum shelf life | 0 |

A score of `0` means the proposed storage cycle is considered a **Storage Window Mismatch**.

---

## 2.2 Profit Score

The model converts modeled net return per MT into a score.

The implemented thresholds include:

| Net Return / MT | Profit Score |
|---:|---:|
| ≥ ₹75,000 | 90 |
| ≥ ₹50,000 | 80 |
| ≥ ₹30,000 | 70 |
| ≥ ₹15,000 | 55 |
| Below ₹15,000 | 35 |

The score is intentionally based on relative economic attractiveness rather than using profit alone as the final decision.

---

## 2.3 Payback Score

Estimated payback is converted into a score:

| Payback | Payback Score |
|---:|---:|
| ≤ 4 years | 100 |
| ≤ 5 years | 90 |
| ≤ 6 years | 80 |
| ≤ 7 years | 70 |
| ≤ 10 years | 50 |
| > 10 years | 20 |

This gives faster capital recovery a higher score.

---

## 2.4 Market Score

Market reliability is converted into:

| Market Reliability | Market Score |
|---:|---:|
| ≥ 0.90 | 100 |
| ≥ 0.80 | 90 |
| ≥ 0.70 | 80 |
| ≥ 0.60 | 65 |
| Below 0.60 | 50 |

---

## 2.5 Production Score

Production deciles are used as a measure of production strength.

| Production Decile | Production Score |
|---:|---:|
| ≤ 1 | 100 |
| ≤ 3 | 90 |
| ≤ 5 | 75 |
| ≤ 8 | 50 |
| Above 8 | 25 |

This helps give stronger production regions an advantage in the investment model.

---

## 2.6 Price Stability Score

Price volatility is represented using the coefficient of variation (CV).

| Price CV | Stability Score |
|---:|---:|
| ≤ 0.15 | 100 |
| ≤ 0.25 | 85 |
| ≤ 0.40 | 70 |
| ≤ 0.60 | 50 |
| > 0.60 | 25 |

Lower volatility therefore receives a higher score.

---

## 2.7 Final Investment Score

The six component scores are combined using the following weights:

```text
Investment Score =
    Profit Score          × 30%
  + Storage Timing Score  × 25%
  + Payback Score         × 20%
  + Market Score          × 10%
  + Production Score      × 10%
  + Stability Score       ×  5%
```

So the model gives the greatest importance to:

1. Profitability
2. Storage feasibility
3. Payback

with market, production and price stability acting as additional decision factors.

---

## 2.8 Final Investment Decision

After scoring, commodities are ranked within each district.

The ranking prioritizes:

1. Positive net return
2. Valid storage timing
3. Higher investment score
4. Higher net return
5. Lower payback period

The final decision labels are:

| Rule | Decision |
|---|---|
| Net Return ≤ 0 | **Do Not Invest** |
| Storage Timing Score = 0 | **Storage Window Mismatch** |
| Payback > 7 years | **High Payback Risk** |
| Investment Score ≥ 80 | **Strong Investment** |
| Investment Score ≥ 65 | **Good Investment** |
| Investment Score ≥ 50 | **Moderate Investment** |
| Otherwise | **Weak Investment** |

The model then retains the top five ranked commodities for each district.

---

# 3. Intrastate Storage Location Model

## Business Question

> **For a commodity within a state, which districts are better locations for cold-storage investment?**

This model is different from the district commodity model.

Instead of asking:

> "Which commodity should I store?"

it asks:

> "Where should I build the storage facility?"

---

## 3.1 Seasonal Price Score

ColdIQ compares the lower-price and higher-price periods for a commodity and district.

The resulting metric is:

```text
Seasonal Price Gain %
=
(High Season Price − Low Season Price)
÷ Low Season Price × 100
```

The gain is then converted into a score.

Higher seasonal price appreciation receives a higher score.

---

## 3.2 Market Reliability Score

Market reliability is scored as:

| Market Reliability | Score |
|---:|---:|
| ≥ 0.90 | 100 |
| ≥ 0.80 | 90 |
| ≥ 0.70 | 80 |
| ≥ 0.60 | 65 |
| Below 0.60 | 50 |

The model also penalizes locations with insufficient market observations.

---

## 3.3 Price Stability Score

Price CV is used again to represent price stability:

| Price CV | Score |
|---:|---:|
| ≤ 0.15 | 100 |
| ≤ 0.25 | 85 |
| ≤ 0.40 | 70 |
| ≤ 0.60 | 50 |
| > 0.60 | 25 |

---

## 3.4 Production Score

Production level is converted into:

| Production Level | Score |
|---|---:|
| Very High | 100 |
| High | 90 |
| Medium | 75 |
| Low | 10 |
| Negligible | 0 |
| Unknown | 0 |

---

## 3.5 Storage Location Score

The final score is:

```text
Storage Location Score =
    Seasonal Score       × 45%
  + Reliability Score    × 25%
  + Stability Score      × 15%
  + Production Score     × 15%
```

Seasonal price opportunity receives the highest weight because the model is specifically looking for locations where storing a commodity can bridge a lower-price period and a higher-price period.

---

## 3.6 Storage Eligibility

A district is marked as storage-eligible only when:

```text
Active Months ≥ 6
AND
Market Observations ≥ 100
AND
Market Reliability ≥ 0.50
AND
Production Level ∈ {Very High, High, Medium}
```

Importantly, the model still keeps other districts in the output.

They are assigned:

```text
Avoid
```

rather than being silently removed from the analysis.

This makes the dashboard useful for comparing both attractive and unattractive locations.

---

## 3.7 Final Intrastate Opportunity

The final classification is:

| Score | Opportunity |
|---:|---|
| ≥ 80 | **Strong Storage Location** |
| ≥ 65 | **Good Storage Location** |
| ≥ 50 | **Moderate Storage Location** |
| Below 50 | **Weak Storage Location** |
| Fails eligibility | **Avoid** |

Districts are also ranked within each:

```text
Commodity + Variety + State
```

combination.

---

# 4. Interstate Trade Model

## Business Question

> **When does moving a commodity from one state to another make economic sense?**

The interstate model evaluates a complete route:

```text
Source State
     ↓
Buy Commodity
     ↓
Transport
     ↓
Transit Spoilage
     ↓
Destination State
     ↓
Sell Commodity
```

---

# 4.1 Gross Price Gain

The first economic measure is:

```text
Gross Price Gain / MT
=
Selling Price / MT − Buying Price / MT
```

and:

```text
Gross Price Gain %
=
Gross Price Gain / Buying Price × 100
```

However, the model does not treat this gross difference as profit.

Transportation and spoilage are deducted before calculating the final route economics.

---

# 4.2 Transportation Cost

Transportation cost is estimated from route distance and the project's freight-rate assumption.

The model calculates:

```text
Transport Cost / MT
=
Distance × Freight Rate
```

---

# 4.3 Transit Spoilage

Transit spoilage is estimated using:

```text
Transit Spoilage
=
Average Spoilage Rate
×
Transit Days / Average Shelf Life
```

with the resulting fraction capped at 100%.

This converts transit time into a potential loss of saleable commodity.

---

# 4.4 Saleable Revenue

The model estimates the revenue remaining after transit spoilage:

```text
Saleable Revenue / MT
=
Selling Price
×
(1 − Transit Spoilage)
```

---

# 4.5 Net Transport Profit

The route-level economic result is:

```text
Net Transport Profit / MT
=
Saleable Revenue
− Buying Price
− Transport Cost
```

This is the key economic measure used by the interstate model.

---

# 4.6 Margin Score

The net transport profit is compared with the buying price.

| Net Profit / Buying Price | Margin Score |
|---:|---:|
| ≥ 30% | 100 |
| ≥ 20% | 80 |
| ≥ 10% | 60 |
| ≥ 5% | 40 |
| Below 5% | 20 |
| Non-positive profit | 0 |

---

# 4.7 Spoilage Score

Transit spoilage is scored as:

| Transit Spoilage | Score |
|---:|---:|
| ≤ 5% | 100 |
| > 5% to 10% | 75 |
| > 10% to 20% | 50 |
| > 20% to 30% | 25 |
| > 30% | 0 |

---

# 4.8 Market Reliability Score

Source and destination market reliability are averaged and converted to a score capped at 100.

This prevents a route from receiving a perfect market score when one or both markets have weak historical reliability.

---

# 4.9 Price Stability Score

The model uses the worse of the source and destination price CV values.

The highest CV is therefore used as the route's stability constraint.

| Maximum Source/Destination CV | Score |
|---:|---:|
| ≤ 0.15 | 100 |
| ≤ 0.25 | 80 |
| ≤ 0.40 | 60 |
| ≤ 0.60 | 40 |
| > 0.60 | 20 |

---

# 4.10 Source Supply Score

The source production level contributes:

| Source Production Level | Score |
|---|---:|
| Very High | 100 |
| High | 85 |
| Medium | 70 |
| Other | 0 |

This helps favour routes where the source has stronger production availability.

---

# 4.11 Final Transport Opportunity Score

The final score is:

```text
Transport Opportunity Score =
    Margin Score              × 35%
  + Spoilage Score             × 20%
  + Market Reliability Score   × 20%
  + Price Stability Score      × 10%
  + Source Supply Score        × 15%
```

The model therefore prioritizes economic margin while still accounting for spoilage, market quality, price stability and source-side supply.

---

# 4.12 Interstate Opportunity Rules

Before the score is interpreted, certain conditions can force a route to:

```text
Avoid
```

These include:

- non-positive net transport profit,
- transit spoilage above 30%,
- source market reliability below 0.50, or
- destination market reliability below 0.50.

Otherwise, the score is classified as:

| Score | Opportunity |
|---:|---|
| ≥ 80 | **Strong Transport Opportunity** |
| ≥ 65 | **Good Transport Opportunity** |
| ≥ 50 | **Moderate Transport Opportunity** |
| Below 50 | **Weak Transport Opportunity** |

The model also generates a **Primary Reason**, such as insufficient price advantage, excessive spoilage, insufficient market reliability, or a strong production-to-market relationship.

---

# 5. Streamlit Scenario Analysis

The Streamlit application adds an interactive scenario layer on top of the district investment results.

This is intentionally separate from the historical scoring model.

The user can change assumptions such as:

- Facility Capacity
- Facility Utilization
- Other Operating Costs
- Electricity Load
- Electrical Load Factor
- Subsidy

---

## 5.1 Effective Capacity

The modeled occupied capacity is:

```text
Effective Capacity
=
Facility Capacity × Utilization %
```

---

## 5.2 Saleable Capacity

After storage spoilage:

```text
Saleable Capacity
=
Effective Capacity × (1 − Spoilage)
```

---

## 5.3 Revenue

```text
Saleable Revenue
=
Saleable Capacity × Selling Price
```

---

## 5.4 Procurement Cost

```text
Procurement Cost
=
Effective Capacity × Buying Price
```

---

## 5.5 Electricity Cost

The scenario model estimates electricity cost using:

```text
Electricity Cost
=
Price per kWh
× Facility Load
× Load Factor
× 24
× 30
× Holding Months
```

---

## 5.6 Operating Cost

Other operating costs are modeled as a percentage of saleable revenue:

```text
Operating Cost
=
Saleable Revenue × Operating Cost Rate
```

---

## 5.7 Infrastructure Cost

The infrastructure cost is adjusted for the selected subsidy:

```text
Net Infrastructure Cost / MT
=
Infrastructure Cost / MT
× (1 − Subsidy %)
```

and:

```text
Total Infrastructure Cost
=
Net Infrastructure Cost / MT
× Facility Capacity
```

---

## 5.8 Net Return

Total modeled cost is:

```text
Total Cost
=
Procurement Cost
+ Electricity Cost
+ Operating Cost
+ Infrastructure Cost
```

Then:

```text
Net Return
=
Saleable Revenue − Total Cost
```

---

## 5.9 Annualized Return

The number of modeled cycles per year is:

```text
Annual Cycles
=
12 / Holding Months
```

Therefore:

```text
Annualized Return
=
Net Return × Annual Cycles
```

---

## 5.10 ROI and Payback

The scenario model calculates:

```text
ROI
=
Annualized Return
÷
Total Infrastructure Cost
× 100
```

and:

```text
Payback
=
Total Infrastructure Cost
÷
Annualized Return
```

These figures are **scenario estimates**.

They are useful for comparing how assumptions affect the model, but they should not be interpreted as guaranteed real-world financial returns.

---

# 6. Why ColdIQ Uses Scores

The project deliberately separates:

### Economic metrics

Examples:

- Net Return / MT
- Price Gain %
- ROI
- Payback
- Net Transport Profit / MT

from:

### Decision scores

Examples:

- Investment Score
- Storage Location Score
- Transport Opportunity Score

This is important because a single economic metric can be misleading.

For example:

```text
High Price Gain
        ≠
Good Storage Opportunity
```

A good storage opportunity also needs to consider storage timing, production, market reliability and price stability.

Similarly:

```text
High Selling Price
        ≠
Good Interstate Route
```

because transportation and transit spoilage can eliminate the apparent margin.

---

# 7. Model Interpretation

ColdIQ should therefore be interpreted as a **comparative decision-support model**.

A high score means:

> The opportunity satisfies more of the factors that the model considers favourable.

It does **not** mean:

> The investment is guaranteed to make a particular amount of money.

The financial scenario and the decision scores should be read together:

```text
Decision Score
      +
Underlying Metrics
      +
Scenario Assumptions
      ↓
Better-Informed Decision
```

This distinction is especially important when using historical market data to evaluate future investment opportunities.
