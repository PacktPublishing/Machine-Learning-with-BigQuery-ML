### Creation of the training table ###
CREATE OR REPLACE TABLE `13_tensorflow_model.training_table` AS
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

### Creation of the prediction table ###
CREATE OR REPLACE TABLE  `13_tensorflow_model.prediction_table` AS
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

CREATE OR REPLACE MODEL `13_tensorflow_model.bigquery_ml_model_to_export`
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
  `13_tensorflow_model.training_table`;
  
CREATE OR REPLACE MODEL `13_tensorflow_model.trip_duration_tf_imported_model`
OPTIONS (model_type='tensorflow',
         model_path='gs://bigqueryml-packt-us-bigqueryml-export-tf/bqml_exported_model/*');

SELECT
  *
FROM
  ML.PREDICT(MODEL `13_tensorflow_model.trip_duration_tf_imported_model`,
    (
    SELECT
         start_station_name,
          end_station_name,
          is_weekend,
          age,
          tripduration
    FROM
           `13_tensorflow_model.prediction_table`
    ));
