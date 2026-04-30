# From Raw to Reliable: Build AI-Powered Data Quality Pipelines with Cortex Code

> **BrightCart is a fictional company.** All data, names, metrics, and scenarios are simulated for demonstration purposes only.

In this quickstart you will use **Cortex Code**, the AI coding assistant built into Snowflake's web interface, to turn five messy raw tables into a fully monitored, continuously validated data pipeline — without writing a single line of code manually. You will fix broken quality check queries, attach Data Metric Functions, build an auto-refreshing validation pipeline with Dynamic Tables, deploy a live Data Quality Dashboard, and launch a Snowflake Intelligence agent for ad-hoc root-cause analysis, all through natural language.

**The scenario:** BrightCart, a fictional e-commerce company, is preparing for its annual flash sale. The data engineering team has discovered that raw order, customer, and inventory data arrives with significant quality problems: missing customer IDs, duplicate records, negative order totals, orphaned foreign keys, and invalid category codes. A single bad-data incident last quarter caused mis-shipments and a revenue reporting error. The team needs a reliable, automated pipeline running before the sale goes live.

---

### Prerequisites

- A Snowflake account with the **ACCOUNTADMIN** role (or a role with sufficient privileges)
- Cortex Code enabled in your Snowflake environment (**Settings → Cortex Code → toggle on**)
- A modern web browser
- Approximately 50 minutes

### What You Will Learn

- Fix broken SQL quality checks using natural language, the inline Fix button, and schema introspection
- Attach system and custom **Data Metric Functions (DMFs)** to tables for automated quality monitoring
- Create an AI-powered DMF using `SNOWFLAKE.CORTEX.AI_FILTER` to detect suspicious data
- Build an auto-refreshing **Dynamic Table** pipeline that scores, validates, and classifies every order
- Deploy a **Streamlit** Data Quality Dashboard served live from the pipeline
- Create a **Semantic View** and **Cortex Agent** for conversational root-cause analysis

### What You Will Build

```
Raw Data (5 tables with quality defects)
  -> Fix Broken Code (natural language + Fix button)
    -> Data Metric Functions (automated quality checks per column)
      -> Dynamic Table (scored, validated, classified orders — auto-refresh)
        -> Streamlit Dashboard (live quality monitoring for the data team)
        -> Intelligence Agent (conversational root-cause analysis)
```

---

## Step 1: Environment Setup

### Create a Workspace

1. Open your browser and navigate to your Snowflake account URL
2. Log in and ensure you are using the **ACCOUNTADMIN** role
3. Click **Projects** in the left sidebar
4. Select **Workspaces** from the dropdown menu
5. Click **+ Workspace** to create a new workspace (or open an existing one)
6. Inside the workspace, click **+** in the tab bar and select **SQL file**
7. The **Cortex Code AI assistant panel** appears on the right side

> **Tip:** The Cortex Code panel is context-aware — it knows which database, schema, and files you are working with as you navigate Snowflake.

### Load BrightCart Data

Cortex Code in the UI cannot fetch files from external URLs, so you will copy the setup script into a worksheet.

1. Open the setup script from the GitHub repo: [00_setup.sql](exercises/00_setup.sql)
2. **Copy the full script** and **paste it into your SQL worksheet**
3. In the Cortex Code panel, type:

```
Execute this setup script in the worksheet. Proceed autonomously —
allow all statements in BRIGHTCART_DQ.
```

4. CoCo will parse and execute each statement. When the **permission prompt** appears, choose **"Allow all non-read SQL"** to avoid repeated confirmations.
5. The script creates:
   - `BRIGHTCART_DQ` database with three schemas: `RAW`, `CLEAN`, `SEMANTIC`
   - `BRIGHTCART_DQ_WH` warehouse (XSMALL, auto-suspend 300s)
   - Five tables loaded with realistic e-commerce data — each with intentional quality defects

> The script is non-destructive. If `BRIGHTCART_DQ` already exists, existing objects are preserved. Safe to re-run.

**Alternative:** Paste the script and click **Run All** in the worksheet manually.

