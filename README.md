# Machine Learning with BigQuery ML

<a href="https://www.packtpub.com/product/machine-learning-with-bigquery-ml/9781800560307?utm_source=github&utm_medium=repository&utm_campaign=9781838982881"><img src="https://static.packt-cdn.com/products/9781800560307/cover/smaller" alt="Machine Learning with BigQuery ML" height="256px" align="right"></a>

This is the code repository for [Machine Learning with BigQuery ML](https://www.packtpub.com/product/machine-learning-with-bigquery-ml/9781800560307?utm_source=github&utm_medium=repository&utm_campaign=9781800560307), published by Packt.

**Create, execute, and improve machine learning models in BigQuery using standard SQL queries**

## What is this book about?
BigQuery ML enables you to easily build machine learning (ML) models with SQL without much coding. This book will help you to accelerate the development and deployment of ML models with BigQuery ML.

The book starts with a quick overview of Google Cloud and BigQuery architecture. You'll then learn how to configure a Google Cloud project, understand the architectural components and capabilities of BigQuery, and find out how to build ML models with BigQuery ML. The book teaches you how to use ML using SQL on BigQuery. You'll analyze the key phases of a ML model's lifecycle and get to grips with the SQL statements used to train, evaluate, test, and use a model. As you advance, you'll build a series of use cases by applying different ML techniques such as linear regression, binary and multiclass logistic regression, k-means, ARIMA time series, deep neural networks, and XGBoost using practical use cases. Moving on, you'll cover matrix factorization and deep neural networks using BigQuery ML's capabilities. Finally, you'll explore the integration of BigQuery ML with other Google Cloud Platform components such as AI Platform Notebooks and TensorFlow along with discovering best practices and tips and tricks for hyperparameter tuning and performance enhancement.

By the end of this BigQuery book, you'll be able to build and evaluate your own ML models with BigQuery ML.

This book covers the following exciting features: 
* Discover how to prepare datasets to build an effective ML model
* Forecast business KPIs by leveraging various ML models and BigQuery ML
* Build and train a recommendation engine to suggest the best products for your customers using BigQuery ML
* Develop, train, and share a BigQuery ML model from previous parts with AI Platform Notebooks
* Find out how to invoke a trained TensorFlow model directly from BigQuery
* Get to grips with BigQuery ML best practices to maximize your ML performance

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/1800560303) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png" alt="https://www.packtpub.com/" border="5" /></a>

## Instructions and Navigations
All of the code is organized into folders.

The code will look like the following:
```
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

```

**Following is what you need for this book:**
This book helps you accelerate machine learning model development with BigQuery ML. Throughout the book, you'll use various ML models to learn about BigQuery ML features and discover how to apply them to different business scenarios. This book will help you to extend existing SQL capabilities to leverage the full potential of machine learning.	

With the following software and hardware list you can run all code files present in the book (Chapter 3-13).

### Software and Hardware List

| Chapter  | Software required                                                                    | OS required                        |
| -------- | -------------------------------------------------------------------------------------| -----------------------------------|
|  3 - 13  |   Google Cloud Platform, Google BigQuery, Google AI Platform Notebooks               | Windows, Mac OS X, and Linux (Any) |


We also provide a PDF file that has color images of the screenshots/diagrams used in this book. [Click here to download it](https://static.packt-cdn.com/downloads/9781800560307_ColorImages.pdf).

## Code in Action
Click on the following link to see the Code in Action: https://bit.ly/3f11XbU


### Related products <Other books you may enjoy>
* Automated Machine Learning [[Packt]](https://www.packtpub.com/product/automated-machine-learning/9781800567689) [[Amazon]](https://www.amazon.com/dp/1800567685)

* Hands-On Artificial Intelligence on Google Cloud Platform [[Packt]](https://www.packtpub.com/product/hands-on-artificial-intelligence-on-google-cloud-platform/9781789538465) [[Amazon]](https://www.amazon.com/dp/B084ZMWRMP)

## Get to Know the Author
**Alessandro Marrandino** is a Google Cloud customer engineer. He helps various enterprises on the digital transformation journey to adopt cloud technologies. He is actively focused on and experienced in data management and smart analytics solutions. He has spent his entire career on data and artificial intelligence projects for global companies in different industries.

