SET search_path TO bnb, public;

CREATE OR REPLACE FUNCTION OVERLAP(LId int) RETURNS BOOLEAN AS $$
BEGIN
IF EXISTS
	(SELECT *
	FROM Booking b1 JOIN Booking b2
	ON b1.listingId = LId AND b2.listingId = b1.listingId AND b1.startdate < b2.startdate
	WHERE b1.startdate + b1.numNights > b2.startdate)
THEN RETURN TRUE;
ELSE RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION CalculateDays(lId int, year int) RETURNS int
AS $$
DECLARE
	endOfYear date;
	startOfYear date;
	numDays int;
BEGIN
	endOfYear := to_date(to_char($2, '9999') || '-12-31', 'YYYY-MM-DD');
	startOfYear := to_date(to_char($2, '9999') || '-01-01', 'YYYY-MM-DD');
	SELECT sum(day) INTO numDays FROM (
		(-- startofyear <= start < end <= endofyear
		 SELECT numNights as day
		 FROM Booking
		 WHERE listingId = $1
		 	AND startdate >= startOfYear
		 	AND startdate + numNights <= endOfYear
		)
		UNION
		(-- startofyear <= start <= endofyear < end
		 SELECT (endOfYear - startdate + 1) as day
		 FROM Booking
		 WHERE listingId = $1
		 	AND startdate >= startOfYear
		 	AND startdate <= endOfYear
		 	AND startdate + numNights > endOfYear
		)
		UNION
		(-- start < startofyear <= end <= endofyear
		 SELECT ((startdate + numNights) - startOfYear) as day
		 FROM Booking
		 WHERE listingId = $1
		 	AND startdate < startOfYear
		 	AND startdate + numNights >= startOfYear
		 	AND startdate + numNights <= endOfYear
		)
		UNION
		(-- start < startofyear < endofyear < end
		 SELECT (endOfYear - startOfYear + 1) as day
		 FROM Booking
		 WHERE listingId = $1
		 	AND startdate < startOfYear
		 	AND startdate + numNights > endOfYear
		)

	) totaldays;
	RETURN numDays;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CheckMax(listingId int, year int, days int, type char(3))
	RETURNS BOOLEAN AS $$
DECLARE total int;
BEGIN
	total := CalculateDays($1, $2);
	IF (type = 'max') and (total > days)
	THEN RETURN TRUE;
	ELSIF (type = 'min')
 	THEN RETURN FALSE;
 	ELSE RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CheckMin(listingId int, year int, days int, type char(3))
	RETURNS BOOLEAN AS $$
BEGIN
	IF ($4 = 'min')
	AND EXISTS (
		 		SELECT *
		 		FROM Booking
		 		WHERE extract(year from startdate) = $2
		 			AND Booking.listingId = $1
		 			AND numNights < $3
		 		)
	THEN RETURN TRUE;
	ELSIF (type = 'max')
 	THEN RETURN FALSE;
 	ELSE RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION VIOLATELAW(listingId int, year int) RETURNS BOOLEAN
AS $$
BEGIN
	IF EXISTS
		(SELECT *
	     FROM CityRegulation, Listing
	     WHERE Listing.listingId = $1
	     AND (Listing.propertyType = CityRegulation.propertyType
	     		OR CityRegulation.propertyType = NULL)
	     AND Listing.city = CityRegulation.city
	     AND (CheckMax($1, $2, days, RegulationType)
			OR CheckMin($1, $2, days, RegulationType))
	    )
	THEN RETURN TRUE;
	ELSE RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- Create a view to find all valid properties.
CREATE OR REPLACE VIEW ValidBooking_q3 AS
SELECT DISTINCT listingId
FROM Booking
WHERE NOT OVERLAP(listingId);

--Create a view for all years.
CREATE OR REPLACE VIEW AllYears_q3 AS
SELECT year
FROM (
	(SELECT extract(year FROM startdate) AS year
	FROM Booking)
	UNION
	(SELECT extract(year FROM (startdate)) + 1 AS year
	FROM Booking)
	UNION
	(SELECT extract(year FROM (startdate)) + 2 AS year
	FROM Booking)
	) BookingYear;


-- Create a view of ValidBooking with years.
CREATE OR REPLACE VIEW BookingWithYear_q3 AS
SELECT listingId, year
FROM ValidBooking_q3, AllYears_q3;

SELECT owner AS homeowner, b3.listingId AS listingID,
	   year::int, list.city AS city
FROM BookingWithYear_q3 b3 JOIN Listing list
ON b3.listingId = list.listingId
WHERE VIOLATELAW(b3.listingId, CAST(b3.year as int))
ORDER BY owner ASC;
