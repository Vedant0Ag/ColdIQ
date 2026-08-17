create view vw_market_metrics as
with ranked as (
select
commodity,commodity_id,variety,district,district_id,state,modal_price,arrival_date,
row_number() over(partition by commodity,variety,district order by modal_price) as rn,
count(*) over(partition by commodity,variety,district) as cnt
from daily_prices),

median_prices as (
select commodity,commodity_id,variety,district,district_id,state,
avg(modal_price) as median_price
from ranked
where rn in (floor((cnt+1)/2),floor((cnt+2)/2))
group by commodity,commodity_id,variety,district,district_id,state),

market_stats as (
select commodity,commodity_id,variety,district,district_id,state,
round(avg(modal_price),2) as avg_price, round(stddev(modal_price),2) as std_price, round(min(modal_price),2) as min_price,round(max(modal_price),2) as max_price,
count(*) as observations, count(distinct arrival_date) as trading_days, count(distinct month(arrival_date)) as active_months
from daily_prices
group by commodity,commodity_id,variety,district,district_id,state)

select
m.commodity,m.commodity_id,m.variety,m.state,m.district,m.district_id,
round(m.median_price,2) as median_price,
s.avg_price, s.std_price,
round(s.std_price/nullif(s.avg_price,0),4) as coefficient_of_variation,
s.min_price, s.max_price,
round(s.max_price-s.min_price,2) as price_range,
s.observations,s.trading_days,
round(s.trading_days/(datediff((select max(arrival_date) from daily_prices),(select min(arrival_date) from daily_prices))+1),4) as market_reliability,
s.active_months,
round(s.observations/nullif(s.active_months,0),2) as avg_records_per_month
from median_prices m
join market_stats s on m.commodity=s.commodity and m.variety=s.variety and m.district_id=s.district_id;

select * from vw_market_metrics;


/*--------------------------------------------------------------------------------------*/


create view vw_production_metrics as

with yearly_production as (
select
commodity,
state,
year,
sum(production) as total_production,
avg(productivity) as avg_productivity
from production
group by commodity,state,year
),

growth as (
select *,
lag(total_production) over(partition by commodity,state order by year) as previous_production
from yearly_production
),

growth_rate as (
select
commodity,
state,
year,
total_production,
avg_productivity,
case
when previous_production is null or previous_production=0 then null
else ((total_production-previous_production)/previous_production)*100
end as growth_rate
from growth
),

summary as (
select
commodity,
state,
sum(total_production) as production,
avg(avg_productivity) as productivity,
round(avg(growth_rate),2) as avg_growth_rate
from growth_rate
group by commodity,state
),

share as (
select *,
production/sum(production) over(partition by commodity)*100 as production_share,
dense_rank() over(partition by commodity order by production desc) as production_rank,
ntile(10) over(partition by commodity order by production desc) as production_decile
from summary
)

select
commodity,
state,
round(production,2) as total_production,
round(productivity,2) as avg_productivity,
round(production_share,2) as production_share,
production_rank,
production_decile,
round(avg_growth_rate,2) as avg_growth_rate,
case
when avg_growth_rate>10 then 'Rapid Growth'
when avg_growth_rate>2 then 'Growing'
when avg_growth_rate<-10 then 'Rapid Decline'
when avg_growth_rate<-2 then 'Declining'
else 'Stable'
end as production_trend
from share;


/*-----------------------------------------------------------------------------------*/

create view vw_route_metrics as
with route_base as (
select s.commodity,s.commodity_id,s.variety,
s.state as source_state,
s.district as source_district,
s.district_id as source_district_id,
d.state as destination_state,
d.district as destination_district,
d.district_id as destination_district_id,
s.median_price as buying_price,
d.median_price as selling_price,
t.approx_actual_distance,c.refrigerated_truck_required, c.Average_Shelf_Life_Days, c.average_spoilage_rate,
case
when c.refrigerated_truck_required='Yes' then 0.55
else 0.35
end as freight_rate
from transport t
join vw_market_metrics s
on t.source_district_id=s.district_id
join vw_market_metrics d
on t.destination_district_id=d.district_id
and s.commodity=d.commodity
and s.variety=d.variety
join commodity c
on s.commodity_id=c.commodity_id
where s.district_id<>d.district_id
)
select
commodity,commodity_id,variety,source_state,source_district,destination_state,destination_district,
round(buying_price,2) as buying_price,
round(selling_price,2) as selling_price,
round(selling_price-buying_price,2) as gross_margin,
round(approx_actual_distance,2) as distance_km,
round(approx_actual_distance/600,2) as transit_days,
refrigerated_truck_required,
freight_rate,
round(freight_rate*approx_actual_distance,2) as transport_cost,
average_shelf_life_days,
average_spoilage_rate,
round(buying_price*(average_spoilage_rate/100)*((approx_actual_distance/600)/average_shelf_life_days),2) as spoilage_loss, /*mileage=45km/hr*/
round(selling_price - buying_price-(freight_rate*approx_actual_distance)- (buying_price*(average_spoilage_rate/100)*((approx_actual_distance/600)/average_shelf_life_days)),2)
as expected_profit
from route_base;


create table route_metrics as select * from vw_route_metrics;
create table market_metrics as select * from vw_market_metrics;
create table production_metrics as select * from vw_production_metrics;

select * from route_metrics;

select count(*) from route_metrics;
select count(*) from production_metrics;
select count(*) from market_metrics;