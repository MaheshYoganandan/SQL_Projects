-- Patient Status

SELECT COUNT(*) AS 'Total Patients',
	SUM(CASE WHEN deathdate is null THEN 1 END) AS 'Living Patients',
	COUNT(deathdate) AS 'Deceased Patients'
FROM patients;


-- Gender classification (No. of Female and Male Patients)

SELECT 
	SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS 'Female Patients',
	SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS 'Male Patients',
	COUNT(*) AS 'Total Patients'
FROM patients;


-- Total cost by encounter class and Insurance coverage, Actual cost incured by patients

SELECT encounterclass, 
	ROUND(SUM(base_encounter_cost + total_claim_cost),2) as 'Total cost', 
	ROUND(SUM(payer_coverage),2) AS 'Insurance Coverage',
	ROUND(SUM(payer_coverage) / SUM(base_encounter_cost + total_claim_cost)*100, 2) AS 'Insurance Coverage "%" ',
	ROUND(SUM(base_encounter_cost + total_claim_cost) - SUM(payer_coverage),2) AS 'Cost Incured by Patients'
	FROM encounters
GROUP BY encounterclass;


-- Top 5 Encounter Reasons

SELECT TOP 5 reasondescription, COUNT(reasondescription) AS reason_counts
FROM encounters e
JOIN patients p ON p.id = e.patient_id
GROUP BY reasondescription
ORDER BY reason_counts DESC;


-- Top 5 Procedures Reasons

SELECT TOP 5 hp.reason_description, COUNT(hp.reason_description) AS procedures_counts
FROM hsp_procedures hp
JOIN patients p ON p.id = hp.patient_id
GROUP BY hp.reason_description
ORDER BY procedures_counts DESC;


-- YoY Revenue of Massachusetts General Hospital

SELECT DATEPART(YEAR, e.start) AS Year_order,
	ROUND(SUM(base_encounter_cost + total_claim_cost),2) as 'Total Revenue'
FROM encounters e
JOIN patients p ON p.id = e.patient_id
GROUP BY DATEPART(YEAR, e.start)
ORDER BY Year_order;


-- YoY Revenue and Revenue and Revenue growth rate

WITH yoy_revenue AS (SELECT DATEPART(YEAR, e.start) AS Year_order,
	ROUND(SUM(base_encounter_cost + total_claim_cost),2) as Total_Revenue
FROM encounters e
JOIN patients p ON p.id = e.patient_id
GROUP BY DATEPART(YEAR, e.start)
),
prev_year_rev as ( SELECT *,
	LAG(Total_Revenue, 1) OVER(ORDER BY Year_order) AS prev_year_revenue
FROM yoy_revenue
)
SELECT Year_order, Total_Revenue, ROUND(((Total_Revenue / prev_year_revenue) * 100)-100, 2) AS YoY_growth
FROM prev_year_rev;


-- Payer key metrics

SELECT p.name AS Payer_name, ROUND(SUM(total_claim_cost), 2) AS Total_claim, 
	ROUND(SUM(payer_coverage),2) AS 'Insurance_Coverage',
	ROUND(SUM(payer_coverage) / SUM(total_claim_cost)*100, 2) AS 'Insurance Coverage "%" '
FROM encounters e
JOIN payers p on p.id = e.payer_id
GROUP BY p.name
ORDER BY Insurance_Coverage DESC;

-- No.of Patients by Payer

SELECT p2.name Insurer_name,COUNT(distinct p.id) No_of_Patients
FROM encounters e
JOIN patients p ON p.id= e.patient_id
JOIN payers p2 ON p2.id = e.payer_id
GROUP BY P2.name;


-- Encounters Description & Reason

SELECT e.description, count(distinct patient_id) as patients_counts, count(distinct e.id) no_of_encounters
FROM encounters e
WHERE e.description IS NOT NULL
GROUP BY e.description
ORDER BY patients_counts DESC;

-- Procedures Description & Reason00

SELECT h.reason_description, 
	count(distinct patient_id) as Patients_Counts, 
	count(distinct h.encounter_id) No_of_Encounters, 
	count(*) No_of_Procedures
FROM hsp_procedures h
WHERE h.reason_description IS NOT NULL
GROUP BY h.reason_description
order by h.reason_description;



-- No of encounters by each patient from 2011-2022
with name_table AS(
     SELECT p.id,
        REPLACE(TRANSLATE(first, '0123456789', '__________'), '_', '') AS First_name,
        REPLACE(TRANSLATE(last, '0123456789', '__________'), '_', '') AS Last_name
    FROM patients p
)
SELECT CONCAT(First_name,' ',Last_name) Patient_Name,
    count(distinct e.id) as No_of_Encounters 
FROM name_table n
JOIN encounters e on e.patient_id = n.id
GROUP BY n.id, CONCAT(First_name,' ',Last_name)
ORDER  BY Patient_Name;



-- Avg hour spend by each patient on encounter 

WITH encounter_time AS (
    SELECT 
        p.id,
        REPLACE(TRANSLATE(p.first, '0123456789', '__________'), '_', '') AS First_name,
        REPLACE(TRANSLATE(p.last, '0123456789', '__________'), '_', '') AS Last_name,
        DATEDIFF(MINUTE, e.start, e.stop) AS Avg_Hour
    FROM patients p
    JOIN encounters e ON p.id = e.patient_id
)
SELECT 
    CONCAT(First_name, ' ', Last_name) AS Patient_name,
    AVG(Avg_Hour) / 60 AS Avg_Encounter_Hours
FROM encounter_time
GROUP BY id, First_name, Last_name
ORDER BY Avg_Encounter_Hours DESC;


-- Altering patient table to add patient name by concating first and last name column

ALTER TABLE patients
ADD patient_name AS (CONCAT(REPLACE(TRANSLATE(first, '0123456789', '__________'), '_', ''), ' ', REPLACE(TRANSLATE(last, '0123456789', '__________'), '_', '')));


-- getting column names from table patient

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'patients'


-- patient group by age

WITH age_group as (
    SELECT 
        CASE 
            WHEN patient_age >= 30 AND patient_age < 40 THEN '30-40'
            WHEN patient_age >= 40 AND patient_age < 50 THEN '40-50'
            WHEN patient_age >= 50 AND patient_age < 60 THEN '50-60'
            WHEN patient_age >= 60 AND patient_age < 70 THEN '60-70'
            WHEN patient_age >= 70 AND patient_age < 80 THEN '70-80'
            WHEN patient_age >= 80 AND patient_age < 90 THEN '80-90'
            WHEN patient_age >= 90 AND patient_age < 100 THEN '90-100'
            WHEN patient_age >= 100 AND patient_age < 110 THEN '100-110'
        END AS age_group,
        id
    FROM(
        SELECT DATEDIFF(year, birthdate,GETDATE()) patient_age, id 
        FROM patients
        WHERE deathdate is NULL) as dob
)
SELECT age_group, count(id) no_of_patients
FROM age_group 
GROUP BY age_group
ORDER BY MIN(CAST(REPLACE(age_group, '-', '') AS INT));
