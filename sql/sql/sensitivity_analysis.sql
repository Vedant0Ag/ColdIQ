CREATE OR REPLACE VIEW merchant_sensitivity_analysis AS

WITH scenarios AS (

    SELECT
        -15 AS Change_Percent
    UNION ALL SELECT -10
    UNION ALL SELECT -5
    UNION ALL SELECT 0
    UNION ALL SELECT 5
    UNION ALL SELECT 10
    UNION ALL SELECT 15
),

variables AS (

    SELECT 'Selling Price' AS Variable
    UNION ALL SELECT 'Buying Price'
    UNION ALL SELECT 'Spoilage'
    UNION ALL SELECT 'Electricity Cost'
    UNION ALL SELECT 'Utilization'
    UNION ALL SELECT 'Interest Rate'
    UNION ALL SELECT 'Holding Period'
),

base AS (

    SELECT
        m.*,

        f.Storage_Spoilage_Percent,

        CASE
            WHEN m.Buy_Price_Per_MT > 0
            THEN
                m.Inventory_Procurement_Cost
                / m.Buy_Price_Per_MT
            ELSE 0
        END AS Base_Procurement_Quantity

    FROM merchant_financial_summary m

    JOIN commodity_financial_model f
        ON m.State = f.State
        AND m.District = f.District
        AND m.Commodity = f.Commodity
),
scenario_grid AS (

    SELECT
        b.*,
        v.Variable,
        s.Change_Percent

    FROM base b
    CROSS JOIN variables v
    CROSS JOIN scenarios s
),

scenario_calculation AS (

    SELECT
        g.*,

        /* =====================================================
           1. ADJUSTED SELLING PRICE
           ===================================================== */

        CASE
            WHEN g.Variable = 'Selling Price'
            THEN
                g.Sell_Price_Per_MT
                * (1 + g.Change_Percent / 100.0)

            ELSE g.Sell_Price_Per_MT
        END AS Adjusted_Sell_Price,

        /* =====================================================
           2. ADJUSTED BUYING PRICE
           ===================================================== */

        CASE
            WHEN g.Variable = 'Buying Price'
            THEN
                g.Buy_Price_Per_MT
                * (1 + g.Change_Percent / 100.0)

            ELSE g.Buy_Price_Per_MT
        END AS Adjusted_Buy_Price,

        /* =====================================================
           3. ADJUSTED HOLDING PERIOD
           ===================================================== */

        CASE
            WHEN g.Variable = 'Holding Period'
            THEN
                GREATEST(
                    g.Holding_Months
                    * (1 + g.Change_Percent / 100.0),
                    0.1
                )

            ELSE g.Holding_Months
        END AS Adjusted_Holding_Months

    FROM scenario_grid g
),

scenario_economics AS (

    SELECT
        s.*,

        /* =====================================================
           ADJUSTED UTILIZATION
           
           Base procurement quantity is scaled by utilization.
           ===================================================== */

        CASE
            WHEN s.Variable = 'Utilization'
            THEN
                s.Base_Procurement_Quantity
                * (1 + s.Change_Percent / 100.0)

            ELSE s.Base_Procurement_Quantity
        END AS Adjusted_Procurement_Quantity,

        /* =====================================================
           ADJUSTED SPOILAGE
           ===================================================== */

        CASE
            WHEN s.Variable = 'Spoilage'
            THEN
                LEAST(
                    0.99,
                    GREATEST(
                        0,
                        (s.Storage_Spoilage_Percent / 100.0)
                        * (1 + s.Change_Percent / 100.0)
                    )
                )

            WHEN s.Variable = 'Holding Period'
            THEN
                LEAST(
                    0.99,
                    GREATEST(
                        0,
                        (s.Storage_Spoilage_Percent / 100.0)
                        *
                        (
                            s.Holding_Months
                            * (1 + s.Change_Percent / 100.0)
                        )
                        /
                        NULLIF(s.Holding_Months,0)
                    )
                )

            ELSE
                s.Storage_Spoilage_Percent / 100.0
        END AS Adjusted_Spoilage_Rate

    FROM scenario_calculation s
),

