create or replace view vw_interstate_opportunities as with
/* ============================================================
1. PRODUCTION LEVEL
============================================================ */
production_state as (
select
Commodity,State,
avg(Production_Share) as Production_Share,
avg(Avg_Productivity) as Avg_Productivity,
avg(Production_Decile) as Production_Decile,
avg(Production_Rank) as Production_Rank,
case
when avg(Production_Decile) <= 1 then 'Very High'
when avg(Production_Decile) <= 3 then 'High'
when avg(Production_Decile) <= 5 then 'Medium'
when avg(Production_Decile) <= 8 then 'Low'
else 'Negligible'
end as Production_Level
from production_metrics
group by Commodity, State),

/* ============================================================
2. ONLY KEEP VALID PRODUCTION DIRECTIONS
source = high/medium production
destination = low/negligible production
============================================================ */

valid_production_routes as (
select
r.Commodity, r.Commodity_ID, r.Variety, r.Source_State, r.Destination_State,
sp.Production_Share as Source_Production_Share,
sp.Avg_Productivity as Source_Avg_Productivity,
sp.Production_Decile as Source_Production_Decile,
sp.Production_Rank as Source_Production_Rank,
sp.Production_Level as Source_Production_Level,
dp.Production_Share as Destination_Production_Share,
dp.Production_Decile as Destination_Production_Decile,
dp.Production_Level as Destination_Production_Level,
min(r.Distance_KM) as Distance_KM,
min(r.Transit_Days) as Transit_Days,
avg(r.Average_Shelf_Life_Days) as Average_Shelf_Life_Days,
avg(r.Average_Spoilage_Rate) as Average_Spoilage_Rate
from route_metrics r
join production_state sp
on r.Commodity = sp.Commodity
and r.Source_State = sp.State
join production_state dp
on r.Commodity = dp.Commodity
and r.Destination_State = dp.State
where r.Source_State <> r.Destination_State
and sp.Production_Level in ('Very High','High','Medium')
and dp.Production_Level in ('Low','Negligible')
and r.Distance_KM > 0
and r.Transit_Days > 0
group by
r.Commodity,
r.Commodity_ID,
r.Variety,
r.Source_State,
r.Destination_State,
sp.Production_Share,
sp.Avg_Productivity,
sp.Production_Decile,
sp.Production_Rank,
sp.Production_Level,
dp.Production_Share,
dp.Production_Decile,
dp.Production_Level),

/* ============================================================
3. MONTHLY STATE PRICE
daily_prices are ₹/quintal.
x10 converts to ₹/MT.

We use a state-month aggregate instead of expensive
row_number median calculation.
============================================================ */

monthly_state_prices as (
select 
Commodity, Commodity_ID, Variety, State,
year(Arrival_Date) as Price_Year,
month(Arrival_Date) as Price_Month,
avg(Modal_Price) * 10 as Price_MT,
count(*) as Observations
from daily_prices
where Modal_Price is not null
and Modal_Price > 0
group by Commodity, Commodity_ID, Variety, State, year(Arrival_Date), month(Arrival_Date)),

/* ============================================================
4. MATCH SOURCE AND DESTINATION PRICES
same commodity + variety + year + month
============================================================ */

price_opportunities as (
select
r.*, s.Price_Year,s.Price_Month,
s.Price_MT as Buying_Price_MT,
d.Price_MT as Selling_Price_MT,
s.Observations as Source_Price_Observations,
d.Observations as Destination_Price_Observations
from valid_production_routes r
join monthly_state_prices s
on r.Commodity_ID = s.Commodity_ID
and r.Variety = s.Variety
and r.Source_State = s.State
join monthly_state_prices d
on r.Commodity_ID = d.Commodity_ID
and r.Variety = d.Variety
and r.Destination_State = d.State
and s.Price_Year = d.Price_Year
and s.Price_Month = d.Price_Month
where d.Price_MT > s.Price_MT
),