> **Note:** The setup script requires the **ACCOUNTADMIN** role. No external integrations or Git connections are needed — all data is generated inline using Snowflake's `TABLE(GENERATOR())`.

### Verify Data Loaded

In the Cortex Code panel, type:

```
Show me row counts for all tables in BRIGHTCART_DQ.RAW
```

| Table | Expected Rows |
|-------|--------------|
| RAW.ORDERS | ~5,150 (5,000 + ~150 duplicate order_ids) |
| RAW.CUSTOMERS | ~2,040 (2,000 + ~40 duplicate customer_ids) |
| RAW.PRODUCTS | 500 |
| RAW.INVENTORY | 1,000 |
| RAW.SHIPMENTS | 4,000 |

Then ask CoCo to give you a first look at the quality landscape:

```
Profile the BRIGHTCART_DQ.RAW.ORDERS table. Show me null rates per
column, count of negative order_total values, and count of duplicate
order_ids. Keep it to a single query.
```

CoCo will surface the key defects you will fix throughout this lab.

---

## Step 2: Fix Broken Quality Check Code

Cortex Code can diagnose and fix broken SQL using natural language, the inline Fix button, and the Explain feature. In this step you will use all three methods on a data quality check query that a junior analyst left behind.

### Stage the Broken Query

Copy and paste this **intentionally broken** SQL into your worksheet:

```sql
SELECT
    region,
    COUNT(*)                                                      AS total_orders,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)               AS null_customer_count,
    COUNT(CASE WHEN order_totl < 0 THEN 1 END)                    AS negative_total_count,
    COUNT(CASE WHEN shiping_address IS NULL THEN 1 END)           AS missing_address_count,
    ROUND(
        COUNT(CASE WHEN customer_id IS NULL THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 2
    )                                                             AS null_pct
FROM BRIGHTCART_DQ.ORDR.ORDERS
GROUP BY region
ORDER BY total_orders DESC;
```

Three errors are hidden in this query:
1. `order_totl` should be `order_total`
2. `BRIGHTCART_DQ.ORDR` should be `BRIGHTCART_DQ.RAW`
3. `shiping_address` should be `shipping_address`

### Use the Explain Button

1. **Select the entire query** in the worksheet
2. The **inline toolbar** appears: Add to Chat, Explain, Quick Edit, Format
3. Click **Explain**
4. CoCo returns a plain-English description of what the quality check is intended to do

> If you inherited this query from someone who left the team, you do not need to reverse-engineer it. Highlight the code and click Explain.

### Method 1: Natural Language Fix

Fix `order_totl` using natural language:

1. **Select `order_totl`** on line 4
2. Click **"Add to Chat"** in the inline toolbar
3. In the CoCo panel, type:

```
Fix this column name typo — the correct column is order_total
```

4. CoCo returns the corrected line. **Accept the change.**

### Method 2: Inline Fix Button

Fix `ORDR` using the compiler:

1. **Run the query** — you get a runtime error: `Schema 'BRIGHTCART_DQ.ORDR' does not exist`
2. A **Fix** button appears below the error message
3. **Click Fix** — CoCo shows a diff view with the correction: `ORDR` → `RAW`
4. Click **"Keep all in file"** to accept

### Method 3: Schema Introspection

Fix `shiping_address` using the Fix button and schema lookup:

1. **Run the query** — you get: `invalid identifier 'SHIPING_ADDRESS'`
2. **Click Fix** — CoCo checks the actual column list of `RAW.ORDERS` and identifies `SHIPPING_ADDRESS` as the correct name
3. **Accept the change.** Run the query — 4 rows returned, one per region.

> CoCo doesn't just pattern-match the error message — it introspects the live table schema to find the right column name. This is especially useful when you don't know what the correct identifier should be.

---

## Step 3: Create Data Metric Functions

Data Metric Functions (DMFs) are Snowflake's native data quality feature. You define a measurement once, attach it to a column, and Snowflake evaluates it automatically on a schedule or whenever the data changes. In this step you will attach system DMFs, write a custom DMF, and add an AI-powered DMF using Cortex AI functions.

