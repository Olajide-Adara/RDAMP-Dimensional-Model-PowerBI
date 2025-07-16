SELECT * FROM [ACE DATA]
SELECT * FROM DIM_PRODUCT;
  DROP TABLE fact_SALES

 
 -----------------LOCATION TABLE------------------
CREATE TABLE dim_location (
    postal_code NVARCHAR(255),
    city NVARCHAR(255),
    region NVARCHAR(255),
    country NVARCHAR(255),
    PRIMARY KEY (postal_code, city)
);
INSERT INTO dim_location (postal_code, city, region, country)
SELECT DISTINCT
    postal_code,
    city,
    region,
    country
FROM [ACE DATA];

------- PRODUCT TABLE-------
CREATE TABLE dim_product (
    product_id NVARCHAR(255) PRIMARY KEY,
    product_name NVARCHAR(255),
    category NVARCHAR(255),
    sub_category NVARCHAR(255)
);

INSERT INTO dim_product (product_id, product_name, category, sub_category)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    sub_category
FROM [ACE DATA];


--------------ORDER MODE--------------------
CREATE TABLE dim_order_mode (
    order_Id NVARCHAR(255) PRIMARY KEY,
	order_mode NVARCHAR(255)
);

INSERT INTO dim_order_mode (order_mode, order_id)
SELECT DISTINCT
    order_mode,
	order_id
FROM [ACE DATA];


----------------ORDER DATE--------
CREATE TABLE dim_date (
    order_date DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    quarter INT
);

INSERT INTO dim_date (order_date, year, month, day, quarter)
SELECT DISTINCT
    order_date,
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    DAY(order_date) AS day,
    DATEPART(QUARTER, order_date) AS quarter
FROM [ACE DATA];



------------FACT TABLE------------
CREATE TABLE fact_Sales (
    order_id NVARCHAR(255) PRIMARY KEY,
    product_id NVARCHAR(255),
    customer_id NVARCHAR(255),
	city NVARCHAR(255),
    postal_code NVARCHAR(255),
    order_date DATE,
    order_mode NVARCHAR(255),
    quantity INT,
    sales DECIMAL(18,2),
    cost_price DECIMAL(18,2),
	Total_cost DECIMAL(18,2),
    discount DECIMAL(18,2),
    profit_margin DECIMAL(18,2),
    total_discount DECIMAL(18,2),
    total_sales DECIMAL(18,2),
    -----foreign keys------
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (postal_code, City) REFERENCES dim_location(postal_code, City),
    FOREIGN KEY (order_date) REFERENCES dim_date(order_date),
    FOREIGN KEY (order_id) REFERENCES dim_order_mode(order_id)
);


INSERT INTO Fact_Sales (
    order_id, product_id, customer_id, city, postal_code, order_date, order_mode,
    quantity, sales, cost_price, discount, Total_cost, profit_margin, total_discount, total_sales
)
SELECT
    order_id, product_id, customer_id, city, postal_code, order_date, order_mode,
    quantity, sales, cost_price, discount, cost_price* quantity AS Total_cost, profit_margin, total_discount, total_sales
FROM[ACE DATA];

--------------------------Product Seasonality-------------------
CREATE VIEW vw_product_seasonality AS
SELECT 
    dp.product_id,
    dp.product_name,
    dd.year,
    dd.month,
    SUM(fs.Total_Sales) AS Total_Sales,
    SUM(fs.profit_margin) AS Total_Profit,
    SUM(fs.Quantity) AS Total_Quantity
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_date dd ON fs.order_date = dd.order_date
GROUP BY dp.product_id, dp.product_name, dd.year, dd.month;

-----------------------------------Discount Impact Analysis-------------------
CREATE VIEW vw_discount_impact_analysis AS
SELECT
    dp.product_id,
    dp.product_name,
    AVG(fs.total_discount) AS Avg_Discount,
    AVG(fs.profit_margin) AS Avg_Profit,
    SUM(fs.Total_Sales) AS Total_Sales,
    COUNT(*) AS Order_Count
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_name;


--------------------------Channel Margin Report------------------
CREATE VIEW vw_channel_margin_report AS
SELECT
    dom.order_mode AS Order_mode,
    SUM(fs.Total_Sales) AS Total_Sales,
    SUM(fs.Total_Cost) AS Total_Cost,
    SUM(fs.profit_margin) AS Profit_Margin,
    AVG(fs.profit_margin) AS Avg_Profit_Per_Order
FROM fact_sales fs
JOIN dim_order_mode dom ON fs.order_mode = dom.order_mode
GROUP BY dom.order_mode;


----------------Region Category Rrankings------------
CREATE VIEW vw_region_category_rankings AS
SELECT
    dl.region,
    dp.category,
    SUM(fs.profit_margin) / NULLIF(SUM(fs.Total_Sales), 0) AS Profit_Margin,
    RANK() OVER(PARTITION BY dl.region ORDER BY SUM(fs.Profit_Margin) / NULLIF(SUM(fs.Total_Sales), 0) DESC) AS Category_Rank
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_location dl ON fs.postal_code = dl.postal_code AND fs.city = dl.city
GROUP BY dl.region, dp.category;