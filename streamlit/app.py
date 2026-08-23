import streamlit as st
import pandas as pd

st.markdown(
    """
    <style>

    /* ---------- STREAMLIT TOP HEADER ---------- */

    header[data-testid="stHeader"] {
        background-color: var(--background-color);
        box-shadow: none;
        border-bottom: none;
    }

    /* ---------- GLOBAL ---------- */

    .stApp {
        background-color: var(--background-color);
    }

    .block-container {
        padding-top: 2rem;
        padding-bottom: 2rem;
        max-width: 1400px;
    }

    /* ---------- COLDIQ TITLE ---------- */

    .coldiq-title {
        font-size: 2.4rem;
        font-weight: 700;
        color: var(--text-color);
        margin-bottom: 0;
    }

    .coldiq-subtitle {
        font-size: 1.05rem;
        color: var(--secondary-text-color);
        margin-top: 0.2rem;
        margin-bottom: 1.5rem;
    }

    .coldiq-description {
        color: var(--secondary-text-color);
        font-size: 1rem;
    }

    /* ---------- MAIN HEADINGS ---------- */

    h1, h2, h3 {
        color: var(--text-color) !important;
    }

    /* ---------- ALL MAIN CONTENT TEXT ---------- */

    .main p,
    .main label,
    .main span {
        color: var(--text-color);
    }

    /* ---------- SIDEBAR ---------- */

    section[data-testid="stSidebar"] {
        background-color: #12355B;
    }

    section[data-testid="stSidebar"] * {
        color: white;
    }

    /* ---------- SIDEBAR INPUTS ---------- */

    section[data-testid="stSidebar"] div[data-baseweb="select"] {
        background-color: #0F1724;
        border-radius: 8px;
    }

    section[data-testid="stSidebar"] div[data-baseweb="select"] * {
        color: white !important;
    }

    /* ---------- METRIC CARDS ---------- */

    div[data-testid="stMetric"] {
        background-color: var(--secondary-background-color);
        border: 1px solid var(--border-color);
        border-radius: 12px;
        padding: 15px;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
    }

    div[data-testid="stMetricLabel"] {
        color: var(--secondary-text-color) !important;
    }

    div[data-testid="stMetricValue"] {
        color: var(--text-color) !important;
        font-weight: 700;
    }

    /* ---------- DATAFRAME ---------- */

    div[data-testid="stDataFrame"] {
        border-radius: 10px;
        overflow: hidden;
    }

    /* ---------- SELECTBOX ---------- */

    div[data-baseweb="select"] > div {
        border-radius: 8px;
    }

    /* ---------- INPUT LABELS ---------- */

    div[data-testid="stNumberInput"] label,
    div[data-testid="stSlider"] label,
    div[data-testid="stSelectbox"] label {
        color: var(--text-color) !important;
    }

    /* ---------- SECTION CARDS / POLISH ---------- */

    .advisor-card {
        background: var(--secondary-background-color);
        border: 1px solid var(--border-color);
        border-radius: 14px;
        padding: 1rem 1.15rem;
        margin-bottom: 0.75rem;
    }

    .stButton > button,
    div[data-baseweb="select"] > div {
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    section[data-testid="stSidebar"] [data-testid="stRadio"] label {
        font-weight: 600;
    }

    /* ---------- DIVIDER ---------- */

    hr {
        border: none;
        border-top: 1px solid var(--border-color);
        margin: 1.5rem 0;
    }

    /* ---------- FOOTER ---------- */

    .coldiq-footer {
        text-align: center;
        color: var(--secondary-text-color);
        font-size: 0.85rem;
        padding: 0.5rem;
    }

    </style>
    """,
    unsafe_allow_html=True
)


st.set_page_config(
    page_title="ColdIQ",
    page_icon="❄️",
    layout="wide"
)

st.markdown(
    '<div class="coldiq-title">❄️ ColdIQ</div>',
    unsafe_allow_html=True
)

st.markdown(
    '<div class="coldiq-subtitle">'
    'Cold Storage Investment Intelligence Platform'
    '</div>',
    unsafe_allow_html=True
)
st.markdown(
    '<div class="coldiq-description">'
    'Identify the most attractive commodity storage opportunities '
    'for a selected district.'
    '</div>',
    unsafe_allow_html=True
)

st.divider()

conn = st.connection("mysql", type="sql")

query = """
SELECT *
FROM commodity_distric_investment
"""

df = conn.query(query, ttl=600)

financial_query = """
SELECT *
FROM merchant_financial_summary
"""

financial_df = conn.query(financial_query, ttl=600)

break_even_query = """
SELECT *
FROM merchant_breakeven_analysis
"""

break_even_df = conn.query(
    break_even_query,
    ttl=600
)



sensitivity_query = """
SELECT *
FROM merchant_sensitivity_summary
"""

sensitivity_df = conn.query(
    sensitivity_query,
    ttl=600
)

st.sidebar.markdown(
    """
    <div style="
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 1rem;
    ">
        ❄️ ColdIQ
    </div>
    """,
    unsafe_allow_html=True
)

