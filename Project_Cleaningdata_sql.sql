SELECT *
FROM PortfolioProject..housingdata

--Standardize data format
SELECT SaleDate, CONVERT(date,SaleDate)
FROM PortfolioProject..housingdata

ALTER TABLE PortfolioProject..housingdata
ALTER COLUMN SaleDate DATE

--Populate data


Select *
From PortfolioProject..housingdata
Where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..housingdata a
JOIN PortfolioProject..housingdata b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Update table
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..housingdata a
JOIN PortfolioProject..housingdata b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--Double check whether there is null or not
Select *
From PortfolioProject..housingdata 
Where PropertyAddress is null


-- Break PropertyAddress down into individual columns address,state

-- Take a look at original PropertyAdress
Select PropertyAddress
From PortfolioProject..housingdata

-- Break down into address
Select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address, -- (-1): Remove ',' after address
 SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address -- (+1): get rid of',', LEN: return the remaining string
From PortfolioProject..housingdata


-- ADD columns from split columns and update table

ALTER TABLE PortfolioProject..housingdata
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject..housingdata
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE PortfolioProject..housingdata
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject..housingdata
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--double check if these columns exist or not

Select *
From PortfolioProject..housingdata;


-- Split owneraddress into individual columns

-- Take a look at original owneraddress
Select OwnerAddress
FROM PortfolioProject..housingdata;

-- Break it down using syntax PARSENAME: return the specific part of given string
-- Step 1: Replace ',' into '.' in order to use PARSENAME
-- Step 2: Arrange from 3 to 1 instead of 1 to 3 bc it's backwards

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject..housingdata;

-- ADD these columns and update table

ALTER TABLE PortfolioProject..housingdata
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject..housingdata
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE PortfolioProject..housingdata
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject..housingdata
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE PortfolioProject..housingdata
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject..housingdata
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

-- Double check for these columns
Select *
FROM PortfolioProject..housingdata




-- Noticing column ' SoldAsVacant' has N, Y, No, Yes 

Select DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
From PortfolioProject..housingdata
Group by SoldAsVacant

-- Change Y, N into Yes, No

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END 
From PortfolioProject..housingdata

-- Update table
Update PortfolioProject..housingdata
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END 

-- Find duplicate USING ROW_NUMBER
-- One way
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject..housingdata
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress


-- Other way
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID) as row_num
From PortfolioProject..housingdata)
SELECT b.ParcelID, b.PropertyAddress, b.SalePrice, b.SaleDate, b.LegalReference, b.UniqueID, a.UniqueID as 'Duplicate of'
FROM RowNumCTE b
INNER JOIN RowNumCTE a
ON b.ParcelID=a.ParcelID
AND b.PropertyAddress=a.PropertyAddress
AND b.SalePrice=a.SalePrice
AND b.SaleDate=a.SaleDate
AND b.LegalReference=a.LegalReference
WHERE b.row_num > 1
AND a.row_num=1


--REMOVE Duplicate
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject..housingdata
)
DELETE 
From RowNumCTE
Where row_num > 1

-- Delete unused columns


ALTER TABLE PortfolioProject..housingdata
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

--double check again

Select *
From PortfolioProject..housingdata