-------------- Create All Table Schema -----------------------

Drop Table if Exists stores; 
Create Table stores (
	store_id Varchar(5) Primary Key,
	store_name Varchar(50),
	city Varchar(30),
	country Varchar(30)
);

Drop Table if Exists category;
Create Table category(
	category_id Varchar(6) Primary Key,
	category_name Varchar(50)
);

Drop Table if Exists products;
Create Table products(
	product_id Varchar(5) Primary Key,
	product_name Varchar(200),
	category_id Varchar(6),
	launch_date date,
	price float,
	CONSTRAINT fk_category Foreign key (category_id) References category(category_id)
);

Drop Table if Exists sales;
Create Table sales(
	sale_id Varchar(20) Primary Key,
	sale_date Date,
	store_id Varchar(5),
	product_id Varchar(5),
	quantity int,
	CONSTRAINT fk_store Foreign key (store_id) References stores(store_id),
	CONSTRAINT fk_product Foreign key (product_id) References products(product_id)
);

Drop Table if Exists warranty;
Create Table warranty(
	claim_id Varchar(20) Primary Key,
	claim_date Date,
	sale_id Varchar(20),
	repair_status Varchar(20),
	CONSTRAINT fk_sales Foreign key (sale_id) References sales(sale_id)
);

----------------------------------------------------------------------------------------------------------------
-- EDA :
-- Improving Query Performance

  Create Index sales_store_id On sales(store_id);
  Create Index sales_product_id On sales(product_id);
  Create Index sales_sale_date On sales(sale_date);  

-- et : 99 ms
-- et after creating index : 10 - 15 ms
   Explain Analyze
   Select * from sales
   Where store_id = 'ST-63';
   
-- et : 121 ms
-- et after creating index : 10 - 15 ms
   Explain Analyze
   Select * from sales
   Where product_id = 'P-38';

-- et : 56 ms
-- et after creating index : 1 ms
   Explain Analyze
   Select * from sales
   Where sale_date = '13-04-2022';

----------------------------------------------------------------------------------------------------------------

------> Easy to Medium (10 Questions) <--------
-----------------------------------------------

-- 1. Find the number of stores in each country.
	Select country, Count(*) as number_of_stores
	From stores
	Group By country
	Order By 2 Desc;
	
-- 2. Calculate the total number of units sold by each store.

	Select s.store_id,
		   st.store_name,
		   sum(s.quantity) as Total_Unit_Sold
	From sales s
	Join stores st
	ON s.store_id = st.store_id
	Group By 1, 2
	Order By 3 Desc;
	
-- 3. Identify how many sales occurred in December 2023.

	Select count(sale_id) as Total_sales
	From sales
	Where To_char(sale_date, 'MM-YYYY') = '12-2023'
	
-- 4. Determine how many stores have never had a warranty claim filed.
	
	Select * from stores
	Where store_id Not in (
			Select Distinct store_id
			From sales s 
			Right Join warranty w
			On s.sale_id = w.sale_id
	 )
	
-- 5. Calculate the percentage of warranty claims marked as "Rejected".
	
	Select 
		Round(Count(repair_status)/
				(Select Count(*) from warranty)::Numeric * 100,
				2) as percentage
	From warranty
	Where repair_status = 'Rejected'
	
-- 6. Identify which store had the highest total units sold in the last year.

	Select st.store_id, st.store_name,
		   To_char(s.sale_date, 'YYYY') as year,
		   Sum(s.quantity) as Total_Unit_sold
	from stores st
	Join sales s
	ON st.store_id = s.store_id
	Where s. sale_date >= (Current_date - Interval '2 year')
	Group By 1, 2, 3
	Order By Total_unit_sold Desc
	Limit 1 ;
	
-- 7. Count the number of unique products sold in the last year.
	Select 
		Count(Distinct product_id) as number_of_product 
	from Sales
	Where sale_date >= (Current_date - Interval '2 Year')
	
-- 8. Find the average price of products in each category.

	Select c.category_id, c.category_name,
		   Round(AVG(p.price)::Numeric,3) as avg_price
	From category c
	Join products p
	ON c.category_id = p.category_id
	Group By 1, 2
	Order By 1;
	
-- 9. How many warranty claims were filed in 2024?

	Select count(claim_id) as warranty_claims
	from warranty
	Where Extract(Year from claim_date) = '2024'
	
