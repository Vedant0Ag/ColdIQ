
# ❄️ ColdIQ

### Cold Storage & Commodity Intelligence Platform

ColdIQ is a data-driven decision-support platform built to answer a practical question:

> **If I want to invest in agricultural cold storage, what should I store, where should I store it, and when does moving a commodity to another market make sense?**

Instead of looking at price alone, ColdIQ combines commodity prices, production, market behaviour, spoilage, storage requirements, infrastructure costs, electricity, government subsidies and transportation to compare different opportunities.

The project combines **MySQL, SQL analytics, Power BI and Streamlit** into one end-to-end platform.

---

## 📌 What Problem Does ColdIQ Solve?

Cold-storage decisions are not as simple as finding a commodity with a high selling price.

A commodity may have a large price difference between two periods, but that opportunity may not be attractive if:

- it spoils quickly,
- the storage period is too long,
- production in the region is too low,
- the market is unreliable,
- prices are highly unstable,
- electricity costs are high,
- transportation costs reduce the margin, or
- the required storage infrastructure is expensive.

ColdIQ tries to bring these factors together so that different commodities, districts and trade routes can be compared using a common analytical framework.

---

# 🎯 Main Objectives

ColdIQ focuses on three major decisions.

### 1. District-Level Investment

> **For a selected district, which commodities are the most attractive for storage investment?**

The model considers price opportunity, storage feasibility, spoilage, production, market reliability, price stability, infrastructure, electricity and subsidy.

---

### 2. Intrastate Storage

> **For a selected commodity and state, which districts are better locations for storage?**

Districts are compared using:

- seasonal price opportunity,
- market reliability,
- price stability, and
- production level.

The result is a ranked list of potential storage locations.

---

### 3. Interstate Trade

> **Which source-to-destination state routes offer attractive trading opportunities?**

The model considers:

- buying price,
- selling price,
- price margin,
- distance,
- transit time,
- transportation cost,
- transit spoilage,
- production availability,
- market reliability, and
- price stability.

---

# 🏗️ How ColdIQ Works

The overall workflow is:

