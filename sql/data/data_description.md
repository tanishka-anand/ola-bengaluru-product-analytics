# Dataset Description

## Source
- **Name:** Ola Bengaluru Rides Dataset
- **Platform:** Kaggle
- **Records:** 49,999 rides
- **Time Period:** January 2024
- **City:** Bengaluru, India

---

## Important Note on Data Quality
This dataset is synthetic in nature. The following observations confirm 
artificial generation:
- Driver cancellation reasons distributed perfectly at ~25% each across 
  4 options
- Customer cancellation reasons distributed at ~20% each across 5 options
- Ratings identical at 4.00 across all vehicle types
- Zero correlations between all numeric variables
- Payment method distributed perfectly at ~25% each across 4 options

All structural findings remain valid. Variable-level analysis is illustrative.

---

## Raw Columns (21)

| Column | Type | Description |
|---|---|---|
| Date | String | Ride date in DD/MM/YYYY format |
| Time | String | Ride time in HH:MM:SS format |
| Booking ID | String | Unique ride identifier |
| Booking Status | String | Success, Cancelled by Driver, Cancelled by Customer, Incomplete |
| Customer ID | Integer | Unique customer identifier |
| Vehicle Type | String | Auto, Bike, eBike, Mini, Prime Plus, Prime Sedan, Prime SUV |
| Pickup Location | String | Area-1 to Area-50 (anonymised) |
| Drop Location | String | Area-1 to Area-50 (anonymised) |
| Avg VTAT | Float | Vehicle Time to Arrive — minutes from acceptance to pickup |
| Avg CTAT | Float | Customer Time to Accept — minutes from booking to acceptance |
| Cancelled by Customer | String | Yes/No flag |
| Reason for Cancelling by Customer | String | Dropdown reason — unreliable |
| Cancelled by Driver | String | Yes/No flag |
| Reason for Cancelling by Driver | String | Dropdown reason — unreliable |
| Incomplete Rides | String | Yes/No flag |
| Incomplete Rides Reason | String | Dropdown reason — unreliable |
| Booking Value | Float | Fare in Indian Rupees |
| Payment Method | String | Cash, UPI, Card, Wallet |
| Ride Distance | Float | Distance in kilometres |
| Driver Ratings | Float | Post-ride rating 1-5 |
| Customer Rating | Float | Post-ride rating 1-5 |

---

## Engineered Columns (9 added during feature engineering)

| Column | Type | Description |
|---|---|---|
| Hour | Integer | Hour extracted from Time column |
| Day_of_Week | String | Day name extracted from Date |
| Week_Number | Integer | Week number in January |
| VTAT_Bucket | String | Wait time category — 0-5, 5-10, 10-15, 15+ mins |
| Time_Segment | String | Morning, Afternoon, Evening, Night |
| Is_Success | Integer | 1 if successful, 0 otherwise |
| Is_Driver_Cancel | Integer | 1 if cancelled by driver, 0 otherwise |
| Is_Customer_Cancel | Integer | 1 if cancelled by customer, 0 otherwise |
| Is_Incomplete | Integer | 1 if incomplete, 0 otherwise |
| Is_Failed | Integer | 1 if any failure type, 0 otherwise |
| Estimated_Leakage | Float | Revenue lost — failed rides × avg successful fare |
| Is_Repeat_Customer | Integer | 1 if customer has 2+ rides, 0 otherwise |
| Total_Customer_Rides | Integer | Total rides by that customer in January |

---

## Key Statistics

| Metric | Value |
|---|---|
| Total Bookings | 49,999 |
| Successful Rides | 33,484 (66.97%) |
| Driver Cancellations | 9,610 (19.22%) |
| Customer Cancellations | 3,799 (7.60%) |
| Incomplete Rides | 3,106 (6.21%) |
| Avg Booking Value (successful) | Rs. 1,023 |
| Avg VTAT (successful rides) | 10.5 minutes |
| Total Revenue Leakage | Rs. 169.02 Lakhs |
| Unique Customers | 48,669 |
| Repeat Customers | 1,310 (2.69%) |

---

## Null Value Analysis

| Column | Null Count | Reason |
|---|---|---|
| Avg VTAT | 16,515 | Failed rides only — structurally valid |
| Avg CTAT | 16,515 | Failed rides only — structurally valid |
| Booking Value | 16,515 | Failed rides only — structurally valid |
| Ride Distance | 16,515 | Failed rides only — structurally valid |
| Driver Ratings | 16,515 | Failed rides only — structurally valid |
| Customer Rating | 16,515 | Failed rides only — structurally valid |
| Payment Method | 16,515 | Failed rides only — structurally valid |
| Reason columns | Variable | Successful rides have no cancel reason — correct |

**Decision:** No imputation performed. All nulls are structurally valid.
Imputing would introduce false data into the analysis.
