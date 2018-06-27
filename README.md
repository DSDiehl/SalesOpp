# Sales Opportunity Data Analysis
##  Marcus Diehl, MSDS 692, Regis University 
### June 23, 2018


# Introduction & Domain
The data set being presented in this assignment is of Sales Opportunities in relation to a manufacturing company.  Sales Opportunities are leads that have the opportunity to result in a deal or contract with a customer. Typically these opportunities are stored in corporate Customer Relation Management (CRM) systems to help management track the success or failure of a company representative in the sales force.

The data set is a extraction of a live CRM solution, and due to agreements for its use, certain identifiable information were required to be masked before it was released to the public.  The identifiable information includes people, places and products.  The analysis of the data set can still be accomplished as the data is not removed, just replaced with an unique ID which allows categories and classifiers to still function properly.

Another issue is that the data was manually entered by sales personnel. This is noted as it highlights the mistakes that human error introduce.  The majority of the work done in this assignment was in cleaning up the data. This will be highlighted in the Preprocessing section.

# Purpose
The overall purpose, or goal of this analysis is to evaluate the potential of a machine learning model in making a prediction against the data set, specifically if an opportunity will be successful or fail.  Though there are plenty of external factors that can influence contract negotiations with a customer, the curiosity to explore is still necessary.  If there are any patterns that can be discovered or the identification of the most influential features would be helpful to know. This is the purpose of the analysis, to discover any insight no matter how small.

# Exploratory Analysis
![Image](/Images/image1.jpg)


The data set contains 77 features and 13,097 samples. Of these samples, there appear to be two distinct categories around the Opportunities. They are 'New Business' and 'Jeopardy'. 

![Image](/Images/image2.jpg)

There are also subcategories for OppType which state the results of the opportunity in relation to the OppType. These features are OppTypeNewState (for New Business) and  OppTypeJepState (for Jeopardy)
![Image1](/Images/image3.jpg)

![Image1](/Images/image4.jpg)

The creation dates (OppCreateDate) of each opportunity are also interesting. Though the earliest entry is in 2011, the concentration of opportunities entered into the CRM didn't rise untill 2015.

![Image1](/Images/image5.jpg)

There is also a category around the Technology being requested to be used in the Opportunity and how a large number of opportunities rely on a certain key number of technologies.

![Image1](/Images/image6.jpg)

# Data Preprocessing
Being that the data set is a raw extract from a CRM system that was provided as an MS Excel file, there was a lot of preprocessing required to clean the data. This is different from much of the academic data sets that already are clean. Typical issues like empty fields, spaces in column names, incorrect data types and unnecessary columns were many of the hurdles in completing the analysis of this data set.

Another aspect of the preprocessing is preparing the data for a specific Opportunity Type analysis. Earlier in EDA, it was discovered that New Business were the majority of the samples and we wish to refine the Machine Learning to focus on only New Business.

![Image1](/Images/image7.jpg)


Also discovered during EDA is that New Business has 3 categories; Sold, Dead, and Active. Sold/Dead have Opportunity Close Dates, while Active are currently active opportunities where business is still being negotiated.

Overall, the goal is to create a Random Forest model to develop a binary classification on whether the Active Opportunity will be Sold (positive) or Dead (negative).

To accomplish this, new features need to be created based on calculations from the original data set. The Opportunities, since they are ordered by Date, should be treated as a Time Series dataset in which we need to start calculating different count of categories over time.

This is accomplished with cumsum() or Cumulative Sum function within R. This was chosen over simple count because though the total measurements will be applied to the Active data, the Dead and Sold data should not be given future results when calculating the measurements.

This is better explained by Sales Opportunity Risk Management, in which the more experience a Sales Rep has, the less risk an opportunity has to result in a Dead classification. But, until the opportunity is closed and labeled, we cannot count its results in the measurement. This is the core use of Cumulative Sum.

Other columns being measured with the grouping of Sold or Dead classifications are Customer history, Competition history, Technology history, Customer Global Region and regular Region history, Customer Core Business Segment and Sub Business Segment history, and the Sales Rep history.

Another calculation towards Risk is the duration of the Opportunity remaining open. The longer an opportunity takes to conclude, the larger the chance it has to reach a Dead classification. However, it was discovered that some of the Opportunities were backdated which is an issue that will be discussed in Data Refinement section.


