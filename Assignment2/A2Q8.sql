SET search_path TO bnb, public;

-- Create a view to hold all reciprocal ratings.
CREATE VIEW viewReciprocalRatings AS
SELECT HomeownerRating.listingId, HomeownerRating.startDate, (HomeownerRating.rating - TravelerRating.rating) AS difference
FROM HomeownerRating JOIN TravelerRating ON HomeownerRating.listingId = TravelerRating.listingId AND HomeownerRating.startDate = TravelerRating.startDate;

-- Create a view to hold the count of reciprocal ratings.
CREATE VIEW viewTotalReciprocals AS
SELECT travelerID, count(difference) AS reciprocals
FROM Booking JOIN viewReciprocalRatings ON Booking.listingId = viewReciprocalRatings.listingId AND Booking.startDate = viewReciprocalRatings.startDate
GROUP BY travelerId;

-- Create a view to hold the count of backscratch ratings.
CREATE VIEW viewTotalBackScratches AS
SELECT travelerID, count(difference) AS backScratches
FROM Booking JOIN viewReciprocalRatings ON Booking.listingId = viewReciprocalRatings.listingId AND Booking.startDate = viewReciprocalRatings.startDate
WHERE difference <= 1
GROUP BY travelerId;

-- Produce the Result Table.
SELECT Traveler.travelerID AS travelerID, coalesce(reciprocals, 0) AS reciprocals, coalesce(backScratches, 0) AS backScratches
FROM Traveler LEFT JOIN viewTotalReciprocals ON Traveler.travelerId = viewTotalReciprocals.travelerId LEFT JOIN viewTotalBackScratches ON Traveler.travelerID = viewTotalBackScratches.travelerID
ORDER BY coalesce(reciprocals, 0) DESC, coalesce(backScratches, 0) DESC;
