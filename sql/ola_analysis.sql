-- ============================================================
-- OLA BENGALURU — PRODUCT ANALYTICS
-- SQL Analysis — All 12 Queries
-- Tool: MySQL Workbench
-- Database: ola_bengaluru
-- Author: Your Name
-- Date: January 2024
-- ============================================================

USE ola_bengaluru;

-- ============================================================
-- QUERY 1: North Star — Overall Ride Completion Metrics
-- Business Question: What is the overall health of the
-- Ola Bengaluru marketplace?
-- ============================================================

SELECT
    COUNT(*)                                                                    AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)                AS Successful_Rides,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)    AS Driver_Cancellations,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END)  AS Customer_Cancellations,
    SUM(CASE WHEN Booking_Status = 'Incomplete' THEN 1 ELSE 0 END)             AS Incomplete_Rides,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Ride_Completion_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Driver_Cancel_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Customer_Cancel_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Incomplete' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Incomplete_Rate_Pct
FROM ola_rides;

-- Finding: 66.97% completion rate — below 70% benchmark
-- Driver cancellations at 19.22% are the primary problem
-- 1 in 3 rides fails to complete

-- ============================================================
-- QUERY 2: Completion Rate by Vehicle Type
-- Business Question: Which vehicle category is underperforming?
-- ============================================================

SELECT
    Vehicle_Type,
    COUNT(*)                                                                    AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)                AS Successful,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)    AS Driver_Cancelled,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END)  AS Customer_Cancelled,
    SUM(CASE WHEN Booking_Status = 'Incomplete' THEN 1 ELSE 0 END)             AS Incomplete,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Completion_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Driver_Cancel_Pct,
    ROUND(AVG(CASE WHEN Booking_Status = 'Success'
          THEN CAST(Booking_Value AS DECIMAL(10,2)) END), 2)                    AS Avg_Booking_Value_Rs,
    ROUND(AVG(CASE WHEN Booking_Status = 'Success'
          THEN CAST(Avg_VTAT AS DECIMAL(10,2)) END), 2)                         AS Avg_Wait_Time_Mins
FROM ola_rides
GROUP BY Vehicle_Type
ORDER BY Completion_Rate_Pct ASC;

-- Finding: Premium vehicles (Prime Plus, Prime Sedan, Prime SUV)
-- have the worst completion rates despite similar booking values
-- Problem is systemic — all vehicle types within 1% of each other

-- ============================================================
-- QUERY 3: Revenue Leakage by Failure Type
-- Business Question: How much money is Ola losing?
-- ============================================================

SELECT
    Booking_Status,

    COUNT(*)                                                                    AS Failed_Rides,

    ROUND(COUNT(*) * AVG(CAST(Booking_Value AS DECIMAL(10,2))), 0)             AS Estimated_Revenue_Lost_Rs,

    ROUND(COUNT(*) * (
          SELECT AVG(CAST(Booking_Value AS DECIMAL(10,2)))
          FROM ola_rides
          WHERE Booking_Status = 'Success'
    ) / 100000, 2)                                                              AS Revenue_Lost_Lakhs,

    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ola_rides), 2)              AS Share_Of_Total_Pct

FROM ola_rides
WHERE Booking_Status != 'Success'
GROUP BY Booking_Status
ORDER BY Failed_Rides DESC;

-- Finding: Total leakage Rs.169 Lakhs in January alone
-- Driver cancellations account for Rs.98.35 Lakhs (58% of total)
-- Annualised leakage: Rs.2028 Lakhs = approx Rs.20 Crore

-- ============================================================
-- QUERY 4: Driver Cancellation Reason Breakdown
-- Business Question: Why are drivers cancelling?
-- ============================================================

SELECT
    Reason_for_Cancelling_by_Driver                                             AS Driver_Cancel_Reason,
    COUNT(*)                                                                    AS Cancellation_Count,
    ROUND(100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM ola_rides
         WHERE Booking_Status = 'Cancelled by Driver'), 2)                      AS Share_Of_Driver_Cancels_Pct
FROM ola_rides
WHERE Booking_Status = 'Cancelled by Driver'
  AND Reason_for_Cancelling_by_Driver IS NOT NULL
  AND Reason_for_Cancelling_by_Driver != ''
GROUP BY Reason_for_Cancelling_by_Driver
ORDER BY Cancellation_Count DESC;

-- Critical Finding: All 4 reasons distributed at exactly 23-26% each
-- Statistically impossible in real behaviour
-- Confirms app dropdown produces unreliable data
-- Drivers selecting any option to cancel quickly

