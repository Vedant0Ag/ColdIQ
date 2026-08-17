
import streamlit as st

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
        districts
    )

    district_df = df[
        (df["State"] == selected_state) &
        (df["District"] == selected_district)
    ]

    if district_df.empty:

        st.warning(
            "No investment opportunities found for this district."
        )

    else:

        # -----------------------------------
        # TOP 5 DISTINCT COMMODITIES
        # -----------------------------------

        top_5 = (
            district_df
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

            # -----------------------------------
            # COMMODITY SELECTION
            # -----------------------------------

            st.header("🔎 Explore Top 5 Commodities")

            commodity_options = top_5[
                "Commodity"
            ].tolist()

            selected_commodity = st.selectbox(
                "Select a commodity for detailed analysis",
                commodity_options
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
                f"Scenario analysis for **{selected_commodity}**. "
                "Adjust operating assumptions to evaluate how the "
                "estimated financial outcome changes."
            )

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
                    max_value=90,
                    value=60,
                    step=5
                )

                operating_cost_rate = st.slider(
                    "Other Operating Costs (% of Revenue)",
                    min_value=10,
                    max_value=50,
                    value=25,
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
            # SELECTED COMMODITY VALUES
            # -----------------------------------

            buy_price = float(
                selected_row["Buy_Price_Per_MT"]
            )

            sell_price = float(
                selected_row["Sell_Price_Per_MT"]
            )

            holding_months = float(
                selected_row["Holding_Months"]
            )

            spoilage = float(
                selected_row["Storage_Spoilage_Percent"]
            ) / 100

            infrastructure_cost = float(
                selected_row["Infrastructure_Cost_Per_MT"]
            )

            price_kwh = float(
                selected_row["Price_KWh"]
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
            # SALEABLE CAPACITY
            # -----------------------------------

            saleable_capacity = (
                effective_capacity
                * (1 - spoilage)
            )

            # -----------------------------------
            # REVENUE
            # -----------------------------------

            saleable_revenue = (
                saleable_capacity
                * sell_price
            )

            # -----------------------------------
            # PROCUREMENT COST
            # -----------------------------------

            procurement_cost = (
                effective_capacity
                * buy_price
            )

            # -----------------------------------
            # ELECTRICITY COST
            # -----------------------------------

            electricity_cost = (
                price_kwh
                * facility_load
                * (load_factor / 100)
                * 24
                * 30
                * holding_months
            )

            # -----------------------------------
            # OTHER OPERATING COSTS
            # -----------------------------------

            operating_cost = (
                saleable_revenue
                * operating_cost_rate
                / 100
            )

            # -----------------------------------
            # INFRASTRUCTURE COST
            # -----------------------------------

            net_infrastructure_cost_per_mt = (
                infrastructure_cost
                * (1 - subsidy / 100)
            )

            total_infrastructure_cost = (
                net_infrastructure_cost_per_mt
                * facility_capacity
            )

            # -----------------------------------
            # TOTAL COST
            # -----------------------------------

            total_cost = (
                procurement_cost
                + electricity_cost
                + operating_cost
                + total_infrastructure_cost
            )

            # -----------------------------------
            # NET RETURN
            # -----------------------------------

            net_return = (
                saleable_revenue
                - total_cost
            )

            # -----------------------------------
            # ANNUALIZED RETURN
            # -----------------------------------

            annual_cycles = (
                12 / holding_months
                if holding_months > 0
                else 0
            )

            annual_return = (
                net_return
                * annual_cycles
            )

            # -----------------------------------
            # ROI
            # -----------------------------------

            roi = (
                annual_return
                / total_infrastructure_cost
                * 100
                if total_infrastructure_cost > 0
                else 0
            )

            # -----------------------------------
            # PAYBACK
            # -----------------------------------

            payback = (
                total_infrastructure_cost
                / annual_return
                if annual_return > 0
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
                    "Electricity Cost",
                    f"₹{electricity_cost:,.0f}"
                )

            with col3:

                st.metric(
                    "Estimated Net Return",
                    f"₹{net_return:,.0f}"
                )

            with col4:

                st.metric(
                    "Estimated ROI",
                    f"{roi:.1f}%"
                )

            col1, col2, col3 = st.columns(3)

            with col1:

                st.metric(
                    "Annualized Return",
                    f"₹{annual_return:,.0f}"
                )

            with col2:

                st.metric(
                    "Estimated Payback",
                    f"{payback:.1f} years"
                )

            with col3:

                st.metric(
                    "Electricity / MT",
                    f"₹{electricity_cost / effective_capacity:,.0f}"
                    if effective_capacity > 0
                    else "₹0"
                )

            st.caption(
                "Scenario outputs are modeled estimates and depend on "
                "the selected operating assumptions. Actual returns "
                "will vary with occupancy, operating costs, market "
                "conditions, financing, maintenance and other "
                "real-world factors."
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
