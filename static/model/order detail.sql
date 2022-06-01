---------------ENTER YOUR SQL CODE---------------
with detailed_data as (
    select
        o.order_date,
        c.category_name,
        p.product_name,
        oi.quantity,
        oi.listprice,
        oi.discount
    from
        Orders o
        left join Order_Item oi on o.id = oi.id
        left join Products p on o.prd_id = p.id
        left join Category c on o.cat_id = c.id
),
product_sales as (
    select
        year(dt.order_date) year,
        month(dt.order_date) month,
        dt.category_name,
        dt.product_name,
        sum(dt.quantity) total_quantity,
        sum(dt.listprice * (1 - dt.discount)) total_product_sales
    from
        detailed_data dt
    group by
        1,
        2,
        3,
        4
),
last_month_data as (
select ps.*
from product_sales ps
where ps.year = year(CURRENT_DATE) -1 
and ps.month = month(CURRENT_DATE) -1
),
prev_month_data as (
select ps.*
from product_sales ps
where ps.year = year(CURRENT_DATE) -2
and ps.month = month(CURRENT_DATE) -2
),
final as (
    select
        lmd.*
    from
        last_month_data lmd
        left join prev_month_data pmd on lmd.category_name = pmd.category_name
)
select
    *
from
    final