```text
Real-World Data
       │
       ▼
Data Cleaning & Preparation
       │
       ▼
      MySQL
       │
       ├───────────────┐
       ▼               ▼
Analytical Views   Supporting Metrics
       │               │
       └───────┬───────┘
               ▼
        Decision Models
               │
       ┌───────┼────────┐
       ▼       ▼        ▼
   District  Intrastate Interstate
   Investment Storage    Trade
       │       │        │
       └───────┼────────┘
               ▼
       ┌───────┴────────┐
       ▼                ▼
    Power BI         Streamlit
   Dashboard       Decision App

The idea is to keep the heavy data processing and scoring in SQL and use Power BI and Streamlit to make the results easier to explore and understand.

🗄️ Data Used

ColdIQ combines several types of data.

Data Area	Purpose
Commodity prices	Understand price levels and seasonal price movement
Commodity characteristics	Shelf life, spoilage and storage requirements
Production	Understand production strength by commodity and state/district
Market metrics	Measure reliability, observations and price volatility
Weather	Provide environmental context
Electricity	Estimate electricity-related storage costs
Infrastructure	Estimate cold-storage infrastructure costs
Government schemes	Account for applicable subsidy assumptions
Transportation	Estimate distance, transit time and transport costs

The project currently works with 18 commodities. The initial analysis also looked at market coverage, seasonality and storage characteristics across these commodities.

🌐 Data Sources

The project uses a combination of government data, public datasets, APIs and derived calculations.

Commodity Prices

Daily market price data was sourced from data.gov.in, covering variety-wise commodity market prices.

Commodity Characteristics

Commodity storage information was based on NCCD guidelines and post-harvest studies, including storage duration and spoilage-related information.

Weather

Weather information was obtained using the NASA POWER API.

Production

District-wise and season-wise crop production data was obtained from data.gov.in.

Electricity

State-wise industrial electricity pricing data was obtained from data.gov.in.

Transportation

Transportation distance was calculated using geographic information and the Haversine approach, with an adjustment for approximate actual road distance. Transit information was based on OpenStreetMap/OSRM-related routing data.

Infrastructure & Government Support

Cold-storage infrastructure cost norms and government subsidy information were incorporated into the investment model.

The project's source notes document these inputs and the transformations used for transportation and other derived variables.

🧮 SQL & Analytical Layer

MySQL is the main analytical engine behind ColdIQ.

Instead of directly putting raw data into Power BI, the project creates intermediate metrics and analytical views.

Some of the major analytical areas include:

Price Analysis

The SQL analysis looks at:

average minimum, maximum and modal prices,
median prices,
seasonal price behaviour,
highest and lowest priced states,
commodity price dominance across states and years.

For example, the initial analysis identified Garlic as the highest-priced commodity and Potato as the cheapest among the commodities considered in that analysis. It also identified seasonal price behaviour and examples of commodities that remained dominant in particular states over multiple years.

Production Analysis

Production analysis looks at:

highest-producing states,
production growth,
declining production,
production trends,
productivity,
production levels,
production share.

The project classifies production into categories such as:

Very High
High
Medium
Low
Negligible

Production trends are also classified into categories such as:

Increasing
Increasing Rapidly
Stable
Decreasing
Decreasing Rapidly

The original analysis found several commodities with increasing production while others such as apples, pomegranate, onion, orange and papaya showed decreasing trends in the analyzed period.

🏆 District Commodity Investment Model

The district investment model is one of the main decision engines in ColdIQ.

For each district and commodity, the model attempts to identify a realistic buy → store → sell cycle.

The model considers:

buying price,
selling price,
holding period,
minimum shelf life,
maximum shelf life,
average shelf life,
spoilage,
electricity,
infrastructure cost,
subsidy,
market reliability,
production,
price stability.

A commodity's storage period is also checked against its feasible storage window.

This is important because a large theoretical price increase is not useful if the commodity cannot realistically survive the required holding period.

The model produces:

Investment Score

A combined score based on the economic and operational factors.

Investment Decision

Possible outputs include:

Strong Investment
Good Investment
Moderate Investment
Weak Investment
High Payback Risk
Storage Window Mismatch
Do Not Invest

The model then ranks the top opportunities within each district.

📍 Intrastate Storage Model

The intrastate model answers:

Where should a particular commodity be stored within a state?

The model compares districts using:

Seasonal Price Opportunity
        +
Market Reliability
        +
Price Stability
        +
Production
        ↓
Storage Location Score

The model also considers market observations and active months while determining whether the underlying data is sufficiently reliable.

The final output classifies locations as:

Strong Storage Location
Good Storage Location
Moderate Storage Location
Weak Storage Location
Avoid

This makes it possible to compare multiple districts for the same commodity instead of simply choosing the district with the highest price.

🚚 Interstate Trade Model

The interstate model evaluates potential commodity movement between states.

The basic idea is:

Source State
     │
     │ Buy Commodity
     ▼
Transportation
     │
     │ Distance + Cost + Transit
     ▼
Destination State
     │
     │ Sell Commodity
     ▼
Net Transport Opportunity

The model considers:

source production level,
destination production level,
buying price,
selling price,
gross price gain,
distance,
transit time,
transport cost,
transit spoilage,
saleable revenue,
net transport profit,
source market reliability,
destination market reliability,
price stability,
source supply.

These factors are combined into a Transport Opportunity Score.

The resulting opportunity is classified as:

Strong Transport Opportunity
Good Transport Opportunity
Moderate Transport Opportunity
Weak Transport Opportunity

The model also provides a Primary Reason to make the recommendation easier to interpret.

📊 Power BI Dashboard

Power BI is used to turn the SQL outputs into an interactive analytical dashboard.

The dashboard currently contains six pages.

Page 1 — Executive Summary

Provides a high-level overview of the ColdIQ platform and major opportunity metrics.

Page 2 — Procurement Intelligence

Focuses on commodity procurement, production behaviour, supply conditions and market context.

Page 3 — Market and Selling Intelligence

Looks at selling opportunities, destination markets, expected profit and market reliability.

Page 4 — Interstate Trade Opportunities

Focuses on profitable interstate routes, transport economics, route-level profit and opportunity scores.

Page 5 — Intrastate Opportunities

Focuses on storage locations within states and compares districts based on storage opportunity.

Page 6 — District Commodity Investment

Focuses on district-level commodity investment recommendations, investment scores, storage timing and scenario-oriented financial metrics.

🌐 Streamlit Application

The Streamlit application turns the SQL models into an interactive decision-support tool.

Instead of only looking at charts, a user can actually select locations and commodities and explore the recommendations.

🏆 District Commodity Advisor

The workflow is:

State
 ↓
District
 ↓
Top 5 Commodities
 ↓
Select Commodity
 ↓
Detailed Analysis
 ↓
Scenario Analysis

The user can view:

investment score,
price gain,
holding period,
storage spoilage,
investment decision,
top 5 commodities.

The scenario section also allows the user to adjust assumptions such as:

facility capacity,
facility utilization,
operating cost rate,
electricity load,
electrical load factor,
subsidy.

The resulting financial figures are modeled scenario estimates, not guaranteed real-world returns.

📍 Intrastate Storage Advisor

The workflow is:

State
 ↓
Commodity
 ↓
Storage Districts

The user can compare storage locations using:

storage score,
production level,
seasonal price gain,
market reliability,
price stability,
opportunity classification.
🚚 Interstate Trade Advisor

The workflow is:

Commodity
 ↓
Source State
 ↓
Destination State
 ↓
Trade Opportunity

The user can explore:

buying price,
selling price,
net transport profit,
opportunity score,
distance,
transit time,
transport cost,
transit spoilage,
market reliability,
primary reason.
🛠️ Technology Stack
Technology	Use
MySQL	Database and analytical processing
SQL	Data transformation, metrics, scoring and ranking
Python	Application and data processing
Pandas	Data handling inside Streamlit
Power BI	Interactive dashboards
Streamlit	Interactive decision-support application
Git/GitHub	Version control and project documentation
📁 Project Structure

A simplified structure of the project is:

ColdIQ/
│
├── README.md
├── requirements.txt
├── .gitignore
│
├── sql/
│   ├── creation.sql
│   ├── price_analysis.sql
│   ├── production_analysis.sql
│   ├── commodity_analysis.sql
│   ├── electricity_analysis.sql
│   ├── transport_analysis.sql
│   ├── district_commodity_opportunity.sql
│   ├── intrastate_storage.sql
│   ├── interstate_transport.sql
│   └── views.sql
│
├── streamlit/
│   └── app.py
│
├── powerbi/
│   └── screenshots/
│
└── docs/
    ├── data_sources.md
    ├── methodology.md
    └── project_architecture.md

The exact folder structure may vary depending on how the project is organized in the final GitHub repository.

⚠️ Important Assumptions & Limitations

ColdIQ is designed as a decision-support and comparison system, not as a guarantee of investment returns.

Some of the financial calculations are based on modeled assumptions such as:

facility capacity,
facility utilization,
electricity load,
electricity pricing,
subsidy percentage,
infrastructure cost,
operating costs,
spoilage,
holding period.

Actual cold-storage operations can differ significantly because of factors such as occupancy, temperature control, maintenance, labour, market fluctuations, handling losses and other operating conditions.

Therefore, the financial outputs should be interpreted as scenario-based estimates useful for comparing commodities, rather than exact predictions of real-world ROI or payback.

Similarly, historical prices and production data do not guarantee future market behaviour.

🚀 Future Improvements

ColdIQ is currently a completed analytics and decision-support project, but there are several directions in which it can be extended.

Machine Learning

A future version can use historical price data to forecast:

future commodity prices,
expected price movement,
potential seasonal price opportunities.

These predictions could then be incorporated into the existing investment scoring model.

AI-Assisted Analysis

An AI layer could allow users to ask questions such as:

"Why is chilli recommended for this district?"

or:

"Compare chilli and mango for this district."

The AI would explain the existing analytical results rather than replacing the underlying scoring model.

Public Deployment

The Streamlit application can also be deployed online so that users can access ColdIQ without running it locally.

📌 Current Project Status
Component	Status
Data collection & preparation	✅ Completed
SQL database	✅ Completed
Price analysis	✅ Completed
Production analysis	✅ Completed
Market analysis	✅ Completed
Transportation analysis	✅ Completed
Electricity analysis	✅ Completed
District investment model	✅ Completed
Intrastate storage model	✅ Completed
Interstate trade model	✅ Completed
Power BI dashboard	✅ Completed
Streamlit application	✅ Completed
Scenario analysis	✅ Completed
Machine Learning	🔄 Planned
AI-assisted analysis	🔄 Planned
Public deployment	🔄 Planned
👨‍💻 Project Goal

The goal of ColdIQ was not simply to create another dashboard.

The project was built to explore how different real-world agricultural factors can be combined into a practical decision-support system.

The final system brings together:

Data → SQL → Analytics → Scoring → Visualization → Interactive Decision Support

⭐ Final Note

ColdIQ is currently an analytical prototype. Its recommendations are intended to help compare opportunities and understand the factors behind them.

Actual investment decisions would require more detailed site-level feasibility studies, current market validation, engineering estimates and financial due diligence.
