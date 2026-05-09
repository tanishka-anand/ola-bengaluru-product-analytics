# ============================================================
# OLA BENGALURU — POWER BI EXPORT
# Author: Tanishka Anand
# Purpose: Feature engineering and clean dataset export
#          for Power BI dashboard consumption
# Output: ola_powerbi_ready.csv — 30 columns, 49,999 rows
# ============================================================

import pandas as pd

# ── LOAD RAW DATA ─────────────────────────────────────────

df = pd.read_csv('Bengaluru_Ola.csv')
df.columns = [c.strip() for c in df.columns]
print(f"Raw data loaded: {df.shape[0]} rows, {df.shape[1]} columns")

# ── DATE AND TIME FEATURES ────────────────────────────────

df['Date'] = pd.to_datetime(df['Date'], dayfirst=True)
df['Hour'] = pd.to_datetime(
    df['Time'], format='%H:%M:%S', errors='coerce').dt.hour
df['Day_of_Week'] = df['Date'].dt.day_name()
df['Week_Number'] = df['Date'].dt.isocalendar().week.astype(int)

print("Date and time features created")

# ── BINARY FLAGS ──────────────────────────────────────────

df['Is_Success'] = (df['Booking Status'] == 'Success').astype(int)
df['Is_Driver_Cancel'] = (
    df['Booking Status'] == 'Cancelled by Driver').astype(int)
df['Is_Customer_Cancel'] = (
    df['Booking Status'] == 'Cancelled by Customer').astype(int)
df['Is_Incomplete'] = (
    df['Booking Status'] == 'Incomplete').astype(int)
df['Is_Failed'] = (
    df['Booking Status'] != 'Success').astype(int)

print("Binary flags created")

# ── NUMERIC CONVERSIONS ───────────────────────────────────

numeric_cols = [
    'Avg VTAT', 'Avg CTAT', 'Booking Value',
    'Ride Distance', 'Driver Ratings', 'Customer Rating'
]
for col in numeric_cols:
    df[col] = pd.to_numeric(df[col], errors='coerce')

print("Numeric columns converted")

# ── VTAT BUCKET ───────────────────────────────────────────

df['VTAT_Bucket'] = pd.cut(
    df['Avg VTAT'],
    bins=[0, 5, 10, 15, float('inf')],
    labels=['0-5 mins', '5-10 mins', '10-15 mins', '15+ mins'])

print("VTAT buckets created")

# ── TIME SEGMENT ──────────────────────────────────────────

def time_segment(hour):
    if pd.isnull(hour):
        return 'Unknown'
    elif 6 <= hour <= 11:
        return '1. Morning (6am-11am)'
    elif 12 <= hour <= 16:
        return '2. Afternoon (12pm-4pm)'
    elif 17 <= hour <= 21:
        return '3. Evening (5pm-9pm)'
    else:
        return '4. Night (10pm-5am)'

df['Time_Segment'] = df['Hour'].apply(time_segment)
print("Time segments created")

# ── REVENUE LEAKAGE ───────────────────────────────────────

avg_successful_value = df[
    df['Booking Status'] == 'Success']['Booking Value'].mean()
df['Estimated_Leakage'] = df['Is_Failed'] * avg_successful_value

print(f"Revenue leakage calculated — Avg successful fare: Rs.{avg_successful_value:.2f}")

# ── REPEAT CUSTOMER FLAG ──────────────────────────────────

customer_ride_count = df.groupby(
    'Customer ID')['Booking ID'].count().reset_index()
customer_ride_count.columns = ['Customer ID', 'Total_Customer_Rides']
df = df.merge(customer_ride_count, on='Customer ID', how='left')
df['Is_Repeat_Customer'] = (df['Total_Customer_Rides'] > 1).astype(int)

print(f"Repeat customers flagged: {df['Is_Repeat_Customer'].sum():,}")

# ── EXPORT ────────────────────────────────────────────────

export_cols = [
    'Date', 'Hour', 'Day_of_Week', 'Week_Number',
    'Booking ID', 'Booking Status', 'Customer ID',
    'Vehicle Type', 'Pickup Location', 'Drop Location',
    'Avg VTAT', 'Avg CTAT', 'VTAT_Bucket', 'Time_Segment',
    'Booking Value', 'Payment Method', 'Ride Distance',
    'Driver Ratings', 'Customer Rating',
    'Reason for Cancelling by Customer',
    'Reason for Cancelling by Driver',
    'Incomplete Rides Reason',
    'Is_Success', 'Is_Driver_Cancel', 'Is_Customer_Cancel',
    'Is_Incomplete', 'Is_Failed', 'Estimated_Leakage',
    'Is_Repeat_Customer', 'Total_Customer_Rides'
]

df[export_cols].to_csv('ola_powerbi_ready.csv', index=False)

# ── FINAL SUMMARY ─────────────────────────────────────────

print("\n" + "=" * 50)
print("EXPORT COMPLETE")
print("=" * 50)
print(f"Total rows exported      : {len(df):,}")
print(f"Total columns exported   : {len(export_cols)}")
print(f"Avg successful fare      : Rs. {avg_successful_value:.2f}")
print(f"Total leakage estimate   : Rs. {df['Estimated_Leakage'].sum()/100000:.2f} Lakhs")
print(f"Unique customers         : {df['Customer ID'].nunique():,}")
print(f"Repeat customers         : {df['Is_Repeat_Customer'].sum():,}")
print(f"Repeat customer rate     : {df['Is_Repeat_Customer'].sum()/df['Customer ID'].nunique()*100:.2f}%")
print(f"\nFile saved as: ola_powerbi_ready.csv")
print("Load this file directly into Power BI")
