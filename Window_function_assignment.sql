-- window_function_assignment
use mavenmovies;
-- 1. Rank the customers based on the total amount they have spent on rentals. 


 select customer_id, rental_id ,sum(amount) as total_amount
 ,rank() over( partition by rental_id order by sum(amount)) as ranked from payment group by 1,2 order by sum(amount) ;
 
 -- 2. Calculate the cumlative revenue generated by each film over time . 
 
select f.film_id , f.title, 
sum(p.amount) over (partition by f.film_id order by sum(p.amount)) as cumlative_amount from film as f 
inner join inventory as i on i.film_id = f.film_id 
inner join rental as r on r.inventory_id = i.inventory_id
inner join payment as p on p.rental_id = r.rental_id 
group by f.title , f.film_id ,p.amount 
order by p.amount;
 -- 3. Determine the average rental duration for each film , considering films with similar length. 
 
 select  title, length,  avg(rental_duration) over(partition by length)avg_rental_duration from film ;
 
 
 -- 4. Identify the top 3 films in each category based on their rental counts. 
 
 
SELECT
    title,
    category_id,
    rental_count,
    rank_within_category
FROM (
    SELECT
        f.title,
        fc.category_id,
        COUNT(r.rental_id) AS rental_count,
        DENSE_RANK() OVER (PARTITION BY fc.category_id ORDER BY COUNT(r.rental_id) DESC) AS rank_within_category
    FROM
        film AS f
    JOIN
        film_category AS fc ON fc.film_id = f.film_id
    JOIN
        inventory AS i ON i.film_id = f.film_id
    JOIN
        rental AS r ON r.inventory_id = i.inventory_id
    GROUP BY
        f.title, fc.category_id
) AS subquery
HAVING
    rank_within_category <= 3;

 -- 5. Calculate the difference in rental counts between each customer's total rental and average rental
 -- across all customers.
 
 SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(rental_id) - AVG(rental_id) AS difference_in_rental_counts
FROM
    rental AS r
        JOIN
    customer AS c ON c.customer_id = r.customer_id
GROUP BY customer_id , customer_name;
 
 -- 6. Find the monthly revenue trend for the entire rental store over time. 
 
 select rental_id , monthname(payment_date) as month, sum(amount) over(partition by month(payment_date)) as monthly_revenue from payment; 
 
 -- 7. Identify the customers whose total spending on rentals falls within the top 20% of all customers. 
 
 
SELECT
    customer_id,
    first_name,
    last_name,
    total_spending,
    spending_rank
FROM (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spending,
        PERCENT_RANK() OVER (ORDER BY SUM(p.amount) DESC) AS spending_rank
    FROM
        payment AS p
    INNER JOIN
        customer AS c ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id, c.first_name, c.last_name
) AS ranked_customers
WHERE
    spending_rank <= 0.2; 

 -- 8. Calculate the running total of rentals per category, ordered by rental count. 
 
 
 select c.name , c.category_id , sum(r.rental_id) over( partition by c.category_id order by count(r.rental_id) desc) as running_total  from rental as r 
 inner join inventory as i on i.inventory_id = r.inventory_id
 inner join film as f on f.film_id = i.film_id
 inner join film_category fc on fc.film_id = i.film_id 
 inner join category c on c.category_id = fc.category_id group by c.name, c.category_id , r.rental_id
 order by running_total;
 
 
 -- 9. Find the films that have been rented less than the average rental count for their respective category. 
 
 
 SELECT
    title,
    category_id,
    rental_count,
    avg_rental_count
FROM (
    SELECT
        f.title,
        c.category_id,
        COUNT(r.rental_id) AS rental_count,
        AVG(COUNT(r.rental_id)) OVER (PARTITION BY c.category_id) AS avg_rental_count,
        ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY COUNT(r.rental_id)) AS row_num
    FROM
        rental r
        INNER JOIN inventory i ON i.inventory_id = r.inventory_id
        INNER JOIN film f ON f.film_id = i.film_id
        INNER JOIN film_category fc ON fc.film_id = i.film_id
        INNER JOIN category c ON c.category_id = fc.category_id
    GROUP BY
        f.title, c.category_id
) as subquery
WHERE
    rental_count < avg_rental_count
ORDER BY
    title, category_id, rental_count;
 -- 10. Identify the top 5 months with the highest revenue and display the revenue generated in each month. 
 
 select distinct month(payment_date)
 as month_payment , sum(amount) over(partition by month(payment_date) 
 order by month(payment_date)) as month_revenue from payment 
 order by month_payment , month_revenue desc
limit 5;
 
