/* PRICE: What is the price fluctuations of a commodity over months*/
create view monthwise_price_commodity as
with Ranked as
(select Commodity,month(Arrival_Date) as Month_No,Modal_Price,
row_number() over (partition by Commodity,month(Arrival_Date) order by Modal_Price) as rn,
count(*) over (partition by Commodity,month(Arrival_Date)) as cnt
from daily_prices)
select Commodity,Month_No,avg(Modal_Price) as Median_Price from Ranked
where rn in(floor((cnt+1)/2),floor((cnt+2)/2))
group by Commodity,Month_No;


/*PRICE:  Which commodity has consistently remained the highest-priced commodity in each state over the years?*/
create view commodity_dominancy_by_state as
with Ranked as
(select Commodity,Year(Arrival_Date) as In_Year, State, Modal_Price,
row_number() over (partition by State,Year(Arrival_Date),Commodity order by Modal_Price) as rn,
count(*) over (partition by State,Year(Arrival_Date),Commodity) as cnt
from daily_prices),
median_prices as(
select Commodity,In_Year, State ,avg(Modal_Price) as Median_Price from Ranked
where rn in(floor((cnt+1)/2),floor((cnt+2)/2)) 
group by State,In_Year,Commodity), 
final_rank as(
select *, dense_rank() over(partition by State,In_Year order by Median_Price desc) as highest_rank 
from median_prices),
yearly_dominance as(
select State, In_Year, Commodity,Median_Price from final_rank
where highest_rank=1),
overall_dominance as(
select State,Commodity,count(*) as Years_dominant,avg(Median_Price) as Avg_Median_Price
from yearly_dominance
group by State,Commodity) 
select  State , Commodity,Years_dominant, Avg_Median_Price from overall_dominance
order by State;

/* PRICE:  Which state records the highest and the lowest prices for each commodity */
create view high_low_price_state_commodity as
with Ranked as
(select Commodity,Year(Arrival_Date) as In_Year, State, Modal_Price,
row_number() over (partition by Commodity, Year(Arrival_Date),State order by Modal_Price) as rn,
count(*) over (partition by Commodity,Year(Arrival_Date), State) as cnt
from daily_prices),
median_prices as(
select Commodity,In_Year, State ,avg(Modal_Price) as Median_Price from Ranked
where rn in(floor((cnt+1)/2),floor((cnt+2)/2)) 
group by Commodity,In_Year,State), 
final_rank as(
select *, dense_rank() over(partition by Commodity,In_Year order by Median_Price desc) as highest_rank,
dense_rank() over(partition by Commodity,In_Year order by Median_Price asc)  as lowest_rank
from median_prices)
select Commodity, In_Year, State , Median_Price,
case
when highest_rank=1 then 'highest'
when lowest_rank=1 then 'lowest'
end as price_level
from final_rank
where highest_rank=1 or lowest_rank=1
order by Commodity,In_Year ,price_level desc;

-- -------------------------------------------------------------------------------------------------------------------------------------

/* PRODUCTION Production trend of each commodity across different states (Increasing / Stable / Decreasing). */
create or replace view production_growth_by_state as
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
    when production_group=1 then 'High'
    when production_group=2 then 'Medium'
    else 'Low'
end as production_level,
case
when avg_growth_rate<-5 and avg_growth_rate>-15 then 'Decreasing'
when avg_growth_rate>5  and avg_growth_rate<15 then 'Increasing'
when avg_growth_rate>15 then 'Increasing Rapidly'
when avg_growth_rate<-15 then 'Decreasing Rapidly'
else 'Stable' end as Production_Trend
from final_data
group by Commodity,State;

/* PRODUCTION:  Which high-production states also have low prices -> Best procurement(purchasing),selling locations  ,2022-26 */
create view price_production_commodity as
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


-- ----------------------------------------------------------------------------------------------------------------------------------------

/* Which states have the most expensive and cheapest industrial electricity */
create view state_wise_electricity as
with state_load_price as(
select State, round(avg(Price_KWh),2) as Avg_Electricity_Price , Load_KW 
from energy
group by Load_KW,State),
state_avg as(
select State,round(avg(Price_KWh),2) as State_Avg_Price from energy group by State)
select 
l.State, l.Avg_Electricity_Price,l.Load_KW,
s.State_Avg_Price 
from state_load_price l 
join state_avg s
on l.State=s.State
order by state_avg_price;


select count(*) from commodity_dominancy_by_state;
select count(*) from high_low_price_state_commodity;
select count(*) from monthwise_price_commodity;
select count(*) from price_production_commodity;
select count(*) from production_growth_by_state;
select count(*) from state_wise_electricity;

create table commodity_dom_state as
select * from commodity_dominancy_by_state;

create table commodity_price_state as
select * from high_low_price_state_commodity;

create table commodity_price_month as
select * from monthwise_price_commodity;

create table commodity_price_production as
select * from price_production_commodity;

create table production_growth_state as
select * from production_growth_by_state;

create table electricity_state as
select * from state_wise_electricity;
