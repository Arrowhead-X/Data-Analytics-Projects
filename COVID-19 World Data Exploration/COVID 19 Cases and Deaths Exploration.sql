select * 
from PortfolioProject..CovidDeaths
Order by 3, 4


--select * 
--from PortfolioProject..CovidVaccinations$
--Order by 3, 4

--View the total cases and total deaths in various countries in the world
select location, date, total_cases, new_cases, total_deaths
from PortfolioProject..CovidDeaths
order by 1, 2

-- Adding a derived column to determine the likely percentage of death if one contracted covid in Nigeria
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%Nigeria%'
order by 1, 2

-- Finding what percentage of the Nigerian population contracted covid-19
select location, date, population, total_cases, (total_cases/population)*100 as case_population_pct
from PortfolioProject..CovidDeaths
WHERE location = 'Nigeria'
ORDER BY 1, 2

--Looking at the countries with the highest number of cases in relation to their population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as InfectedPopulationPct
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Nigeria'
GROUP BY location, population
ORDER BY InfectedPopulationPct DESC

--Showing countries with the highest death coiunts per population
SELECT 
		location
		, population
		, MAX(cast(total_deaths as int)) as HighestDeathCount
		, MAX((total_deaths/population)*100) as PopulationDeathPct
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PopulationDeathPct DESC

-- Showing countries with the highest number of total death counts
SELECT 
		continent
		, location
		, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY TotalDeathCount DESC

-- Examining total deaths by continent
SELECT
		continent
		, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Calculating total daily deaths across continents
SELECT
		date
		, SUM(new_cases) AS TotalCases
		, SUM(CAST(new_deaths AS INT)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Calculating the percentage of daily global deaths to daily global cases
SELECT
		date
		, SUM(new_cases) AS TotalCases
		, SUM(CAST(new_deaths AS INT)) AS TotalDeaths
		, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Calculating total cases, deaths and percetage of deaths to cases globally
SELECT
		SUM(new_cases) AS TotalCases
		, SUM(CAST(new_deaths AS INT)) AS TotalDeaths
		, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- We'll now focus on our vaccination table but let's bring both tables together with a JOIN
SELECT *
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations$ vaccine
ON deaths.location = vaccine.location
AND deaths.date = vaccine.date

SELECT 
		deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccine.new_vaccinations
FROM PortfolioProject..CovidDeaths deaths
	 JOIN PortfolioProject..CovidVaccinations$ vaccine
	 ON deaths.location = vaccine.location
	 AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3


SELECT 
		deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccine.new_vaccinations
		, SUM(CONVERT(INT, vaccine.new_vaccinations)) OVER(PARTITION BY deaths.location ORDER BY deaths.location
		, deaths.date) AS VaccinatedRunningTotal
FROM PortfolioProject..CovidDeaths deaths
	 JOIN PortfolioProject..CovidVaccinations$ vaccine
	 ON deaths.location = vaccine.location
	 AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL AND vaccine.new_vaccinations IS NOT NULL
ORDER BY 2, 3


-- Using CTE to calculate the percentage of people vaccinated in the population
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, VaccinatedRollingTotal)
AS
(
SELECT 
		deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccine.new_vaccinations
		, SUM(CONVERT(INT, vaccine.new_vaccinations)) OVER(PARTITION BY deaths.location ORDER BY deaths.location
		, deaths.date) AS VaccinatedRollingTotal
FROM PortfolioProject..CovidDeaths deaths
	 JOIN PortfolioProject..CovidVaccinations$ vaccine
	 ON deaths.location = vaccine.location
	 AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL AND vaccine.new_vaccinations IS NOT NULL
)
SELECT *, (VaccinatedRollingTotal/Population)*100
FROM PopvsVac



WITH PopvsVac (Continent, Location, Population, New_Vaccinations, VaccinatedRollingTotal)
AS
(
SELECT 
		deaths.continent
		, deaths.location
		, deaths.population
		, vaccine.new_vaccinations
		, SUM(CONVERT(bigint, vaccine.new_vaccinations)) OVER(PARTITION BY deaths.location ORDER BY deaths.location) AS VaccinatedRollingTotal
FROM PortfolioProject..CovidDeaths deaths
	 JOIN PortfolioProject..CovidVaccinations$ vaccine
	 ON deaths.location = vaccine.location
WHERE deaths.continent IS NOT NULL AND vaccine.new_vaccinations IS NOT NULL
)
SELECT *, (VaccinatedRollingTotal/Population)*100 AS VaccinatedPopulationPct
FROM PopvsVac


--Using TEMP TABLE to show the percentage of people vaccinated in the population

DROP TABLE IF EXISTS #VaccinatedPopulationPct
CREATE TABLE #VaccinatedPopulationPct
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
VaccinatedRollingTotal numeric
)
INSERT INTO #VaccinatedPopulationPct
SELECT 
		deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccine.new_vaccinations
		, SUM(CONVERT(INT, vaccine.new_vaccinations)) OVER(PARTITION BY deaths.location ORDER BY deaths.location
		, deaths.date) AS VaccinatedRollingTotal
FROM PortfolioProject..CovidDeaths deaths
	 JOIN PortfolioProject..CovidVaccinations$ vaccine
	 ON deaths.location = vaccine.location
	 AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL AND vaccine.new_vaccinations IS NOT NULL


SELECT *, (VaccinatedRollingTotal/Population)*100
FROM #VaccinatedPopulationPct


-- Creating view to store percentage of people vaccinated from the total population
CREATE VIEW
VaccinatedPopulationPct AS
SELECT 
		deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccine.new_vaccinations
		, SUM(CONVERT(INT, vaccine.new_vaccinations)) OVER(PARTITION BY deaths.location ORDER BY deaths.location
		, deaths.date) AS VaccinatedRollingTotal
FROM PortfolioProject..CovidDeaths deaths
	 JOIN PortfolioProject..CovidVaccinations$ vaccine
	 ON deaths.location = vaccine.location
	 AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL AND vaccine.new_vaccinations IS NOT NULL

SELECT * FROM VaccinatedPopulationPct
