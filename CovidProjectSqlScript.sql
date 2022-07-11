
-- This project will be analyzing global COVID-19 case and vaccine data from Our World In Data
-- dating from the start of the pandemic until about April 2020 using SQL, Python and Tableau.

-- After checking to see the files were correctly imported, I will rename the tables for ease. 
RENAME TABLE CovidDeaths_csv TO CovidDeaths;
ALTER TABLE CovidVaccinations_csv RENAME CovidVaccinations;

-- SQL misread the dates as a string, this leads to the data not correctly organizing according 
-- to date. I tried casting etc and settled on str_to_date as the easiest fix
SELECT str_to_date(date, '%m/%d/%y')
FROM CovidDeaths cd;

-- Let's replace the current date with the correct formatting
UPDATE CovidDeaths 
SET `date` = str_to_date(date, '%m/%d/%y');

UPDATE CovidVaccinations  
SET `date` = str_to_date(date, '%m/%d/%y');

-- Select the data I will be using and order it according to location and the date.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2;

-- Let's look at the Case Fatality rate for total cases per country.
-- Since my data contains aggregates for continent listed under location, 
-- I want to remove those values when looking at individual countries in WHERE.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CaseFatalityRate
FROM CovidDeaths 
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Let's look at the Case Fatality rate for the US 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CaseFatalityRate
FROM CovidDeaths 
WHERE location LIKE '%state%' 
ORDER BY 1, 2;

-- Let's look at the COVID-19 Case Rate in the US, this is the percent of the population 
-- which has received a positive diagnosis for COVID
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CaseRatebyPopulation
FROM CovidDeaths 
WHERE location LIKE '%state%' and date IS NOT NULL
ORDER BY 1, 2;

-- What countries have the highest infection rate by population? 
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS HighestCaseRatebyPop
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY 1,2
ORDER BY HighestCaseRatebyPop DESC;

-- What countries have the highest death count? 
SELECT location, MAX(total_deaths) AS HighestDeathCountbyPop
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY 1
ORDER BY HighestDeathCountbyPop DESC;

-- What is the death count by continent? 
-- Issue here with using select continent (easier way) is that the dataset is incorrectly formatted as it only selects certain values, ie north america only considers US. 
-- FYI the data keeps Australia out, despite it being a continent bc the data set groups it into Oceania 
SELECT location, MAX(total_deaths) as TotalDeathCount 
FROM CovidDeaths
WHERE location = 'Africa' or location = 'Europe' or location = 'North America' or location = 'Oceania' or location = 'South America' or location = 'Asia' 
GROUP BY 1
ORDER BY TotalDeathCount DESC;

-- Let's look at the daily new cases, new deaths, and death rate according to confirmed cases
SELECT date, SUM(new_cases) AS TotalNewCases, SUM(new_deaths) AS TotalNewDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathRatebyConfirmedCases
FROM CovidDeaths 
WHERE location = 'Africa' or location = 'Europe' or location = 'North America' or location = 'Oceania' or location = 'South America' or location = 'Asia' 
GROUP BY date
ORDER BY 1, 2;

-- Let's look at the total new cases, new deaths, and death rate according to confirmed cases
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathRatebyConfirmedCases
FROM CovidDeaths 
WHERE location = 'Africa' or location = 'Europe' or location = 'North America' or location = 'Oceania' or location = 'South America' or location = 'Asia' 
ORDER BY 1, 2;

-- Let's switch gears and look over at the other table we have 
SELECT * 
FROM CovidVaccinations;

-- Let's JOIN the two tables together and look at the world population and new vaccinations per day by date
-- This where clause is how i can get around the filter for null / not null values meant above and remove redundancies for location/continent
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations 
FROM CovidDeaths cd
JOIN 
	CovidVaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER BY 1, 2 DESC;

-- Let's edit this last script to calculate a running total of the daily vaccinations 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
-- Using PARTITION BY here to make sure the running sum is renewed for each country and doesn't continue on indefinitely 
SUM(cv.new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinationCount 
FROM CovidDeaths cd
JOIN 
	CovidVaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER BY 2, 3 DESC;

-- Use CTE (Common Table Expressions) to use the RollingVaccinationCount and Population to calculate the percent of the population vaccinated
WITH PopulationvsVaccination (continent, location, `date`, population, new_vaccinations, RollingVaccinationCount)
as 
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(cv.new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinationCount 
FROM CovidDeaths cd
JOIN 
	CovidVaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER BY 2, 3 ASC
)
SELECT *, (RollingVaccinationCount/population)*100 AS PercentPopulationVaccinated
FROM PopulationvsVaccination;

-- Creating view to store data for visualization in Tableau 
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(cv.new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinationCount 
FROM CovidDeaths cd
JOIN 
	CovidVaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER BY 2, 3 ASC;

