/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

SELECT name FROM `Facilities` WHERE membercost > 0

Tennis Court 1
Tennis Court 2
Massage Room 1
Massage Room 2
Squash Court


/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(name) FROM `Facilities` WHERE membercost = 0

4

/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid,name,membercost,monthlymaintenance FROM `Facilities` WHERE guestcost < (monthlymaintenance * 0.2)

facid	name        	membercost	monthlymaintenance	
    0	Tennis Court 1	5.0     	200
    1	Tennis Court 2	5.0     	200
    4	Massage Room 1	9.9     	3000
    5	Massage Room 2	9.9     	3000

/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */

SELECT *
FROM `Facilities`
WHERE facid
IN ( 1, 5 )

facid 	name        	membercost 	guestcost 	initialoutlay 	monthlymaintenance
    1 	Tennis Court 2 	5.0     	25.0     	8000        	200
    5 	Massage Room 2 	9.9     	80.0     	4000        	3000


/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE
WHEN monthlymaintenance >100
THEN 'expensive'
ELSE 'cheap'
END
FROM `Facilities`

 name           	monthlymaintenance 	CASE WHEN monthlymaintenance >100 THEN 'expensive' ELSE 'cheap' END 	
Tennis Court 1     	200             	expensive
Tennis Court 2     	200             	expensive
Badminton Court   	50              	cheap
Table Tennis     	10              	cheap
Massage Room 1   	3000             	expensive
Massage Room 2   	3000             	expensive
Squash Court    	80              	cheap
Snooker Table    	15               	cheap
Pool Table      	15              	cheap


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM `Members`
WHERE joindate = (
SELECT max( joindate )
FROM Members ) 

firstname 	surname 	
Darren  	Smith

/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT CONCAT( Members.firstname, ' ', Members.surname ) AS membername, Facilities.name
FROM Bookings
JOIN Facilities ON Bookings.facid = Facilities.facid
JOIN Members ON Bookings.memid = Members.memid
WHERE Bookings.facid
IN ( 0, 1 )
ORDER BY membername



/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT Facilities.name, CONCAT( Members.firstname, ' ', Members.surname ) AS membername,
CASE WHEN Bookings.memid <>0
THEN Facilities.membercost * Bookings.slots
ELSE Facilities.guestcost * Bookings.slots
END AS cost
FROM Bookings
JOIN Facilities ON Bookings.facid = Facilities.facid
JOIN Members ON Bookings.memid = Members.memid
WHERE date( Bookings.starttime ) = '2012-09-14'
AND CASE WHEN Bookings.memid <>0
THEN Facilities.membercost * Bookings.slots
ELSE Facilities.guestcost * Bookings.slots
END >30
ORDER BY cost DESC

 name       	membername  	cost  	
Massage Room 2 	GUEST GUEST 	320.0
Massage Room 1 	GUEST GUEST 	160.0
Massage Room 1 	GUEST GUEST 	160.0
Massage Room 1 	GUEST GUEST 	160.0
Tennis Court 2 	GUEST GUEST 	150.0
Tennis Court 1 	GUEST GUEST 	75.0
Tennis Court 2 	GUEST GUEST 	75.0
Tennis Court 1 	GUEST GUEST 	75.0
Squash Court 	GUEST GUEST 	70.0
Massage Room 1 	Jemima Farrell 	39.6
Squash Court 	GUEST GUEST 	35.0
Squash Court 	GUEST GUEST 	35.0

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT name, membername, cost
FROM (

SELECT DISTINCT Facilities.name, CONCAT( Members.firstname, ' ', Members.surname ) AS membername, Facilities.membercost * Bookings.slots AS cost, Bookings.starttime
FROM Bookings
JOIN Facilities ON Bookings.facid = Facilities.facid
JOIN Members ON Bookings.memid = Members.memid
WHERE date( Bookings.starttime ) = '2012-09-14'
AND Bookings.memid <>0
AND Facilities.membercost * Bookings.slots >30
UNION
SELECT DISTINCT Facilities.name, CONCAT( Members.firstname, ' ', Members.surname ) AS membername, Facilities.guestcost * Bookings.slots AS cost, Bookings.starttime
FROM Bookings
JOIN Facilities ON Bookings.facid = Facilities.facid
JOIN Members ON Bookings.memid = Members.memid
WHERE date( Bookings.starttime ) = '2012-09-14'
AND Bookings.memid =0
AND Facilities.guestcost * Bookings.slots >30
)sub
ORDER BY cost DESC

/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT name, revenue
FROM (

SELECT Facilities.name, sum(
CASE WHEN Bookings.memid <>0
THEN Facilities.membercost * Bookings.slots
ELSE Facilities.guestcost * Bookings.slots
END ) AS revenue
FROM Bookings
JOIN Facilities ON Bookings.facid = Facilities.facid
GROUP BY Facilities.name
)sub
WHERE revenue <1000
ORDER BY revenue DESC

name        	revenue 
Pool Table  	270.0
Snooker Table 	240.0
Table Tennis 	180.0
    
    