create database project;
use project1;

-- sheet 1
-- Import table from sheet 1- customer income status
select * from customer_income;
select count(*) from customer_income;

-- set customer criteria based on applicant income
/* • Applicant income >15,000 = grade a
   • Applicant income >9,000 = grade b
   • Applicant income >5000 = middle class customer
   •  Otherwise low class
	(Create this as new table)*/

create table Pro
select *, case
when Applicant_income > 15000 then "Grade A"
when Applicant_income > 9000 then "Grade B"
when Applicant_income > 5000 then "Middle_class_customer"
else "Low class"
end as Grades
from customer_income;
select * from Pro;

-- Monthly interest percentage 
/* • Applicant income <5000 rural=3%
   • Applicant income <5000 semi rural=3.5%
   • Applicant income <5000 urban=5%
   • Applicant income <5000 semi urban= 2.5%
	Otherwise =7% */

create table Pro1
select *,case
when Applicant_income <5000 then
case
when Property_Area = "rural" then 3
when Property_Area = "semi_rural" then 3.5
when Property_Area = "urban" then 5
when Property_Area = "semi urban" then 2.5
else 7 
end 
end as int_per 
from customer_income;
select * from Pro1;

-- Sheet 2 
-- loan status
select * from loan_status;
select count(*) from loan_status;

-- Primary Table
create table loan_status_copy 
(loan_id varchar(50), customer_id varchar(50), loan_amount varchar(50), loan_amount_term int, cibil_score int,
primary key (loan_id));

-- Secondary Table
create table loan_remark (
Loan_id varchar(50),Loan_amount varchar(50),Cibil_Score int,Cibil_Score_status varchar (50),
primary key (loan_id));

-- • Create row level trigger for loan amt 
/* Criteria
•	Loan amt null = loan still processing
•	Create statement level trigger for cibil score */

delimiter //
create trigger Cibil_score before insert on
loan_status_copy for each row
begin
if new.Loan_amount is null then set new.Loan_amount = "Loan is still processing";
end if ;
insert into loan_remark (loan_id,loan_amount,cibil_score,cibil_score_status)
values (new.loan_id,new.loan_amount,new.cibil_score,
case
when new.cibil_score > 900 then "High cibil score"
when new.cibil_score > 750 then "no penalty"
when new.cibil_score > 0 then "Penalty customers"
else "Loan cannot apply"
end );
end //
delimiter ;
drop trigger Cibil_score;

insert into loan_status_copy select * from Loan_status;

select  * from loan_status_copy;
desc loan_status_copy;
select * from loan_remark;

-- Then delete the reject and loan still processing customers
delete from loan_remark where loan_amount = "Loan is still processing" or 
Cibil_Score_status = "loan cannot apply";

-- Update loan as integers
alter table loan_remark modify loan_amount int;


/*Create all the above fields as a table 
Table name - loan cibil score status details*/
alter table loan_remark rename loan_cibil_score_status_details;

select * from loan_cibil_score_status_details;

-- New field creation based on interest
-- • Calculate monthly interest amt and annual interest amt based on loan amt

CREATE TABLE Amount
AS 
SELECT p.*, l.loan_amount, l.cibil_score, l.cibil_score_status 
FROM pro1 p 
INNER JOIN loan_cibil_score_status_details l 
ON p.loan_id = l.loan_id;

select * from Amount;

CREATE TABLE customer_interest_analysis 
AS 
SELECT loan_id, loan_amount, int_per, 
       ROUND((int_per / 100) * loan_amount, 0) AS monthly_int, 
       ROUND(((int_per / 100) * loan_amount) * 12, 0) AS annual_int 
FROM Amount;

/*• Create all the above fields as a table 
Table name - customer interest analysis
(create this into a new table and connect with sheet 2 (loan status) bring the output)*/

select * from customer_interest_analysis;

select l.*,int_per,monthly_int,annual_int from loan_cibil_score_status_details l join customer_interest_analysis c on l.loan_id = c.loan_id;
create table PL select l.*,int_per,monthly_int,annual_int from loan_cibil_score_status_details l join customer_interest_analysis c on l.loan_id = c.loan_id;
select * from PL;
-- Sheet 3 
-- customer info
select * from customer_det;

update customer_det  
set gender =
case
when customer_id = 'IP43006' then 'female'
when customer_id = 'IP43016' then 'female'
when customer_id = 'IP43018' then 'male'
when customer_id = 'IP43038' then 'male'
when customer_id = 'IP43508' then 'female'
when customer_id = 'IP43577' then 'female'
when customer_id = 'IP43589' then 'female'
when customer_id = 'IP43593' then 'female'
else gender
end ,
age = case
when customer_id ='IP43007' then 45
when customer_id ='IP43009'	then 32
else age
end;

-- Sheet 4 and 5- country state and region
-- Join all the 5 tables without repeating the fields - output 1 
SELECT c.*, 
       A.applicant_income, A.coapplican_income, A.property_area, A.loan_status, 
       A.int_per, A.loan_amount, A.cibil_score, A.cibil_score_status, 
       s.postal_code, s.segment, s.state, 
       i.monthly_int, i.annual_int, 
       r.region 
FROM customer_det c 
INNER JOIN Amount A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id;

select*from customer_det;
select * from Amount;

-- output 2

 -- Filter high cibil score - output 3
SELECT c.*, 
       A.applicant_income, A.coapplican_income, A.property_area, A.loan_status, 
       A.int_per, A.loan_amount, A.cibil_score, A.cibil_score_status, 
       s.postal_code, s.segment, s.state, 
       i.monthly_int, i.annual_int, 
       r.region 
FROM customer_det c 
INNER JOIN Amount A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id
order by a.cibil_score desc limit 1;

-- Filter home office and corporate - output 4
SELECT c.*, 
       A.applicant_income, A.coapplican_income, A.property_area, A.loan_status, 
       A.int_per, A.loan_amount, A.cibil_score, A.cibil_score_status, 
       s.postal_code, s.segment, s.state, 
       i.monthly_int, i.annual_int, 
       r.region 
FROM customer_det c 
INNER JOIN Amount A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id
where s.segment in ('home office','corporate');

-- Store all the outputs as procedure
delimiter // 
create procedure final_output()
begin
SELECT c.*, 
       A.applicant_income, A.coapplican_income, A.property_area, A.loan_status, 
       A.int_per, A.loan_amount, A.cibil_score, A.cibil_score_status, 
       s.postal_code, s.segment, s.state, 
       i.monthly_int, i.annual_int, 
       r.region 
FROM customer_det c 
INNER JOIN Amount A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id;

SELECT c.*, 
       A.applicant_income, A.coapplican_income, A.property_area, A.loan_status, 
       A.int_per, A.loan_amount, A.cibil_score, A.cibil_score_status, 
       s.postal_code, s.segment, s.state, 
       i.monthly_int, i.annual_int, 
       r.region 
FROM customer_det c 
INNER JOIN Amount A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id
order by a.cibil_score desc limit 1;

SELECT c.*, 
       A.applicant_income, A.coapplican_income, A.property_area, A.loan_status, 
       A.int_per, A.loan_amount, A.cibil_score, A.cibil_score_status, 
       s.postal_code, s.segment, s.state, 
       i.monthly_int, i.annual_int, 
       r.region 
FROM customer_det c 
INNER JOIN Amount A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id
where s.segment in ('home office','corporate');
end //
delimiter // 

call final_output();

