# E-commerce Growth & Customer Lifecycle Analytics

## Project Overview

This project focuses on analysing e-commerce business performance, customer purchasing behaviour, retention patterns, marketing effectiveness and revenue trends using SQL, Python, Excel and Power BI.

The objective is to transform raw transactional data into actionable business insights that can help businesses improve customer retention, understand revenue drivers, evaluate marketing channels and make data-driven decisions.

## Business Objectives

- Analyse overall business performance and revenue trends.
- Understand customer purchasing behaviour and repeat purchase patterns.
- Identify customer segments using RFM analysis.
- Evaluate customer retention through cohort analysis.
- Analyse the conversion funnel and identify major drop-off stages.
- Evaluate marketing channel performance and estimated customer acquisition cost.
- Identify data-quality issues and implement reusable monitoring.
- Develop interactive dashboards for business reporting.

## Dataset Overview

The project uses a e-commerce dataset consisting of seven relational tables and approximately 1.02 million records.

| Dataset | Records |
|---|---:|
| Customers | 50,000 |
| Orders | 150,000 |
| Order Items | 300,000 |
| Products | 2,000 |
| Events | 500,000 |
| Marketing Spend | 10,000 |
| Refunds | 10,000 |

## Tools & Technologies

- **SQL (MySQL)** 
- **Python** 
- **Power BI** 
- **Excel** 

## Project Workflow

### 1. SQL Analysis

- Database creation and data loading.
- Data validation and quality checks.
- Revenue and order performance analysis.
- Customer purchase frequency and repeat purchase analysis.
- Cohort retention analysis.
- Conversion funnel analysis.
- RFM customer segmentation.
- Marketing channel and estimated CAC analysis.

### 2. SQL Optimization & Automation

- Query optimization using EXPLAIN ANALYZE.
- Indexing strategies and composite indexes.
- Join and subquery optimization.
- Reusable SQL views for business reporting.
- Stored procedures for data-quality logging.
- MySQL Event Scheduler for daily data-quality monitoring.

### 3. Python Analysis & Reporting

- Connected MySQL with Python using SQLAlchemy.
- Extracted analytical data into Pandas DataFrames.
- Analysed monthly revenue, top customers and channel performance.
- Generated customer value and product category summaries.
- Exported analytical outputs into a multi-sheet Excel workbook using Pandas ExcelWriter.

### 4. Power BI Dashboards

Developed two interactive dashboard pages:

**Executive Overview Dashboard**
- Revenue and order KPIs.
- Monthly revenue trends.
- Order status distribution.
- Marketing channel performance.
- Monthly delivered orders.

**Customer Analytics Dashboard**
- Customer segmentation.
- Repeat purchase rate.
- Customer purchase frequency.
- Cohort retention.
- Customer acquisition metrics.

## Key Business Insights

- Delivered orders: 143,964.
- Delivered revenue: ₹131.56 crore.
- Average delivered order value: ₹9,138.07.
- Customers with delivered orders: 47,203.
- Repeat purchase rate: 82.61%.
- Month 18 cohort retention: 13.41%.
- Visit-to-purchase event conversion: approximately 6.07%.
- Major funnel drop-off: Product View to Add to Cart.



## Business Recommendations

- Improve product page experience and product descriptions to address the largest funnel drop-off.
- Develop targeted retention campaigns for at-risk and hibernating customers.
- Evaluate marketing channel efficiency before reallocating acquisition budgets.
- Monitor data-quality issues regularly to improve reporting reliability.
- Use customer segmentation to develop more targeted marketing strategies.


