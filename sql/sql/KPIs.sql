use ColdIQ;

/* No of Commodities */
select distinct count(*) from commodity;

/* no of districts and States */
select count(distinct State) as No_of_States ,count(distinct District) as No_of_Districts from location;

/* no of markets */
select count(distinct Market) as No_of_Markets from daily_prices;

/* date range */
select min(Arrival_Date) as Start_date , max(Arrival_Date) as End_Date from daily_prices;

