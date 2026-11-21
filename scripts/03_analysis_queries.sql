-- Project 07: analysis queries used for the report (SQLite)
-- Q1 headline KPIs
SELECT COUNT(*) incidents, SUM(total_affected) aid_workers_affected, SUM(total_killed) killed, SUM(total_wounded) wounded,
       SUM(total_kidnapped) kidnapped, ROUND(100.0*SUM(total_nationals)/SUM(total_affected),1) pct_national_staff,
       COUNT(DISTINCT country) countries FROM fact_incidents;
-- Q2 trend by year
SELECT year, COUNT(*) incidents, SUM(total_affected) affected, SUM(total_killed) killed FROM fact_incidents GROUP BY year ORDER BY year;
-- Q3 top 10 countries
SELECT country, COUNT(*) incidents, SUM(total_affected) affected, SUM(total_killed) killed
FROM fact_incidents GROUP BY country ORDER BY affected DESC LIMIT 10;
-- Q4 world regions
SELECT d.world_region, COUNT(*) incidents, SUM(f.total_affected) affected
FROM fact_incidents f JOIN dim_country d USING(country) GROUP BY 1 ORDER BY 3 DESC;
-- Q5 attack category & means
SELECT attack_category, COUNT(*) incidents, SUM(total_affected) affected, SUM(total_killed) killed,
       ROUND(1.0*SUM(total_killed)/SUM(total_affected),2) lethality FROM fact_incidents GROUP BY 1 ORDER BY 3 DESC;
-- Q6 organisation type
SELECT SUM(un) un, SUM(ingo) ingo, SUM(nngo) national_ngo, SUM(nrcs_and_ifrc) ns_ifrc, SUM(icrc) icrc, SUM(other) other FROM fact_incidents;
-- Q7 context and location
SELECT attack_context, COUNT(*) incidents, SUM(total_affected) affected FROM fact_incidents GROUP BY 1 ORDER BY 3 DESC;
SELECT location_type, COUNT(*) incidents, SUM(total_affected) affected FROM fact_incidents GROUP BY 1 ORDER BY 3 DESC;
-- Q8 actors (known only)
SELECT actor_group, COUNT(*) incidents, SUM(total_affected) affected FROM fact_incidents GROUP BY 1 ORDER BY 3 DESC;
-- Q9 Syria deep-dive
SELECT year, COUNT(*) incidents, SUM(total_affected) affected, SUM(total_killed) killed FROM fact_incidents WHERE country='Syria' GROUP BY year ORDER BY year;
SELECT admin1, SUM(total_affected) affected FROM fact_incidents WHERE country='Syria' GROUP BY 1 ORDER BY 2 DESC LIMIT 6;
SELECT means_of_attack, SUM(total_affected) affected FROM fact_incidents WHERE country='Syria' GROUP BY 1 ORDER BY 2 DESC LIMIT 5;
-- Q10 gender, nationals vs internationals by outcome
SELECT SUM(gender_male), SUM(gender_female), SUM(gender_unknown) FROM fact_incidents;
SELECT SUM(nationals_killed), SUM(internationals_killed), SUM(nationals_kidnapped), SUM(internationals_kidnapped) FROM fact_incidents;
-- Q11 decades
SELECT CASE WHEN year<2005 THEN '1997-2004' WHEN year<2013 THEN '2005-2012' WHEN year<2019 THEN '2013-2018' ELSE '2019-2024' END period,
       COUNT(*), SUM(total_affected), SUM(total_killed) FROM fact_incidents GROUP BY 1;
-- Q12 2023 vs 2024 top countries
SELECT country, SUM(CASE WHEN year=2023 THEN total_affected END) a2023, SUM(CASE WHEN year=2024 THEN total_affected END) a2024
FROM fact_incidents WHERE year>=2023 GROUP BY 1 ORDER BY 2 DESC LIMIT 8;
-- Q13 motive known
SELECT motive, COUNT(*) FROM fact_incidents GROUP BY 1 ORDER BY 2 DESC;
SELECT date_precision, COUNT(*) FROM fact_incidents GROUP BY 1;
SELECT MAX(incident_date) FROM fact_incidents;
