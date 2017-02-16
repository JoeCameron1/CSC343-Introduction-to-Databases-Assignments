SET search_path TO bnb, public;

-- Create a view to hold all ratings in the last 10 years.
CREATE VIEW viewRatingsInLast10Years AS
SELECT owner, extract(year FROM startdate) AS year, avg(rating) AS averageRating
FROM TravelerRating JOIN Listing ON TravelerRating.listingId = Listing.listingId
WHERE (extract(YEAR FROM current_date) - extract(YEAR FROM startdate)) <= 10
GROUP BY owner, extract(year FROM startdate);

-- Create a view to hold all owners with decreasing ratings.
CREATE VIEW viewDecreasingRatings AS
SELECT DISTINCT r1.owner AS decreasingOwner
FROM viewRatingsInLast10Years r1 JOIN viewRatingsInLast10Years r2 ON r1.owner = r2.owner AND r1.year > r2.year
WHERE r1.averageRating < r2.averageRating;

-- Take the difference between the total number of owners
-- and the number of owners with decreasing ratings, in order to find the
-- number of owners with non-decreasing ratings.
-- Produce the result table.
SELECT (((count(DISTINCT viewRatingsInLast10Years.owner) - count(DISTINCT viewDecreasingRatings.decreasingOwner))::real / count(DISTINCT viewRatingsInLast10Years.owner)) * 100) ::int AS percentage
FROM viewRatingsInLast10Years FULL JOIN viewDecreasingRatings ON viewRatingsInLast10Years.owner = viewDecreasingRatings.decreasingOwner;
