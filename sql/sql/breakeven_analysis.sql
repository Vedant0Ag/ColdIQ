CREATE OR REPLACE VIEW merchant_breakeven_analysis AS

WITH base AS (

    SELECT
        f.State,
        f.District,
        f.Commodity,

        f.Facility_Capacity_MT,

        c.Buy_Price_Per_MT,
        c.Sell_Price_Per_MT,
        c.Holding_Months,
        c.Storage_Spoilage_Percent,

        f.Project_CAPEX,
        f.Term_Loan,
        f.Owner_Equity,

        f.Total_IDC,
        f.Post_Subsidy_Loan,
        f.Holding_Period_Interest,

        f.Inventory_Procurement_Cost,
        f.Saleable_Quantity_MT,

        f.Trading_Revenue,
        f.Gross_Trading_Profit,

        f.Working_Capital_Limit,
        f.Working_Capital_Funded,
        f.Promoter_Inventory_Investment,
        f.Working_Capital_Interest,

        f.Total_Electricity_Cost,

        f.Total_Promoter_Cash_Deployed,
        f.Total_Financing_Cost,

        f.Net_Trading_Profit,
        f.ROI_Percent

    FROM merchant_financial_summary f

    JOIN commodity_financial_model c
        ON f.State = c.State
        AND f.District = c.District
        AND f.Commodity = c.Commodity
),

/* =========================================================
   1. BREAK-EVEN SELLING PRICE
   ========================================================= */

selling_price AS (

    SELECT
        b.*,

        (
            b.Inventory_Procurement_Cost
            +
            b.Total_Financing_Cost
            +
            b.Total_Electricity_Cost
        )
        /
        NULLIF(
            b.Saleable_Quantity_MT,
            0
        )
        AS BreakEven_Selling_Price

    FROM base b
),

/* =========================================================
   2. BREAK-EVEN BUYING PRICE
   ========================================================= */

buying_price AS (

    SELECT
        s.*,

        (
            s.Trading_Revenue
            -
            s.Total_IDC
            -
            s.Holding_Period_Interest
            -
            s.Total_Electricity_Cost
            -
            s.Working_Capital_Interest
        )
        /
        NULLIF(
            s.Saleable_Quantity_MT,
            0
        )
        AS BreakEven_Buy_Price

    FROM selling_price s
),

/* =========================================================
   3. BREAK-EVEN UTILIZATION
   ========================================================= */

utilization AS (

    SELECT
        b.*,

        CASE

            WHEN
                (
                    b.Trading_Revenue
                    -
                    b.Inventory_Procurement_Cost
                ) > 0

            THEN

                (
                    b.Total_IDC
                    +
                    b.Holding_Period_Interest
                    +
                    b.Total_Electricity_Cost
                    +
                    b.Working_Capital_Interest
                )
                /
                (
                    b.Trading_Revenue
                    -
                    b.Inventory_Procurement_Cost
                )
                * 100

            ELSE NULL

        END AS BreakEven_Utilization_Percent

    FROM buying_price b
),

/* =========================================================
   4. BREAK-EVEN ROI
   ========================================================= */

roi AS (

    SELECT
        u.*,

        0.00 AS BreakEven_ROI_Percent

    FROM utilization u
)

/* =========================================================
   FINAL OUTPUT
   ========================================================= */

SELECT

    State,
    District,
    Commodity,

    Facility_Capacity_MT,

    Buy_Price_Per_MT,
    Sell_Price_Per_MT,

    Holding_Months,

    Inventory_Procurement_Cost,
    Saleable_Quantity_MT,

    Trading_Revenue,
    Gross_Trading_Profit,

    Total_Electricity_Cost,
    Total_Financing_Cost,

    Net_Trading_Profit,
    ROI_Percent,

    /* Break-even metrics */

    ROUND(
        BreakEven_Selling_Price,
        2
    ) AS BreakEven_Selling_Price,

    ROUND(
        BreakEven_Buy_Price,
        2
    ) AS BreakEven_Buy_Price,

    ROUND(
        BreakEven_Utilization_Percent,
        2
    ) AS BreakEven_Utilization_Percent,

    BreakEven_ROI_Percent,

    /* Safety margins */

    ROUND(
        Sell_Price_Per_MT
        -
        BreakEven_Selling_Price,
        2
    ) AS Selling_Price_Safety_Margin,

    ROUND(
        BreakEven_Buy_Price
        -
        Buy_Price_Per_MT,
        2
    ) AS Buying_Price_Safety_Margin,

    ROUND(
        100
        -
        BreakEven_Utilization_Percent,
        2
    ) AS Utilization_Safety_Margin,

    /* Decision */

    CASE

        WHEN Net_Trading_Profit <= 0
            THEN 'Below Break-Even'

        WHEN BreakEven_Utilization_Percent > 100
            THEN 'Not Feasible'

        WHEN
            (
                Sell_Price_Per_MT
                -
                BreakEven_Selling_Price
            )
            /
            NULLIF(Sell_Price_Per_MT, 0)
            < 0.10

            THEN 'Low Selling Price Safety'

        WHEN
            (
                BreakEven_Buy_Price
                -
                Buy_Price_Per_MT
            )
            /
            NULLIF(Buy_Price_Per_MT, 0)
            < 0.10

            THEN 'Low Procurement Safety'

        WHEN BreakEven_Utilization_Percent > 90
            THEN 'High Utilization Risk'

        ELSE 'Above Break-Even'

    END AS BreakEven_Decision