-- ============================================================
-- QUERY 5: Customer Cancellation Reason Breakdown
-- Business Question: Why are customers cancelling?
-- ============================================================

SELECT
    Reason_for_Cancelling_by_Customer                                           AS Customer_Cancel_Reason,
    COUNT(*)                                                                    AS Cancellation_Count,
    ROUND(100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM ola_rides
         WHERE Booking_Status = 'Cancelled by Customer'), 2)                    AS Share_Of_Customer_Cancels_Pct
FROM ola_rides
WHERE Booking_Status = 'Cancelled by Customer'
  AND Reason_for_Cancelling_by_Customer IS NOT NULL
  AND Reason_for_Cancelling_by_Customer != ''
GROUP BY Reason_for_Cancelling_by_Customer
ORDER BY Cancellation_Count DESC;

-- Finding: 5 reasons distributed at exactly 19-21% each
-- Same dropdown design problem as driver side
-- Neither drivers nor customers can express true cancellation reasons

-- ============================================================
-- QUERY 6: Wait Time Bucket Analysis
-- Business Question: Does longer wait time affect ride quality?
-- ============================================================

SELECT
    CASE
        WHEN CAST(Avg_VTAT AS DECIMAL(10,2)) <= 5  THEN '1. 0-5 mins   (Fast)'
        WHEN CAST(Avg_VTAT AS DECIMAL(10,2)) <= 10 THEN '2. 5-10 mins  (Acceptable)'
        WHEN CAST(Avg_VTAT AS DECIMAL(10,2)) <= 15 THEN '3. 10-15 mins (Slow)'
        ELSE                                             '4. 15+ mins   (Very Slow)'
    END                                                                         AS VTAT_Bucket,
    COUNT(*)                                                                    AS Total_Rides,
    ROUND(AVG(CAST(Booking_Value AS DECIMAL(10,2))), 2)                         AS Avg_Booking_Value_Rs,
    ROUND(AVG(CAST(Driver_Ratings AS DECIMAL(10,2))), 2)                        AS Avg_Driver_Rating,
    ROUND(AVG(CAST(Customer_Rating AS DECIMAL(10,2))), 2)                       AS Avg_Customer_Rating
FROM ola_rides
WHERE Booking_Status = 'Success'
GROUP BY VTAT_Bucket
ORDER BY VTAT_Bucket;

-- Finding: 78.8% of successful rides had VTAT above 5 minutes
-- Average VTAT 10.5 mins vs healthy benchmark of 7 mins
-- Ratings flat across buckets — survivorship bias confirmed
-- Unhappy customers cancel before rating — invisible in this data

-- ============================================================
-- QUERY 7: Geographic Hotspots
-- Business Question: Which areas have worst cancellation rates?
-- ============================================================

SELECT
    Pickup_Location,
    COUNT(*)                                                                    AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)                AS Successful,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)    AS Driver_Cancelled,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END)  AS Customer_Cancelled,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Completion_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Driver_Cancel_Pct,
    ROUND(AVG(CASE WHEN Booking_Status = 'Success'
          THEN CAST(Avg_VTAT AS DECIMAL(10,2)) END), 2)                         AS Avg_VTAT_Mins
FROM ola_rides
GROUP BY Pickup_Location
HAVING Total_Bookings >= 900
ORDER BY Completion_Rate_Pct ASC
LIMIT 10;

-- Finding: Area-27 worst at 62.66% completion, 22.59% driver cancel rate
-- Supply side problem — not enough drivers in these zones
-- VTAT similar to system average — confirms positioning issue not volume

-- ============================================================
-- QUERY 8: Hourly Cancellation Pattern
-- Business Question: When is the problem worst during the day?
-- ============================================================

SELECT
    HOUR(STR_TO_DATE(Time, '%H:%i:%s'))                                         AS Hour,
    COUNT(*)                                                                    AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)                AS Successful,
    SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)    AS Driver_Cancelled,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Completion_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Driver_Cancel_Pct,
    ROUND(AVG(CASE WHEN Booking_Status = 'Success'
          THEN CAST(Avg_VTAT AS DECIMAL(10,2)) END), 2)                         AS Avg_VTAT_Mins
FROM ola_rides
GROUP BY Hour
ORDER BY Driver_Cancel_Pct DESC
LIMIT 10;

-- Finding: No peak hour pattern — cancellation rate flat across all 24 hours
-- Range only 19-21% regardless of time
-- Confirms problem is structural not situational
-- Peak hour incentives alone will not solve this