scenario_revenue AS (

    SELECT
        e.*,

        /* =====================================================
           ADJUSTED SALEABLE QUANTITY
           ===================================================== */

        e.Adjusted_Procurement_Quantity
        *
        (
            1 - e.Adjusted_Spoilage_Rate
        )
        AS Adjusted_Saleable_Quantity,

        /* =====================================================
           ADJUSTED REVENUE
           ===================================================== */

        e.Adjusted_Procurement_Quantity
        *
        (
            1 - e.Adjusted_Spoilage_Rate
        )
        *
        e.Adjusted_Sell_Price
        AS Adjusted_Revenue,

        /* =====================================================
           ADJUSTED PROCUREMENT COST
           ===================================================== */

        e.Adjusted_Procurement_Quantity
        *
        e.Adjusted_Buy_Price
        AS Adjusted_Procurement_Cost

    FROM scenario_economics e
),

scenario_costs AS (

    SELECT
        r.*,

        /* =====================================================
           ELECTRICITY
           ===================================================== */

        CASE

            WHEN r.Variable = 'Electricity Cost'
            THEN
                r.Total_Electricity_Cost
                * (1 + r.Change_Percent / 100.0)

            WHEN r.Variable = 'Holding Period'
            THEN
                r.Total_Electricity_Cost
                *
                (
                    r.Adjusted_Holding_Months
                    /
                    NULLIF(r.Holding_Months,0)
                )

            WHEN r.Variable = 'Utilization'
            THEN
                r.Total_Electricity_Cost

            ELSE
                r.Total_Electricity_Cost

        END AS Adjusted_Electricity_Cost,

        /* =====================================================
           INFRASTRUCTURE / TERM LOAN INTEREST
           ===================================================== */

        CASE

            WHEN r.Variable = 'Interest Rate'
            THEN
                r.Holding_Period_Interest
                * (1 + r.Change_Percent / 100.0)

            WHEN r.Variable = 'Holding Period'
            THEN
                r.Holding_Period_Interest
                *
                (
                    r.Adjusted_Holding_Months
                    /
                    NULLIF(r.Holding_Months,0)
                )

            ELSE
                r.Holding_Period_Interest

        END AS Adjusted_Holding_Interest,

        /* =====================================================
           WORKING CAPITAL INTEREST
           ===================================================== */

        CASE

            WHEN r.Variable = 'Interest Rate'
            THEN
                r.Working_Capital_Interest
                * (1 + r.Change_Percent / 100.0)

            WHEN r.Variable = 'Holding Period'
            THEN
                r.Working_Capital_Interest
                *
                (
                    r.Adjusted_Holding_Months
                    /
                    NULLIF(r.Holding_Months,0)
                )

            WHEN r.Variable = 'Utilization'
            THEN
                r.Working_Capital_Interest
                *
                (
                    r.Adjusted_Procurement_Quantity
                    /
                    NULLIF(r.Base_Procurement_Quantity,0)
                )

            ELSE
                r.Working_Capital_Interest

        END AS Adjusted_WC_Interest

    FROM scenario_revenue r
),

scenario_profit AS (

    SELECT
        c.*,

        /* =====================================================
           NET TRADING PROFIT
           ===================================================== */

        (
            c.Adjusted_Revenue
            -
            c.Adjusted_Procurement_Cost

            -
            COALESCE(c.Adjusted_Electricity_Cost,0)

            -
            COALESCE(c.Adjusted_Holding_Interest,0)

            -
            COALESCE(c.Adjusted_WC_Interest,0)

            -
            COALESCE(c.Total_IDC,0)
        )
        AS Scenario_Net_Trading_Profit

    FROM scenario_costs c
),

scenario_returns AS (

    SELECT
        p.*,

        /* =====================================================
           ROI
           ===================================================== */

        CASE
            WHEN p.Total_Promoter_Cash_Deployed > 0
            THEN
                (
                    p.Scenario_Net_Trading_Profit
                    /
                    p.Total_Promoter_Cash_Deployed
                ) * 100

            ELSE NULL
        END AS Scenario_ROI_Percent,

        /* =====================================================
           PAYBACK
           ===================================================== */

        CASE
            WHEN p.Scenario_Net_Trading_Profit > 0
            THEN
                p.Total_Promoter_Cash_Deployed
                /
                p.Scenario_Net_Trading_Profit

            ELSE NULL
        END AS Scenario_Payback_Years

    FROM scenario_profit p
)

