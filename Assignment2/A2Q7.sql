SET search_path TO bnb, public;

-- Create a view to hold the bargain percentage for each booking.
CREATE VIEW viewBargainPercentage AS
SELECT Booking.listingId, Booking.travelerId, ((averagePrice - price) ::real/ averagePrice) AS bargainPercentage
FROM Booking JOIN (SELECT listingId, (sum(price) ::real/ sum(numNights)) AS averagePrice FROM Booking GROUP BY listingId) AS listingAverage ON Booking.listingId = listingAverage.listingId
WHERE ((averagePrice - price) ::real/ averagePrice) >= 0.25;

-- Create a view for the good bargainers and their maximum bargain percentage.
CREATE VIEW viewGoodBargainer AS
SELECT travelerId, max(bargainPercentage) AS maxBargainPercentage
FROM viewBargainPercentage
GROUP BY travelerId
HAVING count(listingId) >= 3;

-- Produce the Result Table.
SELECT viewBargainPercentage.travelerId AS travelerID, (viewBargainPercentage.bargainPercentage * 100)::int AS largestBargainPercentage, listingID
FROM viewBargainPercentage JOIN viewGoodBargainer ON viewBargainPercentage.travelerId = viewGoodBargainer.travelerId
WHERE viewBargainPercentage.bargainPercentage = maxBargainPercentage
ORDER BY viewBargainPercentage.bargainPercentage DESC, viewBargainPercentage.travelerId ASC, listingID ASC;
