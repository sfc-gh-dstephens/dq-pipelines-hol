# From Raw to Reliable: Build AI-Powered Data Quality Pipelines with Cortex Code

In this hands-on lab you will use **Cortex Code**, the AI coding assistant built into Snowflake's web interface, to turn five messy raw tables into a fully monitored, continuously validated data pipeline — without writing a single line of code manually. You will attach Data Metric Functions, set expectations, configure notifications, build an AI enrichment layer, deploy an auto-refreshing validation pipeline with Dynamic Tables, and launch a Snowflake Intelligence agent for ad-hoc root-cause analysis, all through natural language.

**The scenario:** An e-commerce data engineering team has discovered that raw order, customer, and inventory data arrives with significant quality problems: missing customer IDs, duplicate records, negative order totals, orphaned foreign keys, and invalid category codes. A single bad-data incident last quarter caused mis-shipments and a revenue reporting error. The team needs a reliable, automated pipeline running before their next major sales event.

---

### Prerequisites

- A Snowflake account with the **ACCOUNTADMIN** role (or a role with sufficient privileges)
- Cortex Code enabled in your Snowflake environment
- A modern web browser
- Approximately 50 minutes

### What You Will Learn

- Use Cortex Code effectively with **#table grounding**, **plan mode**, **specialized skills**, and **ctx remember** for session context
- Attach system and custom **Data Metric Functions (DMFs)** to tables for automated quality monitoring — including nulls, duplicates, freshness, and business rules
- Create an AI-powered DMF using `SNOWFLAKE.CORTEX.AI_FILTER` to detect suspicious data
- Add **expectations** to DMFs so violations are automatically flagged
- Configure **Notification Integrations** and **database-level DQ notifications** that trigger the moment expectations are breached
- Verify quality results after data loads using DMF monitoring views and on-demand evaluation
- Build an **AI-powered enrichment pipeline** using `AI_EXTRACT` and `AI_REDACT`
- Build an auto-refreshing **Dynamic Table** pipeline that scores, validates, and classifies every order
- Create a **Semantic View** and **Cortex Agent** for conversational root-cause analysis

### What You Will Build

```
Setup 1: Infrastructure (warehouse, database, schemas, tables)
  -> Exercise 1: Data Metric Functions & Freshness (attach DMFs before data)
    -> Exercise 2: Expectations (set quality thresholds)
      -> Exercise 3: Notifications (email integration + DB-level DQ notifications)
        -> Setup 2: Load Data (populate tables with realistic defects)
          -> Exercise 4: Check Quality (verify DMF results + expectation violations)
            -> Exercise 5: AI Enrichment Pipeline (AI_EXTRACT, AI_REDACT)
              -> Exercise 6: Dynamic Table Pipeline (scored, validated orders)
                -> Exercise 7: Semantic View & Intelligence Agent
```

---

## Setup 1: Environment & Infrastructure

### Create a Workspace

1. Open your browser and navigate to your Snowflake account URL
2. Log in and ensure you are using the **ACCOUNTADMIN** role
3. Click **Projects** in the left sidebar
4. Select **Workspaces** from the dropdown menu
5. Click **+ Workspace** to create a new workspace (or open an existing one)
6. Inside the workspace, click **+** in the tab bar and select **SQL file**
7. The **Cortex Code AI assistant panel** appears on the right side

> **Tip:** The Cortex Code panel is context-aware — it knows which database, schema, and files you are working with as you navigate Snowflake.

### Cortex Code Power Features

Throughout this lab, take advantage of these Cortex Code capabilities:

| Feature | What It Does | How to Use |
|---------|-------------|------------|
| **Plan Mode** | CoCo outlines its approach before executing, letting you approve or adjust | Type `/plan` before a complex prompt, or toggle Plan Mode in the CoCo settings |
| **#table Grounding** | Reference a specific table inline so CoCo introspects its schema | Type `#HOL_DQ.RAW.ORDERS` in your prompt — CoCo auto-completes and grounds its response to actual columns |
| **Specialized Skills** | CoCo has built-in expertise for DMFs, Streamlit, Semantic Views, etc. | Ask directly: "Create a DMF..." and CoCo activates its data-quality skill automatically |
| **ctx remember** | Save session context so CoCo remembers decisions across messages | Type `ctx remember: We use TRIGGER_ON_CHANGES for all DMFs in this lab` and CoCo retains it for subsequent prompts |

### Run Setup 1

Open `setup/01_setup_infrastructure.sql` and execute all statements. This creates:
- `HOL_DQ` database with three schemas: `RAW`, `CLEAN`, `SEMANTIC`
- `HOL_DQ_WH` warehouse (XSMALL, auto-suspend 300s)
- Five empty tables with realistic column definitions

> The script is non-destructive. Safe to re-run.

---

## Exercise 1: Data Metric Functions & Freshness

Attach DMFs to the empty tables now so they are ready to evaluate as soon as data lands.

See `exercises/01_dmf_and_freshness.sql` for all prompts.

**What you will do:**
1. Attach system DMFs (NULL_COUNT, DUPLICATE_COUNT) to RAW.ORDERS
2. Create a custom DMF for negative order totals
3. Create an AI-powered DMF using CORTEX.AI_FILTER for suspicious addresses
4. Attach the FRESHNESS DMF on ORDER_DATE
5. Manually check freshness

> DMFs are attached with `TRIGGER_ON_CHANGES` — they will auto-evaluate once data arrives.

---

## Exercise 2: DMF Expectations