st.sidebar.caption(
    "Decision Intelligence"
)

page = st.sidebar.radio(
    "Analysis",
    [
        "District Commodity Advisor",
        "Financial Model",
        "Intrastate Storage Advisor",
        "Interstate Trade Advisor"
    ]
)

if page == "District Commodity Advisor":

    states = sorted(
        df["State"].dropna().unique()
    )

    selected_state = st.sidebar.selectbox(
        "State",
        states
    )

    state_df = df[
        df["State"] == selected_state
    ]

    districts = sorted(
        state_df["District"].dropna().unique()
    )

    selected_district = st.sidebar.selectbox(
        "District",
        districts,
        key="advisor_district"
    )

    district_df = df[
        (df["State"] == selected_state) &
        (df["District"] == selected_district)
    ]

    # Optional commodity filter for the district advisor.
    # "All Commodities" keeps the district-wide Top 5 view.
    advisor_commodities = sorted(
        district_df["Commodity"].dropna().unique()
    )

    commodity_filter_options = ["All Commodities"] + advisor_commodities

    selected_commodity_filter = st.sidebar.selectbox(
        "Commodity",
        commodity_filter_options,
        key="advisor_commodity"
    )

    if selected_commodity_filter != "All Commodities":
        filtered_district_df = district_df[
            district_df["Commodity"] == selected_commodity_filter
        ].copy()
    else:
        filtered_district_df = district_df.copy()

    if filtered_district_df.empty:

        st.warning(
            "No investment opportunities found for this district."
        )

    else:

        # -----------------------------------
        # TOP 5 DISTINCT COMMODITIES
        # -----------------------------------

        top_5 = (
            filtered_district_df
            .sort_values("Commodity_Rank")
            .drop_duplicates(
                subset=["Commodity"],
                keep="first"
            )
            .head(5)
        )

        if top_5.empty:

            st.warning(
                "No ranked commodities available for this district."
            )

        else:

            # -----------------------------------
            # DISTRICT RECOMMENDATION
            # -----------------------------------

            best = top_5.iloc[0]

            st.header("🏆 District Recommendation")

            st.markdown('<div class="advisor-card">', unsafe_allow_html=True)
            st.metric(
                "Top Recommendation",
                best["Commodity"]
            )

            st.write(
                f"Investment Score: "
                f"**{best['Investment_Score']:.2f}**"
            )

            st.write(
                f"Decision: "
                f"**{best['Investment_Decision']}**"
            )
            st.markdown('</div>', unsafe_allow_html=True)

            # -----------------------------------
            # COMMODITY SELECTION
            # -----------------------------------

            st.header("🔎 Explore Top 5 Commodities")

            commodity_options = top_5[
                "Commodity"
            ].tolist()

            if selected_commodity_filter != "All Commodities":
                selected_commodity = selected_commodity_filter
                st.caption(
                    f"Commodity filter: **{selected_commodity}**"
                )
            else:
                selected_commodity = st.selectbox(
                    "Select a commodity for detailed analysis",
                    commodity_options,
                    key="advisor_detail_commodity"
                )

            selected_rows = top_5[
                top_5["Commodity"] == selected_commodity
            ]

            selected_row = selected_rows.iloc[0]

            # -----------------------------------
            # SELECTED COMMODITY METRICS
            # -----------------------------------

            col1, col2, col3, col4 = st.columns(4)

            with col1:
                st.metric(
                    "Investment Score",
                    f"{selected_row['Investment_Score']:.2f}"
                )

            with col2:
                st.metric(
                    "Price Gain",
                    f"{selected_row['Price_Gain_Percent']:.2f}%"
                )

            with col3:
                st.metric(
                    "Holding Period",
                    f"{selected_row['Holding_Months']} months"
                )

            with col4:
                st.metric(
                    "Storage Spoilage",
                    f"{selected_row['Storage_Spoilage_Percent']:.2f}%"
                )

            # -----------------------------------
            # WHY THIS COMMODITY?
            # -----------------------------------

            st.header("Why this commodity?")

            reasons = []

            if selected_row["Price_Gain_Percent"] >= 30:
                reasons.append(
                    "Strong seasonal price appreciation"
                )

            if selected_row["Storage_Spoilage_Percent"] <= 10:
                reasons.append(
                    "Low modeled storage spoilage"
                )

            if selected_row["Investment_Score"] >= 80:
                reasons.append(
                    "High overall investment score"
                )

            if reasons:

                for reason in reasons:
                    st.write(f"✓ {reason}")

            else:

                st.write(
                    "The commodity ranks highly based on the "
                    "combined investment model."
                )

            # -----------------------------------
            # TOP 5 TABLE
            # -----------------------------------

            st.header("Top 5 Storage Opportunities")

            display_columns = [
                "Commodity",
                "Commodity_Rank",
                "Investment_Score",
                "Buy_Month",
                "Sell_Month",
                "Holding_Months",
                "Price_Gain_Percent",
                "Investment_Decision"
            ]
            display_df = top_5[display_columns].rename(
            columns={
                "Commodity": "Commodity",
                "Commodity_Rank": "Rank",
                "Investment_Score": "Investment Score",
                "Buy_Month": "Buy Month",
                "Sell_Month": "Sell Month",
                "Holding_Months": "Holding Period",
                "Price_Gain_Percent": "Price Gain %",
                "Investment_Decision": "Decision"
                }
                )
            st.dataframe(
                display_df,
                hide_index=True,
                use_container_width=True
                )
            # -----------------------------------
            # SCENARIO ANALYSIS
            # -----------------------------------

            st.divider()

            st.header("📊 Scenario Analysis")

            st.write(
                f"""
                Scenario analysis for **{selected_commodity}**. 
                Adjust operating assumptions to evaluate how the 
                estimated financial outcome changes.
                """
            )

            # -----------------------------------
            # SCENARIO INPUTS
            # -----------------------------------

            col1, col2 = st.columns(2)

            with col1:

                facility_capacity = st.number_input(
                    "Facility Capacity (MT)",
                    min_value=500,
                    max_value=20000,
                    value=5000,
                    step=500
                )

                utilization = st.slider(
                    "Facility Utilization (%)",
                    min_value=30,
                    max_value=100,
                    value=100,
                    step=5
                )

                operating_cost_rate = st.slider(
                    "Other Operating Costs (% of Revenue)",
                    min_value=0,
                    max_value=30,
                    value=0,
                    step=5
                )

            with col2:

                facility_load = st.number_input(
                    "Electricity Load (kW)",
                    min_value=50,
                    max_value=2000,
                    value=500,
                    step=50
                )

                load_factor = st.slider(
                    "Electrical Load Factor (%)",
                    min_value=30,
                    max_value=80,
                    value=50,
                    step=5
                )

                subsidy = st.number_input(
                    "Subsidy (%)",
                    min_value=0,
                    max_value=50,
                    value=35,
                    step=5
                )


            # -----------------------------------
            # LOAD FINAL FINANCIAL MODEL
            # -----------------------------------


            scenario_financial_df = financial_df.loc[
                (financial_df["State"] == selected_row["State"]) &
                (financial_df["District"] == selected_row["District"]) &
                (financial_df["Commodity"] == selected_row["Commodity"])
                ].copy()
            if scenario_financial_df.empty:
                st.error("Financial model data is not available for this commodity.")
                st.stop()
            financial_row = scenario_financial_df.iloc[0]
                # -----------------------------------
                # BASE COMMODITY VALUES
                # -----------------------------------

            buy_price = float(
                financial_row["Buy_Price_Per_MT"]
            )

            sell_price = float(
                financial_row["Sell_Price_Per_MT"]
            )

            holding_months = float(
                financial_row["Holding_Months"]
            )

            # Storage spoilage still comes from
            # commodity investment model because
            # merchant_financial_summary does not
            # contain the spoilage percentage.

            spoilage = float(
                selected_row["Storage_Spoilage_Percent"]
            ) / 100

            infrastructure_cost_per_mt = float(
                selected_row["Infrastructure_Cost_Per_MT"]
            )

            price_kwh = float(
                selected_row["Price_KWh"]
            )


            # -----------------------------------
            # PROJECT INVESTMENT
            # -----------------------------------

            project_capex = (
                facility_capacity
                * infrastructure_cost_per_mt
            )

            term_loan = (
                project_capex
                * 0.75
            )

            owner_equity = (
                project_capex
                * 0.25
            )


            # -----------------------------------
            # NHB SUBSIDY
            # -----------------------------------

            nhb_subsidy = (
                project_capex
                * subsidy
                / 100
            )

            effective_project_cost = (
                project_capex
                - nhb_subsidy
            )

            effective_net_loan = (
                term_loan
                - nhb_subsidy
            )


            # -----------------------------------
            # EFFECTIVE CAPACITY
            # -----------------------------------

            effective_capacity = (
                facility_capacity
                * utilization
                / 100
            )


            # -----------------------------------
            # SALEABLE QUANTITY
            # -----------------------------------

            saleable_quantity = (
                effective_capacity
                * (1 - spoilage)
            )


            # -----------------------------------
            # INVENTORY PROCUREMENT
            # -----------------------------------

            inventory_procurement_cost = (
                effective_capacity
                * buy_price
            )


            # -----------------------------------
            # TRADING REVENUE
            # -----------------------------------

            trading_revenue = (
                saleable_quantity
                * sell_price
            )


            # -----------------------------------
            # GROSS TRADING PROFIT
            # -----------------------------------

            gross_trading_profit = (
                trading_revenue
                - inventory_procurement_cost
            )


            # -----------------------------------
            # WORKING CAPITAL
            # -----------------------------------

            working_capital_limit = (
                trading_revenue
                * 0.20
            )

            working_capital_funded = min(
                inventory_procurement_cost,
                working_capital_limit
            )

            promoter_inventory_investment = max(
                inventory_procurement_cost
                - working_capital_limit,
                0
            )


            # -----------------------------------
            # CONSTRUCTION IDC
            # -----------------------------------
            #
            # Scale the finalized base IDC
            # according to facility capacity.
            #

            base_idc = float(
                financial_row["Total_IDC"]
            )

            base_capacity = float(
                financial_row["Facility_Capacity_MT"]
            )

            total_idc = (
                base_idc
                * facility_capacity
                / base_capacity
                if base_capacity > 0
                else 0
            )


            # -----------------------------------
            # POST-SUBSIDY LOAN
            # -----------------------------------

            post_subsidy_loan = max(
                effective_net_loan,
                0
            )


            # -----------------------------------
            # HOLDING PERIOD INTEREST
            # -----------------------------------
            #
            # AIF:
            # First ₹2 crore → 6%
            # Remaining amount → 9%
            #

            aif_eligible_balance = min(
                post_subsidy_loan,
                20000000
            )

            non_aif_balance = max(
                post_subsidy_loan
                - 20000000,
                0
            )

            holding_period_interest = (

                aif_eligible_balance
                * 0.06
                / 12
                * holding_months

            ) + (

                non_aif_balance
                * 0.09
                / 12
                * holding_months

            )


            # -----------------------------------
            # WORKING CAPITAL INTEREST
            # -----------------------------------

            working_capital_interest = (

                working_capital_funded
                * 0.09
                / 12
                * holding_months

            )


            # -----------------------------------
            # ELECTRICITY COST
            # -----------------------------------

            total_electricity_cost = (

                price_kwh
                * facility_load
                * (load_factor / 100)
                * 24
                * 30
                * holding_months

            )


            # -----------------------------------
            # OTHER OPERATING COST
            # -----------------------------------

            other_operating_cost = (

                trading_revenue
                * operating_cost_rate
                / 100

            )


            # -----------------------------------
            # TOTAL FINANCING COST
            # -----------------------------------

            total_financing_cost = (

                total_idc
                + holding_period_interest
                + working_capital_interest

            )


            # -----------------------------------
            # TOTAL PROMOTER CASH DEPLOYED
            # -----------------------------------

            total_promoter_cash_deployed = (

                owner_equity
                + promoter_inventory_investment

            )


            # -----------------------------------
            # NET TRADING PROFIT
            # -----------------------------------

            net_trading_profit = (

                gross_trading_profit
                - total_financing_cost
                - total_electricity_cost
                - other_operating_cost

            )


            # -----------------------------------
            # ROI
            # -----------------------------------

            roi = (

                net_trading_profit
                / total_promoter_cash_deployed
                * 100

                if total_promoter_cash_deployed > 0
                else 0

            )


            # -----------------------------------
            # PAYBACK
            # -----------------------------------

            payback = (

                total_promoter_cash_deployed
                / net_trading_profit

                if net_trading_profit > 0
                else 999

            )


            # -----------------------------------
            # SCENARIO RESULTS
            # -----------------------------------

            st.subheader("Scenario Results")

            col1, col2, col3, col4 = st.columns(4)

            with col1:

                st.metric(
                    "Occupied Capacity",
                    f"{effective_capacity:,.0f} MT"
                )

            with col2:

                st.metric(
                    "Trading Revenue",
                    f"₹{trading_revenue:,.0f}"
                )

            with col3:

                st.metric(
                    "Net Trading Profit",
                    f"₹{net_trading_profit:,.0f}"
                )

            with col4:

                st.metric(
                    "ROI",
                    f"{roi:.1f}%"
                )


            col1, col2, col3, col4 = st.columns(4)

            with col1:

                st.metric(
                    "Promoter Cash Deployed",
                    f"₹{total_promoter_cash_deployed:,.0f}"
                )

            with col2:

                st.metric(
                    "Total Financing Cost",
                    f"₹{total_financing_cost:,.0f}"
                )

            with col3:

                st.metric(
                    "Electricity Cost",
                    f"₹{total_electricity_cost:,.0f}"
                )

            with col4:

                st.metric(
                    "Payback",
                    f"{payback:.2f} years"
                    if payback < 999
                    else "Not Achievable"
                )


            # -----------------------------------
            # COST BREAKDOWN
            # -----------------------------------

            st.subheader("Cost Breakdown")

            scenario_cost_df = pd.DataFrame({

                "Component": [
                    "Inventory Procurement",
                    "Electricity",
                    "Financing",
                    "Other Operating Costs"
                ],

                "Amount": [
                    inventory_procurement_cost,
                    total_electricity_cost,
                    total_financing_cost,
                    other_operating_cost
                ]

            })

            st.bar_chart(
                scenario_cost_df.set_index("Component")
            )


            # -----------------------------------
            # SCENARIO INTERPRETATION
            # -----------------------------------

            if net_trading_profit <= 0:

                st.error(
                    "🔴 This scenario is not financially viable. "
                    "The modeled net trading profit is negative."
                )

            elif roi >= 100 and payback <= 1:

                st.success(
                    "🟢 Very Strong Opportunity — "
                    "high modeled ROI with a short payback period."
                )

            elif roi >= 50 and payback <= 2:

                st.success(
                    "🟢 Strong Opportunity — "
                    "the scenario remains financially attractive."
                )

            elif roi >= 25 and payback <= 3:

                st.warning(
                    "🟡 Moderate Opportunity — "
                    "returns are positive but should be evaluated against risk."
                )

            else:

                st.warning(
                    "🟠 Weak Opportunity — "
                    "the scenario has limited financial attractiveness."
                )


            st.caption(
                "Scenario outputs are modeled estimates. They apply the finalized "
                "ColdIQ financial logic while allowing operating assumptions such "
                "as utilization, electricity load, subsidy and operating costs to "
                "be varied."
                )


