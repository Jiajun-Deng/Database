alter table PAYMENT ADD PayDate Date;

alter table RECORD_INFO
DROP Column PayDate;

DROP TABLE RECORDING;

DROP TABLE PAYMENT;

CREATE TABLE RECORDING
(       Tran_id     char(8)    not null,
        Recep_id    char(4)    not null,
        primary key(Tran_id, Recep_id),
        foreign key (Recep_id) references RECEPTIONIST (Id) on delete set null,
        foreign key(Tran_id) references PAYMENT(Tran_id) on delete set null
);

CREATE TABLE PAYMENT
(       Tran_id     char(8)    not null,
        PayDate     date,
        Amt_due	    varchar(20),
        C_flag      int         not null,
        I_flag      int         not null,
        CashAmt     varchar(20),
        InsId       varchar(10),
        Coverage    varchar(20),
        InsAmt      varchar(20),
        P1_id       char(4),
        primary key(Tran_id),
        foreign key(P1_id) references CLASS1_PATIENT(P1_id) on delete set null
);
/*insert states into PAYMENT*/
insert into PAYMENT values('00000001', TO_DATE('2018-08-10'),'1000','1','0','1000','100','300','0','P105');

/*insert states into insurance*/
insert into INSURANCE values('100','BCBS');
insert into INSURANCE values('101','VPS');
insert into INSURANCE values('102','WDS');
insert into INSURANCE values('103','BKS');
insert into INSURANCE values('104','DGE');
insert into INSURANCE values('105','ADS');
insert into INSURANCE values('106','PPS');
insert into INSURANCE values('107','WES');
insert into INSURANCE values('108','BAD');
insert into INSURANCE values('109','NNBS');
insert into INSURANCE values('110','EEGE');

/*MAINTAINS*/

/*RECORD_INFO*/

/*RECORDING*/

SET DEFINE OFF;
Insert into RECORDING values ('10000001','P104');
Insert into RECORDING values ('11111111','P104');
Insert into RECORDING values ('30000001','P104');
Insert into RECORDING values  ('50034011','P104');
Insert into RECORDING values ('50034012','P104');
Insert into RECORDING values  ('66457789','P104');
Insert into RECORDING values ('66457723','P104');
Insert into RECORDING values ('66457724','P104');
Insert into RECORDING values  ('66457725','P104');
Insert into RECORDING values  ('66457726','P104');
Insert into RECORDING values  ('66457727','P104');
Insert into RECORDING values  ('66457728','P104');
Insert into RECORDING values ('66457729','P104');
Insert into RECORDING values  ('64577309','P104');
Insert into RECORDING values  ('66457731','P104');
Insert into RECORDING values ('66457732','P104');
Insert into RECORDING values  ('66457733','P104');
Insert into RECORDING values ('66457734','P104');
Insert into RECORDING values ('66457735','P104');
Insert into RECORDING values ('66457736','P104');
Insert into RECORDING values ('66457737','P104');
Insert into RECORDING values ('66457738','P104');

/*CREATE VIEWS*/


/*1. topDoctor view 1,2*/
CREATE VIEW TopDocId(Doc_id) AS
(               SELECT P1.Doc_id
                FROM CLASS1_PATIENT P1
                GROUP BY P1.Doc_id
                HAVING COUNT(P1.P1_id) > 5
            )
        INTERSECT
        (       SELECT A.Doc_id
                FROM ATTENDS A
                GROUP BY A.Doc_id
                HAVING COUNT(A.P2_id) > 10
            );
        
CREATE VIEW TopDoctor(Fname, Lname, Startdate) AS
    SELECT P.Fname, P.Lname, E.Startdate
    FROM PERSON P, EMPLOYEE E, TopDocId T
    WHERE E.Id = P.Id
    AND     E.Id = T.Doc_id;
    
select *
from TopDoctor;

/*2. TopTreatment view*/
CREATE VIEW TopTreatment(Tname, PayAmt) AS
        SELECT T1.Tname, P.Amt_due
        FROM TREATMENT T1, TREATING T2, PAYMENT P
        WHERE P.P1_id = T2.P2_id
            and T1.Tcode = T2.Tcode
            and T2.Tcode IN
                (SELECT T3.Tcode
                FROM TREATING T3
                GROUP BY T3.Tcode
                ORDER BY COUNT(*) DESC
                FETCH FIRST 1 ROW ONLY
                );
                
/*3. RecorderMeds*/

CREATE VIEW RecorderMeds (Mcode) AS
    (SELECT P.Mcode
    FROM PHARMACY P
    WHERE P.Expir_date <= sysdate + 31)/**/
UNION
    (SELECT P1.Mcode
    FROM PHARMACY P1
    WHERE P1.Qty < 1000);

