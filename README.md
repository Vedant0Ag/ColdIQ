
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
