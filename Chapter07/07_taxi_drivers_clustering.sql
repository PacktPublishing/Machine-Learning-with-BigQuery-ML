### Extracting the time frame of the BigQuery Public dataset ###
SELECT MAX(trip_start_timestamp),
       MIN(trip_start_timestamp)
FROM
`bigquery-public-data.chicago_taxi_trips.taxi_trips`;

### Pointing out outliers in the dataset ###
SELECT MAX (speed_mph), MAX (tot_income)
FROM (
      SELECT taxi_id,
             AVG(trip_miles/(trip_seconds/60/60)) AS speed_mph,
             SUM (fare+tips) AS tot_income
      FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips` 
      WHERE 
            EXTRACT(YEAR from trip_start_timestamp) = 2020
            AND trip_seconds > 0
            AND trip_miles >0
            AND fare > 0
      GROUP BY taxi_id);

### Creation of the first training table with speed_mph as feature###
CREATE OR REPLACE TABLE `07_chicago_taxi_drivers.taxi_miles_per_minute` AS 
SELECT *
FROM (
                SELECT taxi_id,
                         AVG(trip_miles/(trip_seconds/60/60)) AS speed_mph
                FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips` 
                WHERE 
                      EXTRACT(YEAR from trip_start_timestamp) = 2020
                       AND trip_seconds > 0
                       AND trip_miles >0
                GROUP BY taxi_id
      )
WHERE 
      speed_mph BETWEEN 0 AND 50;

### Creation of the second training table with speed_mph and tot_income as features###
CREATE OR REPLACE TABLE `07_chicago_taxi_drivers.taxi_speed_and_income` AS
SELECT *
FROM (
        SELECT taxi_id,
                AVG(trip_miles/(trip_seconds/60/60)) AS speed_mph,
               SUM (fare+tips) AS tot_income
        FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips` 
        WHERE 
              EXTRACT(YEAR from trip_start_timestamp) = 2020
              AND trip_seconds > 0
              AND trip_miles >0
              AND fare > 0
        GROUP BY taxi_id
      )
WHERE 
      speed_mph BETWEEN 0 AND 50
      AND tot_income BETWEEN 0 AND 150000;

### Training of the first k-means clustering model based on speed_mph ###
CREATE OR REPLACE MODEL `07_chicago_taxi_drivers.clustering_by_speed`
OPTIONS(model_type='kmeans', num_clusters=3, kmeans_init_method = 'KMEANS++') AS
  SELECT * EXCEPT (taxi_id)
  FROM `07_chicago_taxi_drivers.taxi_miles_per_minute`;

### Training of the second k-means clustering model based on speed_mph and tot_income ###
CREATE OR REPLACE MODEL `07_chicago_taxi_drivers.clustering_by_speed_and_income`
OPTIONS(model_type='kmeans', num_clusters=3, standardize_features = true, kmeans_init_method = 'KMEANS++') AS
  SELECT * EXCEPT (taxi_id)
  FROM `07_chicago_taxi_drivers.taxi_speed_and_income`;

### Extraction of the centroids ###
SELECT *
FROM ML.CENTROIDS
        (MODEL `07_chicago_taxi_drivers.clustering_by_speed`)
ORDER BY centroid_id;

### Prediction with the second k-means clustering model ###
SELECT
  * EXCEPT(nearest_centroids_distance)
FROM
  ML.PREDICT( MODEL `07_chicago_taxi_drivers.clustering_by_speed_and_income`,
    (
      SELECT *
      FROM
        `07_chicago_taxi_drivers.taxi_speed_and_income`
    ));

### Creation of the Top Drivers list ###
CREATE OR REPLACE TABLE `07_chicago_taxi_drivers.top_taxi_drivers_by_speed_and_income` AS
SELECT
  * EXCEPT(nearest_centroids_distance)
FROM
  ML.PREDICT( MODEL `07_chicago_taxi_drivers.clustering_by_speed_and_income`,
    (
      SELECT *
      FROM
        `07_chicago_taxi_drivers.taxi_speed_and_income`
    ))
WHERE CENTROID_ID=1; 