/* ============================================================
5. MARKET RELIABILITY
============================================================ */
market_state as (
select
Commodity,
Variety,
State,
avg(Market_Reliability) as Market_Reliability,
avg(Coefficient_of_Variation) as Price_CV,
avg(Active_Months) as Active_Months,
avg(Observations) as Market_Observations
from market_metrics
group by Commodity,Variety,State),

/* ============================================================
6. ECONOMICS
freight:
₹4.50/quintal/km
x10 = ₹45/MT/km
============================================================ */
economics as (
select
p.*,
round(p.Distance_KM * 45,2) as Transport_Cost_Per_MT,
round(p.Selling_Price_MT - p.Buying_Price_MT,2) as Gross_Price_Gain_Per_MT,
round((p.Selling_Price_MT - p.Buying_Price_MT)/nullif(p.Buying_Price_MT,0) * 100,2) as Gross_Price_Gain_Percent,
least(1, (p.Average_Spoilage_Rate / 100) * (p.Transit_Days / nullif(p.Average_Shelf_Life_Days,0))) as Transit_Spoilage_Fraction
from price_opportunities p),

/* ============================================================
7. NET TRANSPORT PROFIT
============================================================ */
net_profit as (
select
e.*,
round(e.Selling_Price_MT * (1 - e.Transit_Spoilage_Fraction), 2) as Saleable_Revenue_Per_MT,
round((e.Selling_Price_MT * (1 - e.Transit_Spoilage_Fraction)) - e.Buying_Price_MT - e.Transport_Cost_Per_MT,2) as Net_Transport_Profit_Per_MT
from economics e),

/* ============================================================
8. ADD MARKET DATA
============================================================ */
market_data as (
select
n.*,
sm.Market_Reliability as Source_Market_Reliability,
sm.Price_CV as Source_Price_CV,
sm.Active_Months as Source_Active_Months,
sm.Market_Observations as Source_Market_Observations,
dm.Market_Reliability as Destination_Market_Reliability,
dm.Price_CV as Destination_Price_CV,
dm.Active_Months as Destination_Active_Months,
dm.Market_Observations as Destination_Market_Observations
from net_profit n
left join market_state sm
on n.Commodity = sm.Commodity
and n.Variety = sm.Variety
and n.Source_State = sm.State
left join market_state dm
on n.Commodity = dm.Commodity
and n.Variety = dm.Variety
and n.Destination_State = dm.State),

/* ============================================================
9. SCORE COMPONENTS
============================================================ */
scored as (
select
m.*,
case
when m.Net_Transport_Profit_Per_MT <= 0 then 0
when m.Net_Transport_Profit_Per_MT /
nullif(m.Buying_Price_MT,0) >= 0.30 then 100
when m.Net_Transport_Profit_Per_MT /
nullif(m.Buying_Price_MT,0) >= 0.20 then 80
when m.Net_Transport_Profit_Per_MT /
nullif(m.Buying_Price_MT,0) >= 0.10 then 60
when m.Net_Transport_Profit_Per_MT /
nullif(m.Buying_Price_MT,0) >= 0.05 then 40
else 20
end as Margin_Score,
case
when m.Transit_Spoilage_Fraction > 0.30 then 0
when m.Transit_Spoilage_Fraction > 0.20 then 25
when m.Transit_Spoilage_Fraction > 0.10 then 50
when m.Transit_Spoilage_Fraction > 0.05 then 75
else 100
end as Spoilage_Score,
least(100,(coalesce(m.Source_Market_Reliability,0) + coalesce(m.Destination_Market_Reliability,0)) / 2 * 100) as Market_Reliability_Score,
case
when greatest(coalesce(m.Source_Price_CV,0), coalesce(m.Destination_Price_CV,0)) <= 0.15 then 100
when greatest(coalesce(m.Source_Price_CV,0), coalesce(m.Destination_Price_CV,0)) <= 0.25 then 80
when greatest(coalesce(m.Source_Price_CV,0), coalesce(m.Destination_Price_CV,0)) <= 0.40 then 60
when greatest(coalesce(m.Source_Price_CV,0), coalesce(m.Destination_Price_CV,0)) <= 0.60 then 40
else 20
end as Price_Stability_Score,
case
when m.Source_Production_Level = 'Very High' then 100
when m.Source_Production_Level = 'High' then 85
when m.Source_Production_Level = 'Medium' then 70
else 0
end as Source_Supply_Score
from market_data m),

