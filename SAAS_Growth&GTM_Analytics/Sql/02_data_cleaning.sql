-- 02_data_cleaning
-- Cleaning and updating data based on checks and assumptions


-- Updated the signup_date (customers) and end_date(subscriptions) to Null where the date were '1900-01-01 00:00:00.000' due to import limitation. 

 UPDATE customers
    SET signup_date = NULL
    WHERE signup_date = '1900-01-01 00:00:00.000';

     UPDATE subscriptions
    SET end_date = NULL
    WHERE end_date = '1900-01-01 00:00:00.000';



-- Data Issues Found: 1) Missing signup_date in customers (table) do not match with signup_date in Events (table) data [when event_type = signup] and cannot be updated/replaced directly (inconsisent data found)
-- No Duplicate data found so deduplicating is not considered for the data 

   UPDATE customers
    SET segment = 'Non-Enterprise'
    WHERE segment  = '';

    SELECT * FROM customers