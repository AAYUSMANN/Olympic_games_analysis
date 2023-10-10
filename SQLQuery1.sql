select * from [dbo].[athlete_events]
select * from [dbo].[noc_regions]

---Rename the "Year" column to "Years"
EXEC sp_rename '[dbo].[athlete_events].[Year]', 'Years', 'COLUMN'

 ----Updating 'SIN' to 'SGP' in noc_regions table as 'Singapore' NOC is 'SGP' in athlete_event table.
update noc_regions
set NOC = 'SGP'
where NOC = 'SIN'

select * from [dbo].[athlete_events]

----q1. ----How many olympics games have been held?

select count(distinct(Games)) as Totalgames from [dbo].[athlete_events] 

---q2. ----List down all Olympics games held so far.
select distinct Games from [dbo].[athlete_events] 
group by Games


---q3.----Mention the total no of nations who participated in each olympics game?

select ae.Games, count(nr.region) as No_of_participated_nations
from athlete_events ae
join noc_regions nr
on ae.NOC = nr.NOC
group by ae.Games

 


---q4 ---Which year saw the highest and lowest no of countries participating in olympics?

WITH CTE AS (
    SELECT ae.Year, COUNT(nr.region) AS no_of_nations
    FROM athlete_events ae
    JOIN noc_regions nr ON ae.NOC = nr.NOC
    GROUP BY ae.Year
)
SELECT Year, no_of_nations
FROM CTE
WHERE no_of_nations = (SELECT MAX(no_of_nations) FROM CTE)
   OR no_of_nations = (SELECT MIN(no_of_nations) FROM CTE);


--5 ----Which nation has participated in all of the olympic games?
WITH GamesCount AS (
    SELECT nr.region, COUNT(DISTINCT ae.Games) AS total_no_of_games
    FROM noc_regions nr
    JOIN athlete_events ae 
	ON nr.NOC = ae.NOC
    GROUP BY nr.region
)
SELECT region, total_no_of_games
FROM GamesCount
WHERE total_no_of_games = (SELECT MAX(total_no_of_games) FROM GamesCount)





--6----Identify the sport which was played in all summer olympics.

select distinct Season, Sport
from athlete_events
where Season = 'Summer'



----7--Which Sports were just played only once in the olympics.
select Sport,count(Sport)
from athlete_events
group by Sport
having count(*) = 1





--8--Fetch the total no of sports played in each olympic games.
select Games, count(distinct Sport) as no_of_sports_played
from athlete_events
group by Games


---9---Fetch oldest athletes to win a gold medal
SELECT *
FROM athlete_events
WHERE Medal = 'Gold' AND  Age = (
    SELECT MAX(Age)
    FROM athlete_events
    WHERE Medal = 'Gold'
  )

  ---10--Find the Ratio of male and female athletes participated in all olympic games.
  SELECT 
    (SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) * 1.0) / 
    NULLIF(SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END), 0) AS male_to_female_ratio
FROM 
   athlete_events



   --11--Fetch the top 5 athletes who have won the most gold medals.

   WITH RankedAthletes AS (
    SELECT
        Name,
        COUNT(Medal) AS No_of_Gold,
        DENSE_RANK() OVER (ORDER BY COUNT(Medal) DESC) AS GoldRank
    FROM athlete_events
    WHERE Medal = 'Gold'
    GROUP BY Name
)
SELECT Name, No_of_Gold
FROM RankedAthletes
WHERE GoldRank <= 5
ORDER BY GoldRank

---12Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

   WITH RankedAthletes AS (
    SELECT
        Name,
        COUNT(Medal) AS No_of_Medals,
        DENSE_RANK() OVER (ORDER BY COUNT(Medal) DESC) AS MedalRank
    FROM athlete_events
    WHERE Medal != 'NA'
    GROUP BY Name
)
SELECT Name, No_of_Medals
FROM RankedAthletes
WHERE MedalRank <= 5
ORDER BY MedalRank


--13--Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
 WITH RankedAthletes AS (
    SELECT
        nr.region,
        COUNT(ae.Medal) AS No_of_Medals,
        DENSE_RANK() OVER (ORDER BY COUNT(ae.Medal) DESC) AS MedalRank
    FROM noc_regions nr
	join athlete_events ae
	on nr.NOC = ae.NOC
    WHERE ae.Medal != 'NA'
    GROUP BY nr.region
)
SELECT region, No_of_Medals
FROM RankedAthletes
WHERE MedalRank <= 5
ORDER BY MedalRank

---14--List down total gold, silver and bronze medals won by each country.

select n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze
from
(
select NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_events
group by NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 2 DESC, 3 DESC, 4 DESC

---15-- List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

select TOP 1 n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze
from
(
select NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_events
group by NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 2 DESC, 3 DESC, 4 DESC

--Q.16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
select TOP 1 n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze
from
(
select NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_events
group by NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 2 DESC, 3 DESC, 4 DESC

--17---Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

WITH MedalCounts AS (
    SELECT
        ae.Games,
        nr.region,
        ae.NOC,
        SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
        SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
        SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
    FROM athlete_events AS ae
    JOIN noc_regions AS nr ON ae.NOC = nr.NOC
    GROUP BY ae.Games, nr.region, ae.NOC
)
SELECT TOP 1 WITH TIES Games, region, No_of_Gold, No_of_Silver, No_of_Bronze, (No_of_Gold+No_of_Silver+No_of_Bronze) as Total_Medals
FROM MedalCounts
ORDER BY No_of_Gold DESC, No_of_Silver DESC, No_of_Bronze DESC, Total_Medals DESC;

---18--Which countries have never won gold medal but have won silver/bronze medals?

select nr.region,
SUM(CASE WHEN ae.Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN ae.Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN ae.Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from noc_regions nr
join athlete_events ae
on nr.NOC = ae.NOC
group by nr.region
having SUM(CASE WHEN ae.Medal = 'Gold' THEN 1 ELSE 0 END) = 0  
AND (SUM(CASE WHEN ae.Medal = 'Silver' THEN 1 ELSE 0 END) + SUM(CASE WHEN ae.Medal = 'Bronze' THEN 1 ELSE 0 END)) > 0


---19-- In which Sport/event, INDIA has won highest medals.

select TOP 1 nr.region as Country, ae.Sport, ae.Event, count(ae.Medal) as Highest_Medals
from noc_regions nr
join athlete_events ae
on nr.NOC = ae.NOC
where nr.region = 'India' and ae.Medal != 'NA'
group by nr.region, ae.Sport, ae.Event
order by Highest_Medals DESC


---20-- Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.

select nr.region as Country, ae.Games, ae.Sport, ae.Event, count(ae.Medal) as Highest_Medals
from noc_regions nr
join athlete_events ae
on nr.NOC = ae.NOC
where nr.region = 'India' and ae.Medal != 'NA'
group by nr.region, ae.Games, ae.Sport, ae.Event
order by Highest_Medals DESC