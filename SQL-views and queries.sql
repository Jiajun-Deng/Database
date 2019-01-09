/*e. Use the Create View statement to create the following views:
*/

/*TopDoctor- This view returns the First Name, Last Name and Date of Joining
of those doctors who have made more than 5 Class 1 patients and over 10
Class 2 patients.*/
/*TopDoctor*/
CREATE VIEW TopDocId(Doc_id) AS 
(
    SELECT P1.Doc_id
    FROM CLASS1_PATIENT P1
    GROUP BY P1.Doc_id
    HAVING COUNT(P1.P1_iD) > 5
)
INTERSECT
(
    SELECT A.Doc_id
    FROM ATTENDS A
    GROUP BY A.Doc_id
    HAVING COUNT(A.P2_id) > 10
);

CREATE VIEW TopDoctor(fName, lName, StartDate) AS 
(
    SELECT P.fName, P.lName, E.StartDate 
    FROM Person P, Employee E, TopDocID T
    WHERE E.ID = P.ID AND P.ID = T.Doc_id
);

/*TopTreatment- This view returns the treatment name of the most common
treatment in Dallas Care along with the bill payment amount when a person
receives that treatment*/
/*TopTreatment*/
CREATE VIEW TopTreatmentID(Tcode) AS
(
    SELECT TCODE
    FROM TREATING
    GROUP BY TCODE
    ORDER BY COUNT(P2_ID) DESC
    FETCH FIRST 1 ROW ONLY
);

CREATE VIEW TopTreatment(TNAME, AMT_DUE) AS
(
    SELECT TNAME, AMT_DUE
    FROM TopTreatmentID T1, TREATMENT T2, TREATING T3, PAYMENT P
    WHERE T1.Tcode = T2.Tcode AND T3.TCODE = T1.TCODE
    AND P.P1_ID = T3.P2_ID
);

