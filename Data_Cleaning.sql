-- CLEANING THE DATA

-- Create a cleaned copy to work on
SELECT * 
INTO NashvilleHousing_Cleaned
FROM NashvilleHousing;

--------------------------------------------------------------------------------
-- Standardize Date Format

SELECT
	SaleDate,
	TRY_CONVERT(DATE, SaleDate)
FROM NashvilleHousing_Cleaned;

UPDATE NashvilleHousing_Cleaned
SET SaleDate = TRY_CONVERT(Date, SaleDate);

SELECT SaleDate
FROM NashvilleHousing_Cleaned;

--------------------------------------------------------------------------------
-- Populate Property Address data

-- Inspect the dataset and check for missing property addresses

SELECT *
FROM NashvilleHousing_Cleaned
-- WHERE ProperyAddress IS NULL
ORDER BY ParcelID;


/* Find rows with missing PropertyAddress and try to fill them in 
   by looking at another row with the same ParcelID but different UniqueID */

SELECT 
	a.ParcelID, 
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing_Cleaned a
JOIN NashvilleHousing_Cleaned b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] != b.[UniqueID]
WHERE a.PropertyAddress IS NULL;


-- Update rows in table 'a' where PropertyAddress is NULL
-- Set them equal to the address from table 'b' with the same ParcelID

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing_Cleaned a
JOIN NashvilleHousing_Cleaned b 
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] != b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

--------------------------------------------------------------------------------
-- Breaking out Address into individual columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleHousing_Cleaned
-- WHERE CHARINDEX(',', PropertyAddress) = 0


-- Preview the split of PropertyAddress into Address and City
SELECT 
	CASE
		WHEN CHARINDEX(',', PropertyAddress) > 0 THEN SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
		ELSE PropertyAddress
	END AS Address,
	LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))
 AS City
FROM NashvilleHousing_Cleaned;

-- Add new column to store the split Address
ALTER TABLE NashvilleHousing_Cleaned
ADD PropertySplitAddress Nvarchar(255);

-- Populate PropertySplitAddress with the first part of PropertyAddress
UPDATE NashvilleHousing_Cleaned
SET PropertySplitAddress = 
	CASE 
		WHEN CHARINDEX(',', PropertyAddress) > 0 THEN SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)
	ELSE PropertyAddress
END;

-- Add new column to store the split city
ALTER TABLE NashvilleHousing_Cleaned 
ADD PropertySplitCity Nvarchar(255);

-- Populate PropertySplitCity with the second part of PropertyAddress
UPDATE NashvilleHousing_Cleaned
SET PropertySplitCity = 
    CASE
        WHEN CHARINDEX(',', PropertyAddress) > 0 
            THEN LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))
        ELSE NULL
    END;

SELECT *
FROM NashvilleHousing_Cleaned;

--------------------------------------------------------------------------------
-- Split Owner Address into Address, City, and State

-- Preview the full OwnerAddress
SELECT OwnerAddress 
FROM NashvilleHousing_Cleaned;

-- Split OwnerAddress into parts using PARSENANE
SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing_Cleaned;

-- Add column to store the street part of the address
ALTER TABLE NashvilleHousing_Cleaned
ADD OwnerSplitAddress Nvarchar(255);

-- Populate the street part
UPDATE NashvilleHousing_Cleaned
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

-- Add column to store the city part of the address
ALTER TABLE NashvilleHousing_Cleaned
ADD OwnerSplitCity Nvarchar(255);

-- Populate the city part
UPDATE NashvilleHousing_Cleaned
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

-- Add column to store the state part of the address
ALTER TABLE NashvilleHousing_Cleaned 
ADD OwnerSplitState Nvarchar(255);

-- Populate the state part
UPDATE NashvilleHousing_Cleaned
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT * 
FROM NashvilleHousing_Cleaned;

--------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS count
FROM NashvilleHousing_Cleaned
GROUP BY SoldAsVacant
ORDER BY count;

SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM NashvilleHousing_Cleaned;

UPDATE NashvilleHousing_Cleaned
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

--------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID, 
					 PropertyAddress, 
					 SalePrice, 
					 SaleDate,
					 LegalReference
		ORDER BY UniqueID
    ) row_num
FROM NashvilleHousing_Cleaned
)
--DELETE  
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

SELECT * 
FROM NashvilleHousing_Cleaned

