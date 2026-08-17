use ColdIQ;
select * from production;
/* 1. Which states produce the most of each commodity */
with ranked as(
select Commodity, sum(Production) as Production_over_Years, State,
rank() over(partition by Commodity order by sum(Production) desc) as rk
from Production 
group by Commodity,State)
select Commodity, round(Production_over_Years,2) as Production_over_Years, State from ranked 
where rk<=3
order by Commodity, Production_over_Years desc;

/* Which commodities have increasing and decreasing production in india  */
with year_wise_prod as(
select Commodity, Year , sum(Production) as Total_Production 
from production 
group by Commodity,Year),
prev_prod as(
select * ,
lag(Total_Production) over(partition by Commodity order by Year) as previous_prod
from year_wise_prod),
growth as(
select Commodity,
((Total_Production-previous_prod)/previous_prod)*100 as growth_rate
from prev_prod 
where previous_prod is not Null),
avg_growth as(
select Commodity, round(avg(growth_rate),2) as avg_growth_rate from growth
group by commodity)
select Commodity, avg_growth_rate,case
when avg_growth_rate<0 then 'Decreasing'
when avg_growth_rate>2 then 'Increasing'
else 'Stable' end as Production_Trend
from avg_growth 
group by Commodity;


/* Production trend of each commodity across different states (Increasing / Stable / Decreasing). */
with year_wise_prod as(
select Commodity, Year , State, sum(Production) as Total_Production 
from production 
group by Commodity,Year,State),
prev_prod as(
select * ,
lag(Total_Production) over(partition by Commodity,State order by Year) as previous_prod
from year_wise_prod),
growth as(
select Commodity,State,
((Total_Production-previous_prod)/previous_prod)*100 as growth_rate
from prev_prod 
where previous_prod is not Null
and previous_prod <> 0),
avg_growth as(
select Commodity, State, round(avg(growth_rate),2) as avg_growth_rate from growth
group by commodity,State),
avg_production as (
select commodity,state,avg(Total_Production) as avg_production
from year_wise_prod
group by commodity,state
),

production_level as (
select *,ntile(10) over(partition by commodity order by avg_production desc) as production_group
from avg_production),
final_data as (
select g.commodity,
g.state,
g.avg_growth_rate,
p.avg_production,
p.production_group
from avg_growth g
join production_level p
on g.commodity=p.commodity
and g.state=p.state)
select Commodity,round(avg_production,2) as avg_production, State, avg_growth_rate,
case
    when production_group=1 then 'Very High'
    when production_group between 2 and 3 then 'High'
    when production_group between 4 and 5  then 'Medium'
    when production_group between 6 and 8  then 'Low'
    else 'Negligible'
end as production_level,

case
when avg_growth_rate<-5 and avg_growth_rate>-15 then 'Decreasing'
when avg_growth_rate>5  and avg_growth_rate<15 then 'Increasing'
when avg_growth_rate>15 then 'Increasing Rapidly'
when avg_growth_rate<-15 then 'Decreasing Rapidly'
else 'Stable' end as Production_Trend
from final_data
group by Commodity,State;


/* ---------------------yield------------------*/
/* 1. Which state have the most yeild of each commodity */
with ranked as(
select Commodity, sum(Productivity) as Productivity_over_Years, State,
rank() over(partition by Commodity order by sum(Productivity) desc) as rk
from Production 
group by Commodity,State)
select Commodity, round(Productivity_over_Years,2) as Productivity_over_Years, State from ranked 
where rk<=3
order by Commodity, Productivity_over_Years desc;


/* Productivity trend of each commodity across different states (Increasing / Stable / Decreasing). */
with year_wise_prod as(
select Commodity, Year , State, sum(Productivity) as Total_Productivity 
from production 
group by Commodity,Year,State),
prev_prod as(
select * ,
lag(Total_Productivity) over(partition by Commodity,State order by Year) as previous_prod
from year_wise_prod),
growth as(
select Commodity,State,
((Total_Productivity-previous_prod)/previous_prod)*100 as growth_rate
from prev_prod 
where previous_prod is not Null),
avg_growth as(
select Commodity, State, round(avg(growth_rate),2) as avg_growth_rate from growth
group by commodity,State),
avg_productivity as (
select commodity,state,avg(Total_Productivity) as avg_productivity
from year_wise_prod
group by commodity,state
),
productivity_level as (
select *,ntile(3) over(partition by commodity order by avg_productivity desc) as productivity_group
from avg_productivity),
final_data as (
select g.commodity,
g.state,
g.avg_growth_rate,
p.avg_productivity,
p.productivity_group
from avg_growth g
join productivity_level p
on g.commodity=p.commodity
and g.state=p.state)

select Commodity, State, round(avg_productivity,2) as avg_productivity, avg_growth_rate,
case
    when productivity_group=1 then 'High'
    when productivity_group=2 then 'Medium'
    else 'Low'
