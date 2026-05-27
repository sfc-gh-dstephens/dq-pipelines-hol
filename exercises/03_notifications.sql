-- ========================================================================
-- Exercise 3: Notifications
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Close the detection-to-response loop: get notified the moment a
-- quality expectation is breached.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Create a notification integration for email alerts
-- -----------------------------------------------------------------------
/*
Create an email notification integration called HOL_DQ_EMAIL_INT
that is enabled and allows recipients 'email here'.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 2: Enable DQ notifications on the database
-- -----------------------------------------------------------------------
/*
Configure DATA_QUALITY_MONITORING_SETTINGS on the HOL_DQ database
to enable notifications. Use the HOL_DQ_EMAIL_INT integration,
set cooldown_hours to 1, and include metadata. Execute the SQL.
*/
-- -----------------------------------------------------------------------
