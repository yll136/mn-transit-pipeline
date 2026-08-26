# Minnesota Farm Supply Chain Analytics

[![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![AWS](https://img.shields.io/badge/AWS_S3-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/s3/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-success?style=flat-square)
![Tests](https://img.shields.io/badge/Tests-39%20Passed-brightgreen?style=flat-square)
![Models](https://img.shields.io/badge/dbt%20Models-12-blue?style=flat-square)
![Test Coverage](https://img.shields.io/badge/Test%20Pass%20Rate-100%25-success?style=flat-square)

An end-to-end ELT (extract-load-transform) data pipeline analyzing synthetical agricultural supply chain operations data across Minnesota. Synthetical data was created by AI. 

---

##  Project Overview

This project demonstrates modern data engineering best practices by building a production-ready analytics pipeline using **AWS S3**, **Snowflake**, and **dbt**. The pipeline processes **13,202 transaction records** across **6 data sources** to deliver actionable business intelligence for agricultural supply chain management.

### Key Achievements

- ✅ **100% test pass rate** - 39 automated data quality tests
- ✅ **3-layer medallion architecture** - Bronze → Silver → Gold
- ✅ **12 dbt models** - 6 staging views + 6 analytics tables
- ✅ **Star schema design** - Optimized for BI and reporting
- ✅ **Production-ready documentation** - Comprehensive lineage and testing

---

## Architecture

![ELT Data Pipeline Architecture](img/elt_pipeline.png)

### Data Flow

**Extract → Load → Transform (ELT)**
1. **Extract**: Synthetic Minnesota agriculture data (CSV files)
2. **Load**: Upload to AWS S3 → Copy into Snowflake RAW schema
3. **Transform**: dbt models create cleaned staging views and analytics tables

![Data Lineage Graph](img/DAG.png)

---

## Technology Stack

| Category | Technologies |
|----------|-------------|
| **Cloud Storage** | AWS S3 |
| **Data Warehouse** | Snowflake |
| **Transformation** | dbt (Data Build Tool) 1.11.x |
| **Version Control** | Git, GitHub |
| **Languages** | SQL, Python, YAML |
| **Testing** | dbt tests (unique, not_null, relationships, accepted_values) |

---

## Data Models

![Project Structure](img/models.png)

### Bronze Layer (RAW Schema)
Raw data ingested from S3 with minimal transformation:

| Table | Rows | Description |
|-------|------|-------------|
| `products` | 40 | Agricultural product catalog (seeds, fertilizers, equipment) |
| `suppliers` | 25 | Supplier information and contact details |
| `farms` | 150 | Customer farm details with location and size |
| `orders` | 2,500 | Purchase orders with delivery tracking |
| `order_items` | 10,087 | Order line items with pricing and discounts |
| `inventory` | 400 | Stock levels across warehouse locations |

**Total Bronze Records: 13,202**

---

### Silver Layer (STAGING Schema)
Cleaned and standardized data with business logic:

| View | Source | Key Transformations |
|------|--------|---------------------|
| `stg_products` | products | Product categorization, price tiers |
| `stg_suppliers` | suppliers | Performance metrics, tenure calculations |
| `stg_farms` | farms | Customer segmentation, acreage categories |
| `stg_orders` | orders | Delivery performance indicators, seasonal flags |
| `stg_order_items` | order_items | Discount calculations, data validation |
| `stg_inventory` | inventory | Stock status flags, coverage ratios |

- ✅ Data type casting and standardization
- ✅ Calculated fields (`delivery_delay_days`, `stock_status`)
- ✅ Business logic (`on_time_delivery` boolean)
- ✅ Data quality validation (`line_total_validated`)

---

### Gold Layer (ANALYTICS Schema)
Business-ready dimensional models optimized for BI tools:

#### Dimension Tables

**`dim_products`** (40 rows)
- Product catalog with price tiers and category groupings
- Columns: `product_id`, `product_name`, `category`, `product_category_group`, `price_tier`

**`dim_suppliers`** (25 rows)
- Supplier master with reliability scores and delivery speed categories
- Columns: `supplier_id`, `supplier_name`, `reliability_tier`, `delivery_speed_category`, `years_active`

**`dim_farms`** (150 rows)
- Customer dimension with farm characteristics and regional grouping
- Columns: `farm_id`, `farm_name`, `farm_type`, `region_group`, `is_organic`, `years_as_customer`

#### Fact Tables

**`fct_orders`** (2,500 rows)

![Fact Orders Detail](img/fct_orders.png)

Order transactions with aggregated metrics and dimensional context:
- **Measures**: `net_order_total`, `total_quantity`, `total_line_items`, `delivery_delay_days`
- **Dimensions**: Date (year/month/quarter), farm, supplier, region, season
- **Flags**: `is_delivered`, `is_rush_order`, `on_time_delivery`
- **Business Context**: Farm type, supplier reliability, seasonal categorization

#### Metrics Tables

**`monthly_sales_summary`** (~120 rows)
- Time-series sales KPIs aggregated by month and region
- Metrics: Total orders, revenue, avg order value, on-time delivery rate, rush order percentage

**`supplier_performance`** (25 rows)
- Supplier scorecards with composite performance scores (0-100)
- Metrics: Total revenue, on-time rate, delivery variance, supplier status, overall performance score

---

## 🎯 Key Features & Business Value

### Data Quality Engineering
- **39 automated tests** with 100% pass rate
- **Referential integrity** validation (foreign key relationships)
- **Business rule enforcement** (accepted values, not null constraints)
- **Custom validation** (calculation accuracy checks)

### Business Intelligence Capabilities

#### Seasonal Trend Analysis
- Spring Planting season (April-May): Higher order volumes
- Fall Harvest season (September-October): Equipment purchases peak
- Winter slowdown (November-February): Increased discount rates

#### Supplier Performance Tracking
- Composite scoring: Reliability (40%) + Delivery speed (30%) + On-time rate (30%)
- 92% average on-time delivery rate across all suppliers
- Supplier status tracking: Active, Recently Active, Inactive, Dormant

#### Inventory Optimization
- Stock status categorization: Out of Stock, Low Stock, Normal, Overstocked
- Stock coverage ratio calculation
- Days since restock tracking

#### Regional Insights
- 5 Minnesota regions: Northern, Central, Southern, Western, Twin Cities Metro
- County-level delivery patterns
- Urban/metro vs. rural farm analysis

---

🙏 Acknowledgments

- Data synthetically generated for portfolio demonstration purposes
- Inspired by real Minnesota agricultural supply chain operations
- Built as part of data engineering portfolio development
- Thanks to the dbt community for excellent documentation and resources

---

📞 Contact & Feedback

Interested in discussing this project or data engineering opportunities? Feel free to reach out!
- Open an issue on this repository for questions
- Connect with me on LinkedIn for professional inquiries
- Check out my other projects on GitHub