---------------ENTER YOUR SQL CODE---------------
with base_seniors as (
    select
        experience
        , sum(salary) over(partition by experience order by salary) running_tot
    from candidates
    where experience = 'Senior'
    
)
, base_juniors as (
    select
        experience
        , sum(salary) over(partition by experience order by salary) running_tot
    from candidates
    where experience = 'Junior'
)
, seniors as (
    select 
        'Senior' as experience
        , count(1) as accepted_candidates
        , case when max(running_tot) < 70000 
            then 70000 - max(running_tot) else 70000 end as remaining_tot
    from  base_seniors
    where running_tot < 70000
)
, juniors as (  
    select
        'Junior' as experience
        ,count(1) as accepted_candidates
    from base_juniors
  --  where running_tot < (select remaining_tot from seniors)
)
, final as (
select experience,accepted_candidates  from seniors
union all
select experience,accepted_candidates  from juniors
)
select * from final 