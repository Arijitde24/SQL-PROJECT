
SELECT * FROM music.album
SELECt * FROM music.artist
SELECt * FROM music.record_label
SELECT * FROM music.song


/*record_label.id → artist.record_label_id, artist.id → album.artist_id, album.id → song.album_id*/
---1. List all artists for each record label sorted by artis name

SELECT a.name AS Artist_Name,rl.name AS Record_Name FROM music.artist as a
INNER JOIN music.record_label as rl
ON rl.id = a.record_label_id
ORDER BY a.name ASC;

---2. List all which have no artist

SELECT rl.name AS Record_Name FROM music.artist as a
RIGHT JOIN music.record_label as rl
ON a.record_label_id = rl.id
WHERE a.name IS NULL;

---3.list the number of songs per artist

SELECT ar.name AS artist_name,COUNT(s.name) AS Number_of_songs FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
GROUP BY ar.name
ORDER By Number_of_songs DESC;

---4.which artist or artists have recorded most number of songs

WITH CTE AS(
SELECT ar.name AS artist_name,COUNT(s.name) AS Number_of_songs FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
GROUP BY ar.name
), CTE2 AS(
SELECT MAX(Number_of_songs) AS Max_songs FROM CTE
)
SELECT CTE.artist_name,CTE2.Max_songs FROM CTE2
INNER JOIN CTE ON CTE2.max_songs=CTE.Number_of_songs; 

---5.which artist or artists have recorded least number of songs

WITH CTE AS(
SELECT ar.name AS artist_name,COUNT(s.name) AS Number_of_songs FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
GROUP BY ar.name
), CTE2 AS(
SELECT MIN(Number_of_songs) AS Min_songs FROM CTE
)
SELECT CTE.artist_name,CTE2.Min_songs FROM CTE2
INNER JOIN CTE ON CTE2.Min_songs=CTE.Number_of_songs;


---6.How many artists have recorded least number of songs

WITH CTE AS(
SELECT ar.name AS artist_name,COUNT(s.name) AS Number_of_songs FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
GROUP BY ar.name
), CTE2 AS(
SELECT MIN(Number_of_songs) AS Min_songs FROM CTE
)
SELECT COUNT(CTE.artist_name) as [Artist with least songs] FROM CTE2
INNER JOIN CTE ON CTE2.Min_songs=CTE.Number_of_songs;

---7. Artists who recorded songs longer than 5min.

SELECT ar.name AS artist_name,COUNT(s.name) AS [artists with songs greater than 5min] FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
WHERE s.duration>5.00
GROUP BY ar.name
ORDER BY COUNT(s.name) DESC;

---8. for each artist and albums how many songs with songs smaller than 5

SELECT ar.name AS artist_name,al.name,COUNT(s.name) AS [artists with songs greater than 5min] FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
WHERE s.duration<5.00
GROUP BY ar.name,al.name
ORDER BY COUNT(s.name) DESC;

---9. In which year or years were the most number of songs recorded

WITH cte AS
		(SELECT al.year,COUNT(*) AS [songs released] FROM music.album AS al
INNER JOIN music.artist AS ar
ON ar.id = al.artist_id
INNER JOIN music.song AS s
ON s.album_id = al.id
GROUP BY al.year),
cte2 AS 
	(SELECT MAX([songs released]) As max_song_released FROM cte)
SELECT cte.year,cte2.max_song_released FROM cte
INNER JOIN cte2
ON cte2.max_song_released=cte.[songs released];

---10. list artist,song,year of the top 5 songs

WITH cte AS	
	(SELECT ar.name AS artist_name,s.name AS song_name,s.duration,ROW_NUMBER()OVER(ORDER BY s.duration DESC) AS rank 
	FROM music.album AS al
	INNER JOIN music.artist AS ar
	ON ar.id = al.artist_id
	INNER JOIN music.song AS s
	ON s.album_id = al.id)
SELECT * FROM cte
WHERE rank<=5