/* ============================================================
10. FINAL SCORE
============================================================ */

final_score as (
select
s.*,
round(s.Margin_Score * 0.35 + s.Spoilage_Score * 0.20 + s.Market_Reliability_Score * 0.20 + s.Price_Stability_Score * 0.10 + s.Source_Supply_Score * 0.15,2) as Transport_Opportunity_Score
from scored s)

/* ============================================================
11. FINAL OUTPUT
============================================================ */

select
Commodity,Commodity_ID,Variety,Source_State,Source_Production_Level,Destination_State,Destination_Production_Level,Price_Year,Price_Month,
round(Buying_Price_MT,2) as Buying_Price_Per_MT,
round(Selling_Price_MT,2) as Selling_Price_Per_MT,
round(Gross_Price_Gain_Per_MT,2) as Gross_Price_Gain_Per_MT,
round(Gross_Price_Gain_Percent,2) as Gross_Price_Gain_Percent,
round(Distance_KM,2) as Distance_KM,
round(Transit_Days,2) as Transit_Days,
round(Transport_Cost_Per_MT,2) as Transport_Cost_Per_MT,
round(Transit_Spoilage_Fraction * 100,2) as Transit_Spoilage_Percent,
round(Saleable_Revenue_Per_MT,2) as Saleable_Revenue_Per_MT,
round(Net_Transport_Profit_Per_MT,2) as Net_Transport_Profit_Per_MT,
round(Source_Production_Share,2) as Source_Production_Share,
round(Destination_Production_Share,2) as Destination_Production_Share,
round(Source_Avg_Productivity,2) as Source_Avg_Productivity,
round(Source_Production_Decile,2) as Source_Production_Decile,
round(Destination_Production_Decile,2) as Destination_Production_Decile,
round(Source_Production_Rank,2) as Source_Production_Rank,
round(Source_Market_Reliability,3) as Source_Market_Reliability,
round(Destination_Market_Reliability,3) as Destination_Market_Reliability,
round(Source_Price_CV,3) as Source_Price_CV,
round(Destination_Price_CV,3) as Destination_Price_CV,
round(Source_Active_Months,2) as Source_Active_Months,
round(Destination_Active_Months,2) as Destination_Active_Months,
Source_Price_Observations,
Destination_Price_Observations,
Margin_Score,
Spoilage_Score,
Market_Reliability_Score,
Price_Stability_Score,
Source_Supply_Score,
Transport_Opportunity_Score,
case
when Net_Transport_Profit_Per_MT <= 0 then 'Avoid'
when Transit_Spoilage_Fraction > 0.30 then 'Avoid'
when Source_Market_Reliability < 0.50
or Destination_Market_Reliability < 0.50 then 'Avoid'
when Transport_Opportunity_Score >= 80 then 'Strong Transport Opportunity'
when Transport_Opportunity_Score >= 65 then 'Good Transport Opportunity'
when Transport_Opportunity_Score >= 50 then 'Moderate Transport Opportunity'
else 'Weak Transport Opportunity'
end as Opportunity,
case
when Net_Transport_Profit_Per_MT <= 0
then 'Price advantage is insufficient after freight and spoilage'
when Transit_Spoilage_Fraction > 0.30
then 'Transit spoilage is commercially excessive'
when Source_Market_Reliability < 0.50
or Destination_Market_Reliability < 0.50
then 'Market reliability is insufficient'
when Source_Production_Level = 'Medium'
then 'Medium-production state supplying a low-production state'
when Source_Production_Level in ('Very High','High')
then 'High-production state supplying a low-production state'
else 'Limited economic advantage'
end as Primary_Reason
from final_score;

create table interstate_opportunity as
select * from vw_interstate_opportunities;
select * from interstate_opportunity
where opportunity='Strong Transport Opportunity';

describe interstate_opportunity;
select count(distinct commodity) from  interstate_opportunity;