### Attach System DMFs

In the Cortex Code panel, type:

```
Attach two system Data Metric Functions to BRIGHTCART_DQ.RAW.ORDERS:
1. SNOWFLAKE.CORE.NULL_COUNT on the CUSTOMER_ID column
2. SNOWFLAKE.CORE.DUPLICATE_COUNT on the ORDER_ID column

Set the schedule to TRIGGER_ON_CHANGES.
Then query INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES to confirm
both DMFs are attached. Execute the SQL.
```

CoCo generates the `ALTER TABLE ... ADD DATA METRIC FUNCTION` statements and the confirmation query. You should see both DMFs listed with `STARTED` status.

> `TRIGGER_ON_CHANGES` means Snowflake re-evaluates the metric whenever new data is inserted or existing rows change — no manual scheduling required.

### Create a Custom DMF

In the Cortex Code panel, type:

```
Create a custom Data Metric Function in BRIGHTCART_DQ.RAW called
NEGATIVE_TOTAL_COUNT that counts rows where order_total is less than zero.
Then attach it to BRIGHTCART_DQ.RAW.ORDERS on the ORDER_TOTAL column
with TRIGGER_ON_CHANGES schedule. Execute the SQL.
```

CoCo generates a `CREATE DATA METRIC FUNCTION` with a simple `SELECT COUNT(*)` body, then attaches it to the table.

### Add an AI-Powered DMF

This is where Cortex AI makes data quality active. In the Cortex Code panel, type:

```
Create an AI-powered Data Metric Function in BRIGHTCART_DQ.RAW called
AI_SUSPICIOUS_ADDRESS_COUNT. It should take a TABLE argument with a
shipping_address column and return the count of rows where
SNOWFLAKE.CORTEX.AI_FILTER classifies the address as NOT a real US
shipping address. Attach it to BRIGHTCART_DQ.RAW.ORDERS on the
SHIPPING_ADDRESS column with TRIGGER_ON_CHANGES schedule. Execute the SQL.
```

CoCo creates a DMF that calls `SNOWFLAKE.CORTEX.AI_FILTER` on each address — using an LLM to evaluate whether each value looks like a legitimate US address.

> This pattern is powerful for any text column where rule-based validation is insufficient: product descriptions, customer notes, free-text fields. The LLM evaluates context, not just format.

### Query Quality Results

In the Cortex Code panel, type:

```
Show me the latest Data Metric Function results for
BRIGHTCART_DQ.RAW.ORDERS. Include metric name, value, and timestamp.
```

You should see measurements for `NULL_COUNT`, `DUPLICATE_COUNT`, `NEGATIVE_TOTAL_COUNT`, and `AI_SUSPICIOUS_ADDRESS_COUNT`.

> If results are not yet available, DMF evaluation can take 1–2 minutes after attachment. You can ask CoCo: *"How do I manually trigger DMF evaluation for BRIGHTCART_DQ.RAW.ORDERS?"*

---

## Step 4: Build a Validated Data Pipeline

The question after a good quality profile is always: *"When does this go stale?"* A Dynamic Table solves this — define a transformation query, set a refresh interval, and Snowflake handles re-execution automatically. No Airflow, no cron jobs, no orchestration layer.

### Build the Dynamic Table

In the Cortex Code panel:

```
Create a Dynamic Table called BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
using warehouse BRIGHTCART_DQ_WH with a target lag of 1 minute.

It should read from BRIGHTCART_DQ.RAW.ORDERS and do the following:
- Deduplicate on ORDER_ID, keeping the row with the earliest ORDER_DATE
- Reject rows where CUSTOMER_ID is NULL or ORDER_TOTAL is negative —
  these are hard quality failures
- For remaining rows, compute a QUALITY_SCORE from 0–100: start at 100
  and subtract 20 if ORDER_TOTAL is zero, subtract 15 if SHIPPING_ADDRESS
  is NULL, subtract 10 if the absolute difference between ORDER_TOTAL and
  (QUANTITY * UNIT_PRICE) exceeds 1.00
- Add a QUALITY_STATUS column: 'REJECTED' for hard failures, 'CLEAN' for
  scores 90 and above, and 'REVIEW_NEEDED' for everything in between
- Include all original columns plus QUALITY_SCORE and QUALITY_STATUS

Use a CTE to deduplicate before applying quality rules — do not apply
scoring logic directly on the raw table, as duplicates will skew results.

Execute the SQL.
```

