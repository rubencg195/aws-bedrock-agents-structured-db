# Example Questions for Asset Management Database

## 1. How many assets are located in FMX High School?

**Answer:** 47 in CSV, 63 in Glue

**Query:**
```sql
SELECT COUNT(*) FROM assets WHERE building LIKE '%FMX High School%'
```

**LLM-Answer:** `{"_col0":"63"}`

**LLM-Query:**
```sql
SELECT COUNT(*) FROM assets WHERE building LIKE '%FMX High School%'
```

**LLM-Execution-Time:** 9681.05ms

---

## 2. What is the type of all assets in the dataset?

**Answer:** Electrical, HVAC, Plumbing, Vehicle, Fire Safety

**Query:**
```sql
SELECT DISTINCT type FROM assets
```

**LLM-Answer:** No results found (empty array)

**LLM-Query:**
```sql
SELECT DISTINCT type FROM assets
```

**LLM-Execution-Time:** 6189.04ms

---

## 3. What is the average replacement Asset Value of each asset?

**Answer:** 12000

**Query:**
```sql
SELECT DISTINCT replacement_asset_value FROM assets
```

**LLM-Answer:** `{"average_replacement_asset_value":"11972.226161616161"}`

**LLM-Query:**
```sql
SELECT AVG(CAST(replacement_asset_value AS DOUBLE)) AS average_replacement_asset_value FROM assets
```

**LLM-Execution-Time:** 8839.75ms

---

## 4. Which school has the asset with Tag "1629132 - AHU 14-ES"?

**Answer:** FMX Elementary School

**Query:**
```sql
SELECT building FROM assets WHERE tag LIKE '%1629132 - AHU 14-ES%'
```

**LLM-Answer:** ERROR: Lambda invocation failed: System.Management.Automation.RemoteException An error occurred (InvalidRequestContentException) when calling the Invoke operation: Could not parse request body into json: Could not parse payload into json: Unexpected character ('1' (code 49)): was expecting comma to separate Object entries at [Source: REDACTED (`StreamReadFeature.INCLUDE_SOURCE_IN_LOCATION` disabled); line: 1, column: 52] (after 3 attempts)

**LLM-Query:** ERROR: Lambda invocation failed: System.Management.Automation.RemoteException An error occurred (InvalidRequestContentException) when calling the Invoke operation: Could not parse request body into json: Could not parse payload into json: Unexpected character ('1' (code 49)): was expecting comma to separate Object entries at [Source: REDACTED (`StreamReadFeature.INCLUDE_SOURCE_IN_LOCATION` disabled); line: 1, column: 52] (after 3 attempts)

**LLM-Execution-Time:** 0ms

---

## 5. Which manufacturer appears most frequently in the dataset?

**Answer:** Trane 9 times

**Query:**
```sql
SELECT manufacturer, COUNT(*) as count FROM assets WHERE manufacturer IS NOT NULL GROUP BY manufacturer ORDER BY count DESC LIMIT 1
```

**LLM-Answer:** `{"manufacturer":"","count":"129"}`

**LLM-Query:**
```sql
SELECT manufacturer, COUNT(*) as count 
FROM assets 
GROUP BY manufacturer 
ORDER BY count DESC 
LIMIT 1
```

**LLM-Execution-Time:** 8585.1ms

---

## 6. Which manufacturer (with no empty values) appears most frequently in the dataset?

**Answer:** Trane 9 times

**Query:**
```sql
SELECT manufacturer, COUNT(*) as count FROM assets WHERE manufacturer IS NOT NULL GROUP BY manufacturer ORDER BY count DESC LIMIT 1
```

**LLM-Answer:** No results found (empty array)

**LLM-Query:**
```sql
SELECT manufacturer, COUNT(*) as count
FROM assets
WHERE manufacturer IS NOT NULL
AND manufacturer <> ''
GROUP BY manufacturer
ORDER BY count DESC
LIMIT 1
```

**LLM-Execution-Time:** 7295.01ms

---

## 7. Which building has a unit installed on 2/20/2020?

**Answer:** FMX Middle School

**Query:**
```sql
SELECT building FROM assets WHERE installation_date LIKE '%2/20/2020%'
```

