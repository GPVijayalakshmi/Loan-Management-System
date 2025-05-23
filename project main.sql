create database loan_management_system;
use loan_management_system;
select * from customer_info;
-- ------------------------------------------------------ CUSTOMER CRITERIA --------------------------------------------------------------

/* •	Applicant income >15,000 = grade a
•	Applicant income >9,000 = grade b
•	Applicant income >5000 = middle class customer
•	Otherwise low class
(Create this as new table)
*/
create table customers_criteria as select*,
case 
when applicantincome > 15000
 then "GRADE A"
 when applicantincome > 9000
 then "GRADE B"
 when applicantincome > 5000
 then "Middle class customer"
 else "Low class"
 end as Criteria from customer_info;
 select * from customers_criteria;
 
/* Monthly interest percentage 
Criteria
•	Applicant income <5000 rural=3%
•	Applicant income <5000 semi rural=3.5%
•	Applicant income <5000 urban=5%
•	Applicant income <5000 semi urban= 2.5%
•	Otherwise =7%
*/
create table monthly_interest as select *,
case 
when applicantincome < 5000 and property_area = "rural" 
then "3%"
when applicantincome < 5000 and property_area = "semirural"
then "3.5%"
when applicantincome < 5000 and property_area = "urban"
then "5%"
when applicantincome < 5000 and property_area = "semiurban"
then "2.5%"
else "7%"
end as Monthly_interest_percentage from customer_info;
select count(*) from customer_info;


 -- ------------------------------------------------------- LOAN STATUS ---------------------------------------------------------------------
 
 -- create before insert trigger -- 
 create table dummy (loan_id text, customer_id text, loanamount text, loan_amount_term int, cibil_score int);
  drop table dummy;
 
 delimiter //
 create trigger loan_amt before insert on dummy for each row
 begin
 if new.loanamount is null then set new.loanamount = "Loan still processing";
 end if;
 end //
 delimiter ;
 select * from dummy;
 drop trigger loan_amt;
  show triggers;
  
 -- ---- Primary table -----
 select * from dummy;
 
 -- ---- Secondary table -----
 create table cibil_score (loan_id text, loan_amount text, cibil_score int, cibil_score_status varchar(30));
 
 -- --- after insert trigger ----
  delimiter //
 create trigger cibil after insert on dummy for each row
 begin
 insert into cibil_score (loan_id, loan_amount, cibil_score, cibil_score_status)
 values (new.loan_id, new.loanamount, new.cibil_score,
 case 
when new.cibil_score >900 then " high cibil score"
when new.cibil_score >750 then " no penalty"
when new.cibil_score >0 then "penalty customers"
when new.cibil_score <=0 then "reject customers"
end );
 end //
 delimiter ;
 select * from cibil_score;
 drop table cibil_score;
 drop trigger cibil;
 
 -- Then delete the reject and loan still processing customers --
 
 delete from cibil_score where cibil_score_status = "reject customers";
 delete from cibil_score where loan_amount = "Loan still processing";
 
 
 -- Update loan as integers
 alter table cibil_score modify loan_amount integer;
 
 select * from loan_cibil_score_status_details;
 select count(*) loan_cibil_score_status_details;
 
 /* New field creation based on interest
•	Calculate monthly interest amt and annual interest amt based on loan amt
•	Create all the above fields as a table 
•	Table name - customer interest analysis
(create this into a new table and connect with sheet 2 (loan status) bring the output)
*/
create table customer_interest_analysis select m.*,
l.loan_amount, l.cibil_score,l.cibil_score_status,
case 
when applicantincome < 5000 and property_area = "rural" 
then (loan_amount * 3 /100)
when applicantincome < 5000 and property_area = "semirural"
then (loan_amount * 3.5 / 100)
when applicantincome < 5000 and property_area = "urban"
then (loan_amount * 5 /100)
when applicantincome < 5000 and property_area = "semiurban"
then (loan_amount * 2.5 /100)
else (loan_amount * 7 /100)
end as Monthly_interest,

case 
when applicantincome < 5000 and property_area = "rural" 
then (loan_amount * 3 /100) * 12
when applicantincome < 5000 and property_area = "semirural"
then (loan_amount * 3.5 / 100) * 12
when applicantincome < 5000 and property_area = "urban"
then (loan_amount * 5 /100) * 12
when applicantincome < 5000 and property_area = "semiurban"
then (loan_amount * 2.5 /100) * 12
else (loan_amount * 7 /100) * 12
end as Annual_interest