# ============================================================
# FINANCIAL MODEL
# ============================================================

if page == "Financial Model":

    st.header("💰 Merchant Trading Financial Model")

    st.markdown(
        """
        Evaluate the financial feasibility of establishing a
        cold-storage facility for merchant commodity trading.
        """
    )

    # --------------------------------------------------------
    # FILTERS
    # --------------------------------------------------------

    states = sorted(
        financial_df["State"].dropna().unique()
    )

    selected_state = st.sidebar.selectbox(
        "State",
        states,
        key="financial_state"
    )

    state_df = financial_df[
        financial_df["State"] == selected_state
    ]

    districts = sorted(
        state_df["District"].dropna().unique()
    )

    selected_district = st.sidebar.selectbox(
        "District",
        districts,
        key="financial_district"
    )

    district_df = state_df[
        state_df["District"] == selected_district
    ]

    commodities = sorted(
        district_df["Commodity"].dropna().unique()
    )

    selected_commodity = st.sidebar.selectbox(
        "Commodity",
        commodities,
        key="financial_commodity"
    )

    financial_row = district_df[
        district_df["Commodity"] == selected_commodity
    ].iloc[0]

    # --------------------------------------------------------
    # PROJECT INVESTMENT
    # --------------------------------------------------------

    st.subheader("🏗️ Project Investment")

    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.metric(
            "Project CAPEX",
            f"₹{financial_row['Project_CAPEX']/1e7:.2f} Cr"
        )

    with col2:
        st.metric(
            "Bank Term Loan",
            f"₹{financial_row['Term_Loan']/1e7:.2f} Cr"
        )

    with col3:
        st.metric(
            "Promoter Equity",
            f"₹{financial_row['Owner_Equity']/1e7:.2f} Cr"
        )

    with col4:
        st.metric(
            "NHB Subsidy",
            f"₹{financial_row['NHB_Subsidy']/1e7:.2f} Cr"
        )
    # --------------------------------------------------------
    # MERCHANT TRADING
    # --------------------------------------------------------

    st.subheader("📦 Merchant Trading Economics")

    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.metric(
            "Inventory Procurement",
            f"₹{financial_row['Inventory_Procurement_Cost']/1e7:.2f} Cr"
        )

    with col2:
        st.metric(
            "Saleable Quantity",
            f"{financial_row['Saleable_Quantity_MT']:,.0f} MT"
        )

    with col3:
        st.metric(
            "Trading Revenue",
            f"₹{financial_row['Trading_Revenue']/1e7:.2f} Cr"
        )

    with col4:
        st.metric(
            "Gross Trading Profit",
            f"₹{financial_row['Gross_Trading_Profit']/1e7:.2f} Cr"
        )

    # --------------------------------------------------------
    # OPERATING + FINANCING COSTS
    # --------------------------------------------------------

    st.subheader("⚡ Operating & Financing Costs")

    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.metric(
            "Electricity Cost",
            f"₹{financial_row['Total_Electricity_Cost']/1e5:.2f} L"
        )

    with col2:
        st.metric(
            "Holding Period Interest",
            f"₹{financial_row['Holding_Period_Interest']/1e5:.2f} L"
        )

    with col3:
        st.metric(
            "Working Capital Interest",
            f"₹{financial_row['Working_Capital_Interest']/1e5:.2f} L"
        )

    with col4:
        st.metric(
            "Total Financing Cost",
            f"₹{financial_row['Total_Financing_Cost']/1e5:.2f} L"
        )
    # --------------------------------------------------------
    # EFFECTIVE FINANCING
    # --------------------------------------------------------

    st.subheader("🏦 Effective Financing")

    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric(
            "Effective Project Cost",
            f"₹{financial_row['Effective_Project_Cost']/1e7:.2f} Cr"
        )

    with col2:
        st.metric(
            "Effective Net Loan",
            f"₹{financial_row['Effective_Net_Loan']/1e7:.2f} Cr"
        )

    with col3:
        st.metric(
            "Total IDC",
            f"₹{financial_row['Total_IDC']/1e5:.2f} L"
        )



    # --------------------------------------------------------
    # WORKING CAPITAL
    # --------------------------------------------------------

    st.subheader("💳 Working Capital")

    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric(
            "Bank WC Limit",
            f"₹{financial_row['Working_Capital_Limit']/1e7:.2f} Cr"
        )

    with col2:
        st.metric(
            "Bank WC Funded",
            f"₹{financial_row['Working_Capital_Funded']/1e7:.2f} Cr"
        )

    with col3:
        st.metric(
            "Promoter Inventory Investment",
            f"₹{financial_row['Promoter_Inventory_Investment']/1e7:.2f} Cr"
        )



    # --------------------------------------------------------
    # RETURNS
    # --------------------------------------------------------

    st.divider()

    st.subheader("📈 Investment Returns")

    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric(
            "Promoter Cash Deployed",
            f"₹{financial_row['Total_Promoter_Cash_Deployed']/1e7:.2f} Cr"
        )

    with col2:
        st.metric(
            "Net Trading Profit",
            f"₹{financial_row['Net_Trading_Profit']/1e7:.2f} Cr"
        )

    with col3:
        st.metric(
            "ROI",
            f"{financial_row['ROI_Percent']:.2f}%"
        )

    st.metric(
        "Payback Period",
        f"{financial_row['Payback_Years']:.2f} years"
    )