-- 10. For each store, identify the best-selling day based on highest quantity sold.

	with selling_day as (
		Select store_id,
			   To_char(sale_date, 'day') as day_name,
			   sum(quantity) as Total_unit_sold,
			   Rank() Over(Partition By store_id Order By sum(quantity) desc) as rank
		From sales
		Group By 1, 2
	)
	Select store_id,
		   day_name,
		   total_unit_sold
	From selling_day
	Where rank = 1
	Order By 1;

----------------------------------------------------------------------------------------------------------------
	 
--------> Medium to Hard (5 Questions): <-----------
----------------------------------------------------

-- 11. Identify the least selling product in each country for each year based on total units sold.

	With least_selling_product as (
			Select st.country,
				   Extract(Year from s.sale_date) as years,
				   s.product_id,
				   p.product_name,
				   sum(s.quantity) as Total_unit_sold,
				   Rank() Over(Partition By st.country,Extract(Year from s.sale_date) Order By sum(s.quantity) ASC) as Min_sale_product
			From stores st
			Join sales s
			ON st.store_id = s.store_id
			Join Products p
			ON s.product_id = p.product_id
			Group By 1, 2, 3, 4
	)
	Select Country, years,
		   product_id, product_name,
		   total_unit_sold
	From least_Selling_product
	Where min_sale_product = 1 ;
	
-- 12. Calculate how many warranty claims were filed within 180 days of a product sale.
	
	Select p.product_id, p.product_name,
		   s.sale_date, w.claim_date,
		   (w.claim_date - s.sale_date) as days
	From sales s
	Join warranty w
	On s.sale_id = w.sale_id
	Join products p
	ON s.product_id = p.product_id
	Where w.claim_date - s.sale_date <=180
	Order By 1;

	
-- 13. Determine how many warranty claims were filed for products launched in the last two years.

	Select p.product_id, p.product_name,
	 	   Count(s.sale_id) as Total_sales,
		   Count(w.claim_id) as Total_warranty_claims
	From products p
	Join sales s
	ON p.product_id = s.product_id 
	Left Join warranty w
	ON s.sale_id = w.sale_id
	Where p.launch_date >= (Current_date - Interval '2 years')
	Group By 1, 2
	
-- 14. List the months in the last three years where sales exceeded 5,000 units in the USA.

	Select st.country,
		   To_char(s.sale_date, 'Month') as Months,
		   count(s.quantity) as Total_unit_sold
	From stores st
	Join sales s
	ON st.store_id = s.store_id
	Where st.country = 'United States'
	AND s.sale_date > (current_date - Interval '3 Years')
	Group By 1, 2
	Having count(s.quantity) >= 5000
	Order By 3 Desc;
	
-- 15. Identify the product category with the most warranty claims filed in the last two years.

	Select c.category_name,
		   count(w.claim_id) as Total_warranty_claims
	From category c 
	Join products p
	ON c.category_id = p.category_id
	JOin sales s 
	ON p.product_id = s.product_id
	Join warranty w
	ON s.sale_id  = w.sale_id
	Where w.claim_date >= (Current_date - Interval '2 years')
	Group By 1
	Order By 2 Desc;

----------------------------------------------------------------------------------------------------------------
	
-----------> Complex (6 Questions): <-------------
--------------------------------------------------

-- 16. Determine the percentage chance of receiving warranty claims after each purchase for each country.
	
	With Country_wise_sale as (
		Select st.country,
			   Count(Distinct s.sale_id) as Total_sales
		From Stores st
		Join Sales s
		ON st.store_id = s.store_id
		Group By 1
	),
	Country_wise_claim as (
		Select st.country,
			   Count(w.claim_id) as Total_claim
		From Stores st
		Join Sales s
		ON st.store_id = s.store_id
		Join Warranty w
		ON s.sale_id = w.sale_id
		Group By 1
	)
	Select cs.Country,
		   Round(NULLIF((cc.Total_claim * 100.0 / cs.Total_sales),0),2) as warranty_claim_percentage
	From Country_wise_sale cs
	Left Join Country_wise_claim cc
	ON cs.country = cc.country
	Order By 2 Desc;

--  ** Optimize Version:

	Select st.country,
		   Round((Count(w.claim_id) * 100.0) / 
		   NULLIF(Count(Distinct s.sale_id),0),2) As warranty_claim_percentage
	From Stores st
	Join Sales s
	ON st.store_id = s.store_id
	Left Join Warranty w
	ON s.sale_id = w.sale_id
	Group By 1
	Order By 2 Desc;

	
