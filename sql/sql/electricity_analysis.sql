/* Which states have the most expensive and cheapest industrial electricity */
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



