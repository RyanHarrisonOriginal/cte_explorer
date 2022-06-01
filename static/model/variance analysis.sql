---------------ENTER YOUR SQL CODE---------------
with cy as (
    select 
        material_id
        , product_id
        , customer_id
        , sbu_id
        , market_segment_id
        , sum(contribution_margin) as cm
    from fct_sales
    where year = 2022
    group by 1,2,3,4,5
)
, py as (
    select 
        material_id
        , product_id
        , customer_id
        , sbu_id
        , market_segment_id
        , sum(contribution_margin) as cm
    from fct_sales
    where year = 2021
    group by 1,2,3,4,5
)
, a06 as (
    select 
        coalesce(py.material_id,py.material_id) as material_id
        , coalesce(py.product_id, cy.product_id) as product_id
        , coalesce(py.customer_id, cy.customer_id) as customer_id
        , coalesce(py.sbu_id, cy.sbu_id) as sbu_id
        , coalesce(py.market_segment_id, cy.market_segment_id)  as market_segment_id
        , py.cm - cy.cm as yoy_delta
    from cy left join py 
    on cy.material_id = py.material_id and
        cy.product_id = py.product_id and
        cy.customer_id = py.customer_id and
        cy.sbu_id = py.sbu_id and 
        cy.market_segment_id = py.market_segment_id
)

select * from a06