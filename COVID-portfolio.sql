--SELECT * 
--FROM PortfolioProject..CovidDeaths
--order by 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--order by 3,4


--Select Location, date, total_cases, new_cases, total_deaths, population
--From PortfolioProject..CovidDeaths
--Where continent is not null 
--order by 1,2

--CONTINENT IS NULL WHEN DATA IS ABOUT WORLD

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 OR total_cases IS NULL THEN 0
        ELSE (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    location LIKE 'inida' 
    AND continent IS NOT NULL 
ORDER BY 
    1, 2;



-- Total Cases vs Population
-- Shows what percentage of population infected with Covid per country

SELECT 
    location, 
    date, 
    population, 
    total_cases,  
    CASE 
        WHEN population = 0 OR population IS NULL OR total_cases IS NULL THEN 0
        ELSE (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 
    END AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
ORDER BY 
    location, date;



-- Countries with Highest Infection Rate compared to Population  --Peak Infection % By Country
SELECT 
    location, 
    MAX(CAST(population AS BIGINT)) AS population,
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,  
    MAX(
        CASE 
            WHEN population = 0 OR population IS NULL THEN 0
            ELSE (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100
        END
    ) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY 
    location
ORDER BY 
    PercentPopulationInfected DESC;



-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS --NEW NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
--We have per day data we sum it up every day to get Rolling people vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        CAST(dea.population AS BIGINT) AS population,  -- Cast population to BIGINT
        CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,  -- Cast vaccinations to BIGINT
        SUM(CAST(vac.new_vaccinations AS BIGINT)) 
            OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    *,
    CASE 
        WHEN population IS NULL OR population = 0 THEN NULL  -- Handles NULL or zero population safely
        ELSE (CAST(RollingPeopleVaccinated AS FLOAT) / CAST(population AS FLOAT)) * 100
    END AS rolling_vaccinated_percentage
FROM 
    PopvsVac;





WITH VaccinatedData  AS (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) 
      OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
)

SELECT *, 
  (RollingPeopleVaccinated * 1.0 / population) * 100 AS VaccinationRate
FROM VaccinatedData
where location = 'Albania'




-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations
USE PortfolioProject;
GO
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

SELECT * FROM PercentPopulationVaccinated
