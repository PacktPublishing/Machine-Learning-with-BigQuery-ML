SELECT * FROM `bigquery-public-data.iowa_liquor_sales.sales` LIMIT 10;


SELECT min(date), max(date) FROM `bigquery-public-data.iowa_liquor_sales.sales`; 

SELECT COUNT(DISTINCT date)
FROM
        `bigquery-public-data.iowa_liquor_sales.sales`
WHERE
        EXTRACT (year from date) = 2019
        OR  EXTRACT (year from date) = 2018;

### Creating the training dataset ###
CREATE OR REPLACE TABLE `08_sales_forecasting.iowa_liquor_sales` AS
SELECT 
        date,
        SUM(volume_sold_liters) total_sold_liters
FROM
        `bigquery-public-data.iowa_liquor_sales.sales`
WHERE
        EXTRACT (year from date) = 2019 OR  EXTRACT (year from date) = 2018
GROUP BY
        date;

### Training the ARIMA model for liquor liters forecasting ###
CREATE OR REPLACE MODEL `08_sales_forecasting.liquor_forecasting`
OPTIONS
 (model_type = 'ARIMA',
  time_series_timestamp_col = 'date',
  time_series_data_col = 'total_sold_liters',
  auto_arima = TRUE,
  data_frequency = 'AUTO_FREQUENCY'
) AS
SELECT *
FROM
 `08_sales_forecasting.iowa_liquor_sales`;

### Evaluation of the ARIMA model for liquor liters forecasting ###
SELECT *
FROM
 ML.EVALUATE(MODEL `08_sales_forecasting.liquor_forecasting`);

## Extraction of the ARIMA model parameters for liquor liters forecasting ###
SELECT *
FROM
  ML.ARIMA_COEFFICIENTS(MODEL `08_sales_forecasting.liquor_forecasting`);

## Application of the ARIMA to get the forecast with a 30days horizon ###
SELECT
  *
FROM
  ML.FORECAST(MODEL `08_sales_forecasting.liquor_forecasting`,
              STRUCT(30 AS horizon, 0.8 AS confidence_level));

CREATE OR REPLACE TABLE `08_sales_forecasting.iowa_liquor_sales_forecast` AS
SELECT
  history_date AS date,
  history_value,
  NULL AS forecast_value,
  NULL AS prediction_interval_lower_bound,
  NULL AS prediction_interval_upper_bound
FROM
  (
    SELECT
      date AS history_date,
      total_sold_liters AS history_value
    FROM
      `08_sales_forecasting.iowa_liquor_sales`
  )
UNION ALL
SELECT
  CAST(forecast_timestamp AS DATE) AS date,
  NULL AS history_value,
  forecast_value,
  prediction_interval_lower_bound,
  prediction_interval_upper_bound
FROM
  ML.FORECAST(MODEL `08_sales_forecasting.liquor_forecasting`,
              STRUCT(30 AS horizon, 0.8 AS confidence_level));
