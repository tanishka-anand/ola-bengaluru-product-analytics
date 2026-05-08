# Data Cleaning & Preparation Decisions

## Overview
This document records every data quality issue found and the 
decision made for each. All decisions are documented to ensure 
full reproducibility and transparency.

---

## Step 1 — Duplicate Check

| Check | Result | Decision |
|---|---|---|
| Total rows | 49,999 | — |
| Unique Booking IDs | 49,999 | — |
| Duplicate rows | 0 | No action needed |

**Conclusion:** Dataset has no duplicate records. Booking ID 
is confirmed as unique primary key.

---

## Step 2 — Null Value Analysis

| Column | Null Count | Null % | Decision | Reason |
|---|---|---|---|---|
| Booking ID | 0 | 0% | No action | Clean |
| Booking Status | 0 | 0% | No action | Clean |
| Customer ID | 0 | 0% | No action | Clean |
| Vehicle Type | 0 | 0% | No action | Clean |
| Pickup Location | 0 | 0% | No action | Clean |
| Drop Location | 0 | 0% | No action | Clean |
| Avg VTAT | 16,515 | 33% | Keep as null | Structurally valid |
| Avg CTAT | 16,515 | 33% | Keep as null | Structurally valid |
| Booking Value | 16,515 | 33% | Keep as null | Structurally valid |
| Ride Distance | 16,515 | 33% | Keep as null | Structurally valid |
| Driver Ratings | 16,515 | 33% | Keep as null | Structurally valid |
| Customer Rating | 16,515 | 33% | Keep as null | Structurally valid |
| Payment Method | 16,515 | 33% | Keep as null | Structurally valid |
| Reason columns | Variable | Variable | Keep as null | Correct by design |

**Key Decision:** Nulls exist exclusively in failed and cancelled 
rides. A cancelled ride has no fare, no wait time, no rating, and 
no payment method by definition. These are not missing values — 
they are correct empty values. Imputing or dropping these rows 
would delete 16,515 legitimate records and introduce false data.

---

## Step 3 — Data Type Corrections

| Column | Original Type | Corrected Type | Method |
|---|---|---|---|
| Date | VARCHAR | DATE | STR_TO_DATE in SQL |
| Time | VARCHAR | TIME | HOUR(STR_TO_DATE()) in SQL |
| Avg VTAT | VARCHAR | DECIMAL | CAST(col AS DECIMAL(10,2)) |
| Avg CTAT | VARCHAR | DECIMAL | CAST(col AS DECIMAL(10,2)) |
| Booking Value | VARCHAR | DECIMAL | CAST(col AS DECIMAL(10,2)) |
| Ride Distance | VARCHAR | DECIMAL | CAST(col AS DECIMAL(10,2)) |
| Driver Ratings | VARCHAR | DECIMAL | CAST(col AS DECIMAL(10,2)) |
| Customer Rating | VARCHAR | DECIMAL | CAST(col AS DECIMAL(10,2)) |

**Decision:** All columns loaded as VARCHAR due to LOAD DATA INFILE 
import method. Type conversion handled contextually inside each SQL 
query using CAST. This approach avoids data loss from failed 
conversions and handles nulls gracefully using errors='coerce'.

---

## Step 4 — Outlier Analysis

| Column | IQR Lower | IQR Upper | Outliers Found | Decision |
|---|---|---|---|---|
| Booking Value | Rs.512 | Rs.1534 | Present | Keep |
| Ride Distance | 12.4 km | 38.6 km | Present | Keep |
| Avg VTAT | 5.2 mins | 15.8 mins | Present | Keep |

**Decision:** All outliers retained. High booking values represent 
genuine long distance rides. High VTAT values represent genuine 
supply shortage situations. Removing outliers would eliminate real 
operational problems from the analysis.

---

## Step 5 — Data Quality Flags

The following columns were identified as unreliable for analysis:

### Cancellation Reason Columns
| Column | Issue | Impact |
|---|---|---|
| Reason for Cancelling by Driver | Uniform 25% distribution across 4 options | Cannot be used for root cause analysis |
| Reason for Cancelling by Customer | Uniform 20% distribution across 5 options | Cannot be used for root cause analysis |
| Incomplete Rides Reason | Uniform 33% distribution across 3 options | Cannot be used for root cause analysis |

**Root Cause:** Ola app forces dropdown selection with no free text 
option. Drivers and customers select any available option to complete 
the cancellation screen quickly. The data reflects app design 
constraints, not actual cancellation reasons.

### Rating Columns
| Column | Issue | Impact |
|---|---|---|
| Driver Ratings | Identical 4.00 across all vehicle types | Cannot be used for vehicle quality comparison |
| Customer Rating | Identical 4.00 across all vehicle types | Cannot be used for customer satisfaction analysis |

### Correlation Analysis
All numeric variable pairs show zero correlation — statistically 
impossible in genuine ride-hailing data. This confirms synthetic 
data generation. Structural metrics (completion rates, cancellation 
rates, revenue figures) remain valid for analysis.

---

## Step 6 — Feature Engineering

The following columns were created for analysis:

| New Column | Logic | Purpose |
|---|---|---|
| Hour | HOUR(STR_TO_DATE(Time)) | Time of day analysis |
| Day_of_Week | Date.dt.day_name() | Weekday vs weekend |
| Week_Number | Date.dt.isocalendar().week | Weekly trend |
| VTAT_Bucket | pd.cut(Avg VTAT, bins) | Wait time segmentation |
| Time_Segment | Custom function on Hour | Time of day grouping |
| Is_Success | Booking Status == Success | Binary flag for aggregation |
| Is_Driver_Cancel | Booking Status == Cancelled by Driver | Binary flag |
| Is_Customer_Cancel | Booking Status == Cancelled by Customer | Binary flag |
| Is_Incomplete | Booking Status == Incomplete | Binary flag |
| Is_Failed | Booking Status != Success | Binary flag |
| Estimated_Leakage | Is_Failed × Avg Successful Booking Value | Revenue impact |
| Is_Repeat_Customer | Total_Customer_Rides > 1 | Retention flag |
| Total_Customer_Rides | COUNT per Customer ID | Ride frequency |

---

## Summary

| Category | Finding | Action |
|---|---|---|
| Duplicates | Zero found | None required |
| Nulls | 16,515 structurally valid nulls | Retained as is |
| Data types | All stored as VARCHAR | CAST inside SQL queries |
| Outliers | Present in fare and distance | Retained |
| Unreliable columns | Reason columns, ratings | Flagged, not used for causal analysis |
| Feature engineering | 13 new columns created | Used in Power BI and Python analysis |
