/* No of Commodities */
select distinct count(*) from commodity;

/* Which commodity has the widest market presence? */
select Commodity, count(distinct Market) as Markets_Covered from daily_prices group by Commodity order by Markets_Covered desc;

/* Which commodity runs all round the year and which runs in seasons? Find out which months have the highest amounts of arrival in the markets*/
select Commodity_ID,quarter(Arrival_Date) as Quarter_no,
    count(*) as No_of_Records 
    from daily_prices group by Commodity_ID,Quarter_no order by Commodity_ID,Quarter_no;
    
/* Commodities which can be stored together considering similar range of storage temperature, humidity */
select a.Commodity_Name as Commodity_1,(a.Ideal_Temperature_Min +a.Ideal_Temperature_Max)/2 as Avg_Temp_1,(a.Min_Humidity + a.Max_Humidity)/2 as Avg_Humidity_1,
b.Commodity_Name as Commodity_2,(b.Ideal_Temperature_Min +b.Ideal_Temperature_Max)/2 as Avg_Temp_2,(b.Min_Humidity + b.Max_Humidity)/2 as Avg_Humidity_2
from commodity a join commodity b on a.Commodity_ID < b.Commodity_ID
where abs(a.Ideal_Temperature_Min -b.Ideal_Temperature_Min)<=1 
and abs(a.Ideal_Temperature_Max - b.Ideal_Temperature_Max)<=1
and abs(a.Min_Humidity - b.Min_Humidity)<=5
and abs(a.Max_Humidity - b.Max_Humidity)<=5
and  abs(a.Max_Shelf_Life_Days- b.Max_Shelf_Life_Days)<=10;

/* Which commodity is most prone to perish early */
select Commodity_Name, Max_Shelf_Life_Days from commodity order by Max_Shelf_Life_Days;
CREATE INDEX idx_arrival_date
ON daily_prices(Arrival_Date);

CREATE INDEX idx_commodity_arrival
ON daily_prices(Commodity_ID, Arrival_Date);

SHOW CREATE TABLE daily_prices;
SHOW INDEX FROM daily_prices;


/* -------------------
Commodity Analysis
1. Total number of commodities: 18
2. Most markets covered by commodity: Tomato(2887)
3. Least markets covered by commodity: Pineapples(597)
4. Seasons of commodities: Apple(all), Cabbage(1,2), Carrot(1,2,4), grapes(1,2),guava(1,4),mango(2,3),orange(1,4)peas(all),pineapples(all),pomegranate(all),etc
5. Mixed commodities: Cabbage and Grapes, Chilli and Guava , Papaya and Pineapples
6. Perishable commodoties: Cucumber, peas and chilli perish the earliest while onion,garlic and potato can be stored for months
----------------------*/
