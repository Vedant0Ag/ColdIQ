CREATE OR REPLACE VIEW merchant_financial_summary AS

WITH financial_base AS (

    SELECT
        State,
        District,
        Commodity,

        Facility_Capacity_MT,
	    Electricity_Cost_Per_MT,
        Buy_Price_Per_MT,
        Sell_Price_Per_MT,
        Holding_Months,
        Storage_Spoilage_Percent,

        Infrastructure_Cost_Per_MT,
        Price_KWh,

        Project_CAPEX,
        Term_Loan,
        Owner_Equity,

        Inventory_Procurement_Cost,
        Saleable_Quantity_MT,
        Trading_Revenue,
        Gross_Trading_Profit,
        Working_Capital_Limit,
        Additional_Inventory_Funding

    FROM commodity_financial_model
),

construction_finance AS (

    SELECT
        State,
        District,
        Commodity,

        SUM(IDC) AS Total_IDC,

        MAX(Closing_Loan_Balance)
            AS Construction_End_Loan

    FROM project_construction_finance

    GROUP BY
        State,
        District,
        Commodity
),

subsidy AS (

    SELECT
        State,
        District,
        Commodity,

        MAX(Estimated_NHB_Subsidy)
            AS NHB_Subsidy,

        MAX(Subsidy_Eligibility_Month)
            AS Subsidy_Eligibility_Month

    FROM nhb_subsidy_model

    GROUP BY
        State,
        District,
        Commodity
),

post_subsidy AS (

    SELECT
        State,
        District,
        Commodity,

        MAX(
            CASE
                WHEN Month_No = 12
                THEN Interest_Bearing_Loan
            END
        ) AS Post_Subsidy_Loan

    FROM post_subsidy_loan_balance

    GROUP BY
        State,
        District,
        Commodity
),

integrated AS (

    SELECT

        f.State,
        f.District,
        f.Commodity,
        f.Buy_Price_Per_MT,
        f.Sell_Price_Per_MT,
        f.Facility_Capacity_MT,
        f.Holding_Months,

        /* =========================
           PROJECT INVESTMENT
           ========================= */

        f.Project_CAPEX,
        f.Term_Loan,
        f.Owner_Equity,

        /* =========================
           NHB SUBSIDY
           ========================= */

        s.NHB_Subsidy,

        f.Project_CAPEX
        - s.NHB_Subsidy
        AS Effective_Project_Cost,

        f.Term_Loan
        - s.NHB_Subsidy
        AS Effective_Net_Loan,

        /* =========================
           CONSTRUCTION FINANCE
           ========================= */

        c.Total_IDC,
        c.Construction_End_Loan,

        /* =========================
           POST-SUBSIDY LOAN
           ========================= */

        p.Post_Subsidy_Loan,

        /* =========================
           MERCHANT TRADING
           ========================= */

        f.Inventory_Procurement_Cost,

        f.Saleable_Quantity_MT,

        f.Trading_Revenue,

        f.Gross_Trading_Profit,

        /* =========================
           WORKING CAPITAL
           ========================= */

        f.Working_Capital_Limit,

        /* =========================
           ELECTRICITY COST
           ========================= */
	    f.Electricity_Cost_Per_MT* f.Facility_Capacity_MT AS Total_Electricity_Cost,
        /*
        Bank-funded working capital:
        capped at the inventory procurement
        requirement.
        */

        LEAST(
            f.Inventory_Procurement_Cost,
            f.Working_Capital_Limit
        )
        AS Working_Capital_Funded,

        /*
        Remaining inventory requirement is
        funded by promoter capital.
        */

        GREATEST(
            f.Inventory_Procurement_Cost
            - f.Working_Capital_Limit,
            0
        )
        AS Promoter_Inventory_Investment,

        /* =========================
           HOLDING PERIOD TERM-LOAN INTEREST
           ========================= */

        (
            LEAST(
                GREATEST(
                    p.Post_Subsidy_Loan,
                    0
                ),
                20000000
            )
            * 0.06
            / 12
            * f.Holding_Months
        )
        +
        (
            GREATEST(
                p.Post_Subsidy_Loan
                - 20000000,
                0
            )
            * 0.09
            / 12
            * f.Holding_Months
        )
        AS Holding_Period_Interest,

        /* =========================
           WORKING CAPITAL INTEREST
           
           ONLY the bank-funded WC portion
           bears interest.

           Promoter-funded inventory has
           no financing interest.
           ========================= */

        LEAST(
            f.Inventory_Procurement_Cost,
            f.Working_Capital_Limit
        )
        * 0.09
        / 12
        * f.Holding_Months
        AS Working_Capital_Interest

    FROM financial_base f

    LEFT JOIN construction_finance c
        ON f.State = c.State
        AND f.District = c.District
        AND f.Commodity = c.Commodity

    LEFT JOIN subsidy s
        ON f.State = s.State
        AND f.District = s.District
        AND f.Commodity = s.Commodity

    LEFT JOIN post_subsidy p
        ON f.State = p.State
        AND f.District = p.District
        AND f.Commodity = p.Commodity
),