FROM roi;

SELECT *
FROM merchant_breakeven_analysis
LIMIT 10;

-- ---------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW merchant_risk_opportunity_score AS

WITH base AS (

    SELECT
        b.State,
        b.District,
        b.Commodity,

        b.Facility_Capacity_MT,

        b.Buy_Price_Per_MT,
        b.Sell_Price_Per_MT,

        b.Net_Trading_Profit,
        b.ROI_Percent,
        b.Payback_Years,

        b.Total_Electricity_Cost,
        b.Total_Financing_Cost,

        b.Working_Capital_Limit,
        b.Promoter_Inventory_Investment,
        b.Inventory_Procurement_Cost,
        b.Gross_Trading_Profit,
        /* Break-even metrics */
        e.BreakEven_Selling_Price,
        e.BreakEven_Buy_Price,
        e.BreakEven_Utilization_Percent,

        e.Selling_Price_Safety_Margin,
        e.Buying_Price_Safety_Margin,
        e.Utilization_Safety_Margin

    FROM merchant_financial_summary b

    JOIN merchant_breakeven_analysis e
        ON b.State = e.State
        AND b.District = e.District
        AND b.Commodity = e.Commodity
),

/* =========================================================
   1. PROFITABILITY SCORE
   ========================================================= */

profitability AS (

    SELECT
        *,
        CASE
            WHEN ROI_Percent >= 100 THEN 100
            WHEN ROI_Percent >= 75 THEN 90
            WHEN ROI_Percent >= 50 THEN 80
            WHEN ROI_Percent >= 30 THEN 70
            WHEN ROI_Percent >= 20 THEN 60
            WHEN ROI_Percent >= 10 THEN 45
            WHEN ROI_Percent > 0 THEN 30
            ELSE 0
        END AS Profitability_Score

    FROM base
),

/* =========================================================
   2. PAYBACK SCORE
   ========================================================= */

payback AS (

    SELECT
        *,
        CASE
            WHEN Payback_Years <= 1 THEN 100
            WHEN Payback_Years <= 2 THEN 90
            WHEN Payback_Years <= 3 THEN 80
            WHEN Payback_Years <= 5 THEN 65
            WHEN Payback_Years <= 7 THEN 50
            WHEN Payback_Years <= 10 THEN 30
            ELSE 10
        END AS Payback_Score

    FROM profitability
),

/* =========================================================
   3. SELLING PRICE SAFETY SCORE
   ========================================================= */

selling_price_safety AS (

    SELECT
        *,
        
        CASE
            WHEN Sell_Price_Per_MT > 0
            THEN
                (
                    Selling_Price_Safety_Margin
                    / Sell_Price_Per_MT
                ) * 100
            ELSE 0
        END AS Selling_Price_Safety_Percent

    FROM payback
),

selling_score AS (

    SELECT
        *,
        
        CASE
            WHEN Selling_Price_Safety_Percent >= 50 THEN 100
            WHEN Selling_Price_Safety_Percent >= 30 THEN 90
            WHEN Selling_Price_Safety_Percent >= 20 THEN 80
            WHEN Selling_Price_Safety_Percent >= 10 THEN 65
            WHEN Selling_Price_Safety_Percent >= 5 THEN 45
            WHEN Selling_Price_Safety_Percent > 0 THEN 25
            ELSE 0
        END AS Selling_Price_Safety_Score

    FROM selling_price_safety
),

/* =========================================================
   4. BUYING PRICE SAFETY SCORE
   ========================================================= */

buying_price_safety AS (

    SELECT
        *,
        
        CASE
            WHEN Buy_Price_Per_MT > 0
            THEN
                (
                    Buying_Price_Safety_Margin
                    / Buy_Price_Per_MT
                ) * 100
            ELSE 0
        END AS Buying_Price_Safety_Percent

    FROM selling_score
),

buying_score AS (

    SELECT
        *,
        
        CASE
            WHEN Buying_Price_Safety_Percent >= 50 THEN 100
            WHEN Buying_Price_Safety_Percent >= 30 THEN 90
            WHEN Buying_Price_Safety_Percent >= 20 THEN 80
            WHEN Buying_Price_Safety_Percent >= 10 THEN 65
            WHEN Buying_Price_Safety_Percent >= 5 THEN 45
            WHEN Buying_Price_Safety_Percent > 0 THEN 25
            ELSE 0
        END AS Buying_Price_Safety_Score

    FROM buying_price_safety
),

/* =========================================================
   5. UTILIZATION SAFETY SCORE
   ========================================================= */

