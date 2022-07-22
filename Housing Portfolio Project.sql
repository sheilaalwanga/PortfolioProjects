/*Data Cleaning using SQL*/

  

--Standardize Date format

SELECT SaleDate, CAST(SaleDate AS date)
FROM HousingPortfolioProject..HousingData

ALTER TABLE HousingPortfolioProject..HousingData
ADD ConvertedDate date

UPDATE HousingPortfolioProject..HousingData
SET ConvertedDate = CAST(SaleDate AS date)



--Populate Property Address data

SELECT *
FROM HousingPortfolioProject..HousingData
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.[UniqueID ], a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM HousingPortfolioProject..HousingData a
--WHERE ParcelID = ParcelID AND [UniqueID ] <> [UniqueID ]
JOIN HousingPortfolioProject..HousingData b
     ON a.ParcelID = b.ParcelID
     AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM HousingPortfolioProject..HousingData a
JOIN HousingPortfolioProject..HousingData b
     ON a.ParcelID = b.ParcelID
     AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



--Break up Address into individual columns(Address,City,State)

SELECT PropertyAddress
FROM HousingPortfolioProject..HousingData


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as PropertySplitAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as PropertySplitCity
FROM HousingPortfolioProject..HousingData

ALTER TABLE HousingPortfolioProject..HousingData
ADD PropertySplitAddress nvarchar(255)

UPDATE HousingPortfolioProject..HousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE HousingPortfolioProject..HousingData
ADD PropertySplitCity nvarchar(255)

UPDATE HousingPortfolioProject..HousingData
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT OwnerAddress
FROM HousingPortfolioProject..HousingData

SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) as OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) as OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) as OwnerSplitState
FROM HousingPortfolioProject..HousingData

ALTER TABLE HousingPortfolioProject..HousingData
ADD OwnerSplitAddress nvarchar(255)

UPDATE HousingPortfolioProject..HousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE HousingPortfolioProject..HousingData
ADD OwnerSplitCity nvarchar(255)

UPDATE HousingPortfolioProject..HousingData
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) 

ALTER TABLE HousingPortfolioProject..HousingData
ADD OwnerSplitState nvarchar(255)

UPDATE HousingPortfolioProject..HousingData
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)



--Change 'Y' and 'N' to 'Yes' and 'No' in 'SoldAsVacant' field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingPortfolioProject..HousingData
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE
    when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
FROM HousingPortfolioProject..HousingData

UPDATE HousingPortfolioProject..HousingData
SET SoldAsVacant = CASE
    when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end



--Remove Duplicate Rows

WITH row_numCTE AS(
SELECT *,
ROW_NUMBER()OVER(PARTITION BY ParcelID,
							  PropertyAddress,
							  SaleDate,
							  SalePrice,
							  LegalReference
							  ORDER BY UniqueID) as row_num		
FROM HousingPortfolioProject..HousingData)
DELETE
FROM row_numCTE 
WHERE row_num > 1


--Delete unused columns

SELECT *
FROM HousingPortfolioProject..HousingData

ALTER TABLE HousingPortfolioProject..HousingData
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict