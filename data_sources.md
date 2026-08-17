# 📚 ColdIQ — Data Sources

This document explains where the data used in ColdIQ came from, what each dataset is used for, and how it fits into the overall project.

The aim is to keep the data pipeline understandable and transparent rather than treating the datasets as a black box.

---

## 1. Commodity Price Data

### Source

**data.gov.in — Variety-wise Daily Market Prices Data of Commodities**

### What it provides

The daily price dataset contains market-level commodity observations such as:

- Commodity
- Variety
- State
- District
- Market
- Arrival date
- Minimum price
- Maximum price
- Modal price

### How ColdIQ uses it

This is one of the main datasets in the project.

It is used to calculate:

- Monthly prices
- Median prices
- Seasonal price movement
- Price gains
- Price volatility
- Price stability
- Market observations
- Active trading months
- Market reliability
- Buying and selling opportunities

The daily data is converted into monthly and aggregated metrics before being used by the decision models.

---

## 2. Commodity Characteristics

### Source

**NCCD (National Centre for Cold-chain Development)**

The project uses NCCD guidelines and post-harvest studies as references for commodity storage characteristics.

### Information used

The commodity table contains information such as:

- Commodity
- Commodity category
- Minimum shelf life
- Maximum shelf life
- Recommended storage duration
- Minimum storage temperature
- Maximum storage temperature
- Minimum humidity
- Maximum humidity
- Refrigerated truck requirement
- Average shelf life
- Average spoilage rate

### How ColdIQ uses it

This information is particularly important for the storage and investment models.

For example, ColdIQ checks whether the proposed holding period is compatible with the commodity's storage window.

This prevents a commodity from receiving a strong recommendation simply because its historical selling price was attractive when the required holding period is not realistically compatible with its shelf life.

---

## 3. Weather Data

### Source

**NASA POWER API**

### Information used

Weather data includes variables such as:

- Temperature
- Minimum temperature
- Maximum temperature
- Relative humidity
- Rainfall
- Solar radiation
- Latitude
- Longitude

### How ColdIQ uses it

Weather provides environmental context for the districts being analysed.

It is also useful when considering storage conditions, local climate and energy-related factors.

---

## 4. Location Data

### Sources / Method

Location information is assembled from the commodity and market datasets.

Latitude and longitude information was obtained using a public latitude/longitude dataset.

### Information used

The location layer includes:

- State
- District
- District ID
- Latitude
- Longitude

### How ColdIQ uses it

Location data connects the different datasets at the district and state level.

It is also used for transportation calculations between source and destination locations.

---

## 5. Market Metrics

### Source / Method

Market metrics are **derived from the daily commodity price data and location information** rather than being treated as a separate raw dataset.

### Metrics created

ColdIQ derives measures such as:

- Market reliability
- Price coefficient of variation
- Active months
- Number of observations
- Price stability

### How ColdIQ uses it

These metrics help distinguish between markets with strong and consistent historical activity and markets where the available data is less reliable.

Market reliability is used by the district, intrastate and interstate decision models.

---

## 6. Crop Production Data

### Source

**data.gov.in — District-wise, Season-wise Crop Production Statistics**

The dataset contains crop production information over multiple years.

### Information used

ColdIQ derives metrics such as:

- Production
- Average production
- Production share
- Production rank
- Production decile
- Productivity
- Production level
- Production trend

### Production levels

Production is grouped into categories such as:

- Very High
- High
- Medium
- Low
- Negligible

### How ColdIQ uses it

Production is important because a storage location should not be judged only by market prices.

A district with strong market activity but very little local production can represent a very different business opportunity from a major production centre.

Production information is therefore incorporated into the storage and investment models.

---

## 7. Electricity Data

### Source

**data.gov.in — State-wise Average Rate of Electricity for Domestic and Industrial Consumers**

Additional electricity tariff information was also referenced from electricity tariff documentation where required.

### How ColdIQ uses it

Electricity is used as an operating-cost input for cold-storage scenarios.

The Streamlit scenario model allows electricity assumptions to be varied so that users can see how changes in electrical operating conditions affect the estimated financial outcome.

The electricity component is therefore treated as a modeled cost rather than as a guaranteed future electricity bill.

---

## 8. Diesel and Backup Energy

### Source

**NDTV — Current Diesel Prices**

Diesel prices were collected using automated web scraping.

### Additional assumption

A `generator_fuel_consumption` value is used as an engineered constant for estimating generator-related fuel consumption.

### How ColdIQ uses it

Diesel and generator consumption are intended to represent an additional energy-cost consideration where backup power is required.

The value is therefore an assumption within the model rather than a direct measurement of a specific cold-storage facility.

---

## 9. Government Scheme / Subsidy Data

### Source

Government scheme information was collected and organized separately in an Excel-based government schema.

### Information used

The government layer is used to represent applicable subsidy-related information and assumptions.

### How ColdIQ uses it

Subsidy is incorporated into the modeled infrastructure investment calculation.

The purpose is to compare scenarios with and without the assumed subsidy rather than to claim that a particular project is automatically eligible for a specific subsidy.

Actual eligibility would need to be verified against the applicable government scheme and project conditions.

---

## 10. Cold-Storage Infrastructure Data

### Source

Government cold-storage infrastructure cost norms and project-cost information were organized in an Excel-based infrastructure dataset.

### Information used

The infrastructure layer contains cost assumptions related to areas such as:

- Storage technology
- Construction type
- Cost per MT
- Capacity range
- Miscellaneous costs
- Machinery costs
- Insulation costs
- Logistics and gas-related costs

### How ColdIQ uses it

Infrastructure information is used to estimate the capital requirement of different storage scenarios.

The values are treated as model inputs and benchmarks rather than as exact quotations for constructing a facility.

---

## 11. Transportation Data

### Distance calculation

Transportation distance is estimated using the **Haversine method** and an adjustment factor to approximate actual road distance.

The project uses:

```text
Approximate Road Distance
=
Straight-Line Distance × 1.3
```

### Transit time

Estimated transit time is obtained using **OSRM / OpenStreetMap-related routing information**.

### Freight assumptions

The project uses the following freight-rate assumptions:

| Truck Type             | Freight Rate |
| ---------------------- | -----------: |
| Non-refrigerated truck | ₹3.5 / MT-km |
| Refrigerated truck     | ₹5.5 / MT-km |

The requirement for a refrigerated truck is derived from the commodity characteristics.

### How ColdIQ uses it

Transportation data is used by the interstate trade model to estimate:

- Distance
- Transit time
- Transport cost
- Transit spoilage
- Saleable revenue
- Net transport profit

---

## 12. Chamber Configuration

### Source / Method

Chamber configuration is **user-generated**.

### How ColdIQ uses it

It provides a configurable assumption for how storage capacity can be organized during scenario analysis.

It is not treated as an externally measured dataset.

---

## 13. Chamber Allocation

### Source / Method

Chamber allocation is **derived during simulation**.

### How ColdIQ uses it

The allocation is generated as part of the scenario logic rather than being directly sourced from an external dataset.

---

## 14. Labour

Labour was intentionally **not maintained as a separate database table**.

Instead, labour-related assumptions are kept as user inputs where required.

This keeps the model flexible because labour costs can vary significantly by location, facility and operating arrangement.

---

# 🔗 How the Data Sources Connect

The main relationships between the datasets can be summarized as:

```text
Commodity Characteristics
          │
          ├──────────────┐
          ▼              ▼
     Daily Prices     Production
          │              │
          ▼              ▼
     Market Metrics   Production Metrics
          │              │
          └───────┬──────┘
                  ▼
              Location
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
    Electricity  Weather  Transport
        │         │         │
        └─────────┼─────────┘
                  ▼
        Infrastructure + Subsidy
                  │
                  ▼
          ColdIQ Decision Models
```

---

# 🧹 Data Preparation Approach

The raw sources are not used directly in the final recommendations.

The general process is:

```text
Raw Data
   ↓
Cleaning
   ↓
Standardization
   ↓
Location / Commodity Mapping
   ↓
Aggregation
   ↓
Derived Metrics
   ↓
Analytical SQL Views
   ↓
Decision Models
```

Examples of derived metrics include:

- Median price
- Seasonal price gain
- Production share
- Production decile
- Price coefficient of variation
- Market reliability
- Transport cost
- Transit spoilage
- Net transport profit
- Investment score
- Storage location score
- Transport opportunity score

---

# ⚠️ Important Data Limitations

The data sources come from different systems and therefore have different levels of coverage, frequency and assumptions.

Some important limitations are:

- Historical market prices do not guarantee future prices.
- Production data may not have identical coverage across all commodities and locations.
- Electricity values represent modeled assumptions and tariff references rather than a facility-specific electricity bill.
- Transportation costs are based on assumed freight rates.
- Road distance is estimated rather than obtained from actual truck GPS data.
- Generator fuel consumption is an engineered assumption.
- Infrastructure costs are benchmark values and can vary by project design and location.
- Subsidy assumptions do not guarantee eligibility.
- Spoilage varies with handling, storage conditions, commodity quality and operating practices.

Because of these differences, ColdIQ is intended primarily as a **comparative decision-support system** rather than a replacement for detailed engineering, financial or feasibility studies.

---

# 📌 Summary

ColdIQ combines multiple real-world data sources instead of relying on a single dataset.

The most important inputs are:

**Commodity Prices + Production + Market Behaviour + Storage Characteristics + Weather + Electricity + Infrastructure + Transportation + Government Support**

These inputs are transformed through SQL into the analytical models used by the Power BI dashboard and Streamlit application.
