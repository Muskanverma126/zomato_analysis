#1. what is the total amount each customer spent on zomato?
select s.user_id, sum(p.price) Total_amount_spent from sales s join product p on p.product_id = s.product_id group by user_id;

#2. How many days has each customer visited zomato?
select user_id, count(distinct created_at) distinct_days from sales group by user_id;

#3. what was the first product purchased by each customer?
select * from (select *, rank() over(partition by user_id order by created_at) rnk from sales) a where rnk = 1;

#4. what is the most purchased item on the menu and how many times was it purchased by all customers?
select user_id, count(product_id) cnt from sales where product_id = 
(select product_id from sales group by product_id order by count(product_id) desc limit 1) group by user_id; 

#5.which item was the most popular for each customer?
select * from
(SELECT * , rank() over(partition by user_id order by cnt desc) rnk FROM
  (SELECT user_id, product_id, count(product_id) cnt FROM sales GROUP BY user_id, product_id)a)b
WHERE rnk = 1;

#6. Which item was purchased first by the customer after they become a member?
select * from 
(select c.*, rank() over(partition by user_id order by created_at) rnk from 
(select s.user_id, s.created_at, s.product_id, g.gold_signup_date from sales s
join goldusers_signup g on s.user_id = g.userid and created_at>gold_signup_date) c) subquery_alias where rnk = 1;

#7. which item was purchased just before the customer became a member?

select * from
(select c.*, rank() over(partition by user_id order by created_at) rnk from
(select s.user_id, s.product_id, s.created_at, g.gold_signup_date from sales s join goldusers_signup g
on s.user_id = g.userid where created_at<=gold_signup_date) c)t where rnk = 1;

#8. what is the total orders and amount spent for each member before they became a member?

select user_id, count(created_at) order_purchased, sum(price) total_amt_spend from
(select c.*,p.price from 
(select s.user_id, s.product_id, s.created_at, g.gold_signup_date from sales s join goldusers_signup g
on s.user_id = g.userid where created_at<=gold_signup_date)c
join product p on c.product_id = p.product_id)e
group by user_id ;

#9. If buying each product generates points for eg 5rs=2 zomato point and each product has different
#purchasing points, for eg for  p1 =1 zomato point, p2 10rs=5zomato point, p3 5rs=1 zomato point
#calculate points collected by each customers and for which product most points have been given till now.

select user_id, sum(total_points)*2.5 total_cashback_earned from
(select e.*, round(amt/points)total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5
else 0 end as points from
(select c.user_id, c.product_id, sum(price) amt from
(SELECT s.*, p.price from sales s join product p on p.product_id=s.product_id)c
group by user_id, product_id) d)e)f group by user_id;

select * from 
(select *,rank() over(order by total_points_earned desc) rnk from
(select product_id, sum(total_points) total_points_earned from
(select e.*, round(amt/points)total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5
else 0 end as points from
(select c.user_id, c.product_id, sum(price) amt from
(SELECT s.*, p.price from sales s join product p on p.product_id=s.product_id)c
group by user_id, product_id) d)e)f group by product_id)g)h where rnk = 1;

#10. In the first one year after a customer joins the gold program(including their join date) irrespective
#of what the customer has purchased they earn 5 zomato points for every 10rs spent who earned more 1 or 3
#and what was their points earnings in their first year 7.

#according to question,
#1zp = 2 rupees
#0.5 zp = 1 rupees

select a.*, p.price*0.5 total_points_earned from
(select s.user_id, s.created_at, s.product_id, g.gold_signup_date from sales s join goldusers_signup g
on s.user_id = g.userid and created_at>=gold_signup_date and created_at<=date_add(g.gold_signup_date, interval 1 year))
a inner join product p on p.product_id = a.product_id;

#11. rank all th transactions of the customer

select *, rank() over(partition by user_id order by created_at) from sales;

#12. rank all the transactions for each member whenever they are a gold zomato member for every non
#gold trasaction marked as na.

select a.*, case when gold_signup_date is null then 'na' else rank() over (partition by user_id order by created_at desc) end rnk from
(select s.user_id, s.created_at, s.product_id, g.gold_signup_date 
from sales s
left join goldusers_signup g
on s.user_id = g.userid and created_at>=gold_signup_date)a;