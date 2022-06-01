with position_steak as (
    select track_id
        , track_chart_position
        , track_chart_position_previous
        , chart_date
        , chart_name
        ,(row_number() over (partition by 
            chart_name, 
            track_id order by chart_date) - 
          row_number() over (partition by 
            chart_name, 
            track_id, 
            track_chart_position order by chart_date)) 
            as position_streak_id
    from billboard_analytics.fct_chart_performance
    where track_id is not null
)

, consecutive_weeks_at_postion as (
    select
      track_id
      , track_chart_position
      , chart_name
      , count(1) as num_consecutive_weeks_at_position
      , row_number() over(partition by 
        chart_name, 
        track_id, 
        track_chart_position order by count(1) desc) as dedupe
    
    from position_steak
    group by 1,2,3, position_streak_id
)

, final as (
select
  track_chart_position
  , chart_name
  , track_id
  , concat(track_name ,' by ',artist_name,' @ position #', track_chart_position) 
      as track_name_with_position
  , case when num_consecutive_weeks_at_position 
      = max(num_consecutive_weeks_at_position) 
        over(partition by chart_name, track_id) then 1 else 0 end 
      as is_longest_streak_for_track
  , num_consecutive_weeks_at_position
from consecutive_weeks_at_postion as con 
left join song_bird_analytics.dim_tracks tracks
  on tracks.track_id = con.track_id
left join song_bird_analytics.dim_artists artist
  on tracks.artist_id = artist.artist_id
where dedupe = 1
order by num_consecutive_weeks_at_position desc
)

select * from final