
start D:\Desktop\2018-Fall\95703-F-Database\Assignment3\Comp_Loan_v3.txt
select table_name from user_tables;

set pagesize 500
set linesize 1000
set wrap on
set feedback on
set echo on
COLUMN VENDOR_NAME FORMAT A20
COLUMN Loc_Bldg FORMAT A10
COLUMN Loc_Room FORMAT A10
COLUMN Comp_ID FORMAT A10
COLUMN Comp_Name FORMAT A10

--1
--replace the oldest 3 computers(first 3 computers purchased)
SELECT * FROM 
(SELECT Comp_ID, Comp_Name, Purchase_Date, Purchase_Price, Item_ID, Location_ID, Loc_Bldg, Loc_Room, Vendor_Name, RANK() OVER(ORDER BY Purchase_Date)as rank
FROM COMPUTER JOIN LOCATION USING (Location_ID))
WHERE rank <=3;

--2
COLUMN ITEM_MANUF FORMAT A15
COLUMN ITEM_MODEL FORMAT A15

SELECT * FROM
(SELECT COMP_ID, Comp_Name, Item_Manuf, Item_Model,ROUND(TOTAL_DAYS_ON_LOAN) AS TOTAL_DAYS_ON_LOAN, RANK() OVER(ORDER BY TOTAL_DAYS_ON_LOAN DESC) as rank
FROM
(SELECT COMP_ID, Comp_Name, Item_Manuf, Item_Model,SUM(DAYS_ON_LOAN) AS TOTAL_DAYS_ON_LOAN
FROM(
SELECT COMP_ID, Comp_Name, Item_Manuf, Item_Model,SUM(Date_Returned-Start_Date) AS DAYS_ON_LOAN
FROM LOAN JOIN COMPUTER USING(COMP_ID)
JOIN ITEM USING (Item_ID)
WHERE Date_Returned IS NOT NULL
GROUP BY COMP_ID,Comp_Name, Item_Manuf, Item_Model
UNION
SELECT COMP_ID,Comp_Name, Item_Manuf, Item_Model,SYSDATE - Start_Date AS DAYS_ON_LOAN
FROM LOAN JOIN COMPUTER USING(COMP_ID)
JOIN ITEM USING (Item_ID)
WHERE Date_Returned IS NULL)
GROUP BY COMP_ID,Comp_Name, Item_Manuf, Item_Model))
WHERE rank <= 5;



--3
column COMMENTS format A98
select Comp_ID, Comp_Name,Comments
FROM COMPUTER JOIN ITEM USING (Item_ID)
WHERE REGEXP_LIKE (Comments,'[3]\.[3-9]');

--4
COLUMN St_LName FORMAT A10
COLUMN St_FName FORMAT A10
COLUMN St_FName FORMAT A10
SELECT st_id, St_LName, St_FName,NUMBER_OF_LOAN,DENSE_RANK() OVER(ORDER BY NUMBER_OF_LOAN DESC) AS NUMBER_OF_LOAN_RANK, ROUND(DAYS_OF_LOAN) AS DAYS_OF_LOAN,DENSE_RANK() OVER(ORDER BY DAYS_OF_LOAN DESC) AS DAYS_OF_LOAN_RANK
FROM
(SELECT st_id, St_LName, St_FName, COUNT(LOAN_ID) AS NUMBER_OF_LOAN, SUM(NVL(Date_Returned,SYSDATE)-Start_Date)AS DAYS_OF_LOAN
FROM STUDENT JOIN LOAN USING (St_ID)
GROUP BY st_id, St_LName, St_FName
UNION 
SELECT st_id, St_LName, St_FName,0,0
FROM STUDENT
WHERE st_id NOT IN (SELECT st_id FROM LOAN));


--5
COLUMN Comp_ID FORMAT A25
COLUMN Comp_Name FORMAT A25
SELECT st_id, St_LName, St_FName,Comp_ID, Comp_Name,ROUND(duration) AS duration
FROM(
SELECT st_id, St_LName, St_FName,Comp_ID, Comp_Name, duration,MAX(duration) OVER (partition by st_id) LONGEST
FROM(
SELECT st_id, St_LName, St_FName,Comp_ID, Comp_Name, NVL(Date_Returned-Start_Date,SYSDATE - Start_Date) as duration
FROM STUDENT JOIN LOAN USING (st_id)
JOIN COMPUTER USING (Comp_ID)))
WHERE duration = LONGEST
union
SELECT st_id, St_LName, St_FName,'N/A: Rent No Computer','N/A: Rent No Computer',0
FROM STUDENT 
WHERE st_id NOT IN (SELECT st_id FROM LOAN)
ORDER BY duration DESC;


--6
SELECT Comp_ID,comp_name,St_ID,St_LName, St_FName,DAYS_SINCE_STARTED,NUMBER_OF_TIMES_RENTED
FROM
(SELECT St_ID,St_LName, St_FName,Comp_ID,comp_name,ROUND(SYSDATE-Start_Date) AS DAYS_SINCE_STARTED
FROM STUDENT JOIN LOAN USING (St_ID)
JOIN COMPUTER USING (COMP_ID)
WHERE Date_Returned IS NULL)
JOIN
(SELECT COMP_ID,COUNT(Loan_ID) AS NUMBER_OF_TIMES_RENTED
FROM LOAN
WHERE COMP_ID IN(
SELECT COMP_ID
FROM LOAN
WHERE Date_Returned IS NULL)
GROUP BY COMP_ID) USING (COMP_ID)
ORDER BY DAYS_SINCE_STARTED DESC;

