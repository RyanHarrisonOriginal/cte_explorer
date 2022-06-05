with position_steak as (
    select
        track_id,
        track_chart_position,
        track_chart_position_previous,
        chart_date,
        chart_name -- This how we group streaks into distinct "buckets"
,
(
            row_number() over (
                partition by chart_name,
                track_id
                order by
                    chart_date
            ) - row_number() over (
                partition by chart_name,
                track_id,
                track_chart_position
                order by
                    chart_date
            )
        ) as position_streak_id
    from
        analytics.fct_chart_performance
    where
        track_id is not null
),
consec_wks_at_pos as (
    select
        track_id,
        track_chart_position,
        chart_name,
        count(1) as num_consecutive_weeks_at_position -- dedupe column provides row number for tracks that had multiple streaks at the same position
        -- i.e. has 10 weeks @ #1, drops to #3 for 1 week and rises to #1 again. The track will have
        -- 2 distinct streaks at the #1 position
,
        row_number() over(
            partition by chart_name,
            track_id,
            track_chart_position
            order by
                count(1) desc
        ) as dedupe
    from
        position_steak
    group by
        1,
        2,
        3,
        position_streak_id
),
final as (
    select
        track_chart_position,
        chart_name,
        track_id,
        concat(
            track_name,
            ' by ',
            artist_name,
            ' @ position #',
            track_chart_position
        ) as track_name_with_position,
        case
            when num_consecutive_weeks_at_position = max(num_consecutive_weeks_at_position) over(partition by chart_name, track_id) then true
            else false
        end as is_longest_streak_for_track,
        num_consecutive_weeks_at_position
    from
        consec_wks_at_pos
        left join analytics.dim_tracks tracks using(track_id)
        left join analytics.dim_artists artist using(artist_id)
    where
        dedupe = 1
    order by
        num_consecutive_weeks_at_position desc
)
select
    *
from
    final