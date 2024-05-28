CREATE DATABASE nyc_jobs;

USE nyc_jobs;

SELECT * FROM postings;

DESCRIBE postings;

-- >> ** A. DATA CLEANING ** << --
-- >> Changing Date format to STANDARD and date type from 'TEXT' into DATE

SET sql_safe_updates = 0;

UPDATE postings
SET posting_date = DATE_FORMAT(STR_TO_DATE(posting_date, '%m/%d/%Y'), '%Y-%m-%d')
WHERE posting_date LIKE '%/%/%';

ALTER TABLE postings
MODIFY COLUMN posting_date DATE;

UPDATE postings
SET post_until = IF(post_until = '', '0000-00-00', DATE_FORMAT(STR_TO_DATE(post_until, '%d-%M-%y'), '%Y-%m-%d'));

ALTER TABLE postings
MODIFY COLUMN post_until DATE;

UPDATE postings
SET posting_update = DATE_FORMAT(STR_TO_DATE(posting_update, '%m/%d/%Y'), '%Y-%m-%d')
WHERE posting_update LIKE '%/%/%';

ALTER TABLE postings
MODIFY COLUMN posting_update DATE;

UPDATE postings
SET process_date = DATE_FORMAT(STR_TO_DATE(process_date, '%m/%d/%Y'), '%Y-%m-%d')
WHERE process_date LIKE '%/%/%';

ALTER TABLE postings
MODIFY COLUMN process_date DATE;


-- <<>> Updating data table <<>> --

ALTER TABLE postings
ADD COLUMN update_days INT, 
ADD COLUMN process_days INT;

UPDATE postings 
SET update_days =  timestampdiff(DAY, posting_date, posting_update);

UPDATE postings
SET process_days = timestampdiff(DAY, posting_date, process_date);


-- <<>> What's the annual salary average - Both Hourly and Daily salaries are converted to annual <<>> --

ALTER TABLE postings
ADD COLUMN salary_avg INT;

UPDATE postings
SET salary_avg = (salary_range_from + salary_range_to) / 2 ;

UPDATE postings
SET salary_avg = CASE
	WHEN salary_frequency = 'Annual' THEN salary_avg
	WHEN salary_frequency = 'Hourly' THEN salary_avg * 35 * 52
	ELSE salary_avg * 5 * 52
END;

SELECT * FROM postings;

-- <<>> Salary statistics <<>> --

SELECT COUNT(job_id) AS count_job_id, MIN(update_days) AS shortest_updated_days, 
	   MIN(salary_avg) AS lowest_salary, MIN(process_days) AS shortest_processed_days,
	   MAX(update_days) AS longest_updated_days, MAX(salary_avg) AS highest_salary,  
	   MAX(process_days) AS longest_processed_days
FROM postings
WHERE update_days > 0 AND process_days > 0;

SELECT
	SUM(number_of_position) AS total_jobs,
    MIN(salary_avg) AS lowest_salary, MIN(process_days) AS shortest_processed_days,
    AVG(salary_avg) AS mean_salary, AVG(process_days) AS mean_process_days,
    MAX(salary_avg) AS highest_salary, MAX(process_days) AS longest_processed_days
FROM postings
WHERE process_days > 0 ;


-- ** B. ANSWERING QUESTIONS ** --

-- > 1. What're the Salary Averages breakdown by title classification? < --
SELECT title_classification, COUNT(*) AS count_classification, AVG(salary_avg) AS avg_salary
FROM postings
WHERE salary_avg > 0
GROUP BY title_classification
ORDER BY avg_salary DESC;


-- >> 2. processed days average breakdown by title classification? << --
SELECT title_classification, COUNT(*) AS count_classification, AVG(process_days) AS avg_days
FROM postings
WHERE salary_avg > 0
GROUP BY title_classification
ORDER BY avg_days DESC;

-- >>> 3. What're the career level's salaries breakdown by statut indicator? <<< --
SELECT career_level, COUNT(*) AS count, AVG(salary_avg) AS avg_salary, statut_indicator
FROM postings
WHERE salary_avg > 0
GROUP BY career_level, statut_indicator
ORDER BY avg_salary DESC, count ASC;

-- >>>> 4. What're the career level's process time breakdown by statut indicator? <<<< --
SELECT career_level, COUNT(*) AS count, AVG(process_days) AS avg_days, statut_indicator
FROM postings
WHERE process_days > 0 
GROUP BY career_level, statut_indicator
ORDER BY avg_days DESC, count ASC;

-- >>>>> 5. What's the process time distribution in NYC's job postings? <<<<< --
SELECT 
	MIN(process_days) AS shortest_days,
    MAX(process_days) AS longest_days
FROM postings
WHERE process_days > 0;

SELECT
	CASE
	  WHEN process_days >= 2 AND process_days <= 124 THEN '2-124' 
	  WHEN process_days >= 125 AND process_days <= 249 THEN '125-249'
      WHEN process_days >= 250 AND process_days <= 374 THEN '250-374'
	  WHEN process_days >= 375 AND process_days <= 499 THEN '375-499'
	  WHEN process_days >= 500 AND process_days <= 624 THEN '500-624'
      WHEN process_days >= 625 AND process_days <= 749 THEN '625-749'
      WHEN process_days >= 750 AND process_days <= 874 THEN '750-874'
	  WHEN process_days >= 874 AND process_days <= 999 THEN '874-999'
	  ELSE '1000+'
	END AS process_groups, COUNT(*) AS count
FROM postings
WHERE process_days > 0 
GROUP BY process_groups
ORDER BY count DESC;

-- >>>>>> 6. What's the annual mass salary(total annual salary)? <<<<<< --
SELECT SUM(number_of_position) AS total_jobs, 
	   SUM(number_of_position * salary_avg) AS total_salary
FROM postings
WHERE number_of_position > 0 AND salary_avg > 0 ;


-- >>>>>>> 7. Top 10 highest paid city job by business title? <<<<<<< --
SELECT business_title, COUNT(*) AS count, 
AVG(salary_avg) AS avg_salary, AVG(process_days) AS num_of_days
FROM postings
WHERE salary_avg > 0 AND process_days >= 2
GROUP BY business_title, salary_avg
ORDER BY salary_avg DESC
LIMIT 10; 

-- >>>>>>>> 8. list of 10 highest annual paid business title? <<<<<<<< --
SELECT work_location, COUNT(*) AS count, AVG(salary_avg) AS salary_avg
FROM postings
WHERE salary_avg > 0 AND process_days >= 2
GROUP BY work_location
ORDER BY count DESC
LIMIT 10;

-- >>>>>>>>> 9. Position type distribution? <<<<<<<<< --
SELECT position_type, COUNT(*) AS count, SUM(salary_avg), SUM(process_days)
FROM postings
WHERE process_days >= 2 AND salary_avg != 0
GROUP BY position_type;

-- >>> 9. Position and statut indicator distribution? <<< --
SELECT position_type, statut_indicator, COUNT(*) AS count, SUM(salary_avg), SUM(process_days)
FROM postings
WHERE process_days >= 2 AND salary_avg != 0
GROUP BY position_type, statut_indicator
ORDER BY count DESC;

