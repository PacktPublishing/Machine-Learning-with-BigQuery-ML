--31 619
SELECT  COUNT(*)
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         spc_latin is NULL;

--2 caused by NULL values in sidewalk and health
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

--132 different species
SELECT  DISTINCT spc_latin
FROM    `bigquery-public-data.new_york_trees.tree_census_2015`
WHERE
         spc_latin is NOT NULL
         AND zipcode is NOT NULL 
         AND block_id is NOT NULL 
         AND tree_dbh is NOT NULL
         AND boroname is NOT NULL 
         AND sidewalk is NOT NULL;

--identify the top 5 species
-- Platanus x acerifolia,Gleditsia triacanthos var. inermis,Pyrus calleryana, Quercus palustris,Acer platanoides
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

CREATE OR REPLACE TABLE `06_nyc_trees.top5_species` AS
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

--Creation of the training table
CREATE OR REPLACE TABLE `06_nyc_trees.training_table` AS 
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
         (SELECT spc_latin from `06_nyc_trees.top5_species`) 
         AND MOD(tree_id,11)<=8;

--Creation of the evaluation table
CREATE OR REPLACE TABLE `06_nyc_trees.evaluation_table` AS 
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
         (SELECT spc_latin from `06_nyc_trees.top5_species`) 
         AND MOD(tree_id,11)=9;
         
--Creation of the prediction/classification table
CREATE OR REPLACE TABLE `06_nyc_trees.classification_table` AS 
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
         (SELECT spc_latin from `06_nyc_trees.top5_species`) 
         AND MOD(tree_id,11)=10;

--Training of the first version of the model using the City and the diameter of the tree
CREATE OR REPLACE MODEL `06_nyc_trees.classification_model_version_1`
OPTIONS
  ( model_type='LOGISTIC_REG',
    auto_class_weights=TRUE
  ) AS
SELECT
  zip_city,
  tree_dbh,
  spc_latin as label
FROM
  `06_nyc_trees.training_table` ;

--Training of the first version of the model using the City, the diameter of the tree, the neighobour and the nta
CREATE OR REPLACE MODEL `06_nyc_trees.classification_model_version_2`
OPTIONS
  ( model_type='LOGISTIC_REG',
    auto_class_weights=TRUE
  ) AS
SELECT
  zip_city,
  tree_dbh,
  boroname,
  nta_name,
  spc_latin as label
FROM
  `06_nyc_trees.training_table` ;

--Training of the first version of the model using the City, the diameter of the tree, the neighobour and the nta + others
CREATE OR REPLACE MODEL `06_nyc_trees.classification_model_version_3`
OPTIONS
  ( model_type='LOGISTIC_REG',
    auto_class_weights=TRUE
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
  `06_nyc_trees.training_table`;

--Evaluation of the ML model: result is GOOD
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
  ML.EVALUATE(MODEL `06_nyc_trees.classification_model_version_3`,
    (
    SELECT
       zip_city,
       tree_dbh,
       boroname,
       nta_name,
       health,
       sidewalk,
       spc_latin as label
     FROM `06_nyc_trees.evaluation_table`));

SELECT
  tree_id,
  actual_label,
  predicted_label_probs,
  predicted_label
FROM
  ML.PREDICT (MODEL `06_nyc_trees.classification_model_version_3`,
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
      `06_nyc_trees.classification_table`
     )
  );

--13 323
-- 49% of the times
SELECT COUNT(*)
FROM (
      SELECT
        tree_id,
        actual_label,
        predicted_label_probs,
        predicted_label
      FROM
        ML.PREDICT (MODEL `06_nyc_trees.classification_model_version_3`,
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
            `06_nyc_trees.classification_table`
           )
        )
)
WHERE
      actual_label = predicted_label;