-- ============================================================
-- QUERY 9: Daily Trend Analysis
-- Business Question: Is the problem improving or worsening?
-- ============================================================

SELECT
    Date                                                                        AS Ride_Date,
    COUNT(*)                                                                    AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)                AS Successful,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Completion_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                        AS Driver_Cancel_Pct,
    ROUND(AVG(CASE WHEN Booking_Status = 'Success'
          THEN CAST(Avg_VTAT AS DECIMAL(10,2)) END), 2)                         AS Avg_VTAT_Mins
FROM ola_rides
GROUP BY Date
ORDER BY STR_TO_DATE(Date, '%d/%m/%Y');

-- Finding: Completion rate flat between 65-69% all month
-- No improving or worsening trend — chronic underperformance
-- Jan 18 anomaly: 69.81% completion, 16.49% driver cancel
-- Jan 31 incomplete data — only 66 records, excluded from trend analysis

-- ============================================================
-- QUERY 10: Incomplete Ride Reason Breakdown
-- Business Question: Why do rides that start not finish?
-- ============================================================

SELECT
    Incomplete_Rides_Reason                                                     AS Reason,
    COUNT(*)                                                                    AS Incomplete_Count,
    ROUND(100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM ola_rides
         WHERE Booking_Status = 'Incomplete'), 2)                               AS Share_Pct
FROM ola_rides
WHERE Booking_Status = 'Incomplete'
  AND Incomplete_Rides_Reason IS NOT NULL
  AND Incomplete_Rides_Reason != ''
GROUP BY Incomplete_Rides_Reason
ORDER BY Incomplete_Count DESC;

-- Finding: 3 reasons distributed at 31-35% each
-- Same dropdown design problem extends to incomplete rides
-- All incomplete rides show zero distance and zero booking value
-- These are phantom rides — never actually moved

-- ============================================================
-- QUERY 11: Ratings by Vehicle Type
-- Business Question: Is ride quality differs across vehicle 
-- categories?
-- ============================================================

SELECT
    Vehicle_Type,

    COUNT(*)                                                                AS Total_Successful_Rides,

    ROUND(AVG(CAST(Driver_Ratings AS DECIMAL(10,2))), 2)                    AS Avg_Driver_Rating,

    ROUND(MIN(CAST(Driver_Ratings AS DECIMAL(10,2))), 2)                    AS Min_Driver_Rating,

    ROUND(MAX(CAST(Driver_Ratings AS DECIMAL(10,2))), 2)                    AS Max_Driver_Rating,

    ROUND(AVG(CAST(Customer_Rating AS DECIMAL(10,2))), 2)                   AS Avg_Customer_Rating,

    ROUND(AVG(CAST(Ride_Distance AS DECIMAL(10,2))), 2)                     AS Avg_Ride_Distance_Km,

    ROUND(AVG(CAST(Booking_Value AS DECIMAL(10,2))), 2)                     AS Avg_Booking_Value_Rs

FROM ola_rides
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY Avg_Driver_Rating ASC;

-- Finding: Ratings being exactly 4.00 across every vehicle type with min 3.00 and max 5.00 
-- In a real Ola dataset you would expect natural variation, some vehicle types rated 3.8, others 4.3.
-- Everywhere suggests ratings may also be synthetically generated or heavily rounded

-- ============================================================
-- QUERY 12: Payment Method Analysis
-- Business Question: Does payment method tells anything
-- about ride behaviour?
-- ============================================================

SELECT
    Payment_Method,

    COUNT(*)                                                                AS Total_Successful_Rides,

    ROUND(100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM ola_rides
         WHERE Booking_Status = 'Success'), 2)                              AS Share_Of_Successful_Rides_Pct,

    ROUND(AVG(CAST(Booking_Value AS DECIMAL(10,2))), 2)                     AS Avg_Booking_Value_Rs,

    ROUND(AVG(CAST(Ride_Distance AS DECIMAL(10,2))), 2)                     AS Avg_Ride_Distance_Km,

    ROUND(AVG(CAST(Driver_Ratings AS DECIMAL(10,2))), 2)                    AS Avg_Driver_Rating

FROM ola_rides
WHERE Booking_Status = 'Success'
  AND Payment_Method IS NOT NULL
  AND Payment_Method != ''
GROUP BY Payment_Method
ORDER BY Total_Successful_Rides DESC;

-- Finding: Four payment methods (Cash, UPI, Card and Wallet) has perfectly 25% each
-- It shows the same synthetic distribution pattern.

