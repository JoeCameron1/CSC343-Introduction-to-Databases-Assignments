SET search_path TO bnb, public;

-- 5 star ratings grouped by owner.
CREATE VIEW viewRatingsFiveStar AS
SELECT owner, count(TravelerRating.listingID) as FiveStarCount
FROM TravelerRating JOIN Listing ON TravelerRating.listingID = Listing.listingId
WHERE rating = 5
GROUP BY owner;

-- 4 star ratings grouped by owner.
CREATE VIEW viewRatingsFourStar AS
SELECT owner, count(TravelerRating.listingID) as FourStarCount
FROM TravelerRating JOIN Listing ON TravelerRating.listingID = Listing.listingId
WHERE rating = 4
GROUP BY owner;

-- 3 star ratings grouped by owner.
CREATE VIEW viewRatingsThreeStar AS
SELECT owner, count(TravelerRating.listingID) as ThreeStarCount
FROM TravelerRating JOIN Listing ON TravelerRating.listingID = Listing.listingId
WHERE rating = 3
GROUP BY owner;

-- 2 star ratings grouped by owner.
CREATE VIEW viewRatingsTwoStar AS
SELECT owner, count(TravelerRating.listingID) as TwoStarCount
FROM TravelerRating JOIN Listing ON TravelerRating.listingID = Listing.listingId
WHERE rating = 2
GROUP BY owner;

-- 1 star ratings grouped by owner.
CREATE VIEW viewRatingsOneStar AS
SELECT owner, count(TravelerRating.listingID) as OneStarCount
FROM TravelerRating JOIN Listing ON TravelerRating.listingID = Listing.listingId
WHERE rating = 1
GROUP BY owner;

-- Produce the Result Table.
SELECT homeownerID,
	viewRatingsFiveStar.FiveStarCount as r5,
  viewRatingsFourStar.FourStarCount as r4,
	viewRatingsThreeStar.ThreeStarCount as r3,
  viewRatingsTwoStar.TwoStarCount as r2,
	viewRatingsOneStar.OneStarCount as r1
FROM (SELECT homeownerID FROM Homeowner) hID LEFT JOIN viewRatingsFiveStar ON homeownerID = viewRatingsFiveStar.owner
	FULL JOIN viewRatingsFourStar ON homeownerID = viewRatingsFourStar.owner
	FULL JOIN viewRatingsThreeStar ON homeownerID = viewRatingsThreeStar.owner
	FULL JOIN viewRatingsTwoStar ON homeownerID = viewRatingsTwoStar.owner
	FULL JOIN viewRatingsOneStar ON homeownerID = viewRatingsOneStar.owner
ORDER BY r5 DESC, r4 DESC, r3 DESC, r2 DESC, r1 DESC, homeownerID ASC;
