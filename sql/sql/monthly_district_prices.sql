create table monthly_district_prices as
with ranked_prices as (
select
dp.Commodity,
dp.Commodity_ID,
dp.Variety,
dp.State,
dp.District,
year(dp.Arrival_Date) as Price_Year,
month(dp.Arrival_Date) as Price_Month,
dp.Modal_Price,
row_number() over(
partition by
dp.Commodity_ID,
dp.Variety,
dp.State,
dp.District,
year(dp.Arrival_Date),
month(dp.Arrival_Date)
order by dp.Modal_Price
) as rn,
count(*) over(
partition by
dp.Commodity_ID,
dp.Variety,
dp.State,
dp.District,
year(dp.Arrival_Date),
month(dp.Arrival_Date)
) as cnt
from daily_prices dp
where dp.Modal_Price is not null
and dp.Modal_Price > 0
)
select
Commodity,
Commodity_ID,
Variety,
State,
District,
Price_Year,
Price_Month,
round(avg(Modal_Price) * 10,2) as Median_Price_Per_MT,
count(*) as Median_Records
from ranked_prices
where rn in(
floor((cnt + 1) / 2),
floor((cnt + 2) / 2)
)
group by
Commodity,
Commodity_ID,
Variety,
State,
District,
Price_Year,
Price_Month;