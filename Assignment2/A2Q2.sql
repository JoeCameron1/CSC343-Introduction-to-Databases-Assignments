SET search_path TO bnb, public;

-- Holds the 10 times average.
CREATE VIEW view10TimesAverage AS
SELECT cast (floor (cast (10 / sum(count) * 10 AS float)) AS int) AS average
FROM (SELECT count(requestId) FROM BookingRequest) AS numberOfBookingRequests;

-- Holds the travelers who have 10 times the average number of booking requests.
CREATE VIEW view10TimesTraveler AS
SELECT view10TimesAverage.average, bookingRequestsPerTraveler.travelerId, bookingRequestsPerTraveler.numberOfRequestsPerTraveler AS count
FROM view10TimesAverage, (SELECT travelerId, count(travelerId) AS numberOfRequestsPerTraveler FROM BookingRequest GROUP BY travelerId) AS bookingRequestsPerTraveler
WHERE bookingRequestsPerTraveler.numberOfRequestsPerTraveler >= view10TimesAverage.average;

-- Holds the travelers who have more than 10 times the avg booking requests
-- but have not booked.
CREATE VIEW view10TimesNoBooking AS
SELECT travelerId, count AS numRequests
FROM view10TimesTraveler
WHERE view10TimesTraveler.travelerId NOT IN (SELECT DISTINCT travelerID FROM Booking);

-- Holds the listingID, the city name and the travelerId
-- for every 10 times booking request.
CREATE VIEW viewCities AS
SELECT listingCity.listingId, listingCity.city, t.travelerId
FROM (SELECT listingId, city FROM Listing) AS listingCity, (SELECT BookingRequest.listingId, view10TimesNoBooking.travelerId FROM BookingRequest, view10TimesNoBooking WHERE BookingRequest.travelerId = view10TimesNoBooking.travelerId) AS t
WHERE listingCity.listingId = t.listingId;

-- Holds the count for cities.
CREATE VIEW viewCitiesCount AS
SELECT travelerid, city, count(*)
FROM viewCities
GROUP BY travelerid, city;

-- Holds the maximum requests for each traveler per city.
CREATE VIEW viewMaxRequestPerCity AS
SELECT cityCount.travelerid, cityCount.city
FROM viewCitiesCount AS cityCount
WHERE count = (SELECT max(count) FROM viewCitiesCount WHERE travelerid = cityCount.travelerid)
ORDER BY city;

-- Produces the result table.
SELECT view10TimesNoBooking.travelerId, concat(Traveler.firstname, ' ', Traveler.surname) AS name, coalesce(Traveler.email, 'unknown') AS email, maxReq.min AS mostRequestedCity, view10TimesNoBooking.numRequests
FROM view10TimesNoBooking, Traveler, (SELECT viewMaxRequestPerCity.travelerid, min(viewMaxRequestPerCity.city) FROM viewMaxRequestPerCity GROUP BY travelerId) AS maxReq
WHERE Traveler.travelerid = view10TimesNoBooking.travelerid and Traveler.travelerid = maxReq.travelerid
ORDER BY numRequests DESC, travelerId ASC;
