# RDAMP-Dimensional-Model-PowerBI
# RDAMP-Sales-Analysis

## 1. Exexutive Summary

This project presents a business intelligence report for **ACE SUPERSTORE**, a nationwide retail chain that has experienced significant sales growth over the past two years. As ACE prepares for strategic expansion into additional regions and aims to optimize its current operations, senior leadership requires a consolidated view of key sales performance trends.

My role as a Data Analyst was to perform an initial data exploration and create a comprehensive report that answers foundational business questions using the provided sales dataset.

**Data Overview & Methodology:**

The analysis was performed on the provided sales dataset, encompassing transaction-level data collected over the past two years. The dataset includes information on sales, revenue, discounts, regions, customer segments, product details, and order modes. The data was ectracted from powerbi with calculated Measures including Total_Sales, Total_Cost, Profit, Discount_Amount, and Quantity in CSV format, to enable Business users  analyze performance from multiple angles using a data model designed for usability and scalability. The data wasuploaded on SQL DATABASE and was stored on **ACE DATA** DATABASE
One fact table was created (fact_sale) and 

Four Dimensional tables were created namely 
- Location table
- product table
- Order mode table
- online table

### Dimensional Schema Diagram

<img width="2507" height="1324" alt="image" src="https://github.com/user-attachments/assets/d68f5f72-2437-4708-af05-9e9d5359dbe8" />

### Purpose of Each Table

* **`fact_sales` (Fact Table):**
    * **Purpose:** Stores the quantitative measures (facts) of sales transactions. Each row represents an individual sales line item.
    * **Key Contents:** Foreign keys linking to dimension tables (`Order_Date`, `Product_ID`, `postal_code`, `city`, `Order_ID`, ``) and numerical measures (`Total_Sales`, `Total_Cost`, `Profit_Margin`, `Total_Discount`, `Quantity`).

* **`Dim_Date` (Dimension Table):**
    * **Purpose:** Provides descriptive attributes related to the date of each sales transaction, enabling analysis by year, quarter, month, and day. Finding seasonality, trends, and year-over-year growth
    * **Key Contents:** `Order_Date`(PK), `Year_Number`, `Quarter_Number`, `Month_Number`, `Day_Number`.

* **`Dim_Product` (Dimension Table):**
    * **Purpose:** Contains descriptive information about each product sold, allowing sales and profit to be analyzed by product name, category, and sub-category.
    * **Key Contents:** `Product_ID` (PK),  `product_name`, `category`, `sub_category`.

* **`Dim_Location` (Dimension Table):**
    * **Purpose:** Provides geographical context for sales, enabling analysis by region, city, and postal code.
    * **Key Contents:**  `(postal_code, city)` (composite PK), `postal_code`, `city`, `region`, `country`.

* **`Dim_Order_Mode` (Dimension Table):**
    * **Purpose:** Describes the channel through which orders were placed (e.g., Online, In-Store), facilitating channel-specific performance analysis.
    * **Key Contents:** `Order_ID` (PK), `Order_Mode`.



## 3. Technical Approach & Tools

The analysis followed a typical Business Intelligence workflow:

1.  **Data Extraction & Transformation (ETL):** Raw sales data was extracted from the source (`[ACE DATA]`) and transformed using **SQL** queries within SQL Server. This involved cleaning, standardizing, and deriving new metrics.
2.  **Dimensional Modeling:** The transformed data was loaded into a Star Schema design, comprising the `fact_sales` table and its associated dimension tables (`Dim_Date`, `Dim_Product`, `Dim_Location`, `Dim_Order_Mode`). This structure optimizes data retrieval for analytical queries.
3.  **Data Analysis & Visualization:** **Power BI Desktop** was used to connect to the SQL Server data warehouse, build the data model, and design interactive dashboards to visualize key sales performance trends. **Excel** was used for initial data profiling and specific ad-hoc calculations during the data exploration phase.

**Tools Used:**
* **Database:** SQL Server
* **ETL & Data Modeling:** T-SQL (SQL queries)
* **Data Visualization & Reporting:** Power BI Desktop
* **Initial Data Exploration:** Microsoft Excel

4. ** Dimensional and Fact Table queries**
   ***Create_tables.sql // populate_dimensions.sql***
 -----------------LOCATION TABLE------------------
```  
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
```

------- PRODUCT TABLE-------
```
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
```

--------------ORDER MODE--------------------
```
CREATE TABLE dim_order_mode (
    order_Id NVARCHAR(255) PRIMARY KEY,
	order_mode NVARCHAR(255)
);

INSERT INTO dim_order_mode (order_mode, order_id)
SELECT DISTINCT
    order_mode,
	order_id
FROM [ACE DATA];
```

----------------ORDER DATE--------
```
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
```

 ***Populate_fact_table.sql***