CoCo generates a `CREATE OR REPLACE DYNAMIC TABLE` statement with a deduplication CTE, scoring logic, and status classification.

### Verify the Pipeline

Query the validated table:

```
Show me a quality status breakdown from BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS —
count and percentage for each QUALITY_STATUS value.
```

Expected approximate distribution:

| QUALITY_STATUS | Count | % |
|---|---|---|
| CLEAN | ~4,000 | ~79% |
| REVIEW_NEEDED | ~600 | ~12% |
| REJECTED | ~450 | ~9% |

Check the refresh history:

```
Show me the refresh history for BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
```

> The pipeline is now live. Every time raw orders are inserted or updated, Snowflake automatically re-runs the validation logic within 1 minute — no manual trigger needed.

If CoCo's output shows unexpected results (all rows REJECTED, or zero CLEAN rows), use the corrected fallback in `exercises/03_dynamic_table_prompt.sql`.

---

## Step 5: Deploy a Data Quality Dashboard

The data team needs something they can check every morning before standup — not a query result, but a real application with color-coded status cards, charts, and drill-down capability.

### Generate the App

In the Cortex Code panel:

```
Build a Streamlit in Snowflake app called "Data Quality Dashboard"
in BRIGHTCART_DQ.CLEAN.

The app should read from the BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
dynamic table and include:

1. A title: "BrightCart — Data Quality Dashboard"
   and a subtitle: "Live pipeline • Powered by Cortex Code"

2. Four summary metric cards showing: total orders, clean order count
   + percentage, review-needed count + percentage, and rejected count
   + percentage. Color clean green, review-needed yellow, rejected red
   using st.markdown with inline HTML.

3. A bar chart showing order count by REGION, grouped by QUALITY_STATUS.

4. A sidebar selectbox to filter by QUALITY_STATUS (All, CLEAN,
   REVIEW_NEEDED, REJECTED). Show a filtered data table below the chart.

5. A "Critical Issues" expander at the bottom showing the 20 rows
   with the lowest QUALITY_SCORE.

Use get_active_session() for all data access. Deploy the app.
```

CoCo generates a complete Streamlit Python file and deploys it to Snowflake.

### Open and Interact

1. Navigate to **Projects → Streamlit** in Snowsight
2. Open the **Data Quality Dashboard**
3. Review the quality status cards, the regional breakdown chart, and drill into REJECTED orders via the sidebar filter

### Iterate with CoCo

After reviewing the initial app, ask CoCo to add a trend view:

```
Add a new section to the Streamlit app below the critical issues expander.
Show a line chart of daily order volume for the past 30 days, split by
QUALITY_STATUS. Read ORDER_DATE from BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
and group by ORDER_DATE and QUALITY_STATUS. Title the section
"Daily Order Quality Trend".
```

> The dashboard reads live from the Dynamic Table — so it always reflects the current state of the pipeline. You can iterate on the design conversationally without rewriting the app from scratch.

If CoCo's output needs adjustment, use the complete fallback app in `exercises/streamlit_shell.py`.

---

## Step 6: Create a Quality Monitoring Agent

The final step: give the data team self-service analytics through Snowflake Intelligence — ad-hoc questions in natural language, no SQL required.

### Create the Semantic View

In the Cortex Code panel:

