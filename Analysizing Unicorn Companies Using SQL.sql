

create database Unicorn;
Use Unicorn;
---  Import data files in Databases 
--- Import all csv files as tables in database from select file flat

--- 1 . Finding best 3 performing industries based on the number of new unicorns created over three years 
---     2019,2020,2021 combined

SELECT TOP 3
i.industry, COUNT(*)AS count_new_unicorns
from industries i
JOIN dates d ON i.company_id = d.company_id
WHERE YEAR(d.date_joined) IN ('2019','2020','2021')
GROUP BY i.industry
ORDER BY count_new_unicorns DESC

--- 2.  Calculate the number of unicorns and average valuation, grouped year and industry

select i.industry, year(d.date_joined) AS year,
count(*) AS num_unicorns,
AVG(f.valuation) AS average_valuation
from industries i
JOIN dates d ON i.company_id = d.company_id
JOIN funding f ON d.company_id = f.company_id
GROUP BY i.industry, year(d.date_joined)


--- 3. Create 2 CTEs for tables above and run

WITH top_industries AS (
  SELECT TOP 3
     i.industry,
     COUNT(*) as count_new_unicorns
  from industries as i
  JOIN dates AS d ON i.company_id = d.company_id 
  WHERE year(d.date_joined) IN ( '2019','2020','2021')
  GROUP BY i.industry
  ORDER BY count_new_unicorns DESC
),
yearly_ranks AS
(
   SELECT 
      i.industry,
      COUNT (*) AS num_unicorns,
      year(d.date_joined) as year,
      avg(f.valuation) as average_valuation
   from industries as i
   JOIN dates as d
   ON i.company_id = d.company_id
   JOIN funding as f
   ON d.company_id = f.company_id
   group by i.industry, year(d.date_joined)
)

select yr.industry,yr.year, yr.num_unicorns,
ROUND(AVG(yr.average_valuation / 1000000000), 2) as average_valuation_billions
from yearly_ranks as yr
where yr.year in ('2019','2020','2021')
and yr.industry in (SELECT ti.industry from top_industries as ti)
group by yr.industry, yr.num_unicorns, yr.year, yr.average_valuation
order by yr.industry, yr.year DESC


--- 4. understanding which industries are producing the highest valuations.

select i.industry,
sum(f.valuation) as total_valuation
from industries as i
join funding as f on i.company_id = f.company_id
group by
i.industry
order by
total_valuation desc
offset 0 rows fetch next 5 Rows only;

--- 5. analyze the rate at which new high-value companies are emerging over the years.
--- means how many companies are joined to high value comapnies list in every year

select 
year(d.date_joined) as year,
count(d.company_id) as number_of_companies
from 
dates as d
group by 
year(d.date_joined)
order by
year;

--- 6.  which cities have the highest number of unicorn companies.

select 
c.city ,
count(c.company_id) as number_of_companies
from 
companies as c
group by
c.city
order by
number_of_companies desc;

--- 7. average valuation of unicorn companies based on their continent.

select 
c.continent,
AVG(f.valuation) as average_valuation
from 
companies as c
join funding as f
on c.company_id =f.company_id
group by
c.continent
order by
average_valuation desc ;

--- 8. which investors are most active in funding unicorn companies.

select 
f.select_investors,
count(f.company_id) as number_of_investments
from 
funding as f
group by
 select_investors
order by
number_of_investments desc

--- 9. distribution of unicorn companies by the year they were founded.

select 
d.year_founded,
count(d.company_id) as number_of_companies
from dates as d
group by
year_founded
order by
year_founded;

--- 10.  cities with the highest average company valuation.

select 
c.city,
avg(f.valuation) as average_valuation
from 
companies as c
join
funding as f on c.company_id = f.company_id
group by
 c.city
order by
average_valuation desc

--- 11. top 5 countries with the highest average valuation and the number of unicorn companies in each country.

with CountryValuation as (
select 
c.country,
avg(f.valuation) as average_valuation,
count(c.company_id) as number_of_companies
from 
companies as c
join 
funding as f on c.company_id = f.company_id
group by 
c.country
)

select 
country,
average_valuation,
number_of_companies
from 
CountryValuation
order by
average_valuation desc

--- 12. cities that have had the highest growth in the number of unicorn companies over the past 5 years.

with CurrentYearCompanies as(
    select 
       c.city,
       count(d.company_id) as current_year_count
    from 
       companies as c
    join
       dates as d on c.company_id = d.company_id
    where
       year(d.date_joined) = year(GETDATE())
    group by
       city
),

PastYearCompanies as(
    select 
       c.city,
       count(d.company_id) as past_year_count
    from 
       companies as c
    join
       dates as d on c.company_id = d.company_id
    where
       year(d.date_joined) = year(GETDATE()) - 5
    group by
       city
)

select 
    c.city,
    c.current_year_count,
    p.past_year_count,
    ((c.current_year_count-p.past_year_count)*100.0/p.past_year_count) as growth_percentage
from 
    CurrentYearCompanies as c
join 
    PastYearCompanies as p on c.city = p.city
order by
    growth_percentage desc ;



--- 13. identifying the industries with the highest valuation growth rate over the last 5 years.

WITH CurrentYearValuation AS (
    SELECT 
         i.industry,
	     SUM(f.valuation) AS current_year_valuation
    FROM 
         industries AS i
    JOIN
         funding AS f ON i.company_id = f.company_id
    JOIN 
         dates AS d ON i.company_id = d.company_id
    WHERE
         YEAR(d.date_joined) = YEAR(GETDATE())
    GROUP BY
         i.industry
), PastYearValuation AS(
   SELECT 
       i.industry,
       SUM(f.valuation) AS past_year_valuation
   FROM
       industries AS i
   JOIN
       funding AS f ON i.company_id = f.company_id
   JOIN
       dates AS d ON i.company_id = d.company_id
   WHERE 
       YEAR(date_joined) = YEAR(GETDATE()) -5
   GROUP BY
       i.industry
)
SELECT
    c.industry,
	c.current_year_valuation,
	p.past_year_valuation
	
FROM
    CurrentYearValuation AS c
JOIN
    PastYearValuation AS p ON c.industry = p.industry
ORDER BY
    past_year_valuation DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

--- 14.  average time taken for a company to become a unicorn based on the continent.

WITH TimeToUnicorn AS(
    SELECT
	      c.continent,
		  DATEDIFF(YEAR, d.year_founded, YEAR(d.date_joined)) AS years_to_unicorn
	FROM 
	    companies AS c
	JOIN
	    dates AS d ON c.company_id = d.company_id
)

SELECT
    continent,
	AVG(years_to_unicorn) AS average_years_to_unicorn
FROM
    TimeToUnicorn
GROUP BY
    continent
ORDER BY
    average_years_to_unicorn;