**LLM-Answer:** `{"building":"FMX Middle School"}`

**LLM-Query:**
```sql
SELECT building FROM assets WHERE installation_date LIKE '%2/20/2020%'
```

**LLM-Execution-Time:** 8809.9ms

---

## 8. How many unique buildings are represented in the dataset?

**Answer:** 3

**Query:**
```sql
SELECT COUNT(DISTINCT building) FROM assets
```

**LLM-Answer:** `{"_col0":"4"}`

**LLM-Query:**
```sql
SELECT COUNT(DISTINCT building) FROM assets
```

**LLM-Execution-Time:** 8111.4ms

---

## 9. How many assets have a planned replacement date after 2035?

**Answer:** 3

**Query:**
```sql
SELECT COUNT(*) FROM assets WHERE planned_replacement_date LIKE '%2038%' OR planned_replacement_date LIKE '%2039%'
```

**LLM-Answer:** `{"_col0":"55"}`

**LLM-Query:**
```sql
SELECT COUNT(*) 
FROM assets 
WHERE 
  CAST(SUBSTRING(planned_replacement_date, LENGTH(planned_replacement_date)-3, 4) AS INTEGER) > 2035
```

**LLM-Execution-Time:** 12399.5ms

---

## 10. Which assets have an estimated end-of-life in 2045 but a planned replacement before 2035?

**Answer:** 14

**Query:**
```sql
SELECT COUNT(*) FROM assets WHERE estimated_end_of_life LIKE '%2045%' AND planned_replacement_date LIKE '%2027%' OR planned_replacement_date LIKE '%2029%' OR planned_replacement_date LIKE '%2033%' OR planned_replacement_date LIKE '%2034%'
```

**LLM-Answer:** No results found (empty array)

**LLM-Query:**
```sql
SELECT *
FROM assets
WHERE estimated_end_of_life LIKE '%2045%'
AND (
    CAST(SUBSTRING(planned_replacement_date, LENGTH(planned_replacement_date) - 3) AS INTEGER) < 2035
    OR
    SUBSTRING(planned_replacement_date, LENGTH(planned_replacement_date) - 3) LIKE '20[0-2][0-9]'
    OR
    SUBSTRING(planned_replacement_date, LENGTH(planned_replacement_date) - 3) LIKE '19%'
)
```

**LLM-Execution-Time:** 9725.05ms

---

## 11. How many assets do not have a specified manufacturer?

**Answer:** 5

**Query:**
```sql
SELECT COUNT(*) FROM assets WHERE manufacturer IS NULL OR manufacturer = ''
```

**LLM-Answer:** No results found (empty array)

**LLM-Query:**
```sql
SELECT COUNT(*) 
FROM assets 
WHERE manufacturer IS NULL OR TRIM(manufacturer) = ''
```

**LLM-Execution-Time:** 7275.17ms

---

## 12. What is the average remaining useful life (in years)?

**Answer:** 20.06

**Query:**
```sql
SELECT AVG(CAST(REPLACE(REPLACE(remaining_useful_life, ' years', ''), ' months', '') AS DOUBLE)) FROM assets
```

**LLM-Answer:** `{"average_remaining_useful_life_years":"19.97979797979798"}`

**LLM-Query:**
```sql
SELECT AVG(CAST(REGEXP_EXTRACT(remaining_useful_life, '(\d+)', 1) AS DOUBLE)) AS average_remaining_useful_life_years FROM assets
```

**LLM-Execution-Time:** 9049.68ms

---

## 13. What percentage of assets were manufactured by Trane?

**Answer:** 45

**Query:**
```sql
SELECT (COUNT(CASE WHEN manufacturer LIKE '%Trane%' THEN 1 END) * 100.0 / COUNT(*)) as percentage FROM assets
```

**LLM-Answer:** No results found (empty array)

**LLM-Query:**
```sql
SELECT 
  (COUNT(CASE WHEN manufacturer LIKE '%Trane%' THEN 1 ELSE NULL END) * 100.0 / COUNT(*)) AS trane_percentage
FROM assets
```

**LLM-Execution-Time:** 7655.38ms