/*ReorderMeds- This view returns the medicines that need to be reordered. A
medicine needs to be reordered if the expiration date is 1 month from current
date or quantity is less than 1000.*/
/*ReorderMeds*/
CREATE VIEW RecorderMeds(MCODE, MNAME) AS 
(
    SELECT MCODE, MNAME
    FROM PHARMACY
    WHERE QTY < 1000
)
UNION
(
    SELECT MCODE, MNAME
    FROM PHARMACY
    WHERE EXPIR_DATE <= sysdate + 31
);
/*PotentialPatient- This view returns the name, phone number and ID of patients
who visited the hospital more than 3 times as a Class 1 patient but has not
been admitted yet.*/
/*PotentialPatient*/
CREATE VIEW PotentialPatientID(P1_ID) AS 
(
    SELECT P1_ID
    FROM RECORD_INFO
    GROUP BY P1_ID
    HAVING COUNT(RECORD#) > 3
);

CREATE VIEW PotentialPatient(FNAME, LNAME, PHONE, ID) AS 
(
    SELECT P1.FNAME, P1.LNAME, C.PHONE, P1.ID
    FROM PERSON P1, PotentialPatientID P2, PERSON_CONTACT C
    WHERE P2.P1_ID = P1.ID AND C.ID = P1.ID
);

/*MostFrequentIssues - This view returns the maximum frequency of the reason
that patients visit the hospital for and the associated treatment for the same.
For example, if patients visit the hospital mostly complaining about heart
issues then what are the treatment associated with heart issues.*/
/*MostFrequentIssues*/
--DROP view MostFrequentIssues1;
CREATE VIEW MostFrequentIssues1(DESCP) AS (
    SELECT DESCP
    FROM RECORD_INFO
    GROUP BY DESCP
    ORDER BY COUNT(RECORD#) DESC
    FETCH FIRST 1 ROW ONLY
);

CREATE VIEW MostFrequentIssues(REASON, TCODE, TNAME) AS
(
    SELECT M.DESCP, T2.TCODE, T1.TNAME
    FROM MostFrequentIssues1 M, RECORD_INFO R, TREATMENT T1, TREATING T2
    WHERE M.DESCP = R.DESCP AND R.P1_ID = T2.P2_ID AND T2.TCODE = T1.TCODE
    FETCH FIRST 1 ROW ONLY
);

select *
from MostFrequentIssues;

drop view MostFrequentIssues;

/*f. Answer the following Queries. Feel free to use any of the views that you created in
part (e.):*/

/*1. For each Doctor class, list the start date and specialization of the doctor*/
SELECT D.Dtype, D.SPECIALIZATION, E.STARTDATE
FROM EMPLOYEE E, DOCTOR D
WHERE E.ID = D.ID
ORDER BY DTYPE;

/*2. Find the names of employees who have been admitted to the hospital within 3 months of joining.*/
SELECT P1.FNAME, P1.LNAME
FROM EMPLOYEE E, PERSON P1, CLASS2_PATIENT P2
WHERE P1.ID = E.ID AND P2.P2_ID = E.ID
AND months_between(ADMT_DATE, STARTDATE) <= 3;

/*3. Find the average age and class (trainee, visiting or permanent) of top 5 doctors
in the hospital.*/
SELECT AVG(trunc(months_between(sysdate,DOB)/12)) AS AVG_AVG_OF_TOP_DOCTORS
FROM TOPDOCID, PERSON
WHERE DOC_ID = ID;

SELECT DOC_ID, DTYPE
FROM DOCTOR, TOPDOCID
WHERE ID = DOC_ID;

/*4. Find the name of medicines associated with the most common treatment in the
hospital.*/
SELECT MNAME
FROM PHARMACY P, TREATING T1, TOPTREATMENTID T2
WHERE T2.TCODE = T1.TCODE AND T1.MCODE = P.MCODE
FETCH FIRST 1 ROW ONLY

/*5. Find all the doctors who have not had a patient in the last 5 months. (Hint:
Consider the date of payment as the day the doctor has attended a patient/been
consulted by a patient.*/

SELECT D.ID
FROM DOCTOR D
WHERE NOT EXISTS (
    (
        SELECT DISTINCT DOC_ID 
        FROM PAYMENT P,ATTENDS A
        WHERE P.P1_ID = A.P2_ID AND trunc(months_between(sysdate,P.PAYDATE))<=5 AND A.DOC_ID = D.ID
    )
    UNION
    (
        SELECT DISTINCT DOC_ID
        FROM PAYMENT P, CLASS1_PATIENT C
        WHERE P.P1_ID = C.P1_ID AND trunc(months_between(sysdate,P.PAYDATE))<=5 AND C.DOC_ID = D.ID
    )
);

/*6. Find the total number of patients who have paid completely using insurance
and the name of the insurance provider.*/
SELECT COUNT(P1_ID), I.PROVIDER 
FROM PAYMENT P, INSURANCE I
WHERE P.C_FLAG = 0 AND P.I_FLAG = 1 AND P.INSID = I.INSID
GROUP BY I.PROVIDER;

/*7. Find the most occupied room in the hospital and the average duration of the stay. */
SELECT RM# AS ROOM, COUNT(RM#) AS FREQUENCY, ROUND(AVG(DURATION))AS AVG_DURATION
FROM CLASS2_PATIENT
GROUP BY RM#
ORDER BY COUNT(RM#) DESC
FETCH FIRST 1 ROW ONLY;

/*8. Find the year with the maximum number of patient visiting the hospital and
the reason for their visit. */
SELECT DESCP
FROM RECORD_INFO WHERE TO_CHAR(RDATE, 'YYYY') = (
    SELECT TO_CHAR(RDATE, 'YYYY')
    FROM RECORD_INFO
    GROUP BY TO_CHAR(RDATE, 'YYYY')
    ORDER BY COUNT (*) DESC
    FETCH FIRST ROW ONLY
);

/*9. Find the duration of the treatment that is provided the least to patients.*/
SELECT *
FROM  TREATMENT T
WHERE T.Duration IN
		(SELECT MIN(T.Duration) FROM TREATMENT T);

/*10. List the total number of patients that have been admitted to the hospital after
the most current employee has joined.*/
SELECT COUNT(*)
FROM CLASS2_PATIENT 
WHERE ADMT_DATE >= (
	SELECT MAX(E.startdate) 
	FROM EMPLOYEE E
	);

/*11. List all the patient records of those who have been admitted to the hospital
within a week of being consulted by a doctor.*/
SELECT RECORD#, RDATE, APPT, DESCP, P1_ID
FROM (   
    SELECT R.RECORD#, R.RDATE, R.APPT, R.DESCP, R.P1_ID, 
        (TRUNC(C2.ADMT_DATE) -TRUNC( R.RDATE)) as ONEWEEK
    FROM RECORD_INFO R, CLASS2_PATIENT C2
    WHERE R.P1_ID = C2.P1_ID)
WHERE  ONEWEEK < 7;

/*12. Find the total amount paid by patients for each month in the year 2017.*/
SELECT EXTRACT(MONTH FROM PAYDATE) MONTH, SUM(AMT_DUE) TOTAL_AMOUNT
FROM (
    SELECT *
    FROM PAYMENT
    WHERE TO_CHAR(PAYDATE, 'YYYY') = 2017
)
GROUP BY EXTRACT(MONTH FROM PAYDATE);

/*13. Find the name of the doctors of patients who have visited the hospital only
once for consultation and have not been admitted to the hospital.*/
SELECT P.Fname, P.Lname
FROM PERSON P, CLASS1_PATIENT C
WHERE P.ID = C.DOC_ID
AND C.P1_ID IN
??????? ?????? (????? SELECT P1_ID 
??????? ????????????? FROM RECORD_INFO
?????? ???????? WHERE P1_ID NOT IN
??????????? ???????????????????? (????? SELECT P2_ID
??????????????? ???????????????????? FROM CLASS2_PATIENT)
????????????? GROUP BY P1_ID
????????????? HAVING COUNT(RECORD#) = 1);

/*14. Find the name and age of the potential patients in the hospital. */
SELECT P.FNAME, P.MNAME, P.LNAME, TRUNC(MONTHS_BETWEEN(SYSDATE, P.DOB)/12) AGE
FROM PotentialPatient POTP, PERSON P
WHERE POTP.ID = P.ID;



