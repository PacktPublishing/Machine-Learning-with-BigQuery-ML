### Creation of the training table ###
CREATE OR REPLACE TABLE `11_nyc_bike_sharing_dnn.training_table` AS
              SELECT 
                   tripduration/60 tripduration,
				   start_station_name,
                   end_station_name,
                   IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
                   EXTRACT(YEAR FROM starttime)-birth_year as age
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
CREATE OR REPLACE TABLE  `11_nyc_bike_sharing_dnn.evaluation_table` AS
SELECT 
                   tripduration/60 tripduration,
				   start_station_name,
                   end_station_name,
                   IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
                   EXTRACT(YEAR FROM starttime)-birth_year as age
				FROM
                    `bigquery-public-data.new_york_citibike.citibike_trips`
				WHERE 
                    (EXTRACT (YEAR FROM starttime)=2018 AND (EXTRACT (MONTH FROM starttime)=03 OR EXTRACT (MONTH FROM starttime)=04))
                    AND (tripduration>=3*60 AND tripduration<=3*60*60)
                    AND  birth_year is not NULL
                    AND birth_year < 2007;


### Creation of the prediction table ###
CREATE OR REPLACE TABLE  `11_nyc_bike_sharing_dnn.prediction_table` AS
              SELECT 
                   tripduration/60 tripduration,
				   start_station_name,
                   end_station_name,
                   IF (EXTRACT(DAYOFWEEK FROM starttime)=1 OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
                   EXTRACT(YEAR FROM starttime)-birth_year as age
				FROM
                    `bigquery-public-data.new_york_citibike.citibike_trips`
              WHERE 
                    EXTRACT (YEAR FROM starttime)=2018
                    AND EXTRACT (MONTH FROM starttime)=05
                     AND (tripduration>=3*60 AND tripduration<=3*60*60)
                    AND  birth_year is not NULL
                    AND birth_year < 2007;

CREATE OR REPLACE MODEL `11_nyc_bike_sharing_dnn.trip_duration_by_stations_day_age_relu`
OPTIONS
  (model_type='DNN_REGRESSOR',
        ACTIVATION_FN = 'RELU') AS
SELECT
  start_station_name,
  end_station_name,
  is_weekend,
  age,
  tripduration as label
FROM
  `11_nyc_bike_sharing_dnn.training_table`;
  

CREATE OR REPLACE MODEL `11_nyc_bike_sharing_dnn.trip_duration_by_stations_day_age_crelu`
OPTIONS
  (model_type='DNN_REGRESSOR',
        ACTIVATION_FN = 'CRELU') AS
SELECT
  start_station_name,
  end_station_name,
  is_weekend,
  age,
  tripduration as label
FROM
  `11_nyc_bike_sharing_dnn.training_table`;

SELECT
  *
FROM
  ML.EVALUATE(MODEL `11_nyc_bike_sharing_dnn.trip_duration_by_stations_day_age_relu`,
    (
    SELECT
          start_station_name,
          end_station_name,
          is_weekend,
          age,
          tripduration as label
    FROM
           `11_nyc_bike_sharing_dnn.evaluation_table` ));

SELECT
  *
FROM
  ML.EVALUATE(MODEL `11_nyc_bike_sharing_dnn.trip_duration_by_stations_day_age_crelu`,
    (
    SELECT
          start_station_name,
          end_station_name,
          is_weekend,
          age,
          tripduration as label
    FROM
           `11_nyc_bike_sharing_dnn.evaluation_table` ));

SELECT
   tripduration as actual_duration,
   predicted_label as predicted_duration,
   ABS(tripduration - predicted_label) difference_in_min
FROM
  ML.PREDICT(MODEL `11_nyc_bike_sharing_dnn.trip_duration_by_stations_day_age_relu`,
    (
    SELECT
         start_station_name,
          end_station_name,
          is_weekend,
          age,
          tripduration
    FROM
           `11_nyc_bike_sharing_dnn.prediction_table`
    ))
    order by  difference_in_min asc;

### Final considerations about the difference in terms of actual and predicted values of trip duration  ###
--1 636 606
SELECT COUNT (*)
FROM (
SELECT
   tripduration as actual_duration,
   predicted_label as predicted_duration,
   ABS(tripduration - predicted_label) difference_in_min
FROM
  ML.PREDICT(MODEL  `11_nyc_bike_sharing_dnn.trip_duration_by_stations_day_age_relu`,
    (
    SELECT
          start_station_name,
          end_station_name,
          is_weekend,
          age,
          tripduration
    FROM
           `11_nyc_bike_sharing_dnn.prediction_table`
    ))
    order by  difference_in_min asc) where difference_in_min<=15 ;

