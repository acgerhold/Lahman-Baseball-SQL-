/* What range of years for baseball games played does this database cover? */
-- Between years 1871 and 2016

SELECT MIN(yearid), MAX(yearid)
FROM appearances

/* Find the name and height of the shortest player in the database. How many games did he play in? What is the
	name of the team for which he played? */
-- Eddie Gaedel, aka Edward Carl, played 1 game for the St. Louis Browns at 43 inches tall. 
-- Larry Corcoran, aka Lawrence J., is the second shorted player in the database, at 63 inches. He played 298
--		games for the Chicago White Stockings.

SELECT CONCAT(namefirst, ' ', namelast) AS name,
	namegiven AS nickname,
	height AS height_in_inches,
	SUM(a.g_all) AS games_played,
	t.name as team_name
FROM people AS p
LEFT JOIN appearances AS a
ON p.playerid = a.playerid
LEFT JOIN teams AS t
ON a.teamid = t.teamid AND a.yearid = t.yearid
GROUP BY p.playerid, namegiven, CONCAT(namefirst, ' ', namelast), height, team_name
ORDER BY height_in_inches 
LIMIT 2;
-- I alias the table people as p, appearances as a, and teams as t to quickly refer to the columns in those tables

/* Find all players in the database who played at Vanderbilt University. Create a list showing 
	each player’s first and last names as well as the total salary they earned in the major leagues. 
	Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most 
	money in the majors? */
-- David Price is the highest paid Vanderbilt player in the major leagues. There are 15 total players who
-- 		played for Vanderbilt who went on to earn money in the major leagues.

SELECT DISTINCT(c.playerid),
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	sc.schoolname,
	SUM(DISTINCT(s.salary)) AS total_pro_salary
FROM collegeplaying AS c
LEFT JOIN schools AS sc
on sc.schoolid = c.schoolid
LEFT JOIN people AS p
ON c.playerid = p.playerid
LEFT JOIN salaries AS s
ON c.playerid = s.playerid
WHERE c.schoolid = 'vandy' AND s.salary IS NOT null
GROUP BY c.playerid, p.namefirst, p.namelast, sc.schoolname
ORDER BY total_pro_salary DESC

/* Using the fielding table, group players into three groups based on their position: label players with 
	position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with 
	position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups 
	in 2016. */
-- 1. Infield - 58,934po, 2. Battery - 41,424po, 3. Outfield - 29,560.
SELECT CASE
	WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('P', 'C') THEN 'Battery'
	ELSE 'Infield' END AS position,
	SUM(po) AS putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position
ORDER BY putouts DESC

/* Find the average number of strikeouts per game by decade since 1920. Round the numbers you report 
	to 2 decimal places. Do the same for home runs per game. Do you see any trends? */
-- Average strike-outs per decade increases by each decade, and dropping in the 2010's (dataset ends in '16')
-- Homeruns also follow the same trend, increasing by each decade
SELECT CASE
		WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
		WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
		WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
		WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
		WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
		WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
		WHEN yearid BETWEEN 1980 AND 1989 THEN '1980s'
		WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
		WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
		ELSE '2010s' END AS decade,
	round(SUM(so)::decimal/(SUM(g)/2), 2) AS avg_so_per_g,
	round(SUM(hr)::decimal/(SUM(g)/2), 2) AS hr_per_g
FROM teams
GROUP BY decade
ORDER BY decade 

/* Find the player who had the most success stealing bases in 2016, where success is measured as the 
	percentage of stolen base attempts which are successful. (A stolen base attempt results either in a 
	stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. */
-- Chris Owings had the highest stolen base percentage in 2016 at 91%
SELECT CONCAT(p.namefirst , ' ' , p.namelast) AS full_name,
		round(SUM(sb)::decimal/(SUM(sb)+SUM(cs)),2) AS steal_percentage -- % succesful steals out of total
FROM batting AS b 
INNER JOIN people AS p
ON b.playerid=p.playerid
WHERE yearid=2016
GROUP BY CONCAT(p.namefirst , ' ' , p.namelast)
HAVING SUM(sb)+SUM(cs)>=20 -- Must have at least 20 steal attempts
ORDER BY steal_percentage DESC
LIMIT 1;

/* From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? Doing this will probably 
result in an unusually small number of wins for a world series champion – determine why this is the case. 
Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a 
team with the most wins also won the world series? What percentage of the time? */ 

SELECT yearid, MAX(w), wswin, name 
FROM teams
WHERE wswin = 'N'
AND yearid BETWEEN 1970 AND 2016
GROUP BY yearid, name, wswin
ORDER BY MAX(w) DESC
-- The Seattle Mariners had the highest number of wins (116) in 2001 for a team that DID NOT win the WS