```
Create a semantic view BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY over these tables:
  - BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS  (primary)
  - BRIGHTCART_DQ.RAW.CUSTOMERS

Join VALIDATED_ORDERS to CUSTOMERS on CUSTOMER_ID.

Dimensions: region, quality_status, status (order status), tier (customer tier)

Metrics:
  total_orders         — count of ORDER_ID
  clean_order_count    — count where QUALITY_STATUS = 'CLEAN'
  rejected_count       — count where QUALITY_STATUS = 'REJECTED'
  clean_order_rate     — clean orders as percentage of total, rounded to 2 decimals
  avg_quality_score    — average QUALITY_SCORE
  null_customer_count  — count where CUSTOMER_ID IS NULL
  negative_total_count — count where ORDER_TOTAL < 0

Execute the SQL.
```

### Create the Agent

```
Create a Cortex Agent called BRIGHTCART_QUALITY_AGENT in
BRIGHTCART_DQ.SEMANTIC. Attach the BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY
semantic view as a Cortex Analyst tool.

Use these response instructions: respond concisely with bullet points,
always include a breakdown by region when relevant, highlight the WEST
region specifically when quality scores or rejection rates are a concern,
and suggest a root cause for any metric that is more than 10% worse
than the overall average.

Grant USAGE on the agent to the PUBLIC role.
```

### Test in Snowflake Intelligence

1. Navigate to **AI & ML → Agents → Snowflake Intelligence tab**
2. Click **"Add existing agent"**, search for `BRIGHTCART_QUALITY_AGENT`, and confirm
3. Switch to **Snowflake Intelligence** and test:

```
Which region has the highest rejection rate and what's causing it?
```

```
How does clean order rate compare across customer tiers?
```

```
Is the WEST region's data quality worse than the other regions?
```

> The full pipeline is now connected: raw messy data → DMF monitoring → Dynamic Table validation → Streamlit dashboard → Intelligence agent. Every layer was built through natural language with Cortex Code.

---

## Conclusion

You have built a complete AI-powered data quality pipeline using Cortex Code in Snowsight — entirely through natural language.

### What You Learned

- How to fix broken SQL using the Explain button, natural language, and the inline Fix button
- How to attach system DMFs and write custom DMFs for automated column-level quality monitoring
- How to use `SNOWFLAKE.CORTEX.AI_FILTER` inside a DMF for LLM-powered quality checks
- How to build an auto-refreshing Dynamic Table that scores, validates, and classifies data
- How to deploy a Streamlit Data Quality Dashboard served live from the pipeline
- How to create Semantic Views and Cortex Agents for conversational root-cause analysis

### What You Built

| Asset | What It Does |
|-------|-------------|
| **Code Fixing** | Fixed a broken DQ query using three CoCo methods |
| **Data Metric Functions** | NULL, duplicate, custom, and AI-powered column-level quality checks |
| **Dynamic Table** | Auto-refreshing pipeline scoring every order as CLEAN / REVIEW_NEEDED / REJECTED |
| **Streamlit Dashboard** | Live Data Quality Dashboard with status cards, charts, and drill-down |
| **Semantic View + Agent** | Conversational quality analytics via Snowflake Intelligence |

### Cleanup

To remove objects created during this lab only:

```sql
USE ROLE ACCOUNTADMIN;
DROP DYNAMIC TABLE  IF EXISTS BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS;
DROP STREAMLIT      IF EXISTS BRIGHTCART_DQ.CLEAN."Data Quality Dashboard";
DROP SEMANTIC VIEW  IF EXISTS BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY;
DROP CORTEX AGENT   IF EXISTS BRIGHTCART_DQ.SEMANTIC.BRIGHTCART_QUALITY_AGENT;
```

To remove everything:

```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE  IF EXISTS BRIGHTCART_DQ;
DROP WAREHOUSE IF EXISTS BRIGHTCART_DQ_WH;
```

See `exercises/cleanup.sql` for the full cleanup script including DMF removal.

### Related Resources

- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/ui-snowsight-cortex-code)
- [Data Metric Functions Documentation](https://docs.snowflake.com/en/user-guide/data-quality-intro)
- [Dynamic Tables Documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-about)
- [Streamlit in Snowflake Documentation](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/snowflake-intelligence)
- [AI_FILTER Function Reference](https://docs.snowflake.com/en/sql-reference/functions/ai_filter)
