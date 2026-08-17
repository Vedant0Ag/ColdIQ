/* Which commodity is the most expensive and which is the cheapest amongst all markets */
select Commodity_ID,Year(Arrival_Date) as D_year,avg(Modal_Price) from daily_prices group by Commodity_ID,D_year order by Commodity_ID,D_year;

/* Cheapest and most expensive commodity */
with Ranked as
(select Commodity, Modal_Price,
row_number() over (partition by Commodity order by Modal_Price) as rn,
count(*) over (partition by Commodity) as cnt
from daily_prices)
select Commodity,avg(Modal_Price) as Median_Price from Ranked
where rn in(floor((cnt+1)/2),floor((cnt+2)/2))
group by Commodity
order by Median_Price desc;

/*Minimum and maximum prices of each commodity excluding unforeseen price fluctuation */
with ranked as(
select Commodity, Modal_Price, row_number() over(partition by Commodity order by Modal_Price) as rk,
count(*) over(partition by Commodity)as cnt
from daily_prices)
select 
Commodity, min(Modal_Price) as Min_Price , max(Modal_Price) as Max_Price 
from ranked 
where rk between ceil(cnt*0.025) and floor(cnt*0.975)
group by Commodity order by Commodity;


/* Which state records the highest and the lowest prices for each commodity */
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


/* What is the price fluctuations of a commodity over months*/
with Ranked as
(select Commodity,month(Arrival_Date) as Month_No,Modal_Price,
row_number() over (partition by Commodity,month(Arrival_Date) order by Modal_Price) as rn,
count(*) over (partition by Commodity,month(Arrival_Date)) as cnt
from daily_prices)
select Commodity,Month_No,avg(Modal_Price) as Median_Price from Ranked
where rn in(floor((cnt+1)/2),floor((cnt+2)/2))
group by Commodity,Month_No;

/*11. Which commodity has consistently remained the highest-priced commodity in each state over the years?*/
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


/*-----------------
Price Analysis
1. Most expensive commodity (2022-26): Garlic (8080)
2. Cheapest commodity (2022-26): Potato (1400)
3. Highest and Lowest prices state: Some commodities like apples remained at lower prices in uttarakhand
4. Over the months some commodities show seasonal price increase while some remain constant throughout the year
5. Dominancy of a commodity in a state over years: Chilli remains dominant throughout the years in andaman and nicobar , apples in goa

--------------------*/

