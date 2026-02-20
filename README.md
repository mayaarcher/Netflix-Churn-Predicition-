<h1> Are You Still Watching? — Netflix Churn Prediction</h1>

<p>
  <span class="badge">R</span>
  <span class="badge">Logistic Regression</span>
  <span class="badge">Machine Learning</span>
</p>

<p>
  A logistic regression based machine learning project predicting Netflix subscriber churn
  using customer demographics, subscription details, and usage behavior.
</p>

<h2> Project Overview</h2>
<p>
  This project investigates which customer characteristics and usage patterns are most predictive
  of Netflix churn. Using a dataset of 5,000 Netflix customer records from Kaggle, we built and
  validated a logistic regression model alongside penalized variants (Ridge, Lasso, Elastic Net)
  to classify whether a subscriber is likely to cancel their subscription.
</p>

<h2> Dataset</h2>
<ul>
  <li><strong>Source:</strong> Netflix Customer Churn dataset (Kaggle)</li>
  <li><strong>Size:</strong> 5,000 records, 13 variables</li>
  <li><strong>Features:</strong> Age, gender, region, subscription type, payment method, device,
    watch hours, average watch time per day, number of profiles, days since last login, favorite genre</li>
  <li><strong>Target:</strong> Churn (Yes = 1 / No = 0)</li>
</ul>

<h2> Methodology</h2>
<ul>
  <li>80/20 train-test split</li>
  <li>10-fold cross-validation (3 repeats)</li>
  <li>Assumptions verified: binary dependent variable, observation independence, linearity of log-odds,
    no multicollinearity (VIF &lt; 5), no extreme outliers (Cook's Distance &lt; 0.5)</li>
  <li><code>monthly_fee</code> removed due to perfect multicollinearity with <code>subscription_type</code></li>
  <li>Penalized variants (Ridge, Lasso, Elastic Net) run to validate robustness</li>
</ul>

<h2> Key Findings</h2>
<p>The most significant predictors of churn were:</p>
<table>
  <thead>
    <tr><th>Predictor</th><th>Effect on Churn Odds</th></tr>
  </thead>
  <tbody>
    <tr><td>Payment method — Crypto (vs. credit card)</td><td>+426% higher churn odds</td></tr>
    <tr><td>Payment method — Gift Card (vs. credit card)</td><td>+393% higher churn odds</td></tr>
    <tr><td>Number of profiles (4–5 vs. 1)</td><td>~99% lower churn odds</td></tr>
    <tr><td>Subscription type — Standard (vs. Basic)</td><td>~91% lower churn odds</td></tr>
    <tr><td>Subscription type — Premium (vs. Basic)</td><td>~92% lower churn odds</td></tr>
    <tr><td>Watch hours (per additional hour)</td><td>29% lower churn odds</td></tr>
    <tr><td>Days since last login (per additional day)</td><td>+15% higher churn odds</td></tr>
  </tbody>
</table>
<p>Demographics like age, gender, and region were <strong>not</strong> statistically significant.</p>

<h2> Model Performance</h2>
<p>
  All four models converged to nearly identical test accuracy, confirming the robustness of the results.
</p>
<table>
  <thead>
    <tr><th>Model</th><th>Train Accuracy</th><th>Test Accuracy</th><th>Error Rate</th></tr>
  </thead>
  <tbody>
    <tr><td>Logistic Regression</td><td>90.7%</td><td>89.6%</td><td>10.4%</td></tr>
    <tr><td>Ridge</td><td>—</td><td>89.08%</td><td>10.92%</td></tr>
    <tr><td>Lasso</td><td>—</td><td>89.08%</td><td>10.92%</td></tr>
    <tr><td>Elastic Net</td><td>—</td><td>89.08%</td><td>10.92%</td></tr>
  </tbody>
</table>

<h2> Business Recommendations</h2>
<table>
  <thead>
    <tr><th>Timeframe</th><th>Recommendation</th></tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Immediate</strong></td>
      <td>Re-engage inactive users with personalised emails or push notifications triggered by inactivity thresholds</td>
    </tr>
    <tr>
      <td><strong>Short–Medium Term</strong></td>
      <td>Encourage stable payment methods (e.g. credit/debit card) over crypto or gift cards; run targeted upgrade campaigns for Basic subscribers</td>
    </tr>
    <tr>
      <td><strong>Short–Medium Term</strong></td>
      <td>Re-examine the Netflix Household policy since higher profile counts are strongly associated with lower churn</td>
    </tr>
    <tr>
      <td><strong>Long Term</strong></td>
      <td>Measure intervention impact via 30 day retention rate, cost per saved customer, and ROI per campaign</td>
    </tr>
  </tbody>
</table>

<h2> Tools &amp; Language</h2>
<p>
  <strong>R</strong> — <code>glm</code>, <code>caret</code>, <code>glmnet</code>, <code>car</code>
</p>

<h2> Authors</h2>
<div class="authors">
  Anindita Nadine Khairunnisa · Maya Archer · Michele de Meza · Serafima Indienkova<br/>
  <em>EBA2 Group 6 </em>
</div>

<h2> Course Context</h2>
<p>
  This project was completed as part of the <strong>Introduction to Data Science</strong>
  course at Erasmus University Rotterdam (2025).
</p>

</body>
</html>
