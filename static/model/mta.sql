---------------ENTER YOUR SQL CODE---------------
with order_attribution as (
    select * from order_attribution
    where source_country = 'US'
)
, fct_orders as (
    select * from fct_orders
    where source_country = 'US'
)
, survey_weighting as (
    select * from gsheets.mta_survey_weighting
)
, ad_performance as (
    select * from ad_performance
    where source_country = 'US'
)
, session_credit_attribution as (
    select
        f.order_id
        , f.created_at
        , o.session_id
        , (f.total_gross_revenue - f.total_tax) as revenue
        , f.new_vs_repeat
        , o.attribution_channel
        , o.survey_channel
        , o.survey_response
        , coalesce(o.order_total_sessions,1) 
            as order_total_sessions
        , coalesce(o.order_session_number,1) 
            as order_session_number
        , coalesce(o.fortyfive_ten_fortyfive_points,1) 
            as fortyfive_ten_fortyfive_points
        , coalesce(
            o.fortyfive_ten_fortyfive_revenue,
            f.total_gross_revenue - f.total_tax) 
                as fortyfive_ten_fortyfive_revenue
        , case 
            when o.attribution_channel = o.survey_channel then 1 
            else 0 
            end as survey_click_match
        , case 
            when
                -- direct session
                attribution_channel = 'Direct'
                or attribution_channel is null
                or attribution_channel = 'Organic search'
                or (attribution_channel = 'Email' 
                and f.new_vs_repeat = 'new')
                or attribution_channel like '% brand search%'
            then 1 else 0 end as session_has_direct
    from fct_orders f
        left join order_attribution o on f.order_id = o.order_id
    where 
        f.is_completed = 1
)
, attributed_credit as ( 
    select 
        attribution_channel
        , new_vs_repeat
        , date_trunc(date(created_at,"America/New_York"),day) 
            as created_at
        , case when attribution_channel = 'Direct' then 1
            when attribution_channel is null then 1
            when attribution_channel = 'Organic search' then 1
            when attribution_channel = 'Email' 
                and new_vs_repeat = 'new' then 1
            when attribution_channel like '% brand search%' then 0.7 -- TBD need to validate logic
        else 0 
        end as pct_credit_giveback
        , sum(fortyfive_ten_fortyfive_points) as attributed_orders
        , sum(fortyfive_ten_fortyfive_revenue) as attributed_revenue
    from session_credit_attribution
)
, credit_giveback as (
    select
        attribution_channel
        , new_vs_repeat
        , created_at
        , attributed_orders * pct_credit_giveback as giveback_orders
        , attributed_revenue * pct_credit_giveback as giveback_revenue
        , attributed_orders * (1-pct_credit_giveback) as post_giveback_orders
        , attributed_revenue * (1-pct_credit_giveback) as post_giveback_revenue
        
    from attributed_credit
) 
, attributable_credit as (
    select
        new_vs_repeat
        , created_at
        , sum(giveback_orders) as attributable_orders
        , sum(giveback_revenue) as attributable_revenue
    from credit_giveback
)
, survey_clean as (
    select 
        survey_channel
        , survey_response
        , date_trunc(date(created_at,"America/New_York"),day) 
            as created_at
        , new_vs_repeat
        , count(distinct order_id) as survey_response_count
    from session_credit_attribution
    where survey_click_match = 0 
        and session_has_direct = 1          
)
, num_bucket_options as (
  select
        survey_response
        , count(distinct survey_channel) as num_options
    from fct_hdyhau
    where lower(survey_channel) not like '%general%'
)
, survey_response_direct as (
  select 
    survey_channel
    , survey_response
    , created_at
    , new_vs_repeat
    , sum(survey_response_count*weight) as direct_survey_response_count
  from survey_clean
    inner join survey_weighting 
        on survey_clean.survey_channel = survey_weighting.survey_channel
)
, general_redistribution as (
    select
        survey_response
        , created_at
        , new_vs_repeat
        , sum(direct_survey_response_count)/ max(num_options) as redistirbuted_count
    from survey_response_direct d
    left join num_bucket_options n
        on d.survey_response = n.survey_response
    where d.survey_channel like '%general%'  
    group by 1,2,3
)
, survey_end  as (
    select
        d.survey_channel
        , d.created_at
        , d.new_vs_repeat
        , d.direct_survey_response_count + coalesce(r.redistirbuted_count,0) 
            as direct_survey_response_count
    from survey_response_direct d
    left join general_redistribution r 
    on r.survey_response=d.survey_response 
        and r.created_at = d.created_at 
        and r.new_vs_repeat = d.new_vs_repeat
    where d.survey_channel not like '%general%' 
)
, survey_distribution  as ( 
    select 
        survey_channel
        , created_at
        , new_vs_repeat
        , direct_survey_response_count / sum(direct_survey_response_count) 
            over (
                partition by 
                    created_at
                    , new_vs_repeat
                ) as survey_composition
    from survey_end
    where direct_survey_response_count > 0
)
, reattributed_credit as (
    select 
        new_vs_repeat
        , created_at
        , survey_channel
        , attributable_orders * survey_composition as reattributed_orders
        , attributable_revenue * survey_composition as reattributed_revenue
    from attributable_credit a
    left join survey_distribution b 
        on a.new_vs_repeat = b.new_vs_repear
        and a.created_at = b.created_at
)
, order_join as (
    select 
        attribution_channel as marketing_channel
        , new_vs_repeat
        , created_at  
        , post_giveback_orders as orders
        , post_giveback_revenue as revenue 
    from credit_giveback
    union all
    select 
        case when lower(survey_channel) like '%radio%' then 'Radio am/fm' 
            when lower(survey_channel) like '%tv%' then 'TV' 
            else survey_channel end as marketing_channel
        , new_vs_repeat
        , created_at  
        , reattributed_orders as orders
        , reattributed_revenue as revenue 
    from reattributed_credit 
)
, order_join_calc as (
    select
    
        marketing_channel
        , coalesce(new_vs_repeat,"new") as new_vs_repeat
        , created_at  
        , sum(orders) as orders
        , sum(revenue) as revenue  
    from order_join
)
, order_join_final as (
    select
        marketing_channel
        , created_at  
        , coalesce(sum(case when new_vs_repeat = 'new' then revenue else 0 end),0) as new_attributed_revenue
        , coalesce(sum(case when new_vs_repeat = 'repeat' then revenue else 0 end),0) as repeat_attributed_revenue
        , coalesce(sum(case when new_vs_repeat = 'new' then orders else 0 end),0) as new_attributed_orders
        , coalesce(sum(case when new_vs_repeat = 'repeat' then orders else 0 end),0) as repeat_attributed_orders
    from order_join_calc
)
, ad_spend as (
    select
    
        date_trunc(date_day,day) as created_at  
        , ad_channel as marketing_channel
        , sum(spend) as spend
    from ad_performance
  
)
, final as (
    select
        marketing_channel
        , created_at 
        , coalesce(new_attributed_revenue,0) as new_attributed_revenue
        , coalesce(repeat_attributed_revenue,0) as repeat_attributed_revenue
        , coalesce(new_attributed_orders,0) as new_attributed_orders
        , coalesce(repeat_attributed_orders,0) as repeat_attributed_orders
        , coalesce(spend, 0) as spend
        
    from order_join_final a
    left join ad_spend b
        on a.created_at = b.created_at 
        and a.marketing_channel = b.marketing_channel
)
select * from final