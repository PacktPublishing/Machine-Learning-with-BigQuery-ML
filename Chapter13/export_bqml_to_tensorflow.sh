PROJECT=$(gcloud config get-value project)
BUCKET=${PROJECT}-us-bigqueryml-export-tf
gsutil mb -l us gs://${BUCKET}

bq extract -m 13_tensorflow_model.bigquery_ml_model_to_export gs://${BUCKET}/bqml_exported_model
