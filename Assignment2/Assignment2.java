import java.sql.*;
import java.util.Date;

// If you are looking for Java data structures, these are highly useful.
// Remember that an important part of your mark is for doing as much in SQL (not Java) as you can.
// Solutions that use only or mostly Java will not received a high mark.  
import java.util.ArrayList; 
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to bnb.
   *
   * @param  url       the URL for the database
   * @param  username  the user-name to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
	   
	  try {
		  //Establishing connection with database
		  //Passing through URL, user-name and password
		  this.connection = DriverManager.getConnection(URL,username,password);
		  //PreparedStatement
		  PreparedStatement execStat = this.connection.prepareStatement("SET search_path TO bnb, public;");
		  execStat.execute();
		  return true;
	  } catch (SQLException se) {
          System.err.println("SQL Exception." +
                  "<Message>: " + se.getMessage());
          return false;
      }
	  
   }
   
  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
	   
	   //Release the connection's object database and JDBC
	   try {
		   this.connection.close();
		   //connection returns void
		   return true;
	   } catch (SQLException se) {
		   System.err.println("SQL Exception." +
	               "<Message>: " + se.getMessage());
		   return false;
	   }
	   
   }

   /**
    * Returns the 10 most similar homeowners based on traveller reviews. 
    *
    * Does so by using Cosine Similarity: the dot product between the columns
    * representing different homeowners. If there is a tie for the 10th 
    * homeowner (only the 10th), more than 10 records may be returned. 
    *
    * @param  homeownerID   id of the homeowner
    * @return               a list of the 10 most similar homeowners
    */
   public ArrayList homeownerRecommendation(int homeownerID) {
	   
	   String viewTravelerOwnerMatrix = "CREATE VIEW viewTravelerOwnerMatrix AS "
		  		+ "SELECT travelerId, homeownerId "
		  		+ "FROM Traveler, Homeowner;";
		PreparedStatement statementViewTravelerOwnerMatrix;
		try {
			statementViewTravelerOwnerMatrix = this.connection.prepareStatement(viewTravelerOwnerMatrix);
			statementViewTravelerOwnerMatrix.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}

		  
		String viewTravelerOwnerRating = "CREATE VIEW viewTravelerOwnerRating AS "
		  		+ "SELECT travelerId, owner AS homeownerId, rating "
		  		+ "FROM TravelerRating JOIN Booking ON TravelerRating.listingId = Booking.listingId AND TravelerRating.startdate = Booking.startdate JOIN Listing ON TravelerRating.listingId = Listing.listingId;";
		PreparedStatement statementViewTravelerOwnerRating;
		try {
			statementViewTravelerOwnerRating = this.connection.prepareStatement(viewTravelerOwnerRating);
			statementViewTravelerOwnerRating.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		  
		String viewUtilityMatrix = "CREATE VIEW viewUtilityMatrix AS "
		  		+ "SELECT viewTravelerOwnerMatrix.travelerId, viewTravelerOwnerMatrix.homeownerId, (SELECT avg(rating) AS Average FROM viewTravelerOwnerRating WHERE travelerId = viewTravelerOwnerMatrix.travelerId AND homeownerId = viewTravelerOwnerMatrix.homeownerId GROUP BY travelerId, homeownerId) AS averageRating "
		  		+ "FROM viewTravelerOwnerMatrix;";
		PreparedStatement statementViewUtilityMatrix;
		try {
			statementViewUtilityMatrix = this.connection.prepareStatement(viewUtilityMatrix);
			statementViewUtilityMatrix.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		   
		String viewUtilityMatrixDotProduct = "CREATE VIEW viewUtilityMatrixDotProduct AS "
		  		+ "SELECT homeownerId, (coalesce(averageRating, 0) * (SELECT averageRating FROM viewUtilityMatrix WHERE travelerId = UM.travelerId AND homeownerId = " + homeownerID + ") ) AS dotProduct "
		  		+ "FROM viewUtilityMatrix UM "
		  		+ "WHERE homeownerId <> " + homeownerID + ";";
		PreparedStatement statementViewUtilityMatrixDotProduct;
		try {
			statementViewUtilityMatrixDotProduct = this.connection.prepareStatement(viewUtilityMatrixDotProduct);
			statementViewUtilityMatrixDotProduct.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}

		  
		String viewCosineSimilarity = "CREATE VIEW viewCosineSimilarity AS "
		  		+ "SELECT homeownerId, sum(dotProduct) AS score "
		  		+ "FROM viewUtilityMatrixDotProduct "
		  		+ "GROUP BY homeownerId "
		  		+ "ORDER BY score DESC;";
		PreparedStatement statementViewCosineSimilarity;
		try {
			statementViewCosineSimilarity = this.connection.prepareStatement(viewCosineSimilarity);
			statementViewCosineSimilarity.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		  
		String viewTen = "CREATE VIEW viewTen AS "
		  		+ "SELECT homeownerId, score "
		  		+ "FROM viewCosineSimilarity "
				+ "WHERE score > 0 "
		  		+ "LIMIT 10;";
		PreparedStatement statementViewTen;
		try {
			statementViewTen = this.connection.prepareStatement(viewTen);
			statementViewTen.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		  
		String viewTie = "CREATE VIEW viewTie AS "
		  		+ "SELECT homeownerId, score "
		  		+ "FROM viewCosineSimilarity "
		  		+ "WHERE score = (SELECT score FROM viewTen ORDER BY score ASC LIMIT 1);";
		PreparedStatement statementViewTie;
		try {
			statementViewTie = this.connection.prepareStatement(viewTie);
			statementViewTie.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
		/*
		String viewTenResult = "CREATE VIEW viewTenResult AS "
		  		+ "SELECT homeownerId, score "
		  		+ "FROM viewTen;";
		PreparedStatement statementViewTenResult;
		try {
			statementViewTenResult = this.connection.prepareStatement(viewTenResult);
			statementViewTenResult.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
		String viewTieResult = "CREATE VIEW viewTieResult AS "
		  		+ "SELECT homeownerId, score "
		  		+ "FROM viewTie;";
		PreparedStatement statementViewTieResult;
		try {
			statementViewTieResult = this.connection.prepareStatement(viewTieResult);
			statementViewTieResult.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		*/
		  
		String queryForResult = "SELECT homeownerId, score "
		  		+ "FROM ((SELECT homeownerId, score FROM viewTen) UNION (SELECT homeownerId, score FROM viewTie)) result "
		  		+ "ORDER BY score DESC, homeownerId ASC;";
		PreparedStatement resultQuery;
		try {
			resultQuery = this.connection.prepareStatement(queryForResult);
			ResultSet resultSet = resultQuery.executeQuery();
			ArrayList<Integer> ten = new ArrayList<Integer>();
			while (resultSet.next()) {
				ten.add(resultSet.getInt(1));
			}
			return ten;
		} catch (SQLException e) {
			e.printStackTrace();
			return new ArrayList<Integer>();
		}
	    
   }

   /**
    * Records the fact that a booking request has been accepted by a 
    * homeowner. 
    *
    * If a booking request was made and the corresponding booking has not been
    * recorded, records it by adding a row to the Booking table, and returns 
    * true. Otherwise, returns false. 
    *
    * @param  requestID  id of the booking request
    * @param  start      start date for the booking
    * @param  numNights  number of nights booked
    * @param  price      amount paid to the home owner
    * @return            true if the operation was successful, false otherwise
    */
   public boolean booking(int requestId, Date start, int numNights, int price) {
	   
	   try {
		 //Check booking with placeholder for requestID
		   //BookingRequests(requestID,travelerID,listingID,start date,numNights,numGuests,offerPrice)
		   PreparedStatement check_request = connection.prepareStatement("SELECT startdate, listingId, travelerID, numGuests FROM BookingRequest WHERE requestId = ?;");
		   //Fill in placeholder
		   check_request.setInt(1, requestId);
		   //run query
		   ResultSet results = check_request.executeQuery();
		   //If the request exists, we insert the 
		   if (!results.next()) {
			   return false;   
		   }
		   else {
			   // Does the booking exist?
			   java.sql.Date date = results.getDate(1);
			   int listingId = results.getInt(2);
			   int travelerId = results.getInt(3);
			   int numGuests = results.getInt(4);
		       // Finds if corresponding booking already exists in Booking.
		       PreparedStatement statementExist = this.connection.prepareStatement("SELECT * FROM Booking WHERE listingId = ? AND startdate = ?;");
		       statementExist.setInt(1, listingId);
		       statementExist.setDate(2, date);
		          
		       ResultSet resultExist = statementExist.executeQuery();
		       
		       if (resultExist.next()) {
		    	   return false;
		       } else {
		    	   //set place-holders
				   //Booking(listingID, start date, travelerID, numNights, numGuests, price)
				   PreparedStatement place_booking = connection.prepareStatement("INSERT INTO Booking VALUES (?,?,?,?,?,?);"); 
				   //Fill in place-holders
				   place_booking.setInt(1,listingId);
				   place_booking.setDate(2, new java.sql.Date(start.getTime()));
				   place_booking.setInt(3, travelerId);
				   place_booking.setInt(4, numNights);
				   place_booking.setInt(5, numGuests);
				   place_booking.setInt(6, price);
				   //run update on insert booking
				   place_booking.executeUpdate();
				   return true;
		       }
		       
		   }
		   
	   } catch (SQLException se) {
		   System.err.println("SQL Exception." +
	               "<Message>: " + se.getMessage());
		   return false; 
	   }
	   
   }

   public static void main(String[] args) {
      
   }

}
