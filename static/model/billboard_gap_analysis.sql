---------------ENTER YOUR SQL CODE---------------
---------------ENTER YOUR SQL CODE---------------
with base as (
	SELECT 
		track_id 
		, chart_name 
		, case when is_most_recent_feature then chart_date else null end last_week
		, case when is_chart_debut  then chart_date else null end first_week
	from fct_chart_performance
	where track_id is not null
	and (is_chart_debut or is_most_recent_feature)
)
, final as (
  select  
	track_id
	, concat(track_name,' by ', artist_name) as track_name
	, chart_name
	, date_diff(
	max(last_week) 
	, max(first_week) 
	, week
	) as n_weeks_debut_to_last_seen
	, date_diff(
	max(release_date)
	, max(first_week) 
	, week
	) as n_weeks_release_to_debut
from base
left join dim_tracks track on
 	base.track_id = track.track_id
left join dim_artists artist on
 	base.artist_id = artist.artist_id
group by 1,2,3
order by 5 desc  
)
select * from final