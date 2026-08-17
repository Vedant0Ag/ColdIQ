/* Which transport routes should a company prioritize for procurement, selling, or long-term investment? */


create or replace view vw_transport_opportunities as

with filtered_routes as (
select
r.*,
        sm.market_reliability as source_market_reliability,
        dm.market_reliability as destination_market_reliability,
        sm.coefficient_of_variation as source_cv,
        dm.coefficient_of_variation as destination_cv,
        sm.active_months as source_active_months,
        dm.active_months as destination_active_months,
        sm.observations as source_observations,
        dm.observations as destination_observations,
        pm_source.production_share as source_production_share,
        pm_source.production_decile as source_production_decile,
        pm_source.avg_productivity as source_avg_productivity,
        pm_source.production_rank as source_production_rank,
        pm_source.production_trend as source_production_trend,
        
        coalesce(pm_dest.production_share, 0) as destination_production_share  -- non null values 
    from route_metrics r
    join market_metrics sm
      on r.commodity = sm.commodity and r.variety = sm.variety and r.source_district = sm.district
    join market_metrics dm
      on r.commodity = dm.commodity and r.variety = dm.variety and r.destination_district = dm.district
    join production_metrics pm_source
      on r.commodity = pm_source.commodity and r.source_state = pm_source.state

    left join production_metrics pm_dest
      on r.commodity = pm_dest.commodity and r.destination_state = pm_dest.state
    where sm.market_reliability >= 0.50
      and dm.market_reliability >= 0.50
      and sm.observations >= 100 -- records are enough to arrive to results
      and dm.observations >= 100
      and sm.active_months >= 2  
      and dm.active_months >= 4 -- dest market should be more active to achieve stable profits
      and pm_source.production_decile <= 8 -- Eliminates bottom 20% insignicant source markets
),
profit_rank as (
    select *,
        ntile(10) over(partition by commodity, variety order by expected_profit desc) as profit_decile -- to normalise/regularise proifts amongst different commodity and variety
    from filtered_routes
)

select
    commodity, variety, source_state, source_district, destination_state, destination_district,
    round(buying_price, 2) as buying_price,
    round(selling_price, 2) as selling_price,
    round(gross_margin, 2) as gross_margin,
    round(transport_cost, 2) as transport_cost,
    round(spoilage_loss, 2) as spoilage_loss,
    round(expected_profit, 2) as expected_profit,
    round(source_market_reliability, 2) as source_market_reliability,
    round(destination_market_reliability, 2) as destination_market_reliability,
    round(source_cv, 3) as source_cv,
    round(destination_cv, 3) as destination_cv,
    source_active_months, destination_active_months, source_observations, destination_observations,
    source_production_decile as production_decile,
    round(source_production_share, 2) as production_share,
    round(source_avg_productivity, 2) as avg_productivity,
    source_production_rank as production_rank, 
    source_production_trend as production_trend,

   -- transport opportunity
case
    when expected_profit <= 0 -- loss
         or source_market_reliability < 0.30
         or destination_market_reliability < 0.30
    then 'Avoid'

    when profit_decile = 1 -- excellent profits
         and source_production_decile <= 2 -- good production -- mandatory for procurement hubs
         and source_market_reliability >= 0.70 -- abundant data about markets 
         and destination_market_reliability >= 0.70 -- abusndant data about markets
         and source_cv <= 0.35 -- price stablility 
         and destination_cv <= 0.35 -- price stability
         and source_active_months >= 8 -- almost all year round
         and destination_active_months >= 8
    then 'Procurement Hub(Purchase)'

    when profit_decile <= 2 -- high profits
         and destination_market_reliability >= 0.70 -- excellent reliable dest market
         and destination_cv <= 0.35
    then 'Premium Selling Route' -- here production of a commodity does not matter much. as low production states would be highly profitable and high production states can be profitable during seasons

    when profit_decile <= 5
         and source_market_reliability >= 0.70
         and destination_market_reliability >= 0.70
         and source_cv <= 0.30
         and destination_cv <= 0.30
    then 'Stable Long-Term Route'
    else 'Moderate Opportunity'
end as opportunity,
-- supply indicator
case
    when source_production_trend = 'Rapid Decline' then 'Very High'
    when source_production_trend = 'Declining' then 'High'
    when source_production_trend = 'Stable' then 'Medium'
    when source_production_trend = 'Growing' then 'Low'
    when source_production_trend = 'Rapid Growth' then 'Low'
    else 'Unknown'
end as supply_risk,

-- business recommendation
case
    when expected_profit <= 0
         or source_market_reliability < 0.50
         or destination_market_reliability < 0.50
    then 'Do Not Invest'
    when profit_decile = 1
         and source_production_decile <= 2
         and source_market_reliability >= 0.80
         and destination_market_reliability >= 0.80
    then 'Invest in Bulk Purchase and Cold Storage'
    when profit_decile <= 2
    then 'Develop Premium Supply Chain'
    when profit_decile <= 3
    then 'Seasonal Purchase'
    when profit_decile <= 5
    then 'Establish Long-Term Supply Chains'
    else 'Monitor the Market'
end as recommendation
from profit_rank;


create table transport_opportunity as
select * from vw_transport_opportunities;

select
recommendation,
count(*) as routes
from vw_transport_opportunities
group by recommendation
order by routes desc;

select
opportunity,
count(*) as routes
from transport_opportunity
group by opportunity
order by routes desc;

select min(market_reliability), avg(market_reliability), max(market_reliability)
from market_metrics;
select min(coefficient_of_variation), avg(coefficient_of_variation), max(coefficient_of_variation)
from market_metrics;
select min(active_months), avg(active_months), max(active_months)
from market_metrics;

select * from transport_opportunity;
select count(*) from transport_opportunity;

select
commodity,
round(avg(buying_price),2) as avg_buying_price,
round(avg(selling_price),2) as avg_selling_price,
round(avg(gross_margin),2) as avg_gross_margin,
round(avg(transport_cost),2) as avg_transport_cost,
round(avg(spoilage_loss),2) as avg_spoilage_loss,
round(avg(expected_profit),2) as avg_expected_profit
from route_metrics
group by commodity
order by avg_expected_profit;
