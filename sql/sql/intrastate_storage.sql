create or replace view vw_intrastate_storage_locations as

with ranked_prices as (
select
Commodity,
Commodity_ID,
Variety,
State,
District,
Price_Year,
Price_Month,
Median_Price_Per_MT,
row_number() over(
partition by Commodity_ID,Variety,State,District
order by Median_Price_Per_MT
) as low_rank,
row_number() over(
partition by Commodity_ID,Variety,State,District
order by Median_Price_Per_MT desc) as high_rank
from monthly_district_prices
where Median_Price_Per_MT > 0
),

-- used top and bottom 3 months to segregate seasonal months
price_profile as (
select
Commodity,
Commodity_ID,
Variety,
State,
District,
count(*) as Active_Months,
round(avg(case when low_rank <= 3 then Median_Price_Per_MT end),2) as Low_Season_Price_Per_MT, -- price during buying period
round(avg(case when high_rank <= 3 then Median_Price_Per_MT end),2) as High_Season_Price_Per_MT, -- price during selling period
round((avg(case when high_rank <= 3 then Median_Price_Per_MT end) - avg(case when low_rank <= 3 then Median_Price_Per_MT end))
/nullif(avg(case when low_rank <= 3 then Median_Price_Per_MT end),0)*100, 2) as Seasonal_Price_Gain_Percent  -- seasonal gain percent
from ranked_prices
group by
Commodity,
Commodity_ID,
Variety,
State,
District
),

market as (
select
Commodity,
Variety,
State,
District,
avg(Market_Reliability) as Market_Reliability,
avg(Coefficient_of_Variation) as Price_CV,
avg(Active_Months) as Market_Active_Months,
avg(Observations) as Market_Observations
from market_metrics
group by
Commodity,
Variety,
State,
District
),

production as (
select
Commodity,
State,
case
when avg(Production_Decile) <= 1 then 'Very High'
when avg(Production_Decile) <= 3 then 'High'
when avg(Production_Decile) <= 5 then 'Medium'
when avg(Production_Decile) <= 8 then 'Low'
else 'Negligible'
end as Production_Level
from production_metrics
group by
Commodity,
State
),

eligible as (
select
p.Commodity,
p.Commodity_ID,
p.Variety,
p.State,
p.District,
p.Active_Months,
p.Low_Season_Price_Per_MT,
p.High_Season_Price_Per_MT,
p.Seasonal_Price_Gain_Percent,
coalesce(m.Market_Reliability,0) as Market_Reliability,
coalesce(m.Price_CV,1) as Price_CV,
coalesce(m.Market_Active_Months,0) as Market_Active_Months,
coalesce(m.Market_Observations,0) as Market_Observations,
coalesce(pr.Production_Level,'Unknown') as Production_Level
from price_profile p
left join market m
on p.Commodity = m.Commodity
and p.Variety = m.Variety
and p.State = m.State
and p.District = m.District
left join production pr
on p.Commodity = pr.Commodity
and p.State = pr.State
),

scored as (
select
e.*,
case
when e.Seasonal_Price_Gain_Percent >= 40 then 100
when e.Seasonal_Price_Gain_Percent >= 30 then 90
when e.Seasonal_Price_Gain_Percent >= 20 then 80
when e.Seasonal_Price_Gain_Percent >= 15 then 70
when e.Seasonal_Price_Gain_Percent >= 10 then 55
when e.Seasonal_Price_Gain_Percent >= 5 then 40
else 20
end as Seasonal_Score,
case
when e.Market_Observations<50 then 10
when e.Market_Observations<100 then 30
when e.Market_Reliability >= 0.90 then 100
when e.Market_Reliability >= 0.80 then 90
when e.Market_Reliability >= 0.70 then 80
when e.Market_Reliability >= 0.60 then 65
else 50
end as Reliability_Score,
case
when e.Active_Months<3 then 0
when e.Active_Months<6 then 30
when e.Price_CV <= 0.15 then 100
when e.Price_CV <= 0.25 then 85
when e.Price_CV <= 0.40 then 70
when e.Price_CV <= 0.60 then 50
else 25
end as Stability_Score,
case
when e.Production_Level = 'Very High' then 100
when e.Production_Level = 'High' then 90
when e.Production_Level = 'Medium' then 75
when e.Production_Level = 'Low' then 10
when e.Production_Level = 'Negligible' then 0
when e.Production_Level = 'Unknown' then 0
else 20
end as Production_Score
from eligible e
),

final_score as (
select
s.*,
case
when s.Active_Months<6 then 0
when s.Market_Observations<100 then 0
when s.Market_Reliability<0.50 then 0
when s.Production_Level not in ('Very High','High','Medium') then 0
else 1
end as Storage_Eligible,
round(s.Seasonal_Score * 0.45 + s.Reliability_Score * 0.25 + s.Stability_Score * 0.15 + s.Production_Score * 0.15,2) 
as Storage_Location_Score
from scored s
),

ranked as (
select
f.*,
row_number() over(
partition by f.Commodity,f.Variety,f.State
order by f.Storage_Location_Score desc
) as Storage_Location_Rank
from final_score f
)

select
Commodity,
Commodity_ID,
Variety,
State,
District,
Production_Level,
round(Low_Season_Price_Per_MT,2) as Low_Season_Price_Per_MT,
round(High_Season_Price_Per_MT,2) as High_Season_Price_Per_MT,
round(Seasonal_Price_Gain_Percent,2) as Seasonal_Price_Gain_Percent,
round(Market_Reliability,3) as Market_Reliability,
round(Price_CV,3) as Price_CV,
Storage_Location_Score,
Storage_Location_Rank,
case
when Storage_Eligible=0 then 'Avoid'
when Storage_Location_Score >= 80 then 'Strong Storage Location'
when Storage_Location_Score >= 65 then 'Good Storage Location'
when Storage_Location_Score >= 50 then 'Moderate Storage Location'
else 'Weak Storage Location'
end as Opportunity
from ranked;

create table intrastate_opportunity as
select * from vw_intrastate_storage_locations;

select Opportunity,count(*) from intrastate_opportunity group by opportunity;
select * from intrastate_opportunity where District='Rampur';