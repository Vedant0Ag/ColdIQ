create database ColdIQ;
use ColdIQ;
select * from commodity;
select * from energy;
select * from location;
select * from government;
select * from weather;
select * from transport;
select * from  daily_prices;
select * from infrastructure;
select * from production;

create table commodity(
Commodity_ID int primary key,
Commodity_Name varchar(100),
Commodity_Category varchar(100),
Min_Shelf_Life_Days int,
Max_Shelf_Life_Days int,
Recommended_Storage_Duration varchar(100),
Ideal_Temperature_Min decimal(10,1),
Ideal_Temperature_Max decimal(10,1),
Min_Humidity int,
Max_Humidity int,
Refrigerated_Truck_Required varchar(10),
Average_Shelf_Life_Days int,
Average_Spoilage_Rate decimal(10,1));

create table daily_prices (Arrival_Date date,
	Commodity varchar(50),
    Commodity_Code int,
	District varchar(50),
	Grade varchar(50),
	Market varchar(50),
    Max_Price decimal(10,2),
	Min_Price decimal(10,2),
	Modal_Price decimal(10,2),
	State varchar(50),
	Variety	varchar(50),
    Commodity_ID int,
	District_ID int,
    foreign key (Commodity_ID) references Commodity(Commodity_ID),
    foreign key (District_ID) references Location(District_ID));
    
create table transport (Transport_ID int primary key,
    Source_District_ID int,
	Destination_District_ID int,
	Distance_Straight int,
	Approx_Actual_Distance int,
    foreign key (Source_District_ID) references location(District_ID),
    foreign key (Destination_District_ID) references location(District_ID));

create table weather (
    Weather_ID int primary key,
    Report_Date date,
	State varchar(50),
	District varchar(50),
	Latitude decimal(10,2),
	Longitude decimal(10,2),
	Temperature decimal(10,1),
	Temperature_Max decimal(10,1),
	Temperature_Min decimal(10,1),
	Relative_Humidity decimal(10,1),
	Rainfall decimal(10,1),
	Solar_Radiation decimal(10,1),
    District_ID int,
    foreign key (District_ID) references location(District_ID));

alter table energy add foreign key (State_ID) references states(State_ID);
alter table location add constraint fk_location_state foreign key (State_ID) references states(State_ID);
alter table production add constraint fk_production_state foreign key (State_ID) references states(State_ID);
alter table production add constraint fk_production_commodity foreign key (Commodity_ID) references commodity(Commodity_ID);

show variables like 'local_infile';
set global local_infile=1;

truncate table daily_prices;

load data local infile "C:/Users/Vedant Agarwal/Desktop/Cold Storage Investment Intelligence/datasets/ColdIQ/data/processed/daily_prices/daily_prices_final.csv" 
into table daily_prices
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS
(
    @Arrival_Date,
    Commodity,
    Commodity_Code,
    District,
    Grade,
    Market,
    Max_Price,
    Min_Price,
    Modal_Price,
    State,
    Variety,
    @Commodity_Original,
    Commodity_ID,
    District_ID
)
set Arrival_Date = str_to_date(@Arrival_Date, '%d/%m/%Y');
select distinct Commodity from daily_prices;

truncate table production;
load data local infile "C:/Users/Vedant Agarwal/Desktop/Cold Storage Investment Intelligence/datasets/ColdIQ/data/processed/production/production_master.csv" 
into table production
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS;

load data local infile "C:/Users/Vedant Agarwal/Desktop/Cold Storage Investment Intelligence/datasets/ColdIQ/data/processed/weather/weather_clean.csv" 
into table weather
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(Weather_ID,
Report_Date,
State,  
District, 
Latitude ,
Longitude ,
Temperature, 
Temperature_Max,
Temperature_Min ,
Relative_Humidity, 
Rainfall ,
Solar_Radiation, 
District_ID);

load data local infile "C:/Users/Vedant Agarwal/Desktop/Cold Storage Investment Intelligence/datasets/ColdIQ/data/processed/commodity/commodity_clean.csv" 
into table commodity
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS;


create table transport (
Transport_ID varchar(10)primary key,
Source_District_ID int,
Destination_District_ID int,
Distance_Straight decimal(10,2),
Approx_Actual_Distance decimal(10,3),
foreign key (Source_District_ID) references location(District_ID),
foreign key (Destination_District_ID) references location(District_ID));

load data local infile "C:/Users/Vedant Agarwal/Desktop/Cold Storage Investment Intelligence/datasets/ColdIQ/data/processed/transport/transportation_clean.csv" 
into table transport
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
IGNORE 1 ROWS;


truncate table commodity;
alter table daily_prices drop foreign key daily_prices_ibfk_5;
alter table production drop foreign key production_ibfk_3;
alter table daily_prices add foreign key (Commodity_ID) references Commodity(Commodity_ID) ;
alter table production add foreign key (Commodity_ID) references Commodity(Commodity_ID);
truncate table weather;
drop table commodity;