------------FACT TABLE------------
```
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

***Create_views.sql***
```
--------------------------Product Seasonality-------------------
```
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
```

-----------------------------------Discount Impact Analysis-------------------
```
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
```

--------------------------Channel Margin Report------------------
```
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
```

----------------Region Category Rrankings------------
```
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
```
***OTHER VIEWS***

------------Total profit & Total sales by product category and region--

```
SELECT
    dl.region,
    dp.category,
    SUM(fs.Total_Sales) AS Total_Sales,
    SUM(fs.profit_margin) AS profit_margin
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_location dl ON fs.postal_code = dl.postal_code and fs.city= dl.city
GROUP BY dl.region, dp.category
ORDER BY dl.region, profit_margin DESC;

****Insight****
- This Shows how each product category performs in different regions. 
- Helps the business decide where to promote certain categories and identify underperforming regions for specific products.
```


------------------------Monthly profit trends (time series insight
```
SELECT
    dd.year,
    dd.month,
    SUM(fs.profit_margin) AS Monthly_Profit,
    SUM(fs.Total_Sales) AS Monthly_Sales
FROM fact_sales fs
JOIN dim_date dd ON fs.order_date = dd.order_date
GROUP BY dd.year, dd.month
ORDER BY dd.year, dd.month;

****Insight****
- Tracks profit and sales over months and years.
- Reveals seasonality patterns to plan inventory, staffing,
- Helps in targeting marketing campaigns during peak or slow periods.
```

-------------------------Profit Margin % by Order Channel
```
SELECT
    dom.order_mode AS Order_Channel,
    SUM(fs.profit_margin) / NULLIF(SUM(fs.Total_Sales), 0) AS Profit_Margin,
    SUM(fs.Total_Sales) AS Total_Sales
FROM fact_sales fs
JOIN dim_order_mode dom ON fs.order_mode = dom.order_mode
GROUP BY dom.order_mode;

****Insight****
- Compares profitability between online and in-store sales.
- Helps strategic decision-making: where to invest more resources
- optimize operations, or adjust pricing and marketing.
```
----------------------------------Discount Percentage vs profit by product
```
SELECT
    dp.product_name,
    SUM(fs.total_discount) / NULLIF(SUM(fs.Total_Sales), 0) AS Discount_Rate,
    SUM(fs.profit_margin) AS Profit_margin
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.product_name
ORDER BY Discount_Rate DESC

****Insight****
- Evaluates how much discounting impacts profit by product.
- Helps identify products where aggressive discounts might reduce
- Profit margins, so marketing or pricing strategies can be refined.
```
-------------------------Average Profit Margin by Category and Region
```
SELECT
    dl.region,
    dp.category,
    SUM(fs.profit_margin) / NULLIF(SUM(fs.Total_Sales), 0) AS Avg_Profit_Margin,
    SUM(fs.Total_Sales) AS Total_Sales,
    SUM(fs.profit_margin) AS Profit_Margin
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_location dl ON fs.postal_code = dl.postal_code and fs.city= dl.city
GROUP BY dl.region, dp.category
ORDER BY dl.region, Avg_Profit_Margin DESC;
```
****Insight****
- Shows how profitable each category is in each region.
- Helps decide which categories to promote, discontinue,
- Reprice regionally to maximize profit.


### 5. Screenshots

<img width="2295" height="1080" alt="Screenshot 2025-07-16 001443" src="https://github.com/user-attachments/assets/80d417bf-4242-44d9-8dc7-9c8707696b56" />
<img width="1265" height="789" alt="Screenshot 2025-07-16 001836" src="https://github.com/user-attachments/assets/b964803f-7b16-46b9-8331-cc35a6d275f2" />
<img width="1002" height="819" alt="Screenshot 2025-07-16 002922" src="https://github.com/user-attachments/assets/2deec4b1-0cec-4ffc-8c8a-3ca179d38a08" />






## 6. Recommendations

Based on the analysis, the following actionable recommendations are proposed for ACE's senior leadersh:

1.  **Capitalize on High-Margin Categories:** Intensify marketing and inventory focus on Electronics and Home Goods to maximize overall profitability.
2.  **Enhance Channel-Specific Experiences:** Develop tailored strategies for online and in-store channels, focusing on increasing average order value online and leveraging the higher value of in-store transactions.
4.  **Strategic Product Portfolio Review:** Conduct a deeper dive into underperforming products to assess their viability and potential for discontinuation or revitalization.

## 7. Future Enhancements 

This report serves as a baseline. Future analysis could include:
* Time-series analysis for seasonality and trend forecasting.
* Customer lifetime value (CLTV) analysis.
* Geospatial analysis to identify high-potential expansion areas.
* Integration of marketing spend data to assess ROI.