--7
 -- NEVER ON LOAN
SELECT COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME, ROUND(SYSDATE - PURCHASE_DATE) AS AVG_downtime
FROM COMPUTER LEFT OUTER JOIN LOAN USING (COMP_ID) 
WHERE LOAN_ID IS NULL
UNION
--CURRENLY ON LOAN:
SELECT COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME, ROUND(AVG(START_DATE-LAST_RETURN)) AS AVG_downtime
FROM(
SELECT COMP_ID, COMP_NAME, PURCHASE_DATE, PURCHASE_PRICE, ITEM_ID, VENDOR_NAME, LOAN_ID, ST_ID, START_DATE, DATE_RETURNED, 
LAG(Date_Returned,1,PURCHASE_DATE) OVER (PARTITION BY Comp_ID ORDER BY Start_Date) AS LAST_RETURN
FROM COMPUTER JOIN LOAN USING (COMP_ID) 
ORDER BY Comp_ID,Start_Date)
WHERE Comp_ID IN (SELECT Comp_ID FROM LOAN WHERE DATE_RETURNED IS NULL)
GROUP BY COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME
--ON LOAN BEFORE BUT CURRENLY NOT ON LOAN:
UNION
SELECT COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME, ROUND(AVG(DOWNTIME)) AS AVG_downtime
FROM(
SELECT COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME, START_DATE - LAST_RETURN AS DOWNTIME
FROM
(SELECT COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME, START_DATE, DATE_RETURNED,
LAG(Date_Returned,1,PURCHASE_DATE) OVER (PARTITION BY Comp_ID ORDER BY Start_Date) AS LAST_RETURN
FROM COMPUTER JOIN LOAN USING (COMP_ID) 
WHERE Comp_ID NOT IN (SELECT Comp_ID FROM LOAN WHERE DATE_RETURNED IS NULL))
UNION 
SELECT DISTINCT COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME,SYSDATE - MAX(DATE_RETURNED) AS DOWNTIME
FROM COMPUTER JOIN LOAN USING (COMP_ID) 
WHERE Comp_ID NOT IN (SELECT Comp_ID FROM LOAN WHERE DATE_RETURNED IS NULL)
GROUP BY COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME)
GROUP BY COMP_ID, COMP_NAME, PURCHASE_DATE, ITEM_ID, VENDOR_NAME;



--Bonus
--DEFINE SEMESTER: 
--SEMESTER 1: JANUARY TO APRIL
--SEMESTER 2: MAY TO AUGUST
--SEMESTER 3: SEPTEMBER TO DECEMBER
COLUMN NUMBER_OF_LOANS_INITIATED FORMAT A30
SELECT decode(SEMESTER_PROGRAM,'SEMESTER','PROGRAM_TOTAL',SEMESTER_PROGRAM) AS NUMBER_OF_LOANS_INITIATED, COMPFIN, HNZECON, HNZIS, COMPFIN+HNZECON+HNZIS AS SEMESTER_TOTAL
FROM
(SELECT NVL('SEMESTER'||semester, 'Program_Total') AS SEMESTER_PROGRAM,
sum(decode(TRIM(Prog_ID),'COMPFIN',NUMBER_OF_LOAN,0)) as "COMPFIN",
sum(decode(TRIM(Prog_ID),'HNZECON',NUMBER_OF_LOAN,0)) as "HNZECON",
sum(decode(TRIM(Prog_ID),'HNZIS',NUMBER_OF_LOAN,0)) as "HNZIS"
FROM 
(SELECT B.Prog_ID, B.semester,count(Loan_ID) AS NUMBER_OF_LOAN
FROM
(SELECT Loan_ID,Prog_ID,semester
FROM
(SELECT Loan_ID, St_ID,Prog_ID, Comp_ID,
	   CASE WHEN EXTRACT(YEAR FROM Start_Date) = EXTRACT(YEAR FROM SYSDATE)-1 AND EXTRACT(MONTH FROM Start_Date) BETWEEN 1 AND 4 THEN 1
			WHEN EXTRACT(YEAR FROM Start_Date) = EXTRACT(YEAR FROM SYSDATE)-1 AND EXTRACT(MONTH FROM Start_Date) BETWEEN 5 AND 8 THEN 2
			WHEN EXTRACT(YEAR FROM Start_Date) = EXTRACT(YEAR FROM SYSDATE)-1 AND EXTRACT(MONTH FROM Start_Date) BETWEEN 9 AND 12 THEN 3
			END AS semester
FROM LOAN JOIN STUDENT USING (St_ID)
		  JOIN PROGRAM USING (Prog_ID))
WHERE semester IS NOT NULL) A RIGHT OUTER JOIN (SELECT semester,Prog_ID from(SELECT 0+level as semester FROM dual CONNECT BY level <= 3), PROGRAM) B ON A.semester = B.semester AND A.Prog_ID = B.Prog_ID
GROUP BY GROUPING SETS((B.Prog_ID, B.semester))
ORDER BY B.Prog_ID, B.semester)
GROUP BY GROUPING SETS (semester,()));
