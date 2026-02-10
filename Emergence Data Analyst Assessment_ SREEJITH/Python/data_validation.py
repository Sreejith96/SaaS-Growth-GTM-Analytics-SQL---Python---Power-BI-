# Importing and Loading data for exploration and validation
import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import pyodbc  # For SQL Server

# Loading CSVs
customers = pd.read_csv('G:/Emergence Data Analyst Assessment_ SREEJITH/Data/customers.csv')
subscriptions = pd.read_csv('G:/Emergence Data Analyst Assessment_ SREEJITH/Data/subscriptions.csv')  
events = pd.read_csv('G:/Emergence Data Analyst Assessment_ SREEJITH/Data/events.csv')

# Initial Data exploration and salience to identify the column heads(table structure),Shape (rows by column), counts of missing data (any blank/null), duplicates, counts of a specific head/attribute (column) 

print("\n=CUSTOMERS=")
print(customers.head(3))
print(f"Shape: {customers.shape}")
print("\nMissing:", customers.isnull().sum())
print("\nDupes:", customers.duplicated().sum())
print("\nSegment:", customers['segment'].value_counts())

print("\n=== SUBSCRIPTIONS ===")
print(subscriptions.head(3))
print(f"Shape: {subscriptions.shape}")
print("\nMissing:", subscriptions.isnull().sum())
print("\nDupes:", subscriptions.duplicated().sum())
print("\nStatus values:", subscriptions['status'].value_counts())

print("\n=== EVENTS ===")
print(events.head(3))
print(f"Shape: {events.shape}")
print("\nMissing:", events.isnull().sum())
print("\nDupes:", events.duplicated().sum())
print("\nEvent types:", events['event_type'].value_counts())

# Validation and sanity checks
# For "customer data"
print("\n=Customers data=")
print("- Unique customer_ids:", customers['customer_id'].nunique())
print("- signup_date format issues:", pd.to_datetime(customers['signup_date'], errors='coerce').isnull().sum())
print("- How many are enterprise (count):", customers['is_enterprise'].value_counts(dropna=False))

# For "events data"
print("\n=Events data=")
print("- Maximum count of multiple events same customer same day:", events.groupby(['customer_id', 'event_date'])['event_id'].count().max())

# Count of customers with multiple events on same day
daily_counts = events.groupby(['customer_id', 'event_date']).size().reset_index(name='event_count')
multiple_events = daily_counts[daily_counts['event_count'] > 1]
result = multiple_events['customer_id'].nunique()
print("- Count of customers with multiple events on same day:", result)

# For "Subscriptions data"
print("\n=Subscriptions data=")
print("- Customer_ids not in customers:", len(subscriptions[~subscriptions['customer_id'].isin(customers['customer_id'])]))
print("- Active subs with end_date in past:", len(subscriptions[(subscriptions['status'] == 'active') & 
                                                         (pd.to_datetime(subscriptions['end_date']) < pd.Timestamp.now())]))
print("- Negative prices?", (subscriptions['monthly_price'] < 0).sum())



# -Data Issues Found: (Add to README)
#1) Missing signup_date in customers (table) do not match with signup_date in Events (table) data [when event_type = signup] and cannot be updated/replaced directly (inconsisent data found)

# 2) Data summary follows as below:
# Customers data:
# - Unique customer_ids: 1000
# - signup_date format issues: 36 (These are the missing dates)
# - segement information missing in 243 entries(rows)
# - How many are enterprise in the data? : 250 customers are enterprise (No Null values)

# Events data:
# - Maximum count of multiple events same customer same day: 2
# - Count of customers with multiple events on same day: 94

# Subscriptions data:
# - Customer_ids not in customers: 0
# - Active subs with end_date in past: 0
# - Negative prices: 0





