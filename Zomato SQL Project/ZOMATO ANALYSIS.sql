--creating gold users table
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

--creating users table
CREATE TABLE users(userid integer,signup_date date); 
INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

--creating sales table
CREATE TABLE sales(userid integer,created_date date,product_id integer); 
INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

--creating product table
CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);
 
select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--1.what is total amount each customer spent on zomato ?
SELECT a.userid,sum(b.price)total_amount_spend from sales as a INNER JOIN product as b
on a.product_id = b.product_id
GROUP BY a.userid
order by a.userid

--2.How many days has each customer visited zomato?

SELECT userid,count(DISTINCT created_date) from sales GROUP by userid;

--3.what was the first product purchased by each customer?

SELECT * from
(SELECT *,rank() over (PARTITION by userid ORDER by created_date)rnk from sales) a WHERE rnk=1;

--4.what is most purchased item on menu & how many times was it purchased by all customers ?

SELECT userid,COUNT(product_id)purchased_count from sales where product_id=
(SELECT product_id from sales group by product_id order by COUNT(product_id) desc LIMIT 1 )GROUP by userid

--5.which item was most popular for each customer?

SELECT * from
(SELECT *,rank() over(PARTITION by userid order by cnt desc)rnk from
(SELECT userid,product_id,count(product_id) cnt from sales group by userid,product_id )a)b
WHERE rnk=1;

--6.which item was purchased first by customer after they become a member ?

SELECT * from(
SELECT c.*,rank() over(PARTITION by userid ORDER by created_date)rnk from
(SELECT a.userid,b.created_date,b.product_id,a.gold_signup_date from goldusers_signup as a 
INNER JOIN sales as b on a.userid = b.userid AND created_date >= gold_signup_date)c) d WHERE rnk = 1;

--7. which item was purchased just before the customer became a member?

SELECT * from(
SELECT c.*,rank() over(PARTITION by userid ORDER by created_date DESC)rnk from
(SELECT a.userid,b.created_date,b.product_id,a.gold_signup_date from goldusers_signup as a 
INNER JOIN sales as b on a.userid = b.userid AND created_date <= gold_signup_date)c) d WHERE rnk = 1;

-- 8. what is total orders and amount spent for each member before they become a member?

SELECT userid,COUNT(created_date)total_orders,sum(price)Total_amount from 
(SELECT c.*,d.price from 
(SELECT a.userid,b.created_date,b.product_id,a.gold_signup_date from goldusers_signup as a 
INNER JOIN sales as b on a.userid = b.userid AND created_date <= gold_signup_date)c 
INNER JOIN product as d on d.product_id = c.product_id)e 
GROUP by userid
ORDER by userid;

/*9. If buying each product generates points for eg 5rs=2 zomato point and each product 
has different purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point
and p3 5rs=1 zomato point 2rs =1zomato point, calculate points collected by each customer
and for which product most points have been given till now.*/


SELECT userid,sum(total_Points)*2.5 total_amount_earned from
(select e.*,amt/points total_points from
(SELECT d.*,case when product_id=1 then 5 
WHEN product_id=2 then 2
WHEN product_id=3 then 5 ELSE 0 end as points from(
SELECT c.userid,c.product_id,sum(price)amt FROM(
SELECT a.*,b.price from sales as A 
INNER JOIN product as b on a.product_id=b.product_id)c GROUP by userid,product_id)d)e)f GROUP by userid;

SELECT * from
(SELECT *,rank() over(order by total_point_earned DESC) rnk from
(SELECT product_id,sum(total_Points) total_point_earned from
(select e.*,amt/points total_points from
(SELECT d.*,case when product_id=1 then 5 
WHEN product_id=2 then 2
WHEN product_id=3 then 5 ELSE 0 end as points from(
SELECT c.userid,c.product_id,sum(price)amt FROM(
SELECT a.*,b.price from sales as A 
INNER JOIN product as b on a.product_id=b.product_id) c GROUP by userid,product_id)d)e)f
 GROUP by product_id)f)g WHERE rnk=1
 
 
 
/*10. In the first year after a customer joins the gold program (including the join date )
 irrespective of what customer has purchased earn 5 zomato points for every 10rs spent 
 who earned more 1 or 3 what int earning in first yr ? 1zp = 2rs */
 
 
 select c.*,d.price,d.price*0.5 total_points from
 (SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a 
 INNER join goldusers_signup as B on a.userid=b.userid and  created_date>=gold_signup_date AND
 created_date<=gold_signup_date + INTEGER  '365')c 
 INNER join product as d 
 on c.product_id = d.product_id
 
 --11. rnk all transaction of the customers
 
 SELECT *,rank() over(PARTITION by userid order BY created_date)rnk from sales
 
 
 --12. rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na
 
 SELECT e.*,case when rnk=0 then 'na' else rnk end as rnkk from
(SELECT c.*, cast((case when gold_signup_date is NULL then 0 else
 rank() over(PARTITION by userid order by created_date desc) end) as VARCHAR) as rnk from 
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a 
LEFT JOIN  goldusers_signup as b on a.userid = b.userid AND created_date >= gold_signup_date)c )e;