--Part 1

--1

INSERT INTO item VALUES 
('30', 'Dell', 'Alienware 15', '2.1-GHz Intel Core i7-8750H processor, 16GB Memory, 256GB Solid State Drive');
INSERT INTO item VALUES 
('31', 'Apple', 'MacBook Air', '1.8GHz dual-core Intel Core i5 processor, 8GB of 1600MHz LPDDR3 onboard memory, 128GB PCIe-based SSD');
INSERT INTO item VALUES 
('32', 'HP', 'Envy', '8th Generation Intel Core i7 processor, 8 GB memory, 1 TB HDD');

--2
SELECT * FROM ITEM;

--3
ALTER TABLE LOAN
ADD CONSTRAINT RETURN_DAY_CONSTRAINT CHECK (DATE_RETURNED >= START_DATE);