utilization_score AS (

    SELECT
        *,
        
        CASE
            WHEN Utilization_Safety_Margin >= 75 THEN 100
            WHEN Utilization_Safety_Margin >= 50 THEN 90
            WHEN Utilization_Safety_Margin >= 30 THEN 80
            WHEN Utilization_Safety_Margin >= 20 THEN 65
            WHEN Utilization_Safety_Margin >= 10 THEN 45
            WHEN Utilization_Safety_Margin > 0 THEN 25
            ELSE 0
        END AS Utilization_Safety_Score

    FROM buying_score
),

/* =========================================================
   6. WORKING CAPITAL RISK SCORE
   ========================================================= */

working_capital_score AS (

    SELECT
        *,
        
        CASE
            WHEN Promoter_Inventory_Investment <= 0 THEN 100

            WHEN
                Promoter_Inventory_Investment
                / NULLIF(
                    Inventory_Procurement_Cost,
                    0
                ) <= 0.20
                THEN 90

            WHEN
                Promoter_Inventory_Investment
                / NULLIF(
                    Inventory_Procurement_Cost,
                    0
                ) <= 0.40
                THEN 75

            WHEN
                Promoter_Inventory_Investment
                / NULLIF(
                    Inventory_Procurement_Cost,
                    0
                ) <= 0.60
                THEN 55

            WHEN
                Promoter_Inventory_Investment
                / NULLIF(
                    Inventory_Procurement_Cost,
                    0
                ) <= 0.80
                THEN 35

            ELSE 15
        END AS Working_Capital_Score

    FROM utilization_score
),

/* =========================================================
   7. FINANCING RISK SCORE
   ========================================================= */

financing_score AS (

    SELECT
        *,
        
        CASE
            WHEN Total_Financing_Cost
                 / NULLIF(
                     Gross_Trading_Profit,
                     0
                 ) <= 0.10
                THEN 100

            WHEN Total_Financing_Cost
                 / NULLIF(
                     Gross_Trading_Profit,
                     0
                 ) <= 0.20
                THEN 90

            WHEN Total_Financing_Cost
                 / NULLIF(
                     Gross_Trading_Profit,
                     0
                 ) <= 0.30
                THEN 75

            WHEN Total_Financing_Cost
                 / NULLIF(
                     Gross_Trading_Profit,
                     0
                 ) <= 0.40
                THEN 60

            WHEN Total_Financing_Cost
                 / NULLIF(
                     Gross_Trading_Profit,
                     0
                 ) <= 0.50
                THEN 40

            ELSE 20
        END AS Financing_Score

    FROM working_capital_score
),

/* =========================================================
   8. FINAL RISK-ADJUSTED SCORE
   ========================================================= */

final_score AS (
    SELECT
        *,
        ROUND(
            Profitability_Score * 0.25
            +
            Payback_Score * 0.15
            +
            Selling_Price_Safety_Score * 0.15
            +
            Buying_Price_Safety_Score * 0.10
            +
            Utilization_Safety_Score * 0.10
            +
            Working_Capital_Score * 0.15
            +
            Financing_Score * 0.10
        , 2) AS Risk_Adjusted_Investment_Score

    FROM financing_score
)

/* =========================================================
   9. FINAL OUTPUT
   ========================================================= */

SELECT

    State,
    District,
    Commodity,

    Facility_Capacity_MT,

    Buy_Price_Per_MT,
    Sell_Price_Per_MT,

    Net_Trading_Profit,
    ROI_Percent,
    Payback_Years,

    /* Break-even */
    BreakEven_Selling_Price,
    BreakEven_Buy_Price,
    BreakEven_Utilization_Percent,

    /* Safety */
    Selling_Price_Safety_Margin,
    Buying_Price_Safety_Margin,
    Utilization_Safety_Margin,

    ROUND(
        Selling_Price_Safety_Percent,
        2
    ) AS Selling_Price_Safety_Percent,

    ROUND(
        Buying_Price_Safety_Percent,
        2
    ) AS Buying_Price_Safety_Percent,

    /* Component scores */
    Profitability_Score,
    Payback_Score,
    Selling_Price_Safety_Score,
    Buying_Price_Safety_Score,
    Utilization_Safety_Score,
    Working_Capital_Score,
    Financing_Score,

    /* Final score */
    Risk_Adjusted_Investment_Score,

    CASE

        WHEN Risk_Adjusted_Investment_Score >= 85
            THEN 'Very Strong Opportunity'

        WHEN Risk_Adjusted_Investment_Score >= 75
            THEN 'Strong Opportunity'

        WHEN Risk_Adjusted_Investment_Score >= 65
            THEN 'Good Opportunity'

        WHEN Risk_Adjusted_Investment_Score >= 50
            THEN 'Moderate Opportunity'

        WHEN Risk_Adjusted_Investment_Score >= 35
            THEN 'High Risk Opportunity'

        ELSE 'Weak Opportunity'

    END AS Investment_Decision

FROM final_score;

SELECT *
FROM merchant_risk_opportunity_score
LIMIT 10;