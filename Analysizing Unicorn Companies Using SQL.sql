

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