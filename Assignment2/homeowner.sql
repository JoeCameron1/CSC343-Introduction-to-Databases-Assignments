CREATE VIEW viewTravelerOwnerMatrix AS
SELECT travelerId, homeownerId
FROM Traveler, Homeowner;

CREATE VIEW viewTravelerOwnerRating AS
SELECT travelerId, owner AS homeownerId, rating
FROM TravelerRating JOIN Booking ON TravelerRating.listingId = Booking.listingId AND TravelerRating.startdate = Booking.startdate JOIN Listing ON TravelerRating.listingId = Listing.listingId;

CREATE VIEW viewUtilityMatrix AS
SELECT viewTravelerOwnerMatrix.travelerId, viewTravelerOwnerMatrix.homeownerId, (SELECT avg(rating) AS Average FROM viewTravelerOwnerRating WHERE travelerId = viewTravelerOwnerMatrix.travelerId AND homeownerId = viewTravelerOwnerMatrix.homeownerId GROUP BY travelerId, homeownerId) AS averageRating
FROM viewTravelerOwnerMatrix;

CREATE VIEW viewUtilityMatrixDotProduct AS
SELECT homeownerId, (coalesce(averageRating, 0) * (SELECT averageRating FROM viewUtilityMatrix WHERE travelerId = UM.travelerId AND homeownerId = " + homeownerID + ") ) AS dotProduct
FROM viewUtilityMatrix UM
WHERE homeownerId <> "+ homeownerID";

CREATE VIEW viewCosineSimilarity AS
SELECT homeownerId, sum(dotProduct) AS score
FROM viewUtilityMatrixDotProduct
GROUP BY homeownerId
ORDER BY score DESC;

CREATE VIEW viewTen AS
SELECT homeownerId, score
FROM viewCosineSimilarity
WHERE score > 0
LIMIT 10;

CREATE VIEW viewTie AS
SELECT homeownerId, score
FROM viewCosineSimilarity
WHERE score = (SELECT score FROM viewTen ORDER BY score ASC LIMIT 1);

CREATE VIEW viewTenResult AS
SELECT homeownerId, score
FROM viewTen;

CREATE VIEW viewTieResult AS
SELECT homeownerId, score
FROM viewTie;

SELECT homeownerId, score
FROM (viewTenResult UNION viewTieResult) result
ORDER BY score DESC, homeownerId ASC;
