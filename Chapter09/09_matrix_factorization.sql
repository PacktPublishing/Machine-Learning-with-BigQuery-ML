CREATE OR REPLACE TABLE `09_recommendation_engine.all_ga_sessions` AS
SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`;

SELECT *
FROM `09_recommendation_engine.all_ga_sessions`
LIMIT 10;

CREATE OR REPLACE TABLE `09_recommendation_engine.product_purchases` AS
SELECT 	fullVisitorId,
		hits_product.productSKU AS purchased_product_id,
		COUNT(hits_product.productSKU) AS quantity
FROM
		`09_recommendation_engine.all_ga_sessions`,
		UNNEST(hits) AS hits,
		UNNEST(hits.product) AS hits_product
WHERE fullVisitorId IN (
                            SELECT fullVisitorId
                            FROM
									`09_recommendation_engine.all_ga_sessions`,
									UNNEST(hits) AS hits
                            WHERE hits.eCommerceAction.action_type = '6'
                            GROUP BY fullVisitorId
                          )
GROUP BY fullVisitorId, purchased_product_id;

CREATE OR REPLACE MODEL `09_recommendation_engine.purchase_recommender`
OPTIONS(model_type='matrix_factorization',
        user_col='fullVisitorID',
        item_col='purchased_product_id',
        rating_col='quantity',
        feedback_type='implicit'
        )
AS
SELECT fullVisitorID, purchased_product_id, quantity FROM `09_recommendation_engine.product_purchases`; 

SELECT
  *
FROM
  ML.EVALUATE(MODEL `09_recommendation_engine.recommender`,
    (
    SELECT * FROM `09_recommendation_engine.product_visits`));
	
CREATE OR REPLACE TABLE `09_recommendation_engine.product_recommendations` AS
	SELECT
	  DISTINCT fullVisitorID, purchased_product_id, predicted_quantity_confidence
	FROM
	  ML.RECOMMEND(MODEL`09_recommendation_engine.purchase_recommender`,
		(
		SELECT
		  fullVisitorID
		FROM
		  `09_recommendation_engine.product_purchases` ));
		  
SELECT *
FROM
	`09_recommendation_engine.product_recommendations`
ORDER BY predicted_quantity_confidence DESC
LIMIT 100;
