############ DISCLAIMER: the queries below are stubs to explain the syntax of BigQuery ML and cannot be executed as is ############


############ BigQuery ML Model Creation (Training Stage)  ############
CREATE MODEL`<project_name>.<dataset_name>.<ml_model_name>`
TRANSFORM (<list_of_features_transformed>
OPTIONS(<list_of_options>)
AS <select_statement>;

############ BigQuery ML EVALUATE Function (Evaluation Stage)  ############
SELECT *
FROM ML.EVALUATE(MODEL `<project_name>.<dataset_name>.<ml_model_name>`,
          `<project_name>.<dataset_name>.<evaluation_table>`
          , STRUCT(<treshold> AS threshold));
		  

############ BigQuery ML CONFUSION_MATRIX Function (Evaluation Stage)  ############		 
SELECT *
FROM ML.CONFUSION_MATRIX(MODEL `<project_name>.<dataset_name>.<ml_model_name>`,
          `<project_name>.<dataset_name>.<evaluation_table>`
          , STRUCT(<treshold> AS threshold));
		  
		  
############ BigQuery ML ROC_CURVE Function (Evaluation Stage)  ############		 
SELECT *
FROM ML.ROC_CURVE(MODEL `<project_name>.<dataset_name>.<ml_model_name>`,
          `<project_name>.<dataset_name>.<evaluation_table>`
          , GENERATE_ARRAY(<treshold_1>, <treshold_2>, <treshold_n> ));
		  
		  
############ BigQuery ML PREDICT Function (Use Stage)  ############
SELECT *
FROM ML.PREDICT(MODEL `<project_name>.<dataset_name>.<ml_model_name>`,
          `<project_name>.<dataset_name>.<features_table>`
          , STRUCT(<treshold> AS threshold));
		 

############ BigQuery ML FORECAST Function (Use Stage)  ############
SELECT *
FROM ML.FORECAST(MODEL `<project_name>.<dataset_name>.<ml_model_name>`,
          STRUCT(<horizon_value> AS horizon, <confidence_value> AS confidence_level));

############ BigQuery ML RECOMMEND Function (Use Stage)  ############
SELECT *
FROM ML.RECOMMEND(MODEL `<project_name>.<dataset_name>.<ml_model_name>`,
          (`<project_name>.<dataset_name>.<user_item_table>`));
		  
		  
############ BigQuery ML Deletion of a ML model  ############
DROP MODEL `<project_name>.<dataset_name>.<ml_model_name>`;

DROP MODEL IF EXISTS `<project_name>.<dataset_name>.<ml_model_name>`;