-- 17. Analyze the year-by-year growth ratio for each store.

	With current_sales As (
		Select st.store_id,
			   st.store_name,
			   To_char(s.sale_date, 'YYYY') as Years,
			   sum(s.quantity * p.price) as Curr_year_revenue,
			   LAG(sum(s.quantity * p.price)) Over(Partition By st.store_id) as Prev_year_revenue
		From Stores st
		Right Join Sales s
		ON st.store_id = s.store_id
		Join products p
		ON s.product_id = p.product_id
		Group By 1, 2, 3
	)
	Select store_id,
		   years,
		   Curr_year_revenue,
		   Prev_year_revenue,
		   COALESCE(Curr_year_revenue - Prev_year_revenue,Curr_year_revenue) as Difference,
		   Round(((Curr_year_revenue - Prev_year_revenue) / 
		   			NULLIF(prev_year_revenue,0) * 100)::Numeric, 2) as Per_growth_ratio
	From current_sales
		   
-- 18. Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.
		
	With Product_sales_claims as (
		Select p.product_id,
			   p.price,
			   sum(s.quantity) as Total_Unit_sold,
			   count(w.claim_id) as Total_claim
		From sales s
		Join products p
		ON s.product_id = p.product_id
		Left Join warranty w
		On s.sale_id = w.sale_id
		Where s.sale_date >= (current_date - Interval '5 Years')
		Group By 1, 2
	),
	product_price_range as (
		Select product_id,
			   price,
			   Total_unit_sold,
			   Total_claim,
		       Case
			   	  When price < 500 Then 'Low Price'
				  When price Between 500 And 1000 Then 'Mid Price'
				  When price Between 1001 And 1500 Then 'High Price'
				  Else 'Premium'
			   End as price_range
	     From Product_sales_claims
    )
	Select 
		  Price_range,
		  Round(CORR(price, Total_claim)::Numeric,2) as price_claim_correlation
	From product_price_range
	Group By 1
	Order By 2 Desc ;
 
	
-- 19. Identify the store with the highest percentage of "Rejected" claims relative to total claims filed.

	With rejected_count as (
		Select s.store_id,
			   Count(w.claim_id) as Total_claim,
			   count(Case When w.repair_status = 'Rejected' Then 1 End) as Total_rejected
		From sales s
		Right Join warranty w
		On s.sale_id = w.sale_id
		Group By 1
	)
	Select r.store_id,
		   st.store_name,
		   st.city,
		   st.country,
		   r.total_claim,
		   r.total_rejected,
		   Round(r.total_rejected::Numeric / r.total_claim::Numeric * 100, 2)::Numeric as Rejection_Percentage
	From rejected_count r
	Join stores st
	ON r.store_id = st.store_id
	Order By 7 Desc
	Limit 1
	
-- 20. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

	With Monthly_sales as (
		Select st.store_id,
			   st.store_name,
			   Date_Trunc('month', s.sale_date) as sale_months,
			   sum(s.quantity * p.price) as Monthly_Revenue
		From stores st
		Join sales s
		On st.store_id = s.store_id
		Join products p
		On s.product_id = p.product_id
		Where s.sale_date >= (Current_date - Interval '4 Years')
		Group By 1, 2, 3
	)
	Select store_id,
		   store_name,
		   sale_months,
		   Monthly_Revenue,
		   sum(Monthly_Revenue) Over(Partition By store_id Order By sale_months
		   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
	From Monthly_sales
	
-- 21. Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.

	With Sales_with_period AS (
		Select p.product_id, p.product_name,
			   p.launch_date,
			   s.sale_date,
			   (s.quantity*p.price) as revenue,
			   (DATE_PART('year', AGE(s.sale_date, p.launch_date)) * 12 +
	            DATE_PART('month', AGE(s.sale_date, p.launch_date))) AS months_since_launch
		from sales s
		Join products p
		ON s.product_id = p.product_id
	)
	Select product_id,
		   product_name,
		   Case
			   When months_since_launch Between 0 AND 5 Then '0-6 months'
			   When months_since_launch Between 6 AND 12 Then '7-12 months'
			   When months_since_launch Between 12 AND 18 Then '13-18 months'
			   Else '19+ months'
		   End as sales_period,
		   sum(revenue) as total_revenue,
		   Round((sum(revenue)/ count(Distinct sale_date))::Numeric, 2) as dealy_avg_revenue
	From Sales_with_period
	Group By 1, 2, 3
	Order By 1, 4 desc;
