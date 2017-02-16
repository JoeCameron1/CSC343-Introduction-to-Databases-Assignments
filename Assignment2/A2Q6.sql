SET search_path TO bnb, public;

-- Create a view to hold all traveler requests.
CREATE VIEW viewRequests AS
SELECT travelerId, listingId
FROM BookingRequest
GROUP BY travelerId, listingId;

-- Create a view to hold all traveler bookings.
CREATE VIEW viewBookings AS
SELECT travelerId, listingId
FROM Booking
GROUP BY travelerId, listingId;

-- Create a view to hold travelers who have made a request but not booked,
-- and to hold travelers who have booked without making a request.
CREATE VIEW viewNotValid AS
((SELECT * FROM viewRequests) EXCEPT (SELECT * FROM viewBookings))
UNION
((SELECT * FROM viewBookings) EXCEPT (SELECT * FROM viewRequests));

-- Produce the Result Table.
SELECT Booking.travelerId AS travelerID, surname, count(DISTINCT listingId) AS numListings
FROM Booking LEFT JOIN Traveler ON Booking.travelerId = Traveler.travelerId
WHERE Booking.travelerId NOT IN (SELECT travelerId FROM viewNotValid)
GROUP BY Booking.travelerId, surname
ORDER BY Booking.travelerId ASC;
