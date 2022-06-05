
with customers as (
    select * except(id) from customers
)
, station_proximity
as
(
  select  id              as station_id,
          name            as station_name,
          st_distance(
            st_geogpoint( longitude, latitude),
            st_geogpoint(-0.118092, 51.509865)
          )               as distance_from_city_centre_m
        
  from london_bicycles.cycle_stations
  join customers using(customer_id)
),
station_journeys 
as
(
select  s.station_id,
        s.station_name,
        s.distance_from_city_centre_m,
        count(1)    as journey_count
from station_proximity s
  inner join  london_bicycles.cycle_hire j
  on j.end_station_id = s.station_id
  and cast(j.end_date as date) >= date_sub('2017-1-1', interval 1 year)
group by s.station_id, s.station_name, s.distance_from_city_centre_m
),
stations_near_centre
as
(
  select  sp.station_id,
          sj.journey_count,
          dense_rank() 
            over (order by sj.journey_count desc) journey_rank,
  from    station_proximity sp
  
  inner join station_journeys sj
  on sj.station_id = sp.station_id
  where   sp.distance_from_city_centre_m <= 500
)
select station_name,
       distance_from_city_centre_m,
       journey_count
from   station_journeys 
where  journey_count >
(
  select journey_count
  from   stations_near_centre s
  where  s.journey_rank = 1
)
order by journey_count desc