### Preview of the table that will be used to create the model ###
SELECT *
FROM
  `bigquery-public-data.chicago_taxi_trips.taxi_trips`
LIMIT 10;


### Getting the time frame of the dataset ###
SELECT MIN(trip_start_timestamp), MAX(trip_start_timestamp)
FROM
       `bigquery-public-data.chicago_taxi_trips.taxi_trips`;

### Checking if the label tips can be null ###
### Result: 4764 ###
SELECT COUNT(*)
FROM
       `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE
        tips IS NULL;


### Getting the distribution of the dataset ###
SELECT     EXTRACT (YEAR FROM trip_start_timestamp) year,
           EXTRACT (MONTH FROM trip_start_timestamp) month,
           COUNT(*) total
FROM
          `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE 
           tips IS NOT NULL AND
           trip_seconds IS NOT NULL AND
           trip_miles IS NOT NULL AND
           fare IS NOT NULL AND
           tolls IS NOT NULL AND
           pickup_location IS NOT NULL AND
           dropoff_location IS NOT NULL AND
           pickup_latitude IS NOT NULL AND
           pickup_longitude IS NOT NULL AND
           dropoff_latitude IS NOT NULL AND
           dropoff_longitude IS NOT NULL AND
           company IS NOT NULL AND
           trip_miles > 1 AND
           trip_seconds > 180
GROUP BY
          year, month
ORDER BY
           year, month ASC;

### Creation of the training table ###
CREATE OR REPLACE TABLE `05_chicago_taxi.training_table` AS
    SELECT *
    FROM
          `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE
           tips IS NOT NULL AND
           trip_seconds IS NOT NULL AND
           trip_miles IS NOT NULL AND
           fare IS NOT NULL AND
           tolls IS NOT NULL AND
           pickup_location IS NOT NULL AND
           dropoff_location IS NOT NULL AND
           pickup_latitude IS NOT NULL AND
           pickup_longitude IS NOT NULL AND
           dropoff_latitude IS NOT NULL AND
           dropoff_longitude IS NOT NULL AND
           company IS NOT NULL AND
           trip_miles > 1 AND
           trip_seconds > 180 AND
           EXTRACT (YEAR FROM trip_start_timestamp) = 2019 AND
           (EXTRACT (MONTH FROM trip_start_timestamp) >=1 AND EXTRACT (MONTH FROM trip_start_timestamp)<=8);

### Creation of the evaluation table ###
CREATE OR REPLACE TABLE `05_chicago_taxi.evaluation_table` AS
    SELECT *
    FROM
          `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE
           tips IS NOT NULL AND
           trip_seconds IS NOT NULL AND
           trip_miles IS NOT NULL AND
           fare IS NOT NULL AND
           tolls IS NOT NULL AND
           pickup_location IS NOT NULL AND
           dropoff_location IS NOT NULL AND
           pickup_latitude IS NOT NULL AND
           pickup_longitude IS NOT NULL AND
           dropoff_latitude IS NOT NULL AND
           dropoff_longitude IS NOT NULL AND
           company IS NOT NULL AND
           trip_miles > 1 AND
           trip_seconds > 180 AND
           EXTRACT (YEAR FROM trip_start_timestamp) = 2019 AND
           EXTRACT (MONTH FROM trip_start_timestamp) = 09;