Add expectations (thresholds) to DMFs so violations trigger notifications automatically.

See `exercises/02_expectations.sql` for prompts.

**What you will do:**
1. Add expectations: `few_negatives`, `no_duplicates`, `low_nulls`, `fresh_data`

> Expectations won't fire yet — there's no data. They'll be evaluated after Setup 2.

---

## Exercise 3: Notifications

Configure the notification integration so the team is alerted when expectations are violated.

See `exercises/03_notifications.sql` for prompts.

**What you will do:**
1. Create an email notification integration
2. Enable database-level DQ notifications on HOL_DQ

> Once enabled, Snowflake automatically sends a notification whenever a DMF detects an expectation violation — for any table in the database.

---

## Setup 2: Load Data

Open `setup/02_setup_data.sql` and execute all statements. This populates the five tables with realistic e-commerce data including intentional quality defects:

| Table | Expected Rows | Known Defects |
|-------|--------------|---------------|
| RAW.ORDERS | ~5,150 | ~8% NULL customer_id, ~2% negative totals, ~150 duplicate order_ids |
| RAW.CUSTOMERS | ~2,040 | ~5% malformed emails, ~40 duplicate customer_ids |
| RAW.PRODUCTS | 500 | ~5% invalid categories, ~3% price outliers |
| RAW.INVENTORY | 1,000 | ~3% orphaned product_ids, ~5% negative stock |
| RAW.SHIPMENTS | 4,000 | ~5% NULL tracking on DELIVERED, ~4% future ship dates |

> After data insertion, the DMFs will trigger evaluation automatically. Results may take 1-2 minutes to appear.

---

## Exercise 4: Check Quality Results

Now that data has been loaded, verify that DMFs ran and expectations fired.

See `exercises/04_check_quality.sql` for prompts.

**What you will do:**
1. Query DMF results from the monitoring view
2. Evaluate expectations on demand
3. Check expectation violation history

> You should see violations for `no_duplicates` (we inserted ~150 duplicate order_ids) and potentially `few_negatives` and `low_nulls`.

---

## Exercise 5: AI-Powered Enrichment Pipeline

Use Cortex AI functions to structure and protect your data before it reaches the CLEAN schema.

See `exercises/05_ai_enrich_pipeline.sql` for prompts.

**What you will do:**
1. Extract structured address components with AI_EXTRACT
2. Redact PII from shipping addresses with AI_REDACT
3. Combine into an enrichment view: `HOL_DQ.CLEAN.AI_ENRICHED_ORDERS`

> This view is your reference pattern for an AI enrichment layer. In production, you would materialize this as a Dynamic Table for incremental processing.

---

## Exercise 6: Build a Validated Data Pipeline (Dynamic Table)

Define a transformation query with quality scoring, set a refresh interval, and let Snowflake handle re-execution automatically.

See `exercises/06_dynamic_table_pipeline.sql` for the prompt.

**What you will do:**
1. Create `HOL_DQ.CLEAN.VALIDATED_ORDERS` dynamic table that:
   - Deduplicates on ORDER_ID
   - Rejects NULL customer_id and negative totals
   - Scores remaining rows 0-100
   - Classifies as CLEAN / REVIEW_NEEDED / REJECTED
2. Verify quality status distribution
3. Check refresh history

> The pipeline is live. Every time raw orders change, Snowflake re-validates within 1 minute.

---

## Exercise 7: Create a Quality Monitoring Agent

Give the data team self-service analytics through Snowflake Intelligence — ad-hoc questions in natural language, no SQL required.

See `exercises/07_semantic_view_agent.sql` for prompts.

**What you will do:**
1. Create semantic view `HOL_DQ.SEMANTIC.ORDER_QUALITY`
2. Create Cortex Agent `HOL_QUALITY_AGENT`
3. Test in Snowflake Intelligence with questions like:
   - "Which region has the highest rejection rate?"
   - "How does clean order rate compare across customer tiers?"

---

## Conclusion

You have built a complete AI-powered data quality pipeline using Cortex Code in Snowsight — entirely through natural language.

### What You Built

| Asset | What It Does |
|-------|-------------|
| **Data Metric Functions** | NULL, duplicate, freshness, custom, and AI-powered quality checks |
| **Expectations** | Threshold-based violation detection with automatic notification |
| **Notifications** | Email alerts on expectation breach — zero manual monitoring |
| **AI Enrichment Pipeline** | AI_EXTRACT + AI_REDACT in a reusable view |
| **Dynamic Table** | Auto-refreshing pipeline scoring every order as CLEAN / REVIEW_NEEDED / REJECTED |
| **Semantic View + Agent** | Conversational quality analytics via Snowflake Intelligence |

### Cleanup

To remove objects created during this lab:

```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE  IF EXISTS HOL_DQ;
DROP WAREHOUSE IF EXISTS HOL_DQ_WH;
DROP NOTIFICATION INTEGRATION IF EXISTS HOL_DQ_EMAIL_INT;
```

See `exercises/cleanup.sql` for granular cleanup including individual DMF removal.

### Related Resources

- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/ui-snowsight-cortex-code)
- [Cortex AI Functions](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)
- [Data Metric Functions Documentation](https://docs.snowflake.com/en/user-guide/data-quality-intro)
- [System DMFs Reference](https://docs.snowflake.com/en/user-guide/data-quality-system-dmfs)
- [DQ Notifications](https://docs.snowflake.com/en/user-guide/data-quality-notifications)
- [Dynamic Tables Documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-about)
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/snowflake-intelligence)