from monthly_interest m inner join loan_cibil_score_status_details l on m.loan_id = l.loan_id;
 select * from customer_interest_analysis;
 
-- --------------------------------------------------- CUSTOMER INFO ----------------------------------------------------------------------- 
-- Import the table
-- Update gender and age based on customer id 
select * from customer_det;
update customer_det set gender = "Female" where customerid ="IP43006";
update customer_det set gender = "Female" where customerid ="IP43016";
update customer_det set gender = "Male" where customerid ="IP43018";
update customer_det set gender = "Male" where customerid ="IP43038";
update customer_det set gender = "Female" where customerid ="IP43508";
update customer_det set gender = "Female" where customerid ="IP43577";
update customer_det set gender = "Female" where customerid ="IP43589";
update customer_det set gender = "Female" where customerid ="IP43593";
update customer_det set age = 45 where customerid ="IP43007";
update customer_det set age = 32 where customerid ="IP43009";

-- ----------------------------------------------- COUNTRY STATE AND REGION --------------------------------------------------------------
select * from country_state;
select * from region_info;
select c.*,
r.region,r.region_id from country_state c right join region_info r on c.region_id = r.region_id;

-- -------------------------------------------------------- OUTPUT -------------------------------------------------------------------------
-- output 1 --
create table output_1 as select a.*,
c.loan_amount,c.cibil_score,c.cibil_score_status,c.monthly_interest,c.annual_interest,
d.customerid,d.customer_name, d.gender,d.age,d.married,d.education,d.self_employed,d.region_id,r.postal_code,r.segment,r.state
from customers_criteria a 
inner join customer_interest_analysis c on a.loan_id = c.loan_id
inner join customer_det d on c.loan_id = d.loan_id
inner join country_state r on d.customerid = r.customerid;

-- output 2--
create table output_2 as select c.*,
s.postal_code,s.segment,s.state,r.region from customer_det c right join country_state s on c.customerid = s.customerid
right join region_info r on r.region_id = s.region_id where c.customerid is null and s.segment is null ;
select * from output_2;
-- output 3 --
create table output_3 as select a.*,
c.loan_amount,c.cibil_score,c.cibil_score_status,c.monthly_interest,c.annual_interest,
d.customerid,d.customer_name, d.gender,d.age,d.married,d.education,d.self_employed,d.region_id,r.postal_code,r.segment,r.state
from customers_criteria a 
inner join customer_interest_analysis c on a.loan_id = c.loan_id
inner join customer_det d on c.loan_id = d.loan_id
inner join country_state r on d.customerid = r.customerid where c.cibil_score_status = ' high cibil score';
-- output 4 --
create table output_4 as select a.*,
c.loan_amount,c.cibil_score,c.cibil_score_status,c.monthly_interest,c.annual_interest,
d.customerid,d.customer_name, d.gender,d.age,d.married,d.education,d.self_employed,d.region_id,r.postal_code,r.segment,r.state
from customers_criteria a 
inner join customer_interest_analysis c on a.loan_id = c.loan_id
inner join customer_det d on c.loan_id = d.loan_id
inner join country_state r on d.customerid = r.customerid where segment in ('home office', 'corporate');
show tables;
drop table output;
-- storing in procedure --
delimiter //
create procedure projectoutput ()
begin
select * from output_1;
select * from output_2;
select * from output_3;
select * from output_4;
end //
delimiter ;

call projectoutput();
-- -----------------------------------------------------ADD FOREIGN KEY --------------------------------------------------------------
show tables;
select * from dummy;
alter table customer_info drop foreign key customer_foreign_key;
alter table customer_info
 add constraint customer_foreign_key foreign key (loan_id) references dummy(loan_id),
 add constraint customer_analysis_foreignkey foreign key(customerid) references customer_interest_analysis(customerid),
 add constraint monthly_interest_foreignkey foreign key(loan_id) references monthly_interest(loan_id),
 add constraint loan_foreign_key foreign key(loan_id) references loan_cibil_score_status_details(loan_id);
alter table loan_cibil_score_status_details modify loan_id varchar(30);
alter table customer_info modify customerid varchar(30);
select * from region_info;
desc customer_interest_analysis;