-- Analysis of UEFA Competitions

create table goals(
	goal_id varchar(15),
	match_id varchar(15),
	pid varchar(20),
	duration int,
	assist varchar(20),
	goal_desc varchar(50)
);

create table matches(
	match_id varchar(20),
	season varchar(25),
	DATE varchar,
	home_team varchar(50),
	away_team varchar(50),
	stadium varchar(50),	
	home_team_score int,
	away_team_score int,
	penalty_shoot_out int,
	attendance int
);

create table players(
	player_id varchar(20),
	first_name varchar(50),
	last_name varchar(50),
	nationality varchar(50),
	dob date,
	team varchar(100),
	jersey_number float,
	position varchar(20),
	height float,
	weight float,	
	foot varchar(10)
);

create table teams(
	team_name varchar(50),
	country varchar(50),
	home_stadium varchar(50)
);

create table stadium(
	name varchar(50),
	city varchar(50),
	country varchar(50),
	capacity int
); 

copy goals from 'C:\Program Files\PostgreSQL\17\data\datacopy\goals.csv'
delimiter ','
csv header;

copy matches from 'C:\Program Files\PostgreSQL\17\data\datacopy\Matches.csv'
delimiter ','
csv header;

copy players from 'C:\Program Files\PostgreSQL\17\data\datacopy\players.csv'
delimiter ','
csv header;

copy teams from 'C:\Program Files\PostgreSQL\17\data\datacopy\teams.csv'
delimiter ','
csv header;

copy stadium from 'C:\Program Files\PostgreSQL\17\data\datacopy\stadiums.csv'
delimiter ','
csv header;

--1)Count the Total Number of Teams

select count(team_name) total_teams from teams;

--2)Find the Number of Teams per Country

select country,count(team_name) Number_of_teams
from teams
group by country
order by Number_of_teams desc;

--3)Calculate the Average Team Name Length

select round(avg(length(team_name))) avg_team_name_length
from teams;

--4)Calculate the Average Stadium Capacity in Each Country round it off and sort by the total stadiums in the country.

select country,round(avg(capacity),0) avg_stadium_capacity,count(distinct(name)) as total_stadiums
from stadium
group by country
order by avg_stadium_capacity desc;


--5)Calculate the Total Goals Scored.

select count(distinct goal_id) total_goals
from goals;
	
--6)Find the total teams that have city in their names

select distinct(team_name), count(distinct(team_name)) from teams where team_name like '%City%' group by team_name;

--7) Use Text Functions to Concatenate the Team's Name and Country
select concat(team_name,' - ',country) team_country 
from teams;

--8) What is the highest attendance recorded in the dataset, and which match (including home and away teams, and date) does it correspond to?
select home_team,away_team,date,attendance from matches
where attendance=(select max(attendance) from matches);

--Alternate
select home_team,away_team,date,max(attendance) maximum_attendance
from matches
group by home_team,away_team,date
order by  maximum_attendance desc
limit 1;

--9)What is the lowest attendance recorded in the dataset, and which match (including home and away teams, and date) does it correspond to set the criteria as greater than 1 as some matches had 0 attendance because of covid.
select home_team,away_team,date,attendance from matches
where attendance=(select min(attendance) from(select * from matches where attendance >1 order by attendance));

--10) Identify the match with the highest total score (sum of home and away team scores) in the dataset. Include the match ID, home and away teams, and the total score.

select match_id,home_team,away_team,home_team_score+away_team_score total_score
from matches
order by total_score desc 
limit 1;

--11)Find the total goals scored by each team, distinguishing between home and away goals. Use a CASE WHEN statement to differentiate home and away goals within the subquery

select a.team_name,sum(case when b.home_team=a.team_name then home_team_score else 0 end) as home_goals,
sum(case when b.away_team=a.team_name then away_team_score else 0 end) as away_goals 
from teams a
left join matches b on a.team_name=b.home_team or a.team_name=b.away_team
group by a.team_name;

select * from matches;
--12) windows function - Rank teams based on their total scored goals (home and away combined) using a window function.In the stadium Old Trafford.

select away_team as team_name,
rank() over(order by total_goals desc) as rank
from (select away_team,sum(home_team_score+away_team_score) as total_goals 
	from matches where stadium like 'Old Trafford'
	group by away_team);   

--13) TOP 5 l players who scored the most goals in Old Trafford, ensuring null values are not included in the result (especially pertinent for cases where a player might not have scored any goals).

select player_name, count(distinct(goal_id)) as total_goals from (select concat(a.first_name, ' ', a.last_name) as player_name ,b.* from players as a 
	right join (select goals.goal_id, goals.match_id, goals.pid, matches.stadium from goals left join matches on goals.match_id = matches.match_id) as b
	on a.player_id = b.pid where b.stadium like 'Old Trafford') group by player_name having count(distinct(goal_id)) is not null order by total_goals desc limit 5;

--14)Write a query to list all players along with the total number of goals they have scored. Order the results by the number of goals scored in descending order to easily identify the top 6 scorers.

select player_name,total_goals from(
	select p.player_id,concat(p.first_name,' ',p.last_name) as player_name,
	count(g.goal_id) as total_goals
	from players p 
	right join goals g on p.player_id=g.pid
	group by p.player_id,player_name having p.player_id is not null 
	order by total_goals desc
	limit 6
);

--15)Identify the Top Scorer for Each Team - Find the player from each team who has scored the most goals in all matches combined. This question requires joining the Players, Goals, and possibly the Matches tables, and then using a subquery to aggregate goals by players and teams.


select player_name,team,total_goals from
	(select player_name,team,total_goals,row_number() over(partition by team order by total_goals desc)as rank 
	from
	(select player_name,team,count((goal_id)) as total_goals 
	from
	(select p.player_id,concat(p.first_name,' ',p.last_name) as player_name,p.team,g.goal_id 
	from goals g
	left join players p on g.pid=p.player_id
	where p.team is not null) 
	group by player_name,team)) where rank=1;

--16)Find the Total Number of Goals Scored in the Latest Season - Calculate the total number of goals scored in the latest season available in the dataset. This question involves using a subquery to first identify the latest season from the Matches table, then summing the goals from the Goals table that occurred in matches from that season.
select count(g.goal_id) as total_number_of_goals 
from goals as g
inner join matches m on g.match_id=m.match_id
where m.season=(select max(season) from matches);

--17)Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance higher than the average attendance across all matches. This question requires a subquery to calculate the average attendance first, then use it to filter matches.
select * 
from matches
where attendance > (select avg(attendance) from matches);

--18)Find the Number of Matches Played Each Month - Count how many matches were played in each month across all seasons. This question requires extracting the month from the match dates and grouping the results by this value. as January Feb march

select to_char(date::date,'Month') as months,
count(distinct(match_id)) as number_of_matches
from matches 
group by months 
order by number_of_matches desc;


