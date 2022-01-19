SELECT * 
FROM covid_deaths
order by location, date;

-- SELECT * 
-- FROM covid_vaccinations
-- order by location, date;

--- Changing the column date from text to date type
ALTER TABLE covid_deaths ALTER COLUMN date TYPE DATE 
using to_date(date, 'DD-MM-YYYY');

ALTER TABLE covid_vaccinations ALTER COLUMN date TYPE DATE 
using to_date(date, 'DD-MM-YYYY');

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population 
FROM covid_deaths
order by location, date;

--- Total Cases vs Total Deaths: likehood of dying
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases) * 100) AS rate_death
FROM covid_deaths
order by location, date;

SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases) * 100) AS rate_death
FROM covid_deaths
WHERE location = 'Brazil'
order by location, date;

SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases) * 100) AS rate_death
FROM covid_deaths
WHERE location ILIKE '%states%'
order by location, date;

--- Comparing for each country the maximum death rate recorded so far
SELECT continent, location, population, MAX(total_deaths) as highest_death_number, MAX((total_deaths/population)) * 100 AS highest_rate_death
FROM covid_deaths
GROUP BY continent, location, population
HAVING MAX(total_deaths) IS NOT NULL AND population IS NOT NULL AND continent IS NOT NULL
ORDER BY highest_rate_death DESC;




--- Total Cases vs Population: Infection rate
SELECT location, date, population, total_cases, ((total_cases/population) * 100) AS rate_infection
FROM covid_deaths
WHERE location = 'Brazil'
order by location, date;

-- Comparing for each country the maximum infection rate recorded so far
SELECT continent, location, population, MAX(total_cases) as highest_infection_number, MAX((total_cases/population)) * 100 AS highest_rate_infection
FROM covid_deaths
GROUP BY continent, location, population
HAVING MAX(total_cases) IS NOT NULL AND population IS NOT NULL AND continent IS NOT NULL
ORDER BY highest_rate_infection DESC;

SELECT location, date, population,  MAX(total_cases) as highest_infection_number, MAX((total_cases/population)) * 100 AS highest_rate_infection
FROM covid_deaths
GROUP BY location, population, date
HAVING MAX(total_cases) IS NOT NULL AND population IS NOT NULL
ORDER BY highest_rate_infection DESC;




---- Total death per country
SELECT location, MAX(total_deaths) as highest_death_number
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY highest_death_number DESC;


---- Total death per continent, dropping the 'income' groups, world, international and european union
SELECT location, MAX(total_deaths) as highest_death_number
FROM covid_deaths
WHERE continent IS NULL AND location NOT ILIKE '%income%' AND location <> 'World' AND location <> 'International' AND location <> 'European Union'
GROUP BY location
ORDER BY highest_death_number DESC;




--- Global Numbers

-- Evaluating per each day across the world
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / SUM(new_cases)) * 100 AS rate_death_by_day
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Evaluating for the entire time across the world
SELECT SUM(CAST(new_cases AS bigint)) AS total_cases, SUM(CAST(new_deaths AS bigint)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS bigint)) / SUM(CAST(new_cases AS bigint)) * 100, 2) AS rate_death_globally
FROM covid_deaths
WHERE continent IS NOT NULL;


SELECT location, population
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population DESC



--- Checking the covid vaccinations table
SELECT * 
FROM covid_vaccinations
ORDER BY location, date;


SELECT death.continent, death.location, death.date, death.population, vac.new_tests, vac.new_vaccinations
FROM covid_deaths death
JOIN covid_vaccinations vac
	ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date;

--- Getting the vaccinations growth and rate per day for each country, using partition by and CTE
WITH vaccination_by_pop (continent, location, date, population, new_tests, new_vaccinations, total_vaccinations_per_day)
AS
(SELECT death.continent, death.location, death.date, death.population, vac.new_tests, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS total_vaccinations_per_day
FROM covid_deaths death
JOIN covid_vaccinations vac
	ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date)
SELECT *, (total_vaccinations_per_day/population) * 100 AS rate_vaccionation_per_day
FROM vaccination_by_pop
WHERE new_vaccinations IS NOT NULL



--- Population vs Population fully vaccinated: Rate growth people fully vaccinated per day
SELECT death.continent, death.location, death.date, death.population, vac.people_fully_vaccinated, vac.people_fully_vaccinated / death.population * 100 AS rate_people_fully_vaccinated_per_day
FROM covid_deaths death
JOIN covid_vaccinations vac
	ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL AND death.location = 'United Arab Emirates'
ORDER BY death.location, death.date;


--- Top countries rates fully vaccinated
SELECT death.location, death.population, MAX(vac.people_fully_vaccinated) AS total_people_fully_vaccinated, MAX(vac.people_fully_vaccinated) / death.population * 100 AS rate_people_fully_vaccinated_per_country
FROM covid_deaths death
JOIN covid_vaccinations vac
	ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL AND death.population IS NOT NULL AND vac.people_fully_vaccinated IS NOT NULL
GROUP BY death.location, death.population
ORDER BY rate_people_fully_vaccinated_per_country DESC;

