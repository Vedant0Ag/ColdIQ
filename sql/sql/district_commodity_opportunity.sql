create or replace view vw_district_commodity_investment as
with
params as (
select 5000 as facility_capacity_mt,500 as facility_load_kw
),

/* 1. Convert commodity storage recommendations into maximum feasible days */
commodity_data as (
select
Commodity_ID,
Commodity_Name,
Commodity_Category,
Min_Shelf_Life_Days,
Max_Shelf_Life_Days,
Average_Shelf_Life_Days,
Average_Spoilage_Rate,
Refrigerated_Truck_Required
from commodity
),

/* 2. Create feasible buy-sell price cycles */
price_pairs as (
select
b.Commodity,
b.Commodity_ID,
b.State,
b.District,
b.Median_Price_Per_MT as Buy_Price_Per_MT,
s.Median_Price_Per_MT as Sell_Price_Per_MT,
b.Price_Year as Buy_Year,
b.Price_Month as Buy_Month,
s.Price_Year as Sell_Year,
s.Price_Month as Sell_Month,
c.Min_Shelf_Life_Days,
c.Max_Shelf_Life_Days,
c.Average_Shelf_Life_Days,
(
(s.Price_Year*12+s.Price_Month)
-
(b.Price_Year*12+b.Price_Month)
) as Holding_Months,
row_number() over(
partition by b.Commodity_ID,b.State,b.District
order by
(
(s.Median_Price_Per_MT-b.Median_Price_Per_MT)
/
nullif(b.Median_Price_Per_MT,0)
) desc
) as rn
from monthly_district_prices b
join monthly_district_prices s
on b.Commodity_ID=s.Commodity_ID
and b.State=s.State
and b.District=s.District
and (
(s.Price_Year*12+s.Price_Month)
-
(b.Price_Year*12+b.Price_Month)
)>0
join commodity_data c
on b.Commodity_ID=c.Commodity_ID
where b.Median_Price_Per_MT>0
and s.Median_Price_Per_MT>b.Median_Price_Per_MT
and ((s.Price_Year*12+s.Price_Month) - (b.Price_Year*12+b.Price_Month))* 30 <= c.Max_Shelf_Life_Days),

/* 3. Keep the best realistic price cycle for each district commodity */
best_cycle as (
select *
from price_pairs
where rn=1
),

/* 4. Consolidate market metrics to one row per district commodity */
market_data as (
select
Commodity_ID,
State,
District,
sum(observations) as Observations,
sum(coefficient_of_variation*observations)/nullif(sum(observations),0) as Price_CV,
sum(market_reliability*observations)/nullif(sum(observations),0) as Market_Reliability
from market_metrics
where observations>=100
group by
Commodity_ID,
State,
District
),

/* 5. Consolidate production to one row per commodity and state */
production_data as (
select
Commodity,
State,
max(production_decile) as Production_Decile
from production_metrics
group by
Commodity,
State
),

/* 6. Match electricity using the selected load tier */
energy_data as (
select
e.State,
e.Price_KWh,
e.Load_KW
from energy e
join params p
on e.Load_KW=p.facility_load_kw
),

/* 7. Select one infrastructure configuration for the common 5000 MT scenario */
infrastructure_data as (
select
i.Technology,
i.Estimated_Total_Cost_Per_MT
from infrastructure i
join params p
on p.facility_capacity_mt between i.Min_Capacity_MT and i.Max_Capacity_MT
order by i.Estimated_Total_Cost_Per_MT
limit 1
),

/* 8. Combine the decision factors */
base as (
select
b.Commodity,
b.Commodity_ID,
b.State,
b.District,
b.Buy_Price_Per_MT,
b.Sell_Price_Per_MT,
b.Buy_Month,
b.Sell_Month,
b.Holding_Months,
b.Min_Shelf_Life_Days,
b.Max_Shelf_Life_Days,
b.Average_Shelf_Life_Days,
round(
(b.Sell_Price_Per_MT-b.Buy_Price_Per_MT)
/
nullif(b.Buy_Price_Per_MT,0)*100,
2
) as Price_Gain_Percent,
c.Average_Spoilage_Rate,
m.Price_CV,
m.Market_Reliability,
p.Production_Decile,
coalesce(e.Price_KWh,0) as Price_KWh,
coalesce(e.Load_KW,0) as Load_KW,
i.Estimated_Total_Cost_Per_MT as Infrastructure_Cost_Per_MT,
35 as Subsidy_Percent
from best_cycle b
join commodity_data c
on b.Commodity_ID=c.Commodity_ID
join market_data m
on b.Commodity_ID=m.Commodity_ID
and b.State=m.State
and b.District=m.District
left join production_data p
on b.Commodity=p.Commodity
and b.State=p.State
left join energy_data e
on b.State=e.State
cross join infrastructure_data i
where b.rn=1
),

/* 9. Calculate spoilage and storage feasibility */
economics as (
select
b.*,
least(
1,
(coalesce(b.Average_Spoilage_Rate,0)/100)
*
(
b.Holding_Months*30
/
nullif(b.Average_Shelf_Life_Days,1)
)
) as Storage_Spoilage,
case
when b.Holding_Months*30<=b.Min_Shelf_Life_Days then 100
when b.Holding_Months*30<=b.Max_Shelf_Life_Days then 70
else 0
end as Storage_Timing_Score,
b.Sell_Price_Per_MT*
(
1-
least(
1,
(coalesce(b.Average_Spoilage_Rate,0)/100)
*
(
b.Holding_Months*30
/
nullif(b.Average_Shelf_Life_Days,1)
)
)
) as Saleable_Revenue_Per_MT
from base b
),

