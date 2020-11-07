### Data Quality Check: the label tripduration should be not equal to null and less than 0 ###
SELECT COUNT(*)
FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
        tripduration is NULL
        OR tripduration<=0;

### Data Quality Check: max and min of trip duration ###
SELECT  MIN (tripduration)/60 minimum_duration_in_minutes,
        MAX (tripduration)/60  maximum_duration_in_minutes
FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
        tripduration is not NULL
        AND tripduration>0;

### Data Quality Check: features not null ###
SELECT  COUNT(*)
FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
        (tripduration is not NULL
        AND tripduration>0) AND (
        starttime is NULL
        OR start_station_name is NULL
        OR end_station_name is NULL
        OR start_station_latitude is NULL
        OR start_station_longitude is NULL
        OR end_station_latitude is NULL
        OR end_station_longitude is NULL);

### Data Quality Check: birth_year not null ###
SELECT  COUNT(*)
FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
        (tripduration is not NULL
        AND tripduration>0)
        AND ( birth_year is NULL);

### Data Exploration: segmentation of records by month and year ###
SELECT
          EXTRACT (YEAR FROM starttime) year,
          EXTRACT (MONTH FROM starttime) month,
          count(*) total
FROM
          `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE 
          EXTRACT (YEAR FROM starttime)=2017 OR
          EXTRACT (YEAR FROM starttime)=2018
          AND (tripduration>=3*60 AND tripduration<=3*60*60)
          AND  birth_year is not NULL
          AND birth_year < 2007
GROUP BY
          year, month 
ORDER BY
          year, month asc;

### Creation of the training table ###
CREATE OR REPLACE TABLE `04_nyc_bike_sharing.training_table` AS
              SELECT 
                    tripduration/60 tripduration,
					starttime,
					stoptime,
					start_station_id,
					start_station_name,
					start_station_latitude,
					start_station_longitude,
					end_station_id,
					end_station_name,
					end_station_latitude,
					end_station_longitude,
					bikeid,
					usertype,
					birth_year,
					gender,
					customer_plan
              FROM
                    `bigquery-public-data.new_york_citibike.citibike_trips`
              WHERE 
                    (
                        (EXTRACT (YEAR FROM starttime)=2017 AND
                          (EXTRACT (MONTH FROM starttime)>=04 OR EXTRACT (MONTH FROM starttime)<=10))
                        OR (EXTRACT (YEAR FROM starttime)=2018 AND
                          (EXTRACT (MONTH FROM starttime)>=01 OR EXTRACT (MONTH FROM starttime)<=02))
                    )
                    AND (tripduration>=3*60 AND tripduration<=3*60*60)
                    AND  birth_year is not NULL
                    AND birth_year < 2007;


### Creation of the evaluation table ###
CREATE OR REPLACE TABLE  `04_nyc_bike_sharing.evaluation_table` AS
SELECT 
                    tripduration/60 tripduration,
					starttime,
					stoptime,
					start_station_id,
					start_station_name,
					start_station_latitude,
					start_station_longitude,
					end_station_id,
					end_station_name,
					end_station_latitude,
					end_station_longitude,
					bikeid,
					usertype,
					birth_year,
					gender,
					customer_plan
				FROM
                    `bigquery-public-data.new_york_citibike.citibike_trips`
				WHERE 
                    (EXTRACT (YEAR FROM starttime)=2018 AND (EXTRACT (MONTH FROM starttime)=03 OR EXTRACT (MONTH FROM starttime)=04))
                    AND (tripduration>=3*60 AND tripduration<=3*60*60)
                    AND  birth_year is not NULL
                    AND birth_year < 2007;


### Creation of the prediction table ###
CREATE OR REPLACE TABLE  `04_nyc_bike_sharing.prediction_table` AS
              SELECT 
                   tripduration/60 tripduration,
					starttime,
					stoptime,
					start_station_id,
					start_station_name,
					start_station_latitude,
					start_station_longitude,
					end_station_id,
					end_station_name,
					end_station_latitude,
					end_station_longitude,
					bikeid,
					usertype,
					birth_year,
					gender,
					customer_plan
				FROM
                    `bigquery-public-data.new_york_citibike.citibike_trips`
              WHERE 
                    EXTRACT (YEAR FROM starttime)=2018
                    AND EXTRACT (MONTH FROM starttime)=05
                     AND (tripduration>=3*60 AND tripduration<=3*60*60)
                    AND  birth_year is not NULL
                    AND birth_year < 2007;
					
### 1st attempt of model creation using stations ###
CREATE OR REPLACE MODEL `04_nyc_bike_sharing.trip_duration_by_stations`
OPTIONS
  (model_type='linear_reg') AS
SELECT
  start_station_name,
  end_station_name,
  tripduration as label
FROM
  `04_nyc_bike_sharing.training_table`;

### 2nd attempt of model creation using stations and day of the week###  
  CREATE OR REPLACE MODEL `04_nyc_bike_sharing.trip_duration_by_stations_and_day`
OPTIONS
  (model_type='linear_reg') AS
SELECT
  start_station_name,
  end_station_name,
   IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
  tripduration as label
FROM
  `04_nyc_bike_sharing.training_table`;

### 3rd attempt of model creation using stations, day of the week and age of the customer ###
CREATE OR REPLACE MODEL `04_nyc_bike_sharing.trip_duration_by_stations_day_age`
OPTIONS
  (model_type='linear_reg') AS
SELECT
  start_station_name,
  end_station_name,
  IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
  EXTRACT(YEAR FROM starttime)-birth_year as age,
  tripduration as label
FROM
  `04_nyc_bike_sharing.training_table`;

### Evaluation of the 2nd model  ###
SELECT
  *
FROM
  ML.EVALUATE(MODEL `04_nyc_bike_sharing.trip_duration_by_stations_and_day`,
    (
    SELECT
          start_station_name,
          end_station_name,
          IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
           tripduration as label
    FROM
           `04_nyc_bike_sharing.evaluation_table`));

### Prediction using the 2nd model  ###
SELECT
   tripduration as actual_duration,
   predicted_label as predicted_duration,
   ABS(tripduration - predicted_label) difference_in_min
FROM
  ML.PREDICT(MODEL `04_nyc_bike_sharing.trip_duration_by_stations_and_day`,
    (
    SELECT
          start_station_name,
          end_station_name,
          IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
           tripduration
    FROM
           `04_nyc_bike_sharing.prediction_table`
    ))
    order by  difference_in_min asc;

### Final considerations about the difference in terms of actual and predicted values of trip duration  ###
SELECT COUNT (*)
FROM (
SELECT
   tripduration as actual_duration,
   predicted_label as predicted_duration,
   ABS(tripduration - predicted_label) difference_in_min
FROM
  ML.PREDICT(MODEL `04_nyc_bike_sharing.trip_duration_by_stations_and_day`,
    (
    SELECT
          start_station_name,
          end_station_name,
          IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
           tripduration
    FROM
           `04_nyc_bike_sharing.prediction_table`
    ))
    order by  difference_in_min asc) where difference_in_min<=15 ;