# --------------------------------------------------------
# INVESTMENT DECISION
# --------------------------------------------------------

    st.divider()
    st.subheader("🎯 Investment Decision")

    roi = financial_row["ROI_Percent"]
    payback = financial_row["Payback_Years"]
    net_profit = financial_row["Net_Trading_Profit"]

# Simple decision logic
    if roi >= 100 and payback <= 1:
        decision = "🟢 Very Strong Opportunity"
    elif roi >= 75 and payback <= 2:
        decision = "🟢 Strong Opportunity"
    elif roi >= 50 and payback <= 3:
        decision = "🟡 Moderate Opportunity"
    elif roi >= 25 and payback <= 5:
        decision = "🟠 Weak Opportunity"
    else:
        decision = "🔴 High Risk / Poor Opportunity"

    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric(
            "Investment Decision",
            decision
        )

    with col2:
        st.metric(
            "Net Profit",
            f"₹{net_profit/1e7:.2f} Cr"
        )

    with col3:
        st.metric(
            "ROI",
            f"{roi:.2f}%"
        )

    st.write(
        f"""
        **Interpretation:** The selected {selected_commodity} opportunity in
        {selected_district}, {selected_state} generates an estimated net trading
        profit of **₹{net_profit/1e7:.2f} Cr** with an ROI of **{roi:.2f}%**
        and an estimated payback period of **{payback:.2f} years**.
        """
    )

    
