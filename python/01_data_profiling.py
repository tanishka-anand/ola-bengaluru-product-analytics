# ============================================================
# OLA BENGALURU — DATA PROFILING & CORRELATION ANALYSIS
# Author: Tanishka Anand
# Purpose: Understand data structure, distributions,
#          and correlations before SQL analysis
# ============================================================

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

# ── LOAD DATA ─────────────────────────────────────────────

df = pd.read_csv('Bengaluru_Ola.csv')
df.columns = [c.strip() for c in df.columns]

print("Shape:", df.shape)
print("Columns:", df.columns.tolist())

# ── BOOKING STATUS DISTRIBUTION ───────────────────────────

status = df['Booking Status'].value_counts()
status_pct = df['Booking Status'].value_counts(normalize=True).mul(100).round(2)
print("\nBooking Status Distribution:")
print(pd.concat([status, status_pct], axis=1, keys=['Count', '%']))

# ── VEHICLE TYPE DISTRIBUTION ─────────────────────────────

print("\nVehicle Type Distribution:")
print(df['Vehicle Type'].value_counts())

# ── NULL ANALYSIS ──────────────────────────────────────────

print("\nNull Values per Column:")
print(df.isnull().sum())

# ── WAIT TIME STATS ───────────────────────────────────────

success = df[df['Booking Status'] == 'Success'].copy()
success['Avg VTAT'] = pd.to_numeric(success['Avg VTAT'], errors='coerce')
success['Avg CTAT'] = pd.to_numeric(success['Avg CTAT'], errors='coerce')

print("\nVTAT Stats (Successful Rides):")
print(success['Avg VTAT'].describe().round(2))

# ── REVENUE LEAKAGE ESTIMATE ──────────────────────────────

success['Booking Value'] = pd.to_numeric(
    success['Booking Value'], errors='coerce')
avg_value = success['Booking Value'].mean()
failed = df[df['Booking Status'] != 'Success']
leakage = len(failed) * avg_value

print(f"\nAvg Booking Value (Successful): Rs. {avg_value:.2f}")
print(f"Total Failed Rides: {len(failed)}")
print(f"Estimated Revenue Leakage: Rs. {leakage/100000:.2f} Lakhs")

# ── CORRELATION HEATMAP ───────────────────────────────────

numeric_cols = success[[
    'Avg VTAT', 'Avg CTAT', 'Booking Value',
    'Ride Distance', 'Driver Ratings', 'Customer Rating'
]].apply(pd.to_numeric, errors='coerce')

corr = numeric_cols.corr()

print("\nCorrelation Matrix:")
print(corr.round(2))

plt.figure(figsize=(10, 7))
sns.heatmap(corr,
            annot=True,
            fmt='.2f',
            cmap='RdYlGn',
            center=0,
            square=True,
            linewidths=0.5)

plt.title('Correlation Heatmap — Successful Rides\nOla Bengaluru January 2024',
          fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('correlation_heatmap.png', dpi=150, bbox_inches='tight')
plt.show()

print("\nKey Finding: Zero correlations across all variable pairs.")
print("Confirms synthetic data generation.")
print("Structural metrics remain valid for analysis.")

# ── COHORT RETENTION ANALYSIS ─────────────────────────────

success['Date'] = pd.to_datetime(success['Date'], dayfirst=True)
success['Week'] = success['Date'].dt.isocalendar().week.astype(int)
success['Customer ID'] = success['Customer ID'].astype(str)

first_week = success.groupby('Customer ID')['Week'].min().reset_index()
first_week.columns = ['Customer ID', 'Cohort_Week']
success = success.merge(first_week, on='Customer ID')
success['Week_Number'] = success['Week'] - success['Cohort_Week']

cohort = success.groupby(
    ['Cohort_Week', 'Week_Number'])['Customer ID'].nunique().reset_index()
cohort.columns = ['Cohort_Week', 'Week_Number', 'Customers']

cohort_pivot = cohort.pivot_table(
    index='Cohort_Week',
    columns='Week_Number',
    values='Customers')

cohort_size = cohort_pivot[0]
retention = cohort_pivot.divide(cohort_size, axis=0).mul(100).round(1)

print("\nWeekly Cohort Retention Table (%):")
print(retention.to_string())

plt.figure(figsize=(12, 6))
sns.heatmap(retention,
            annot=True,
            fmt='.1f',
            cmap='YlOrRd_r',
            linewidths=0.5,
            cbar_kws={'label': 'Retention %'})

plt.title('Weekly Cohort Retention — Ola Bengaluru January 2024',
          fontsize=13, fontweight='bold')
plt.xlabel('Weeks Since First Ride')
plt.ylabel('Cohort Week')
plt.tight_layout()
plt.savefig('cohort_retention.png', dpi=150, bbox_inches='tight')
plt.show()

print("\nKey Finding: Retention collapses to under 1% after Week 1.")
print("2.69% of customers return for a second ride.")
