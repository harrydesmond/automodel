# 30-day readmission model
- `data/readmit.csv`: one row per hospital admission (48,213 rows in the full extract; first 24 rows kept here).
  Columns: admission_id, patient_id, age, sex, los_days (length of stay), n_prior_adm (admissions in previous
  12 months), creatinine, sodium, hb (haemoglobin), discharge_to (home/care/other), readmit30 (0/1 outcome).
- `baseline.py`: logistic regression on all raw features, 5-fold CV AUC 0.684. One fit takes ~2 s.
