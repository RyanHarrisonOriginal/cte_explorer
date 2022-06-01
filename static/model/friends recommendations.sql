---------------ENTER YOUR SQL CODE---------------
with base as (
    select
        user_id
        , song_id
        , day
    from listens
    group by user_id, song_id, day
)
, base_calc as (
    select
        a.user_id as user_id 
        ,b.user_id as recommended_id
        ,a.day
        ,count(1) as match_count
        , concat(a.user_id,"|",b.user_id) as f_key
    from base a
    join base b
        on a.song_id = b.song_id
        and a.day = b.day
        and a.user_id <> b.user_id
    group by a.user_id, b.user_id, a.day
)
, exclusion as (
    select concat(u1,"|",u2) as f_key
    from
    (
        select user1_id as u1, user2_id as u2 from friendship
        union all
        select user2_id, user1_id from friendship
    ) as ex
)
, final as (
select  
    user_id, recommended_id 
from base_calc 
where match_count >=3 
    and f_key not in (select f_key from exclusion) 
group by user_id, recommended_id 
)

select * from final