### Creation of the prediction/classification table ###
CREATE OR REPLACE TABLE `05_chicago_taxi.classification_table` AS
    SELECT *
    FROM
          `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE
           tips IS NOT NULL AND
           trip_seconds IS NOT NULL AND
           trip_miles IS NOT NULL AND
           fare IS NOT NULL AND
           tolls IS NOT NULL AND
           pickup_location IS NOT NULL AND
           dropoff_location IS NOT NULL AND
           pickup_latitude IS NOT NULL AND
           pickup_longitude IS NOT NULL AND
           dropoff_latitude IS NOT NULL AND
           dropoff_longitude IS NOT NULL AND
           company IS NOT NULL AND
           trip_miles > 1 AND
           trip_seconds > 180 AND
           EXTRACT (YEAR FROM trip_start_timestamp) = 2019 AND
           EXTRACT (MONTH FROM trip_start_timestamp) = 10;

###Training of the first version of the Bilary Logistic Regression Model using the duration of the trip as feature ###
CREATE OR REPLACE MODEL `05_chicago_taxi.binary_classification_version_1`
OPTIONS
  (model_type='logistic_reg', labels = ['will_get_tip']) AS
    SELECT
        trip_seconds,
        IF(tips>0,1,0) AS will_get_tip
    FROM  `05_chicago_taxi.training_table`;

###Training of the second version of the Bilary Logistic Regression Model using the duration of the trip as feature ###
CREATE OR REPLACE MODEL `05_chicago_taxi.binary_classification_version_2`
OPTIONS
  (model_type='logistic_reg', labels = ['will_get_tip']) AS
    SELECT
        trip_seconds,
        fare,
        tolls,
        company,
        IF(tips>0,1,0) AS will_get_tip
    FROM  `05_chicago_taxi.training_table`;

###Training of the third version of the Bilary Logistic Regression Model using the duration of the trip as feature ###
CREATE OR REPLACE MODEL `05_chicago_taxi.binary_classification_version_3`
OPTIONS
  (model_type='logistic_reg', labels = ['will_get_tip']) AS
    SELECT
        trip_seconds,
        fare,
        tolls,
        company,
        payment_type,
        IF(tips>0,1,0) AS will_get_tip
    FROM  `05_chicago_taxi.training_table`; 

###Training of the fourth version of the Bilary Logistic Regression Model using the duration of the trip as feature ###
CREATE OR REPLACE MODEL `05_chicago_taxi.binary_classification_version_4`
OPTIONS
  (model_type='logistic_reg', labels = ['will_get_tip']) AS
    SELECT
        trip_seconds,
        fare,
        tolls,
        company,
        payment_type,
        pickup_location,
        dropoff_location,
        IF(tips>0,1,0) AS will_get_tip
    FROM  `05_chicago_taxi.training_table`; 


### Evaluation of the model leveraging meaningful labels and ROC Curve###
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'EXCELLENT'
    WHEN roc_auc > .8 THEN 'VERY GOOD'
    WHEN roc_auc > .7 THEN 'GOOD'
    WHEN roc_auc > .6 THEN 'FINE'
    WHEN roc_auc > .5 THEN 'NEEDS IMPROVEMENTS'
  ELSE
  'POOR'
END
  AS model_quality
FROM 
  ML.EVALUATE(MODEL `05_chicago_taxi.binary_classification_version_4`,
    (
    SELECT
        trip_seconds,
        fare,
        tolls,
        company,
        payment_type,
        pickup_location,
        dropoff_location,
        IF(tips>0,1,0) AS will_get_tip
     FROM `05_chicago_taxi.evaluation_table`));

### Prediction with the Binary Logistic Regression Model with a very high treshold of 0.9385 extracted from the ML model info###
SELECT predicted_will_get_tip, predicted_will_get_tip_probs, will_get_tip actual
FROM
  ML.PREDICT(MODEL`05_chicago_taxi.binary_classification_version_4`,
    (
      SELECT
        trip_seconds,
        fare,
        tolls,
        company,
        payment_type,
        pickup_location,
        dropoff_location,
        IF(tips>0,1,0) AS will_get_tip
       FROM `05_chicago_taxi.classification_table`));

### Prediction with the Binary Logistic Regression Model with a very high treshold of 0.9385 extracted from the ML model info###
-- Result: 727 464
-- Total size of the table: 744,058
SELECT COUNT(*)
FROM (
      SELECT predicted_will_get_tip, predicted_will_get_tip_probs, will_get_tip actual_tip
      FROM
        ML.PREDICT(MODEL`05_chicago_taxi.binary_classification_version_4`,
          (
            SELECT
              trip_seconds,
              fare,
              tolls,
              company,
              payment_type,
              pickup_location,
              dropoff_location,
              IF(tips>0,1,0) AS will_get_tip
             FROM `05_chicago_taxi.classification_table`)))
WHERE
       predicted_will_get_tip =  actual_tip;
