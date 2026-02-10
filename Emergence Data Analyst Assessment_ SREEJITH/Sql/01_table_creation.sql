-- 01_table_creation
-- Creating table and tables with proper data types

USE Emergence;

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    signup_date DATE,
    segment VARCHAR(50),
    country VARCHAR(100),
    is_enterprise BIT);

    select * from customers WHERE customer_id = 'C0090'
    
    UPDATE customers
    SET signup_date = NULL
    WHERE signup_date = '1900-01-01 00:00:00.000';



CREATE TABLE events (
    event_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    event_type VARCHAR(50),
    event_date DATE,
    source VARCHAR(100));
    
    select * from events
 

CREATE TABLE subscriptions (
    subscription_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    start_date DATE,
    end_date DATE,
    monthly_price INT,
    status VARCHAR(20)); 

     UPDATE subscriptions
    SET end_date = NULL
    WHERE end_date = '1900-01-01 00:00:00.000';

select * from subscriptions 

BULK INSERT customers
FROM 'G:\Emergence Data Analyst Assessment_ SREEJITH\Data\customers.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,           -- skip header
    FIELDTERMINATOR = ','  -- columns separated by comma
  );

-- Data imported via Import Data / SQL Server Import and Export Wizard due to server connection issue for the bulk insert
-- Updated the signup_date (customers) and end_date(subscriptions) to Null where the date were '1900-01-01 00:00:00.000' due to import limitation. 