final_calculation AS (

    SELECT
        *,

        /* =========================
           TOTAL FINANCING COST
           ========================= */

        COALESCE(Total_IDC, 0)
        +
        COALESCE(Holding_Period_Interest, 0)
        +
        COALESCE(Working_Capital_Interest, 0)
        +
        COALESCE(Total_Electricity_Cost, 0)
        AS Total_Financing_Cost,

        /* =========================
           TOTAL PROMOTER CAPITAL
           ========================= */

        Owner_Equity
        +
        Promoter_Inventory_Investment
        AS Total_Promoter_Cash_Deployed,

        /* =========================
           NET TRADING PROFIT
           ========================= */

        Gross_Trading_Profit
        -
        (
            COALESCE(Total_IDC, 0)
            +
            COALESCE(Holding_Period_Interest, 0)
            +
            COALESCE(Working_Capital_Interest, 0)
            +
            coalesce(Total_Electricity_Cost,0)
        )
        AS Net_Trading_Profit

    FROM integrated
),

roi_calculation AS (

    SELECT
        *,

        /* =========================
           ROI
           ========================= */

        CASE
            WHEN Total_Promoter_Cash_Deployed > 0
            THEN
                (
                    Net_Trading_Profit
                    /
                    Total_Promoter_Cash_Deployed
                ) * 100

            ELSE NULL
        END AS ROI_Percent,

        /* =========================
           PAYBACK PERIOD
           ========================= */

        CASE
            WHEN Net_Trading_Profit > 0
            THEN
                Total_Promoter_Cash_Deployed
                /
                Net_Trading_Profit

            ELSE NULL
        END AS Payback_Years

    FROM final_calculation
)

SELECT

    State,
    District,
    Commodity,
    Facility_Capacity_MT,
    Holding_Months,

    /* Project */
    round(Project_CAPEX,2) as Project_CAPEX,
    round(Term_Loan,2) as Term_Loan,
    round(Owner_Equity,2) as Owner_Equity,
    
    /* Pricing */
    round(Buy_Price_Per_MT,2) as Buy_Price_Per_MT,
    round(Sell_Price_Per_MT,2) as Sell_Price_Per_MT,

    /* Subsidy */
    NHB_Subsidy,
    round(Effective_Project_Cost,2) as Effective_Project_Cost,
    round(Effective_Net_Loan,2) as Effective_Net_Loan,

    /* Construction */
    round(Total_IDC,2) as Total_IDC,

    /* Post subsidy */
    round(Post_Subsidy_Loan,2) as Post_Subsidy_Loan,
    round(Holding_Period_Interest,2) as Holding_Period_Interest,

    /* Trading */
    round(Inventory_Procurement_Cost,2) as Inventory_Procurement_Cost,
    Saleable_Quantity_MT,
    round(Trading_Revenue,2) as Trading_Revenue,
    round(Gross_Trading_Profit,2) as Gross_Trading_Profit,
    /* Working capital */
    round(Working_Capital_Limit,2) as Working_Capital_Limit,
	round(Working_Capital_Funded,2) as Working_Capital_Funded,
	round(Promoter_Inventory_Investment,2) as Promoter_Inventory_Investment,
	round(Working_Capital_Interest,2) as Working_Capital_Interest,
        /* Electricity */
    round(Total_Electricity_Cost,2) as Total_Electricity_Cost,

    /* Investment */
    round(Total_Promoter_Cash_Deployed,2) as Total_Promoter_Cash_Deployed,

    /* Returns */
    round(Total_Financing_Cost,2) as Total_Financing_Cost,
    round(Net_Trading_Profit,2) as Net_Trading_Profit,
    round(ROI_Percent,2) as ROI_Percent,
    round(Payback_Years,2) as Payback_Years

FROM roi_calculation;


SELECT *
FROM merchant_financial_summary
LIMIT 10;

describe merchant_financial_summary;