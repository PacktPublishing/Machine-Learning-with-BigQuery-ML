
SELECT  COUNT(*)
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         spc_latin is NULL;


SELECT  COUNT(*)
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         spc_latin is NOT NULL
         AND (
            zip_city is NULL OR
            tree_dbh is NULL OR
            boroname is NULL OR
            nta_name is NULL OR
            health is NULL OR
            sidewalk is NULL) ;


SELECT  DISTINCT spc_latin
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         spc_latin is NOT NULL
         AND zipcode is NOT NULL 
         AND block_id is NOT NULL 
         AND tree_dbh is NOT NULL
         AND boroname is NOT NULL 
         AND sidewalk is NOT NULL;


SELECT   spc_latin,
         COUNT(*) total
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         spc_latin is NOT NULL
         AND zip_city is NOT NULL
         AND tree_dbh is NOT NULL
         AND boroname is NOT NULL
         AND nta_name is NOT NULL
         AND health is NOT NULL
         AND sidewalk is NOT NULL
GROUP BY
         spc_latin
ORDER BY
         total desc
LIMIT 5;

CREATE OR REPLACE TABLE `10_nyc_trees_xgboost.top5_species` AS
      SELECT   spc_latin,
         COUNT(*) total
      FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
      WHERE
               spc_latin is NOT NULL
               AND zip_city is NOT NULL
               AND tree_dbh is NOT NULL
               AND boroname is NOT NULL
               AND nta_name is NOT NULL
               AND health is NOT NULL
               AND sidewalk is NOT NULL
      GROUP BY
               spc_latin
      ORDER BY
               total desc
      LIMIT 5;


CREATE OR REPLACE TABLE `10_nyc_trees_xgboost.training_table` AS 
SELECT  *
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         zip_city is NOT NULL
         AND tree_dbh is NOT NULL
         AND boroname is NOT NULL
         AND nta_name is NOT NULL
         AND health is NOT NULL
         AND sidewalk is NOT NULL
         AND spc_latin in 
         (SELECT spc_latin from `10_nyc_trees_xgboost.top5_species`) 
         AND MOD(tree_id,11)<=8;


CREATE OR REPLACE TABLE `10_nyc_trees_xgboost.evaluation_table` AS 
SELECT  *
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         zip_city is NOT NULL
         AND tree_dbh is NOT NULL
         AND boroname is NOT NULL
         AND nta_name is NOT NULL
         AND health is NOT NULL
         AND sidewalk is NOT NULL
         AND spc_latin in 
         (SELECT spc_latin from `10_nyc_trees_xgboost.top5_species`) 
         AND MOD(tree_id,11)=9;
         

CREATE OR REPLACE TABLE `10_nyc_trees_xgboost.classification_table` AS 
SELECT  *
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         zip_city is NOT NULL
         AND tree_dbh is NOT NULL
         AND boroname is NOT NULL
         AND nta_name is NOT NULL
         AND health is NOT NULL
         AND sidewalk is NOT NULL
         AND spc_latin in 
         (SELECT spc_latin from `10_nyc_trees_xgboost.top5_species`) 
         AND MOD(tree_id,11)=10;


CREATE OR REPLACE MODEL `10_nyc_trees_xgboost.xgboost_classification_model_version_1`
OPTIONS
  ( MODEL_TYPE='BOOSTED_TREE_CLASSIFIER',
    BOOSTER_TYPE = 'GBTREE',
    NUM_PARALLEL_TREE = 1,
    MAX_ITERATIONS = 50,
    TREE_METHOD = 'HIST',
    EARLY_STOP = FALSE,
    AUTO_CLASS_WEIGHTS=TRUE
  ) AS
SELECT
  zip_city,
  tree_dbh,
  spc_latin as label
FROM
  `10_nyc_trees_xgboost.training_table` ;


CREATE OR REPLACE MODEL `10_nyc_trees_xgboost.xgboost_classification_model_version_2`
OPTIONS
  ( MODEL_TYPE='BOOSTED_TREE_CLASSIFIER',
    BOOSTER_TYPE = 'GBTREE',
    NUM_PARALLEL_TREE = 1,
    MAX_ITERATIONS = 50,
    TREE_METHOD = 'HIST',
    EARLY_STOP = FALSE,
    AUTO_CLASS_WEIGHTS=TRUE
  ) AS
SELECT
  zip_city,
  tree_dbh,
  boroname,
  nta_name,
  spc_latin as label
FROM
  `10_nyc_trees_xgboost.training_table` ;


CREATE OR REPLACE MODEL `10_nyc_trees_xgboost.xgboost_classification_model_version_3`
OPTIONS
  ( MODEL_TYPE='BOOSTED_TREE_CLASSIFIER',
    BOOSTER_TYPE = 'GBTREE',
     NUM_PARALLEL_TREE = 1,
    MAX_ITERATIONS = 50,
    TREE_METHOD = 'HIST',
    EARLY_STOP = FALSE,
    AUTO_CLASS_WEIGHTS=TRUE
  ) AS
SELECT
  zip_city,
  tree_dbh,
  boroname,
  nta_name,
  health,
  sidewalk,
  spc_latin as label
FROM
  `10_nyc_trees_xgboost.training_table`;


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
  ML.EVALUATE(MODEL `10_nyc_trees_xgboost.xgboost_classification_model_version_3`,
    (
    SELECT
       zip_city,
       tree_dbh,
       boroname,
       nta_name,
       health,
       sidewalk,
       spc_latin as label
     FROM `10_nyc_trees_xgboost.evaluation_table`));

SELECT
  tree_id,
  actual_label,
  predicted_label_probs,
  predicted_label
FROM
  ML.PREDICT (MODEL `10_nyc_trees_xgboost.xgboost_classification_model_version_3`,
    (
    SELECT
       tree_id,
       zip_city,
       tree_dbh,
       boroname,
       nta_name,
       health,
       sidewalk,
       spc_latin as actual_label
    FROM
      `10_nyc_trees_xgboost.classification_table`
     )
  );

--14 277
-- 52,52% of the times
SELECT COUNT(*)
FROM (
      SELECT
        tree_id,
        actual_label,
        predicted_label_probs,
        predicted_label
      FROM
        ML.PREDICT (MODEL `10_nyc_trees_xgboost.xgboost_classification_model_version_3`,
          (
          SELECT
             tree_id,
             zip_city,
             tree_dbh,
             boroname,
             nta_name,
             health,
             sidewalk,
             spc_latin as actual_label
          FROM
            `10_nyc_trees_xgboost.classification_table`
           )
        )
)
WHERE
      actual_label = predicted_label;