SELECT yearid, MIN(w), wswin, name 
FROM teams
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
GROUP BY yearid, name, wswin
ORDER BY MIN(w)
-- The LA Dodgers had the lowest number of wins (63) in 1981 for a team that DID win the WS
-- This is due to the 1981 MLB strike where 713 games during the regular season were cancelled

with winning_teams AS (SELECT yearid, MAX(w) AS max_w  -- Create CTE of each team with the max wins each yr
					FROM teams
					WHERE yearid BETWEEN 1970 AND 2016
					AND yearid <> 1981 -- Strike year
					GROUP BY yearid
				  	ORDER BY yearid)
SELECT SUM(CASE WHEN t.wswin = 'Y' THEN 1 ELSE 0 END) AS count_max_is_champ, -- Count of max win champs
		AVG(CASE WHEN t.wswin = 'Y' THEN 1 ELSE 0 END) AS percent_max_is_champ -- % max win team is champ
FROM winning_teams AS wt
INNER JOIN teams AS t 
ON wt.yearid = t.yearid and wt.max_w = t.w
-- 12 times has the team with the most wins has been the WS champ between 1970 and 2016. 23% of the time.
-- Have to use CTE for the max win teams because including it in the CTE shows max win team and the WS winner
-- Inner join teams again to be able to calculate

/* Using the attendance figures from the homegames table, find the teams and parks which had the top 5 
average attendance per game in 2016 (where average attendance is defined as total attendance divided 
by number of games). Only consider parks where there were at least 10 games played. Report the park name, 
team name, and average attendance. Repeat for the lowest 5 average attendance. */
-- Top 5 lowest attendance on average is as follows: 1. Tropicana Field (Rays) - 15,878, 2. Oakland-Alameda
-- 		County Coliseum (Athletics) - 18,874, 3. Progressive Field (Indians) - 19,650, 4. Marlins Park 
-- 		(Marlins) - 21,405, 5. U.S. Cellular Field (White Sox) - 21,559

SELECT DISTINCT p.park_name, name AS team_name, SUM(h.attendance)/SUM(h.games) AS Avg_attendance 
FROM homegames AS h 
INNER JOIN parks AS p USING (park)
INNER JOIN teams AS t ON t.teamid = h.team AND h.year = t.yearid			
WHERE year = '2016' AND h.games >= 10
GROUP BY p.park_name, name
ORDER BY Avg_attendance
LIMIT 5;

/* Which managers have won the TSN Manager of the Year award in both the National League (NL) and 
the American League (AL)? Give their full name and the teams that they were managing when they won 
the award. */
-- Davey Johnson won the award in AL in 1997 with the Orioles, and in NL in 2012 with the Nationals
-- Jim Leyland won the award in AL in 2006 with the Tigers, and 3 time with the Pirates in NL in years
--		1988, 1990, 1992.
WITH NL_award AS (SELECT a.playerid, CONCAT(p.namefirst, ' ', p.namelast) AS mname, 
				  		a.yearid, a.awardid, t.name AS Team, a.lgid
					FROM  AwardsManagers AS a 
				  	INNER JOIN people AS p USING (playerid)
					INNER JOIN managers AS m USING (playerid)
					INNER JOIN teams AS t ON t.teamid = m.teamid AND t.lgid = m.lgid 
				  		AND t.yearid = m.yearid AND t.lgid = a.lgid AND t.yearid = a.yearid
				    WHERE awardid = 'TSN Manager of the Year' AND a.lgid = 'NL') -- CTE with all NL winners
SELECT DISTINCT mname, a.awardid, a.lgid, a.yearid, t.name, NL.lgid, NL.yearid, NL.team
FROM NL_award AS NL
INNER JOIN AwardsManagers AS a USING (playerid)
INNER JOIN people AS p USING (playerid)
INNER JOIN managers AS m USING (playerid)
INNER JOIN teams AS t
	ON t.teamid = m.teamid AND t.lgid = m.lgid AND t.yearid = m.yearid 
		AND t.lgid = a.lgid AND t.yearid = a.yearid
WHERE a.lgid = 'AL' AND a.awardid = 'TSN Manager of the Year' -- Join with the AL winners

/* Find all players who hit their career highest number of home runs in 2016. Consider only players who 
have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the 
players' first and last names and the number of home runs they hit in 2016. */
-- 80 players had their most home runs in 2016. Nelson Cruz had the highest record homeruns in 2016 at 43

SELECT CONCAT(p.namefirst, ' ', p.namelast), b.hr, round(sum((finalgame::date - debut::date)::dec/365),1) as yrs_played, yearid
FROM batting AS b 
INNER JOIN people AS p USING (playerid)
WHERE yearid = '2016' AND hr > 1
GROUP BY b.hr, namefirst, namelast, yearid
HAVING round (SUM((finalgame::date - debut::date)::DEC/365),1) > 10
ORDER BY hr DESC;






