/*4. PotentialPatient view*/
CREATE VIEW PotentialPatientID(Pid) AS
        SELECT P1_id
        FROM   RECORD_INFO
        WHERE P1_id
        NOT IN
                (SELECT P2_id
                 FROM CLASS2_PATIENT)
                 GROUP BY P1_id
                 HAVING COUNT(Record#)>3;
                 
CREATE VIEW PotentialPatient(Fname, Lname, Phone, Pid) AS
        SELECT  P.Fname, P.Lname, PC.Phone, P1.Pid
        FROM PERSON P, PERSON_CONTACT PC, PotentialPatientID P1
        WHERE P.Id = PC.Id
        AND	P.Id = P1.Pid;
        
/*5. MostFrequentIssues*/

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

/*F. SQL QUERIES*/
/*1. For each Doctor class, list the start date and specialization of the doctor.*/
SELECT D.Dtype, D.SPECIALIZATION, E.STARTDATE
FROM EMPLOYEE E, DOCTOR D
WHERE E.ID = D.ID
ORDER BY DTYPE;

/*2. Find the names of employees who have been admitted to the hospital within 3 
months of joining*/
SELECT P.Fname, P.Lname
FROM PERSON P, EMPLOYEE E, CLASS2_PATIENT P2
WHERE months_between(P2.ADMT_DATE, E.STARTDATE) <= 3
AND P.ID = E.ID
AND E.ID = p2.EMP_id;

/*3. Find the average age and class (trainee, visiting or permanent) of top 5 doctors 
in the hospital.*/
SELECT AVG(trunc(months_between(sysdate,P.Dob)/12)) AS AVG_AGE
FROM PERSON P,TopDocID T
WHERE P.ID = T.DOC_ID;

SELECT DTYPE
FROM DOCTOR, TopDocID
WHERE ID = DOC_ID;

/*4. Find the name of medicines associated with the most common treatment in the hospital.*/
SELECT P.Mname, T3.Tname
FROM TopTreatmentID T1, TREATING T2, Treatment T3, PHARMACY P
WHERE T1.Tcode = T3.Tcode
AND T2.Tcode = T3.Tcode
AND T2.Mcode = P.Mcode
FETCH FIRST 1 ROW ONLY;

/*5. Find all the doctors who have not had a patient in the last 5 months. (Hint:
Consider the date of payment as the day the doctor has attended a patient/been
consulted by a patient*/
SELECT D.ID
FROM DOCTOR D
WHERE D.id not in
(   (SELECT DISTINCT C1.doc_id
     FROM PAYMENT A, CLASS1_PATIENT C1
     WHERE C1.P1_id = A.P1_id
     AND months_between(sysdate, A.PAYDATE)<= 5)
    UNION
    (SELECT DISTINCT AT.doc_id
    FROM PAYMENT B, ATTENDS AT
    WHERE B.P1_ID = AT.P2_ID
    AND months_between(sysdate, B.PAYDATE)<=5)
)

/*6.  Find the total number of patients who have paid completely using insurance
and the name of the insurance provider.*/
SELECT COUNT(P.P1_ID), I.Provider
FROM PAYMENT P, INSURANCE I
WHERE P.C_FLAG = 0
AND P.I_FLAG = 1
AND P.INSID = I.INSID
GROUP BY I.PROVIDER;

/*7. Find the most occupied room in the hospital and the average duration of the stay.*/
SELECT RM#, COUNT(p2_id) AS Freq, AVG(Duration)
FROM CLASS2_PATIENT
GROUP BY RM#
ORDER BY Freq desc
FETCH FIRST 1 ROW ONLY;

/*8. Find the year with the maximum number of patient visiting the hospital and
the reason for their visit.*/
SELECT TO_CHAR(RDATE, 'YYYY'), DESCP
FROM RECORD_INFO
WHERE TO_CHAR(RDATE, 'YYYY') IN (
    SELECT TO_CHAR(RDATE, 'YYYY')
    FROM RECORD_INFO
    GROUP BY TO_CHAR(RDATE, 'YYYY')
    ORDER BY COUNT(RECORD#) DESC
    FETCH FIRST 1 ROW ONLY
    );
    
/*9. Find the duration of the treatment that is provided the least to patients*/
SELECT *
FROM  TREATMENT T
WHERE T.Duration IN
		(SELECT MIN(T.Duration) FROM TREATMENT T);
    
/*10. List the total number of patients that have been admitted to the hospital after
the most current employee has joined.*/
SELECT COUNT(P2_ID)
FROM CLASS2_PATIENT
WHERE ADMT_DATE >=
    (SELECT MAX(E.STARTDATE)
    FROM EMPLOYEE E);
        
/*11.  List all the patient records of those who have been admitted to the hospital
within a week of being consulted by a doctor*/
SELECT R.RECORD#, R.RDATE, R.APPT, R.DESCP, R.P1_ID
FROM RECORD_INFO R, CLASS2_PATIENT P
WHERE R.P1_ID = P.P2_ID
AND (P.ADMT_DATE - R.RDATE) <= 7;

/*12. Find the total amount paid by patients for each month in the year 2017*/
SELECT EXTRACT(MONTH FROM PAYDATE) AS MONTH, SUM(AMT_DUE) AS TOTAL_AMOUNT
FROM PAYMENT
WHERE TO_CHAR(PAYDATE, 'YYYY') = '2017'
GROUP BY EXTRACT(MONTH FROM PAYDATE);

/*13. Find the name of the doctors of patients who have visited the hospital only
once for consultation and have not been admitted to the hospital.*/
SELECT P.Fname, P.Lname
FROM PERSON P, CLASS1_PATIENT C
WHERE P.ID = C.DOC_ID
AND C.P1_ID IN
        (SELECT P1_ID 
        FROM RECORD_INFO
        WHERE P1_ID NOT IN
            (   SELECT P2_ID
                FROM CLASS2_PATIENT)
        GROUP BY P1_ID
        HAVING COUNT(RECORD#) = 1);
    
/*14. Find the name and age of the potential patients in the hospital. */
SELECT P.FNAME, P.MNAME, P.LNAME, TRUNC(MONTHS_BETWEEN(SYSDATE, P.DOB)/12) AGE
FROM PotentialPatient PP, PERSON P
WHERE PP.PID = P.ID;