# Data Refinement
Now that Preprocessing of data has been completed, there is still some refinement on the data that is required.  The creation of Duration highlighted a missed discovery in EDA that would have shown an issue of Back Dating. Back Dating is the creation of an Opportunity AFTER the results are known. This causes the CloseDate to be Older than the CreateDate which results in negative durations being calculated.  Overall, 3.7% of all Opportunities had a negative duration.

![Image1](/Images/image8.jpg)

Based on that small amount a solution was devised to replace the negative durations with a Mean Duration so as not lose the other features related to those samples.  The mean duration turned out to be 282 days.

There was also the issue of missing values peppered across the data set. This had to be handled differently because the missing values were mostly around the categorical data like labeling of Region. 

Columns with missing data were expected since there individual columns were directly related to New Business or Jeopardy categories of OppType. Then there were columns related to if the Opportunity was successful in winning the business or not and the actual profits made on successful Opportunities. These columns could be ignored as they would not be used in the prediction. Other columns though were labeled as important for the Random Forest and needed to have the missing values fixed.  

Below is the actual missing data directly related to New Business and identified as being of benefit for the Machine Learning model.


![Image1](/Images/image9.jpg)

![Image1](/Images/image10.jpg)


# Machine Learning
After the Cumulative Sum, Opportunity Duration analysis and cleaning up  missing values (NAs), it was time to focus on the New Business data. Currently the data of New Business is split with 44.6% Sold, 30.1% Dead, and 25.2% still active.

![Image1](/Images/image11.jpg)

For the purpose of the Random Forest modeling, the Active and !Active (Sold or Dead) classification data types will need to be separated so the Random Forest model can be created on the !Active.

To conduct a Machine Learning (ML) model, the data set for History must be split into Training and Test datasets. A ratio 70:30 for Train and Test was selected. Exploring the data, features that were numeric or categorical were selected to be used for the ML model. Some categorical data was dropped due to the size of the options, but the Cumulative Sum measurements created from those categories were retained. In the end, 33 of the 94 Columns were selected.

The createDataParition (), from caret library, breaks the original data set into an equal share of Solds and Deads based on the label OppTypeNewState. The reason for this is that any improvement or detrimental of sales techniques over time should not be an influence on the model.

![Image1](/Images/image12.jpg)

![Image1](/Images/image13.jpg)

93% accuracy! This was not originally expected to be doable since it was theorized that there were too many external influences on the success or failure of opportunities to be contained in this data set. External markets fluctuations, production changes, and competition were never made available in the dataset.

![Image1](/Images/image14.jpg)

From the plot above, we can see that after 20 trees, there is no longer a dramatic reduction in error, but there is still a gradual descent.  

The Top 10 Variable Importance based on the model highlights how much the Cumulative Sum measurements came into play. The main variables were the Customer’s Sold and Dead experience scores which were unexpected. Initially, it was hypothesized that the Sales Rep would have the most influence on the outcome.

Another point of interest is that though it was pricted that the Duration of the Opportunity would have a high influence on the model, the Create Date of the Opportunity did as well. Customer Core Business Segment had a high influence, which was expected but not the Region grouping of Dead opportunities.

Last in the Top 10 were around the competition, which was expected.


# Conclusion
The ML model did better than expected at being able to provide a prediction towards New Business Opportunities. There was concern about the undocumented or unmeasured external influences that factor into predicting the Opportunity classifcation. 

Though not stated originally, the extraction of the CRM system data was provided on 05/19/2018. In a few months' time, some of the Active Opportunities should close out and it will be interesting to see how well the model works outside the Train/Test workspace. 

# Summary
The Random Forest Machine Learning Supervised model worked exceptionally well in creating a Binary Classifier.  The results were enhanced by the addition of calculated features off the Time Series data set which were created by Cumulative Sum based on this historical Opportunity results.

# References
http://www.inflexion-point.com/blog/why-every-sales-opportunity-needs-a-regular-opportunity-risk-assessment

https://www.r-bloggers.com/random-forests-in-r/

https://www.r-bloggers.com/random-forest-classification-of-mushrooms/
