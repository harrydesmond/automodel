import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import make_pipeline

df = pd.read_csv("data/readmit.csv")
num = ["age", "los_days", "n_prior_adm", "creatinine", "sodium", "hb"]
cat = ["sex", "discharge_to"]
pre = ColumnTransformer([("num", StandardScaler(), num), ("cat", OneHotEncoder(drop="first"), cat)])
model = make_pipeline(pre, LogisticRegression(max_iter=1000))
print("CV AUC", cross_val_score(model, df[num + cat], df["readmit30"], cv=5, scoring="roc_auc").mean())