# --------------------------------------------------------
# BREAK-EVEN ANALYSIS
# --------------------------------------------------------

    st.divider()

    st.subheader("⚖️ Break-Even Analysis")

    break_even_row = break_even_df[
        (break_even_df["State"] == selected_state) &
        (break_even_df["District"] == selected_district) &
        (break_even_df["Commodity"] == selected_commodity)
    ].iloc[0]

    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric(
            "Break-Even Selling Price",
            f"₹{break_even_row['BreakEven_Selling_Price']:,.0f}/MT"
        )

    with col2:
        st.metric(
            "Break-Even Buying Price",
            f"₹{break_even_row['BreakEven_Buy_Price']:,.0f}/MT"
        )

    with col3:
        st.metric(
            "Break-Even Utilization",
            f"{break_even_row['BreakEven_Utilization_Percent']:.1f}%"
        )

    st.write(
        f"**Decision:** {break_even_row['BreakEven_Decision']}"
    )   

# --------------------------------------------------------
# SENSITIVITY ANALYSIS
# --------------------------------------------------------

    st.divider()

    st.subheader("📊 Sensitivity Analysis")

    sensitivity_display = sensitivity_df[
        (sensitivity_df["State"] == selected_state) &
        (sensitivity_df["District"] == selected_district) &
        (sensitivity_df["Commodity"] == selected_commodity)
    ]

    display_columns = [
        "Variable",
        "Profit_Minus_15",
        "Profit_Base",
        "Profit_Plus_15",
        "ROI_Minus_15",
        "ROI_Base",
        "ROI_Plus_15"
    ]

    st.dataframe(
        sensitivity_display[display_columns],
        hide_index=True,
        use_container_width=True
    )

