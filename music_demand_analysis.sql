-- Q1) Who is the senior most employee based on job title?
SELECT DISTINCT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2) Which country has the most invoices?
SELECT COUNT(*) AS C, billing_country FROM invoice
GROUP BY billing_country
ORDER BY C DESC;

-- Q3) What are the top 3 values of total invoice?
SELECT invoice_id, total FROM invoice
ORDER BY total DESC
LIMIT 3;

-- Q4) Which city has the best customers? We would like to throw a promotional music festival in that city. Write a query that returns one city that has the highest sum of invoice totals. Return city name and sum of all invoice totals.
SELECT billing_city, SUM(total) AS invoice_total FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC;

-- Q5) Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.
SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS invoice_total
FROM customer
JOIN invoice
	 ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY invoice_total DESC
LIMIT 1;

-- Q6) Write query to return the email, first name, last name, and Genre of all rock music listeners. Return your list ordered alphabetically by email starting with A.
SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice 
	 ON customer.customer_id = invoice.customer_id
JOIN invoice_line
     ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN 
                  (SELECT track_id 
                   FROM track
                   JOIN genre
                        ON track.genre_id = genre.genre_id
				   WHERE genre.name = 'ROCK')
ORDER BY email;

-- Q7) Let’s invite the artists who have written the most rock music in our dataset. Write a query that returns the artist name and total track count of the top 10 rock bands.
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS track_count
FROM artist
JOIN album
     ON artist.artist_id = album.artist_id
JOIN track
     ON track.album_id = album.album_id
JOIN genre
     ON track.genre_id = genre.genre_id
WHERE genre.name = 'ROCK'
GROUP BY artist.artist_id
ORDER BY track_count DESC 
LIMIT 5;

-- Q8) Return all the track names that have a song length longer than the average song length. Return the name and milliseconds for each track. Order by the song length with the longest songs listed first. 
SELECT name, milliseconds FROM musicstoreanalysis.track
WHERE milliseconds > (
					  SELECT avg(milliseconds) AS average_length
                      FROM track)
ORDER BY milliseconds DESC;

-- Q9) Find how much amount was spent by each customer on artists. Write a query to return customer name, artist name and total money spent. 
WITH best_selling_artist AS(
						 SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_revenue
                         FROM invoice_line
                         JOIN track
                              ON track.track_id = invoice_line.track_id
						 JOIN album
                              ON album.album_id = track.album_id
						 JOIN artist
                              ON artist.artist_id = album.artist_id
                         GROUP BY 1
                         ORDER BY 3 DESC
                         LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c
     ON c.customer_id = i.customer_id
JOIN invoice_line il
     ON i.invoice_id = il.invoice_id
JOIN track t
     ON t.track_id = il.track_id
JOIN album alb
     ON alb.album_id = t.album_id
JOIN best_selling_artist bsa
     ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Q10) We want to find out the most popular music genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top genre. For countries where the maximum number of purchases is shared, return all genres.
WITH popular_genre AS(
                   SELECT count(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
                   ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY count(invoice_line.quantity) DESC) AS RowNo
                   FROM invoice_line
                   JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
                   JOIN customer ON customer.customer_id = invoice.customer_id
                   JOIN track ON track.track_id = invoice_line.track_id
                   JOIN genre ON genre.genre_id = track.genre_id
                   GROUP BY 2,3,4
                   ORDER BY 2 ASC, 1 DESC
)
SELECT*FROM popular_genre WHERE RowNo <= 1;     

-- Q11) Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount is shared, provide all customers who spent this amount. 
WITH RECURSIVE customer_per_country AS( 
								    SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
                                    FROM invoice
                                    JOIN customer
                                                 ON customer.customer_id = invoice.customer_id
									GROUP BY 1,2,3,4
                                    ORDER BY 1,5 DESC),
                                    
				country_max_spending AS(
                                     SELECT billing_country, MAX(total_spending) AS max_spending
                                     FROM customer_per_country
                                     GROUP BY billing_country)
                                     
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id 
FROM customer_per_country cc
JOIN country_max_spending ms 
                            ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;