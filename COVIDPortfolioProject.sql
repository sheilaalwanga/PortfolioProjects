/*

COVID 19 Data exploration for the first year of the pandemic

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


--Looking at the data we are going to be using

SELECT * FROM CovidPortfolioProject..CovidDeaths
SELECT * FROM CovidPortfolioProject..CovidVaccinations


--Total deaths vs Total cases
--Shows liklihood of dying(in percentage) if you contracted Covid in your country

SELECT location, date, total_cases, total_deaths, 
(TRY_CAST(total_deaths AS float)/NULLIF(TRY_CAST(total_cases AS float),0))*100 death_percentages
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%Kenya%'



--Total deaths vs Population
--Shows the percentage of the population in your country that died of Covid

SELECT location, date, total_deaths, population, 
(CAST(total_deaths AS float)/CAST(population AS float))*100 death_percentages
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%Kenya%'



--Total cases vs Population
--Shows the percentage of the population in your country that was infected by Covid

SELECT location, date, population, total_cases, 
(CAST(total_cases AS float)/CAST(population AS float))*100 case_percentages
FROM CovidPortfolioProject..CovidDeaths
WHERE location like '%Kenya%'



--Total tests vs Population
--Shows the testing rate of countries relative to their population, from the most to the least.

SELECT vac.location, dea.population, SUM(CAST(vac.new_tests AS float)) total_tests,
(SUM(CAST(vac.new_tests as float))/NULLIF(CAST(dea.population as float),0))*100 testing_rate
FROM CovidPortfolioProject..CovidVaccinations vac
JOIN CovidPortfolioProject..CovidDeaths dea
     ON vac.date = dea.date
	 AND vac.location = dea.location
WHERE vac.continent LIKE '%a' OR vac.continent LIKE '%e'
GROUP BY vac.location,dea.population
ORDER BY testing_rate desc



--Countries with highest infection rate relative to the Population

SELECT location, population, MAX(total_cases) Highest_infection_count,
MAX(TRY_CAST(total_cases AS float)/NULLIF(TRY_CAST(population AS float),0))*100 Infection_rate
FROM CovidPortfolioProject..CovidDeaths
WHERE continent LIKE '%a' OR continent LIKE '%e'
GROUP BY location,population
ORDER BY infection_rate desc



--Countries with highest death count

SELECT location, CAST(MAX(total_deaths)AS FLOAT) highest_death_count
FROM CovidPortfolioProject..CovidDeaths
WHERE continent LIKE '%a' OR continent LIKE '%e'
GROUP BY location
ORDER BY highest_death_count desc



--Percentages of Total deaths vs Vaccinations
--Checks if there is a correlation between the number of vaccinations and death rates of countries

SELECT dea.location, dea.date, dea.new_deaths, vac.new_vaccinations, 
(CAST(dea.new_deaths AS float)/NULLIF(CAST(vac.new_vaccinations AS float),0))*100 death_rate
FROM CovidPortfolioProject..CovidVaccinations vac
JOIN CovidPortfolioProject..CovidDeaths dea
ON dea.location = vac.location
AND dea.date =vac.date
WHERE dea.continent LIKE '%a' or dea.continent LIKE '%e'
ORDER BY 1



--BREAKING THINGS DOWN BY CONTINENT

--Continents with highest death count

SELECT continent, CAST(MAX(total_deaths)AS float) highest_death_count
FROM CovidPortfolioProject..CovidDeaths
WHERE continent LIKE '%a' or continent LIKE '%e'
GROUP BY continent
ORDER BY highest_death_count desc


--Continents with highest infection count

SELECT continent, CAST(MAX(total_cases)as float) highest_infection_count
FROM CovidPortfolioProject..CovidDeaths
WHERE continent LIKE '%a' or continent LIKE '%e'
GROUP BY continent
ORDER BY highest_infection_count desc


--GLOBAL NUMBERS

SELECT date, SUM(try_cast(new_cases as float)) total_cases, SUM(try_cast(new_deaths as float)) total_deaths,
(SUM(try_cast(new_deaths as float))/NULLIF(SUM(try_cast(new_cases as float)),0))*100 death_percentage
FROM CovidPortfolioProject..CovidDeaths
GROUP BY date


--Total Population vs Vaccinations
--Shows percentage of the population that has recieved at least one vaccine

SELECT vac.continent, vac.location, try_cast(vac.date as date), dea.population, vac.new_vaccinations, 
SUM(CONVERT(float,vac.new_vaccinations))OVER (PARTITION BY vac.location ORDER BY try_cast(vac.date as date)) rolling_population_vaccinated
--(rolling_population_vaccinated/population)*100
FROM CovidPortfolioProject..CovidVaccinations vac
JOIN CovidPortfolioProject..CovidDeaths dea
     ON vac.location = dea.location
	 AND try_cast(vac.date as date) = try_cast(dea.date as date)
WHERE vac.continent LIKE '%a' OR vac.continent LIKE '%e'



--Using CTE to perform calculations on PARTITION BY in previous query

WITH PopvsVac(Continent, Location, Date, Population, NewVaccinations, RollingPopulationVaccinated )
AS
(SELECT vac.continent, vac.location, try_cast(vac.date as date), dea.population, vac.new_vaccinations, 
SUM(CONVERT(float,vac.new_vaccinations))OVER (PARTITION BY vac.location ORDER BY try_cast(vac.date as date)) rolling_population_vaccinated
--(rolling_population_vaccinated/population)*100
FROM CovidPortfolioProject..CovidVaccinations vac
JOIN CovidPortfolioProject..CovidDeaths dea
     ON vac.location = dea.location
	 AND try_cast(vac.date as date) = try_cast(dea.date as date)
WHERE vac.continent LIKE '%a' OR vac.continent LIKE '%e'
)
SELECT *,(RollingPopulationVaccinated/NULLIF(Population,0))*100 RollingPercentPopulationVaccinated
FROM PopvsVac


--Using TEMP TABLE to perform calculations on PARTITION BY in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPopulationVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT vac.continent, vac.location, try_cast(vac.date as date), try_cast(dea.population as numeric), try_cast(vac.new_vaccinations as numeric), 
SUM(CONVERT(float,vac.new_vaccinations))OVER (PARTITION BY vac.location ORDER BY try_cast(vac.date as date)) rolling_population_vaccinated
--(rolling_population_vaccinated/population)*100
FROM CovidPortfolioProject..CovidVaccinations vac
JOIN CovidPortfolioProject..CovidDeaths dea
     ON vac.location = dea.location
	 AND try_cast(vac.date as date) = try_cast(dea.date as date)
WHERE vac.continent LIKE '%a' OR vac.continent LIKE '%e'

SELECT * ,(RollingPopulationVaccinated/NULLIF(Population,0))*100 RollingPercentPopulationVaccinated
FROM #PercentPopulationVaccinated


--Creating views to store data for later visualizations

CREATE VIEW TotalDeathsVsTotalCases AS
SELECT location, date, total_cases, total_deaths, 
(TRY_CAST(total_deaths AS float)/NULLIF(TRY_CAST(total_cases AS float),0))*100 death_percentages
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%Kenya%'


CREATE VIEW TotalDeathsVsPopulation AS
SELECT location, date, total_deaths, population, 
(CAST(total_deaths AS float)/CAST(population AS float))*100 death_percentages
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%Kenya%'


CREATE VIEW GlobalCasesAndDeaths AS
SELECT date, SUM(try_cast(new_cases as float)) total_cases, SUM(try_cast(new_deaths as float)) total_deaths,
(SUM(try_cast(new_deaths as float))/NULLIF(SUM(try_cast(new_cases as float)),0))*100 death_percentage
FROM CovidPortfolioProject..CovidDeaths
GROUP BY date