end as productivity_level,
case
when avg_growth_rate<-5 and avg_growth_rate>-15 then 'Decreasing'
when avg_growth_rate>5  and avg_growth_rate<15 then 'Increasing'
when avg_growth_rate>15 then 'Increasing Rapidly'
when avg_growth_rate<-15 then 'Decreasing Rapidly'
else 'Stable' end as Productivity_Trend
from final_data
group by Commodity,State;


/*  Which high-production states also have low prices -> Best procurement(purchasing),selling locations  ,2022-26 */
with avg_production as (
select commodity,
state,
round(avg(production),2) as avg_production
from production
group by commodity,state
),
commodity_total as (
select commodity,
sum(avg_production) as commodity_total_production
from avg_production
group by commodity
),
production_level as (
select p.*,
round((p.avg_production/c.commodity_total_production)*100,2) as production_share
from avg_production p
join commodity_total c
on p.commodity=c.commodity
),
ranked_price as (
select commodity,
state,
modal_price,
row_number() over(partition by commodity,state order by modal_price) as rn,
count(*) over(partition by commodity,state) as cnt
from daily_prices
),
median_price as (
select commodity,
state,
avg(modal_price) as median_modal_price
from ranked_price
where rn in (floor((cnt+1)/2),floor((cnt+2)/2))
group by commodity,state
),
price_level as (
select *,
ntile(3) over(partition by commodity order by median_modal_price desc) as price_group
from median_price
)
select p.commodity, p.state, p.avg_production,p.production_share,
case
when production_share>=15 then 'High'
when production_share>=5 then 'Medium'
else 'Low'
end as production_level,
round(m.median_modal_price,2) as median_modal_price,
case
when price_group=1 then 'High'
when price_group=2 then 'Medium'
else 'Low'
end as price_level,
case
when production_share>=15 and price_group=3 then 'Procurement Hub'
when production_share>=15 and price_group=1 then 'Premium Producer'
when production_share>=15 and price_group=2 then 'Moderate Opportunity'

when production_share>=5 and price_group=3 then 'Moderate Opportunity'
when production_share>=5 and price_group=2 then 'Balanced Market'
when production_share>=5 and price_group=1 then 'Moderate Opportunity'

when production_share<5 and price_group=1 then 'Selling Market'
when production_share<5 and price_group=2 then 'Moderate Opportunity'
when production_share<5 and price_group=3 then 'Avoid Market'
end as opportunity
from production_level p
join price_level m
on p.commodity=m.commodity
and p.state=m.state
order by commodity,avg_production desc;



/*  Which high-production states also have low prices -> Best procurement(purchasing),selling locations  ,2026 */
with t_production as (
select commodity,state,sum(production) as  total_production
from production
where Year=2024
group by commodity,state
),
commodity_total as (
select commodity,
sum(total_production) as commodity_total_production
from t_production
group by commodity
),
production_level as (
select p.*,
round((p.total_production/c.commodity_total_production)*100,2) as production_share
from t_production p
join commodity_total c
on p.commodity=c.commodity
),
ranked_price as (
select commodity,
state,
modal_price,
row_number() over(partition by commodity,state order by modal_price) as rn,
count(*) over(partition by commodity,state) as cnt
from daily_prices
where Year(Arrival_Date)=2024
),
median_price as (
select commodity,
state,
avg(modal_price) as median_modal_price
from ranked_price
where rn in (floor((cnt+1)/2),floor((cnt+2)/2))
group by commodity,state
),
price_level as (
select *,
ntile(3) over(partition by commodity order by median_modal_price desc) as price_group
from median_price
)
select p.commodity, p.state, p.total_production,p.production_share,
case
when production_share>=15 then 'High'
when production_share>=5 then 'Medium'
else 'Low'
end as production_level,
round(m.median_modal_price,2) as median_modal_price,
case
when price_group=1 then 'High'
when price_group=2 then 'Medium'
else 'Low'
end as price_level,
case
when production_share>=15 and price_group=3 then 'Procurement Hub'
when production_share>=15 and price_group=1 then 'Premium Producer'
when production_share>=15 and price_group=2 then 'Moderate Opportunity'

when production_share>=5 and price_group=3 then 'Moderate Opportunity'
when production_share>=5 and price_group=2 then 'Balanced Market'
when production_share>=5 and price_group=1 then 'Moderate Opportunity'

when production_share<5 and price_group=1 then 'Selling Market'
when production_share<5 and price_group=2 then 'Moderate Opportunity'
when production_share<5 and price_group=3 then 'Avoid Market'
end as opportunity
from production_level p
join price_level m
on p.commodity=m.commodity
and p.state=m.state
order by commodity,total_production desc;


/*---------------------
PRODUCTION ANALYSIS
1. States with highest production: apples(Jammu and Kashmir), Cabbage(West Bengal), etc
2. Decreasing Production: Apples,Pomegranate, onion, orange, papaya
3. stable Production: Pineapples,Tomato
4. Rest Increasing in Production
5. High productivity areas: Apples(Kerala), Cabbage(Tamil Nadu), etc


------------------------*/