# --------------------------------------------------------
# PROFIT & COST BREAKDOWN
# --------------------------------------------------------

    st.divider()
    st.subheader("💰 Profit & Cost Breakdown")

    profit = float(financial_row["Gross_Trading_Profit"])
    electricity = float(financial_row["Total_Electricity_Cost"])
    financing = float(financial_row["Total_Financing_Cost"])
    net_profit = float(financial_row["Net_Trading_Profit"])

    breakdown_df = pd.DataFrame({
        "Component": [
            "Gross Trading Profit",
            "Electricity Cost",
            "Financing Cost",
            "Net Trading Profit"
        ],
        "Amount": [
            profit,
            electricity,
            financing,
            net_profit
        ]
    })

    st.bar_chart(
        breakdown_df.set_index("Component")
    )


if page == "Intrastate Storage Advisor":

    st.header("📍 Intrastate Storage Advisor")

    st.markdown(
        "Identify the strongest districts for establishing "
        "commodity storage within a selected state."
    )

    intrastate_query = """
    SELECT *
    FROM intrastate_opportunity
    where not opportunity="Avoid"
    """

    intrastate_df = conn.query(
        intrastate_query,
        ttl=600
    )

    # -----------------------------------
    # STATE SELECTION
    # -----------------------------------

    states = sorted(
        intrastate_df["State"]
        .dropna()
        .unique()
    )

    selected_state = st.sidebar.selectbox(
        "State",
        states,
        key="intrastate_state"
    )

    state_df = intrastate_df[
        intrastate_df["State"] == selected_state
    ]

    # -----------------------------------
    # COMMODITY SELECTION
    # -----------------------------------

    commodities = sorted(
        state_df["Commodity"]
        .dropna()
        .unique()
    )

    selected_commodity = st.sidebar.selectbox(
        "Commodity",
        commodities,
        key="intrastate_commodity"
    )

    # -----------------------------------
    # FILTER
    # -----------------------------------

    result_df = state_df[
        state_df["Commodity"] == selected_commodity
    ]

    # -----------------------------------
    # RANK DISTRICTS
    # -----------------------------------

    result_df = (
        result_df
        .sort_values("Storage_Location_Rank")
        .drop_duplicates(
            subset=["District"],
            keep="first"
        )
    )

    if result_df.empty:

        st.warning(
            "No storage opportunities found "
            "for this selection."
        )

    else:

        # -----------------------------------
        # BEST DISTRICT
        # -----------------------------------

        best_location = result_df.iloc[0]

        st.header("🏆 Best Storage District")

        st.metric(
            "Recommended District",
            best_location["District"]
        )

        st.write(
            f"Storage Location Score: "
            f"**{best_location['Storage_Location_Score']:.2f}**"
        )

        st.write(
            f"Opportunity: "
            f"**{best_location['Opportunity']}**"
        )

        # -----------------------------------
        # SUPPORTING METRICS
        # -----------------------------------

        col1, col2, col3 = st.columns(3)

        with col1:

            st.metric(
                "Production Level",
                best_location["Production_Level"]
            )

        with col2:

            st.metric(
                "Price Gain",
                f"{best_location['Seasonal_Price_Gain_Percent']:.2f}%"
            )

        with col3:

            st.metric(
                "Market Reliability",
                f"{best_location['Market_Reliability']:.2f}"
            )

        # -----------------------------------
        # TOP STORAGE DISTRICTS
        # -----------------------------------

        st.header("Top Storage Locations")

        display_columns = [
            "District",
            "Production_Level",
            "Low_Season_Price_Per_MT",
            "High_Season_Price_Per_MT",
            "Seasonal_Price_Gain_Percent",
            "Market_Reliability",
            "Price_CV",
            "Storage_Location_Score",
            "Storage_Location_Rank",
            "Opportunity"
        ]

        top_locations = result_df.head(10)
        display_df = top_locations[display_columns].rename(columns={
            "District": "District",
            "Production_Level": "Production Level",
            "Low_Season_Price_Per_MT": "Low Season Price / MT",
            "High_Season_Price_Per_MT": "High Season Price / MT",
            "Seasonal_Price_Gain_Percent": "Seasonal Price Gain %",
            "Market_Reliability": "Market Reliability",
            "Price_CV": "Price CV",
            "Storage_Location_Score": "Location Score",
            "Storage_Location_Rank": "Rank",
            "Opportunity": "Opportunity"
            }
            )
        st.dataframe(
            display_df,
            hide_index=True,
            use_container_width=True
            )

