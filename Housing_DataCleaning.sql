--DATA CLEANING REGARDING HOUSING DATA

-- Populate Property Address data

-- I've found identical parcelid's with the same propertyaddress numerous times
-- meaning I can infer that for each parcelid, there is a specific property address
-- If parcelid x has property y and if there is another parcelid x with null propertyaddress, that propertyaddess to be y.

UPDATE housing AS missingInfo
SET propertyaddress = COALESCE(missingInfo.propertyaddress, hasInfo.propertyaddress)
FROM housing AS hasInfo
WHERE hasInfo.parcelid = missingInfo.parcelid
  AND hasInfo.uniqueid <> missingInfo.uniqueid
  AND missingInfo.propertyaddress IS NULL;


-- Breaking out propertyaddress into individual columns

Select propertyaddress,
	split_part(propertyaddress, ',', 1) AS address,
	split_part(propertyaddress, ',', 2) AS city
from housing;

-- Create and update tables

ALTER TABLE housing
ADD propertySplitAddress varchar(255);

UPDATE housing
SET propertySplitAddress = split_part(propertyaddress, ',', 1);

ALTER TABLE housing
ADD propertySplitCity varchar(255);

UPDATE housing
SET propertySplitCity = split_part(propertyaddress, ',', 2);

-- Breaking down owneraddress

SELECT owneraddress,
	split_part(owneraddress, ',', 1) AS address,
	split_part(owneraddress, ',', 2) AS city,
	split_part(owneraddress, ',', 3) AS statee
from housing;

-- Create and update tables

ALTER TABLE housing
ADD ownerSplitAddress varchar(255);

UPDATE housing
SET ownerSplitAddress = split_part(owneraddress, ',', 1);

ALTER TABLE housing
ADD ownerSplitCity varchar(255);

UPDATE housing
SET ownerSplitCity = split_part(owneraddress, ',', 2);

ALTER TABLE housing
ADD ownerSplitState varchar(255);

UPDATE housing
SET ownerSplitState = split_part(owneraddress, ',', 3);


-- Change Y and N to "Yes" and "No" in Sold as Vacant field

UPDATE housing
SET soldasvacant = CASE
		WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
	END;
	
-- Remove duplicates, If any column contains two of the same information, delete.

DELETE FROM housing
USING (
    SELECT uniqueid
    FROM (
        SELECT uniqueid,
               ROW_NUMBER() OVER (
                   PARTITION BY parcelid, propertyaddress, saleprice, saledate, legalreference
                   ORDER BY uniqueid
               ) as row_num
        FROM housing
    ) sub
    WHERE row_num > 1
) duplicates
WHERE housing.uniqueid = duplicates.uniqueid;

-- Confirm the duplicate records are removed.

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY parcelid,
									propertyaddress,
									saleprice,
									saledate,
									legalreference 
									ORDER BY uniqueid) as row_num
FROM housing)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- Deleting columns that won't be needed after data has been cleaned.

ALTER TABLE housing
DROP COLUMN owneraddress, 
DROP COLUMN propertyaddress, 
DROP COLUMN taxdistrict;