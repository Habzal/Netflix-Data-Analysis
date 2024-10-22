select * from netflix_raw 

--Handling foriegn characters
--This was done by changing datatype of title column from varchar to nvarchar

--Remove duplicates
Select show_id, count(*)
from netflix_raw
group by show_id
having count(*) > 1

Select * from netflix_raw
where concat(upper(title),type) in (
Select concat(upper(title),type)
from netflix_raw
group by upper(title), type
having count(*) > 1)
order by title

WITH CTE as 
(Select *, row_number() over(partition by title, type order by show_id) as rn from netflix_raw)

Select show_id, type, title, cast(date_added as date) as date_added, release_year, rating, case when duration is null then rating else duration end as duration, description into netflix from CTE 
where rn = 1

--Since the columns 'listed_in', 'director', 'cast', and 'country' have more than one value for each row, lets create new tables for each column and seperate the values by a comma
-->
Select show_id, trim(value) as director
into netflix_directors
from netflix_raw 
cross apply string_split(director, ',')

select * from netflix_directors

-->
Select show_id, trim(value) as country
into netflix_country
from netflix_raw 
cross apply string_split(country, ',')

select * from netflix_country

-->
Select show_id, trim(value) as cast
into netflix_cast
from netflix_raw 
cross apply string_split(cast, ',')

select * from netflix_cast

-->
Select show_id, trim(value) as genre
into netflix_genre
from netflix_raw 
cross apply string_split(listed_in, ',')

select * from netflix_genre

--Populate missing values in country 
Select show_id, country 
from netflix_raw 
where country is null

--One way to handle missing country values is to look for the director name and see if that director has directed another movie, if so then lets assume the country can be used to populate our null values
Select director, country 
from netflix_country nc
inner join netflix_directors nd on nc.show_id = nd.show_id
group by director, country

-->
Insert Into Netflix_Country
select show_id, m.country
from netflix_raw nr
inner join (
Select director, country 
from netflix_country nc
inner join netflix_directors nd on nc.show_id = nd.show_id
group by director, country
) m on nr.director = m.director
where nr.country is null


--Populate missing values in Duration
Select * from netflix_raw where duration is null
--update our main netflix table to handle when duration is null, take the rating values as the two columns were miscalculated

--OUR FINAL CLEAN TABLE
Select * from Netflix


--------------------------------------------------------------------------------------------------------------------------------------------
--NETFLIX DATA ANALYSIS

/* 1. For each director, count the number of movies and tv shows created by them in seperate columns. */
Select nd.director,
COUNT(DISTINCT Case when n.type = 'Movie' then n.show_id end) as num_of_movies,
COUNT(DISTINCT Case when n.type = 'TV Show' then n.show_id end) as num_of_tv_shows
from netflix n
inner join netflix_directors nd on n.show_id = nd.show_id
group by nd.director
having count(distinct n.type) > 1


/* 2. Which countries have highest number of comedy movies */
Select TOP 1 nc.country, count(ng.show_id) as num_of_movies
from netflix_genre ng 
inner join netflix_country nc on nc.show_id = ng.show_id
inner join netflix n on ng.show_id = n.show_id
where ng.genre = 'Comedies' and n.type = 'Movie'
group by nc.country
order by num_of_movies desc

/* 3. Which director has maximum number of movies released for each year (based on date_added) */
WITH CTE as (
Select  nd.director, year(date_added) as date_year, COUNT(n.show_id) as num_of_movies
from netflix n 
inner join netflix_directors nd on n.show_id = nd.show_id
where type = 'Movie'
group by nd.director, year(date_added)
),

CTE2 as (
Select *, row_number() Over (Partition by date_year order by num_of_movies desc, director) as rn
from CTE
--order by date_year, num_of_movies desc
)

Select * 
from CTE2 
where rn = 1 


/* 4. What is the average duration of movies in each genre */
Select  ng.genre,  AVG(cast(replace(duration, ' min', '') as int)) as avg_duration
from netflix n
inner join netflix_genre ng on n.show_id = ng.show_id
where type = 'Movie'
Group by ng.genre


/* 5. List of directors who have created both horror and comedy movies 
	  Display director name along with number of comedy and horror movies directed by them */
Select nd.director,
Count(Distinct Case when ng.genre = 'Comedies' then n.show_id end) as num_of_comedy,
Count(Distinct Case when ng.genre = 'Horror Movies' then n.show_id end) as num_of_horror_movies
from netflix n
inner join netflix_genre ng on n.show_id = ng.show_id
inner join netflix_directors nd on n.show_id = nd.show_id
where type = 'Movie' and ng.genre in ('Comedies', 'Horror Movies')
group by nd.director 
having count(distinct genre) > 1