/* 10. Calculate electricity, subsidy and net economics */
returns as (
select
e.*,
(e.Infrastructure_Cost_Per_MT*e.Subsidy_Percent/100) as Subsidy_Per_MT,
(e.Price_KWh* e.Load_KW*24*30* e.Holding_Months /nullif(5000,0)) as Electricity_Cost_Per_MT
from economics e
),

net as (
select
r.*,
(
r.Saleable_Revenue_Per_MT
-r.Buy_Price_Per_MT
-r.Electricity_Cost_Per_MT
-r.Infrastructure_Cost_Per_MT
+r.Subsidy_Per_MT
) as Net_Return_Per_MT
from returns r
),

/* 11. Calculate ROI and payback */
investment as (
select
n.*,
case
when n.Net_Return_Per_MT>0 then
(
n.Net_Return_Per_MT
/
nullif(
n.Infrastructure_Cost_Per_MT-n.Subsidy_Per_MT,
0
)
)*100
else 0
end as ROI_Percent,
case
when n.Net_Return_Per_MT>0 then
(
n.Infrastructure_Cost_Per_MT-n.Subsidy_Per_MT
)
/
n.Net_Return_Per_MT
else 999
end as Payback_Years
from net n
),

/* 12. Score the economic opportunity */
scored as (
select
i.*,

case
when i.Net_Return_Per_MT<=0 then 0
when i.Net_Return_Per_MT>=100000 then 100
when i.Net_Return_Per_MT>=75000 then 90
when i.Net_Return_Per_MT>=50000 then 80
when i.Net_Return_Per_MT>=30000 then 70
when i.Net_Return_Per_MT>=15000 then 55
else 35
end as Profit_Score,

case
when i.Payback_Years<=4 then 100
when i.Payback_Years<=5 then 90
when i.Payback_Years<=6 then 80
when i.Payback_Years<=7 then 70
when i.Payback_Years<=10 then 50
else 20
end as Payback_Score,

case
when i.Market_Reliability>=0.90 then 100
when i.Market_Reliability>=0.80 then 90
when i.Market_Reliability>=0.70 then 80
when i.Market_Reliability>=0.60 then 65
else 50
end as Market_Score,

case
when i.Production_Decile<=1 then 100
when i.Production_Decile<=3 then 90
when i.Production_Decile<=5 then 75
when i.Production_Decile<=8 then 50
else 25
end as Production_Score,

case
when i.Price_CV<=0.15 then 100
when i.Price_CV<=0.25 then 85
when i.Price_CV<=0.40 then 70
when i.Price_CV<=0.60 then 50
else 25
end as Stability_Score

from investment i
),

/* 13. Final investment score */
final_score as (
select
s.*,
round(
s.Profit_Score*0.30
+s.Storage_Timing_Score*0.25
+s.Payback_Score*0.20
+s.Market_Score*0.10
+s.Production_Score*0.10
+s.Stability_Score*0.05,
2
) as Investment_Score
from scored s
),

/* 14. Rank distinct commodities within each district */
ranked as (
select
f.*,
row_number() over(
partition by f.State,f.District
order by
case
when f.Net_Return_Per_MT<=0 then 1
when f.Storage_Timing_Score=0 then 1
else 0
end,
f.Investment_Score desc,
f.Net_Return_Per_MT desc,
f.Payback_Years asc
) as Commodity_Rank
from final_score f
)

/* 15. Final compact output */
select
State,
District,
Commodity,
Commodity_ID,
round(Buy_Price_Per_MT,2) as Buy_Price_Per_MT,
round(Sell_Price_Per_MT,2) as Sell_Price_Per_MT,
Buy_Month,
Sell_Month,
Holding_Months,
round(Price_Gain_Percent,2) as Price_Gain_Percent,
round(Storage_Spoilage*100,2) as Storage_Spoilage_Percent,
round(Electricity_Cost_Per_MT,2) as Electricity_Cost_Per_MT,
round(Infrastructure_Cost_Per_MT,2) as Infrastructure_Cost_Per_MT,
35 as Subsidy_Percent,
round(Net_Return_Per_MT,2) as Net_Return_Per_MT,
round(ROI_Percent,2) as ROI_Percent,
round(Payback_Years,2) as Payback_Years,
Price_KWh,
round(Investment_Score,2) as Investment_Score,
Commodity_Rank,
case
when Net_Return_Per_MT<=0 then 'Do Not Invest'
when Storage_Timing_Score=0 then 'Storage Window Mismatch'
when Payback_Years>7 then 'High Payback Risk'
when Investment_Score>=80 then 'Strong Investment'
when Investment_Score>=65 then 'Good Investment'
when Investment_Score>=50 then 'Moderate Investment'
else 'Weak Investment'
end as Investment_Decision
from ranked
where Commodity_Rank<=5;

create table commodity_distric_investment as
select * from vw_district_commodity_investment;

select * from commodity_distric_investment;
use ColdIQ;

describe commodity_distric_investment;
