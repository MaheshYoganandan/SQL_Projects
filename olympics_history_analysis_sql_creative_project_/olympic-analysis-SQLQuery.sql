

--1 which team has won the maximum gold medals over the years.

SELECT TOP 1 team, COUNT(team) no_of_gold_medals
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE medal = 'Gold'
GROUP BY a.country
ORDER BY no_of_gold_medals DESC

--2 for each country print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

WITH country_year_medals AS(
SELECT team, year, COUNT(*) no_of_silver_medals,
	ROW_NUMBER() OVER(PARTITION BY team  ORDER BY COUNT(*) DESC) rn
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE medal = 'Silver'
GROUP BY team, year
)
SELECT team, year, no_of_silver_medals
FROM country_year_medals
WHERE rn = 1
ORDER BY no_of_silver_medals DESC


--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years


SELECT  TOP 1 name, team, COUNT(*) no_of_gold_medals
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE medal = 'Gold' AND name NOT IN (SELECT name FROM athletes a JOIN athlete_events e ON e.athlete_id = a.id WHERE medal = 'Silver' or medal ='Bronze')
GROUP BY name, team
ORDER BY no_of_gold_medals DESC

--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.

WITH year_wise_gold_medal AS(
SELECT *,
	RANK() OVER(PARTITION BY year ORDER BY no_of_gold_medals DESC) rnk
FROM 
	(SELECT year, name, COUNT(*) no_of_gold_medals 
	FROM athletes a
	JOIN athlete_events e ON e.athlete_id = a.id
	WHERE medal='Gold'
	GROUP BY year, name) gold_medal_table
)
SELECT year, STRING_AGG(name, ', ')  players ,no_of_gold_medals
FROM year_wise_gold_medal
WHERE rnk = 1
GROUP BY year, no_of_gold_medals
ORDER BY year

--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

SELECT medal, year, event
FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY medal ORDER BY year) rn
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
where team = 'India' and medal <> 'NA' ) india_medal_table
WHERE rn = 1
ORDER BY year

--6 find players who won gold medal in summer and winter olympics both.

SELECT  name
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE medal = 'Gold'
GROUP BY name 
HAVING COUNT(DISTINCT season) = 2

--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

SELECT  year, name
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE medal <> 'NA'
GROUP BY year, name 
HAVING COUNT(DISTINCT medal) = 3
ORDER BY year


--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

WITH medal_year AS(
SELECT name,year,event
FROM athlete_events ae
JOIN athletes a ON ae.athlete_id=a.id
WHERE year >=2000 AND season='Summer'AND medal = 'Gold'
)
SELECT name, event, year_1 ,year year_2, year_3
FROM
(SELECT *, LAG(year,1) OVER(PARTITION BY name, event ORDER BY year ) AS year_1,
 LEAD(year,1) OVER(PARTITION BY name,event ORDER BY year ) AS year_3
FROM medal_year) A
WHERE year=year_1 + 4 and year= year_3 - 4
ORDER BY year_1


select column_name as athelets_column
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'athletes'

select column_name as athelets_events_column
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'athlete_events'

-- 9 What is the distribution of athletes by sex?
SELECT 
	COUNT(*) AS total_players,
	SUM(CASE SEX WHEN 'M' THEN 1 ELSE 0 END) AS male_players,
	SUM(CASE SEX WHEN 'F' THEN 1 ELSE 0 END) AS female_players
FROM athletes

-- 10 How many athletes are from the team "India" IN YEAR 2000 - 2016?

SELECT year, COUNT(*) no_of_players
FROM athletes a
JOIN athlete_events e on e.athlete_id = a.id
WHERE team = 'India' AND year >= 2000 AND season = 'Summer'
GROUP BY year
ORDER BY YEAR

-- 11 Which city has hosted the most number of games?

SELECT TOP 5 city, COUNT(distinct year) no_of_times_host
FROM athlete_events
WHERE season = 'Summer'
GROUP BY city
ORDER BY no_of_times_host DESC



-- 12 Which athlete has participated in the most number of events?
-- (Most of the players are gymnast )

SELECT TOP 10 name, year, COUNT(DISTINCT event) no_of_events
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE year > 2000
GROUP BY name, year
ORDER BY no_of_events DESC

-- 13 How many athletes have won medals in all events they participated in?


SELECT name, year, season,
	COUNT(DISTINCT event) no_of_events, 
	SUM(CASE WHEN medal <> 'NA' THEN 1 ELSE 0 END) no_of_medal
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
WHERE year >= 2000 
GROUP BY name, year, season
HAVING SUM(CASE WHEN medal <> 'NA' THEN 1 ELSE 0 END) >= 5
ORDER BY no_of_medal DESC

-- 14 Which athlete has the highest medal-to-event ratio?

WITH medal_event as (
SELECT name, year, season,
	COUNT(DISTINCT event) no_of_events, 
	SUM(CASE WHEN medal <> 'NA' THEN 1 ELSE 0 END) no_of_medal
FROM athletes a
JOIN athlete_events e ON e.athlete_id = a.id
GROUP BY name, year, season
)
SELECT *, CONVERT(DECIMAL(10, 2), (1.0 * no_of_medal / no_of_events)) AS medal_ratio
FROM medal_event
WHERE no_of_medal >=1
ORDER BY no_of_medal DESC


-- 15 Total No of playeres in top 10 event
SELECT TOP 10 event, COUNT(*) avg_no_of_players
FROM athlete_events
GROUP BY event
ORDER BY avg_no_of_players DESC









