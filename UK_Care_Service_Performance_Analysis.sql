
-- ============================================================
-- UK CARE SERVICE PERFORMANCE ANALYSIS (2025)
-- SQL DATA ANALYST PORTFOLIO PROJECT
-- ============================================================
-- Database: SQLite
-- Dataset: Synthetic UK care service operational data
--
-- Project Objective:
-- Analyse operational performance, identify locations
-- requiring further investigation and support
-- evidence based management decisions.
-- ============================================================


-- ============================================================
-- SECTION 1: DATA OVERVIEW AND QUALITY CHECKS
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT service_location) AS total_locations,
    COUNT(DISTINCT record_id) AS unique_record_ids,
    COUNT(*) - COUNT(DISTINCT record_id)
        AS duplicate_or_null_record_ids,
    SUM(
        CASE
            WHEN service_user_satisfaction_score IS NULL
                 OR TRIM(
                     CAST(service_user_satisfaction_score AS TEXT)
                 ) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_satisfaction_scores
FROM care_performance;


-- ============================================================
-- SECTION 2: OVERALL PERFORMANCE KPIs
-- ============================================================

SELECT
    SUM(scheduled_visits) AS total_scheduled_visits,
    SUM(completed_visits) AS total_completed_visits,
    SUM(missed_visits) AS total_missed_visits,
    SUM(delayed_visits) AS total_delayed_visits,

    ROUND(
        SUM(missed_visits) * 100.0 /
        NULLIF(SUM(scheduled_visits), 0),
        2
    ) AS missed_visit_rate_pct,

    ROUND(
        SUM(delayed_visits) * 100.0 /
        NULLIF(SUM(completed_visits), 0),
        2
    ) AS delayed_visit_rate_pct,

    ROUND(
        SUM(staff_worked_hours) * 100.0 /
        NULLIF(SUM(staff_scheduled_hours), 0),
        2
    ) AS staff_attendance_pct,

    SUM(incident_reports) AS total_incident_reports,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(
                    CAST(service_user_satisfaction_score AS TEXT)
                ) = ''
                THEN NULL
                ELSE CAST(
                    service_user_satisfaction_score AS REAL
                )
            END
        ),
        3
    ) AS average_satisfaction_score

FROM care_performance;


-- ============================================================
-- SECTION 3: LOCATION PERFORMANCE ANALYSIS
-- ============================================================


SELECT
    service_location,

    SUM(scheduled_visits) AS total_scheduled_visits,
    SUM(missed_visits) AS total_missed_visits,

    ROUND(
        SUM(missed_visits) * 100.0 /
        NULLIF(SUM(scheduled_visits), 0),
        2
    ) AS missed_visit_rate_pct,

    ROUND(
        SUM(delayed_visits) * 100.0 /
        NULLIF(SUM(completed_visits), 0),
        2
    ) AS delayed_visit_rate_pct,

    ROUND(
        SUM(staff_worked_hours) * 100.0 /
        NULLIF(SUM(staff_scheduled_hours), 0),
        2
    ) AS staff_attendance_pct

FROM care_performance

GROUP BY service_location

ORDER BY missed_visit_rate_pct DESC;


-- ============================================================
-- SECTION 4: MONTHLY PERFORMANCE ANALYSIS
-- ============================================================


SELECT
    strftime('%Y-%m', service_date) AS service_month,

    SUM(scheduled_visits) AS total_scheduled_visits,
    SUM(missed_visits) AS total_missed_visits,

    ROUND(
        SUM(missed_visits) * 100.0 /
        NULLIF(SUM(scheduled_visits), 0),
        2
    ) AS missed_visit_rate_pct,

    ROUND(
        SUM(delayed_visits) * 100.0 /
        NULLIF(SUM(completed_visits), 0),
        2
    ) AS delayed_visit_rate_pct,

    ROUND(
        SUM(staff_worked_hours) * 100.0 /
        NULLIF(SUM(staff_scheduled_hours), 0),
        2
    ) AS staff_attendance_pct,

    SUM(incident_reports) AS total_incident_reports

FROM care_performance

GROUP BY strftime('%Y-%m', service_date)

ORDER BY service_month ASC;


-- ============================================================
-- SECTION 5: PRIORITY LOCATION IDENTIFICATION
-- ============================================================


WITH overall_rates AS (

    SELECT
        SUM(missed_visits) * 100.0 /
            NULLIF(SUM(scheduled_visits), 0)
            AS overall_missed_rate,

        SUM(delayed_visits) * 100.0 /
            NULLIF(SUM(completed_visits), 0)
            AS overall_delayed_rate

    FROM care_performance

),

location_rates AS (

    SELECT
        service_location,

        SUM(missed_visits) * 100.0 /
            NULLIF(SUM(scheduled_visits), 0)
            AS missed_rate,

        SUM(delayed_visits) * 100.0 /
            NULLIF(SUM(completed_visits), 0)
            AS delayed_rate

    FROM care_performance

    GROUP BY service_location

)

SELECT
    l.service_location,

    ROUND(l.missed_rate, 2)
        AS missed_visit_rate_pct,

    ROUND(l.delayed_rate, 2)
        AS delayed_visit_rate_pct,

    CASE
        WHEN l.missed_rate > o.overall_missed_rate
         AND l.delayed_rate > o.overall_delayed_rate
        THEN 'Priority Review'
        ELSE 'Monitor'
    END AS performance_status

FROM location_rates AS l

CROSS JOIN overall_rates AS o

ORDER BY
    CASE
        WHEN l.missed_rate > o.overall_missed_rate
         AND l.delayed_rate > o.overall_delayed_rate
        THEN 0
        ELSE 1
    END,
    l.missed_rate DESC;


-- ============================================================
-- SECTION 6: KEY FINDINGS AND MANAGEMENT RECOMMENDATIONS
-- ============================================================

-- KEY FINDING 1: OVERALL SERVICE PERFORMANCE
--
-- Approximately 2.62% of scheduled visits were missed.
-- Approximately 6.5% of completed visits were delayed.
-- Staff attendance was approximately 96.8%.
-- The dataset recorded 870 incident reports.
-- Average satisfaction was 4.399 out of 5,
-- excluding missing responses.


-- KEY FINDING 2: LOCATION PERFORMANCE
--
-- Northampton Central recorded the highest missed-
-- visit rate at 3.12%.
--
-- Kettering recorded the lowest at 2.10%.
--
-- The difference was 1.02 percentage points.


-- KEY FINDING 3: PRIORITY LOCATIONS
--
-- Three locations exceeded both organisation-wide
-- missed-visit and delayed-visit rates:
--
-- Northampton Central
-- Milton Keynes North
-- Wellingborough


-- MANAGEMENT RECOMMENDATIONS
--
-- 1. Prioritise operational reviews at the three
--    identified locations.
--
-- 2. Investigate staffing capacity, scheduling,
--    travel arrangements and other possible
--    contributing factors.
--
-- 3. Monitor missed-visit and delayed-visit
--    percentages monthly.
--
-- 4. Review incident-report patterns and severity
--    before interpreting the incident totals.
--
-- 5. Evaluate whether improvement actions lead
--    to measurable performance changes.
--
-- CONCLUSION
--
-- SQL analysis identified differences in operational
-- performance across locations and over time.
--
-- The results can support evidence-based management
-- decisions and help prioritise further investigation.
--
-- This project uses synthetic data. Correlations
-- and performance differences do not prove causation.