SELECT

    State,
    District,
    Commodity,

    Variable,
    Change_Percent,

    ROUND(
        Adjusted_Sell_Price,
        2
    ) AS Adjusted_Sell_Price,

    ROUND(
        Adjusted_Buy_Price,
        2
    ) AS Adjusted_Buy_Price,

    ROUND(
        Adjusted_Holding_Months,
        2
    ) AS Adjusted_Holding_Months,

    ROUND(
        Adjusted_Procurement_Quantity,
        2
    ) AS Adjusted_Procurement_Quantity,

    ROUND(
        Adjusted_Saleable_Quantity,
        2
    ) AS Adjusted_Saleable_Quantity,

    ROUND(
        Adjusted_Revenue,
        2
    ) AS Adjusted_Revenue,

    ROUND(
        Adjusted_Procurement_Cost,
        2
    ) AS Adjusted_Procurement_Cost,

    ROUND(
        Adjusted_Electricity_Cost,
        2
    ) AS Adjusted_Electricity_Cost,

    ROUND(
        Adjusted_Holding_Interest,
        2
    ) AS Adjusted_Holding_Interest,

    ROUND(
        Adjusted_WC_Interest,
        2
    ) AS Adjusted_WC_Interest,

    ROUND(
        Scenario_Net_Trading_Profit,
        2
    ) AS Scenario_Net_Trading_Profit,

    ROUND(
        Scenario_ROI_Percent,
        2
    ) AS Scenario_ROI_Percent,

    ROUND(
        Scenario_Payback_Years,
        2
    ) AS Scenario_Payback_Years

FROM scenario_returns;

SELECT
    Variable,
    Change_Percent,
    Scenario_Net_Trading_Profit,
    Scenario_ROI_Percent,
    Scenario_Payback_Years
FROM merchant_sensitivity_analysis
WHERE State = 'Andhra Pradesh'
  AND District = 'Annamayya'
  AND Commodity = 'Tomato'
ORDER BY Variable, Change_Percent;

CREATE OR REPLACE VIEW merchant_sensitivity_summary AS

SELECT
    State,
    District,
    Commodity,
    Variable,

    MAX(
        CASE
            WHEN Change_Percent = -15
            THEN Scenario_Net_Trading_Profit
        END
    ) AS Profit_Minus_15,

    MAX(
        CASE
            WHEN Change_Percent = 0
            THEN Scenario_Net_Trading_Profit
        END
    ) AS Profit_Base,

    MAX(
        CASE
            WHEN Change_Percent = 15
            THEN Scenario_Net_Trading_Profit
        END
    ) AS Profit_Plus_15,

    MAX(
        CASE
            WHEN Change_Percent = -15
            THEN Scenario_ROI_Percent
        END
    ) AS ROI_Minus_15,

    MAX(
        CASE
            WHEN Change_Percent = 0
            THEN Scenario_ROI_Percent
        END
    ) AS ROI_Base,

    MAX(
        CASE
            WHEN Change_Percent = 15
            THEN Scenario_ROI_Percent
        END
    ) AS ROI_Plus_15,

    MAX(
        CASE
            WHEN Change_Percent = -15
            THEN Scenario_Payback_Years
        END
    ) AS Payback_Minus_15,

    MAX(
        CASE
            WHEN Change_Percent = 0
            THEN Scenario_Payback_Years
        END
    ) AS Payback_Base,

    MAX(
        CASE
            WHEN Change_Percent = 15
            THEN Scenario_Payback_Years
        END
    ) AS Payback_Plus_15

FROM merchant_sensitivity_analysis

GROUP BY
    State,
    District,
    Commodity,
    Variable;
    
SELECT *
FROM merchant_sensitivity_summary
WHERE State = 'Andhra Pradesh'
  AND District = 'Annamayya'
  AND Commodity = 'Tomato';
  
  
