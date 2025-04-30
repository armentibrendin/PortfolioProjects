-- Grab all of the data of relevance for this project

SELECT location, date, total_cases, new_cases, 
total_deaths, population
FROM coviddeaths
ORDER BY 1,2;

-- Looking at the total cases vs total deaths
-- for each country, calculate the deaths to total cases percentage
-- shows the likelihood of dying if you contract covid

SELECT location, date, total_cases, 
total_deaths, CAST (total_deaths AS float)/CAST (total_cases AS float)*100 as DeathPercentage
FROM coviddeaths
ORDER BY 1,2;

-- percentage rates for Canada
SELECT location, date, total_cases, 
total_deaths, CAST (total_deaths AS float)/CAST (total_cases AS float)*100 as DeathPercentage
FROM coviddeaths
WHERE location like '%Canada%'
ORDER BY 1,2;

-- Looking at the total cases vs the population
-- for Canada
-- shows percentage of population that got Covid
SELECT location, date, total_cases, 
population, CAST (total_cases AS float)/CAST (population AS float)*100 as CasesPercentage
FROM coviddeaths
ORDER BY 1,2;

-- Countries with the highest infection rates (removed offset 21 and incluced where clauses in this query and below)

SELECT location,population, max(total_cases) as highestInfectionCount, 
MAX(CAST(total_cases AS float)/CAST (population AS float))*100 as casesPercentage
FROM coviddeaths
WHERE continent is not null
and total_cases is not null
GROUP BY location, population
ORDER BY casesPercentage desc;

--Same above but with date included

SELECT location,population,date, max(total_cases) as highestInfectionCount, 
MAX(CAST(total_cases AS float)/CAST (population AS float))*100 as casesPercentage
FROM coviddeaths
WHERE continent is not null
and total_cases is not null
GROUP BY location, population,date
ORDER BY casesPercentage desc;

--  Breaking things down by continent

-- How many people died due to covid-19
-- this is the right way, but we will switch it back for the sake of the project (location in select, group by along
--with continent is null in where is accurate)

SELECT continent, max(total_deaths) as totalDeathCount
FROM coviddeaths
WHERE total_deaths IS NOT NULL --omits records where no deaths were recorded, causing null values
AND continent IS NOT NULL --omits continents as "countries"
GROUP BY continent
ORDER BY totalDeathCount desc;

-- Showing total deaths per continent

SELECT location, SUM(cast(new_deaths as int)) as TotalDeathCount
from coviddeaths
where continent is null
and location not in ('World', 'European Union', 'International')
group by location
order by TotalDeathCount desc;

-- I want to start looking at the data in terms of how to visualize it
-- Let's get some global statistics

-- Show total cases globally as per day

SELECT date, sum(new_cases) as totalCasesPerDay, sum(new_deaths) as totalDeathsPerDay,
(sum(CAST (new_deaths as float))/sum(CAST (new_cases as float)))*100 as DeathPercentage
from coviddeaths
where continent is not null
group by date
order by date, totalCasesPerDay;

-- removing the date (in select and group by) shows the total cases, deaths and death rate
-- globally over the course of the whole pandemic

SELECT sum(new_cases) as totalCasesPerDay, sum(new_deaths) as totalDeathsPerDay,
(sum(CAST (new_deaths as float))/sum(CAST (new_cases as float)))*100 as DeathPercentage
from coviddeaths
where continent is not null
-- group by date
order by totalCasesPerDay;


--joining the two tables
-- Looking at Total Population vs Vaccinations
--Total amount of people in who world that have been vaccinated PER DAY
-- counting column that continuely adds the new vaccinations to the previous records value

-- Using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)as 
	(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
	from coviddeaths dea join covidvaccinations vac on
	dea.location = vac.location AND
	dea.date = vac.date
	where dea.continent is not null
	ORDER BY 2,3)
SELECT *, (rollingPeopleVaccinated *1.0/population)*100
FROM PopvsVac;

-- Temp table
DROP TABLE if exists PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated
(	continent text,
	location text,
	date date,
	population bigint,
	new_vaccinations integer,
	rollingPeopleVaccinated numeric
);
INSERT INTO PercentPopulationVaccinated
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
	from coviddeaths dea join covidvaccinations vac on
	dea.location = vac.location AND
	dea.date = vac.date
	where dea.continent is not null
	ORDER BY 2,3);

SELECT *, (rollingPeopleVaccinated *1.0/population)*100
FROM PercentPopulationVaccinated;

-- Create a view to store data for later visualizations
-- PercentPopulationVaccinated View

Create View PercentPopulationVaccinated as
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
	from coviddeaths dea join covidvaccinations vac on
	dea.location = vac.location AND
	dea.date = vac.date
	where dea.continent is not null
	ORDER BY 2,3;

-- DeathPercentage Per day View

Create View DeathPercentagePerDay as
	SELECT date, sum(new_cases) as totalCasesPerDay, sum(new_deaths) as totalDeathsPerDay,
	(sum(CAST (new_deaths as float))/sum(CAST (new_cases as float)))*100 as DeathPercentage
	from coviddeaths
	where continent is not null
	group by date
	order by date, totalCasesPerDay;

-- Highest Infection Rate Countries

Create View HighestInfRateCountries as
	SELECT location, max(total_cases) as highestInfectionCount, 
	MAX(CAST(total_cases AS float)/CAST (population AS float))*100 as casesPercentage
	FROM coviddeaths
	GROUP BY location, population
	ORDER BY casesPercentage desc
	OFFSET 21;