if page == "Interstate Trade Advisor":

    st.header("🚚 Interstate Trade Advisor")

    st.markdown(
        "Identify attractive interstate commodity trade routes "
        "based on price opportunity, transport economics, spoilage "
        "and market conditions."
    )

    interstate_query = """
    SELECT *
    FROM interstate_opportunity
    """

    interstate_df = conn.query(
        interstate_query,
        ttl=600
    )

    # -----------------------------------
    # COMMODITY SELECTION
    # -----------------------------------

    commodities = sorted(
        interstate_df["Commodity"]
        .dropna()
        .unique()
    )

    selected_commodity = st.sidebar.selectbox(
        "Commodity",
        commodities,
        key="interstate_commodity"
    )

    commodity_df = interstate_df[
        interstate_df["Commodity"] == selected_commodity
    ]

    # -----------------------------------
    # SOURCE STATE SELECTION
    # -----------------------------------

    source_states = sorted(
        commodity_df["Source_State"]
        .dropna()
        .unique()
    )

    selected_source_state = st.sidebar.selectbox(
        "Source State",
        source_states,
        key="interstate_source_state"
    )

    source_df = commodity_df[
        commodity_df["Source_State"] == selected_source_state
    ]

    # -----------------------------------
    # DESTINATION STATE SELECTION
    # -----------------------------------

    destination_states = sorted(
        source_df["Destination_State"]
        .dropna()
        .unique()
    )

    selected_destination_state = st.sidebar.selectbox(
        "Destination State",
        destination_states,
        key="interstate_destination_state"
    )

    route_df = source_df[
        source_df["Destination_State"]
        == selected_destination_state
    ]

    # -----------------------------------
    # CHECK FOR AVAILABLE ROUTES
    # -----------------------------------

    if route_df.empty:

        st.warning(
            "No interstate opportunities found "
            "for this route."
        )

    else:

        # -----------------------------------
        # BEST TRADE ROUTE
        # -----------------------------------

        best_route = (
            route_df
            .sort_values(
                "Transport_Opportunity_Score",
                ascending=False
            )
            .iloc[0]
        )

        st.header("🏆 Best Trade Opportunity")

        st.metric(
            "Source State",
            best_route["Source_State"]
        )

        st.metric(
            "Destination State",
            best_route["Destination_State"]
        )

        # -----------------------------------
        # KEY TRADE METRICS
        # -----------------------------------

        col1, col2, col3, col4 = st.columns(4)

        with col1:

            st.metric(
                "Buying Price",
                f"₹{best_route['Buying_Price_Per_MT']:,.0f}/MT"
            )

        with col2:

            st.metric(
                "Selling Price",
                f"₹{best_route['Selling_Price_Per_MT']:,.0f}/MT"
            )

        with col3:

            st.metric(
                "Net Transport Profit",
                f"₹{best_route['Net_Transport_Profit_Per_MT']:,.0f}/MT"
            )

        with col4:

            st.metric(
                "Opportunity Score",
                f"{best_route['Transport_Opportunity_Score']:.2f}"
            )

        # -----------------------------------
        # ROUTE DETAILS
        # -----------------------------------

        col1, col2, col3, col4 = st.columns(4)

        with col1:

            st.metric(
                "Distance",
                f"{best_route['Distance_KM']:,.0f} km"
            )

        with col2:

            st.metric(
                "Transit Time",
                f"{best_route['Transit_Days']:.1f} days"
            )

        with col3:

            st.metric(
                "Transport Cost",
                f"₹{best_route['Transport_Cost_Per_MT']:,.0f}/MT"
            )

        with col4:

            st.metric(
                "Transit Spoilage",
                f"{best_route['Transit_Spoilage_Percent']:.2f}%"
            )

        # -----------------------------------
        # MARKET & SUPPLY CONTEXT
        # -----------------------------------

        st.header("Market & Supply Context")

        col1, col2, col3, col4 = st.columns(4)

        with col1:

            st.metric(
                "Source Production",
                best_route["Source_Production_Level"]
            )

        with col2:

            st.metric(
                "Source Reliability",
                f"{best_route['Source_Market_Reliability']:.2f}"
            )

        with col3:

            st.metric(
                "Destination Reliability",
                f"{best_route['Destination_Market_Reliability']:.2f}"
            )

        with col4:

            st.metric(
                "Price Stability",
                f"{best_route['Price_Stability_Score']:.0f}"
            )

        # -----------------------------------
        # RECOMMENDATION
        # -----------------------------------

        st.header("Trade Recommendation")

        st.write(
            f"**Opportunity:** "
            f"{best_route['Opportunity']}"
        )

        st.write(
            f"**Primary Reason:** "
            f"{best_route['Primary_Reason']}"
        )

        # -----------------------------------
        # TOP TRADE ROUTES
        # -----------------------------------

        st.header("Top Trade Routes")

        display_columns = [
            "Source_State",
            "Destination_State",
            "Buying_Price_Per_MT",
            "Selling_Price_Per_MT",
            "Gross_Price_Gain_Percent",
            "Distance_KM",
            "Transit_Days",
            "Transport_Cost_Per_MT",
            "Transit_Spoilage_Percent",
            "Net_Transport_Profit_Per_MT",
            "Transport_Opportunity_Score",
            "Opportunity"
        ]

        top_routes = (
            route_df
            .sort_values(
                "Transport_Opportunity_Score",
                ascending=False
            )
            .head(10)
        )
        display_df = top_routes[display_columns].rename(columns={
            "Source_State": "Source State",
            "Destination_State": "Destination State",
            "Buying_Price_Per_MT": "Buying Price / MT",
            "Selling_Price_Per_MT": "Selling Price / MT",
            "Gross_Price_Gain_Percent": "Gross Price Gain %",
            "Distance_KM": "Distance (KM)",
            "Transit_Days": "Transit Days",
            "Transport_Cost_Per_MT": "Transport Cost / MT",
            "Transit_Spoilage_Percent": "Transit Spoilage %",
            "Net_Transport_Profit_Per_MT": "Net Profit / MT",
            "Transport_Opportunity_Score": "Opportunity Score",
            "Opportunity": "Opportunity"
            })

        st.dataframe(
            display_df,
            hide_index=True,
            use_container_width=True
            )

st.divider()

st.markdown(
    """
    <div style="
        text-align: center;
        color: #7A8491;
        font-size: 0.85rem;
        padding: 0.5rem;
    ">
        ColdIQ • Data-Driven Cold Storage & Commodity Intelligence
    </div>
    """,
    unsafe_allow_html=True
)
