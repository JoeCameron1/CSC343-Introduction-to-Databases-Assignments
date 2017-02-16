SET search_path TO bnb, public;

-- Bookings within current_date - startdate < 10
CREATE VIEW viewBookings10Years AS
SELECT travelerId, extract(YEAR FROM Booking.startdate) AS bookingYear
FROM Booking
WHERE (extract(YEAR FROM current_date) - extract(YEAR FROM Booking.startdate)) <= 10;

-- Requests within current_date - startdate < 10
CREATE VIEW viewBookingRequests10Years AS
SELECT travelerId, extract(YEAR FROM BookingRequest.startdate) AS requestYear
FROM BookingRequest
WHERE (extract(YEAR FROM current_date) - extract(YEAR FROM BookingRequest.startdate)) <= 10;

-- Traveller's bookings per year
CREATE VIEW viewBookingCount10Years AS
SELECT travelerId, bookingYear, count(*) AS numBooking
FROM viewBookings10Years
GROUP BY travelerId, bookingYear;

-- Traveller's requests per year
CREATE VIEW viewBookingRequestCount10Years AS
SELECT travelerId, requestYear, count(*) AS numRequests
FROM viewBookingRequests10Years
GROUP BY travelerId, requestYear;

-- Producing the useful information
CREATE VIEW viewHelperResult AS
SELECT DISTINCT viewBookingCount10Years.travelerId, viewBookingCount10Years.bookingYear, viewBookingRequestCount10Years.numRequests, viewBookingCount10Years.numBooking
FROM viewBookingCount10Years, viewBookingRequestCount10Years
WHERE viewBookingCount10Years.travelerId = viewBookingRequestCount10Years.travelerId AND viewBookingCount10Years.bookingYear = viewBookingRequestCount10Years.requestYear;

-- Produce the result table
SELECT Traveler.travelerId AS travelerId, Traveler.email AS email, coalesce(viewHelperResult.bookingYear, NULL) AS year, coalesce(viewHelperResult.numRequests, 0) AS numRequests, COALESCE(viewHelperResult.numBooking, 0) AS numBooking
FROM viewHelperResult RIGHT JOIN Traveler ON Traveler.travelerId = viewHelperResult.travelerId
ORDER BY year DESC;
