-- ========================================================================
-- Exercise 6: Notifications & Alerts
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Close the detection-to-response loop: get notified the moment a
-- quality threshold is breached.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Create a notification integration for email alerts
-- -----------------------------------------------------------------------
/*
Create an email notification integration called BRIGHTCART_DQ_EMAIL_INT
that is enabled and allows recipients 'dstephens@snowflake.com'.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 2: Enable DQ notifications on the database
-- -----------------------------------------------------------------------
/*
Configure DATA_QUALITY_MONITORING_SETTINGS on the BRIGHTCART_DQ database
to enable notifications. Use the BRIGHTCART_DQ_EMAIL_INT integration,
set cooldown_hours to 1, and include metadata. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 3: Create an alert for negative order totals
-- -----------------------------------------------------------------------
/*
Create a Snowflake alert called BRIGHTCART_DQ.RAW.NEGATIVE_TOTALS_ALERT
using warehouse BRIGHTCART_DQ_WH that runs every 60 minutes. The alert
should fire when the count of rows with ORDER_TOTAL < 0 in
BRIGHTCART_DQ.RAW.ORDERS exceeds 50. When it fires, send an email via
SYSTEM$SEND_EMAIL using the BRIGHTCART_DQ_EMAIL_INT integration to
'dstephens@snowflake.com' with subject 'DQ ALERT: Negative order totals
threshold breached' and a body that includes the count of negative rows.
Then resume the alert. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 4: Create an alert for data freshness
-- -----------------------------------------------------------------------
/*
Create a Snowflake alert called BRIGHTCART_DQ.RAW.FRESHNESS_ALERT using
warehouse BRIGHTCART_DQ_WH that runs every 60 minutes. The alert should
fire when SNOWFLAKE.CORE.FRESHNESS on the ORDER_DATE column of
BRIGHTCART_DQ.RAW.ORDERS exceeds 86400 seconds (24 hours). When it fires,
send an email via SYSTEM$SEND_EMAIL using BRIGHTCART_DQ_EMAIL_INT to
'dstephens@snowflake.com' with subject 'DQ ALERT: Orders table data is
stale' and a body showing the freshness in hours. Then resume the alert.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 5: Check alert history
-- -----------------------------------------------------------------------
/*
Query the alert history for all alerts in the BRIGHTCART_DQ database
from the last 24 hours. Show alert name, state, scheduled time, and
completed time. Order by scheduled time descending. Execute the SQL.
*/
-- -----------------------------------------------------------------------
