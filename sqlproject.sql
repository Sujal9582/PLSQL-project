--Table Structure for Parking Slots.

CREATE TABLE parking_slots (
    slot_id NUMBER PRIMARY KEY,
    is_available CHAR(1) CHECK (is_available IN ('Y', 'N')),  -- 'Y' for available, 'N' for taken
    vehicle_type VARCHAR2(50),   -- Type of vehicle allowed (e.g., 'car', 'bike')
    location VARCHAR2(100)
);

-- Insert parking slots data
INSERT INTO parking_slots (slot_id, is_available, vehicle_type, location) 
VALUES (1, 'Y', 'car', 'A1');

INSERT INTO parking_slots (slot_id, is_available, vehicle_type, location) 
VALUES (2, 'Y', 'car', 'A2');

INSERT INTO parking_slots (slot_id, is_available, vehicle_type, location) 
VALUES (3, 'Y', 'bike', 'B1');

INSERT INTO parking_slots (slot_id, is_available, vehicle_type, location) 
VALUES (4, 'N', 'car', 'A3');  -- Slot A3 is taken (not available)

INSERT INTO parking_slots (slot_id, is_available, vehicle_type, location) 
VALUES (5, 'N', 'bike', 'B2');  -- Slot B2 is taken (not available)

select * from parking_slots;


--To find available parking slots for cars.

SELECT slot_id, location
FROM parking_slots
WHERE is_available = 'Y' AND vehicle_type = 'car';

--Table Structure for Vehicles:

CREATE TABLE vehicles (
    vehicle_id NUMBER PRIMARY KEY,
    slot_id NUMBER,
    entry_time TIMESTAMP,       -- Use Oracle's TIMESTAMP datatype
    exit_time TIMESTAMP,        -- Use Oracle's TIMESTAMP datatype
    vehicle_type VARCHAR2(50),  -- Vehicle type: 'car', 'bike', etc.
    FOREIGN KEY (slot_id) REFERENCES parking_slots(slot_id)
);

-- Insert vehicles data
INSERT INTO vehicles (vehicle_id, slot_id, entry_time, exit_time, vehicle_type) 
VALUES (101, 1, TIMESTAMP '2025-01-06 08:00:00', TIMESTAMP '2025-01-06 10:30:00', 'car');

INSERT INTO vehicles (vehicle_id, slot_id, entry_time, exit_time, vehicle_type) 
VALUES (102, 2, TIMESTAMP '2025-01-06 09:00:00', TIMESTAMP '2025-01-06 12:00:00', 'car');

INSERT INTO vehicles (vehicle_id, slot_id, entry_time, exit_time, vehicle_type) 
VALUES (103, 3, TIMESTAMP '2025-01-06 07:30:00', TIMESTAMP '2025-01-06 09:00:00', 'bike');

select * from vehicles;


--Trigger for Vehicle Entry (Mark Slot as Unavailable):
    
CREATE OR REPLACE TRIGGER vehicle_entry
AFTER INSERT ON vehicles
FOR EACH ROW
BEGIN
    UPDATE parking_slots
    SET is_available = 'N'
    WHERE slot_id = :NEW.slot_id;
END;

--Trigger for Vehicle Exit (Mark Slot as Available):

CREATE OR REPLACE TRIGGER vehicle_exit
AFTER DELETE ON vehicles
FOR EACH ROW
BEGIN
    UPDATE parking_slots
    SET is_available = 'Y'
    WHERE slot_id = :OLD.slot_id;
END;

--PL/SQL Procedure to Calculate Parking Charges:
CREATE OR REPLACE PROCEDURE calculate_parking_charge (
    p_vehicle_id IN NUMBER,
    p_charge OUT NUMBER
) IS
    v_entry_time TIMESTAMP;
    v_exit_time TIMESTAMP;
    v_duration INTERVAL DAY TO SECOND;  -- This will hold the difference in time
    v_rate_per_hour NUMBER;
    v_vehicle_type VARCHAR2(50);
BEGIN
    -- Retrieve entry and exit times, along with vehicle type
    SELECT entry_time, exit_time, vehicle_type
    INTO v_entry_time, v_exit_time, v_vehicle_type
    FROM vehicles
    WHERE vehicle_id = p_vehicle_id;

    -- Check if exit_time is NULL (vehicle hasn't exited yet)
    IF v_exit_time IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Vehicle has not exited yet.');
        p_charge := 0;  -- Set charge to 0 if vehicle has not exited
        RETURN;         -- Exit the procedure
    END IF;

    -- Calculate the parking duration
    v_duration := v_exit_time - v_entry_time;
    
    -- Determine rate based on vehicle type
    IF v_vehicle_type = 'car' THEN
        v_rate_per_hour := 10;  -- $10 per hour for cars
    ELSE
        v_rate_per_hour := 5;   -- $5 per hour for bikes
    END IF;
    
    -- Calculate the total charge based on the duration
    -- First, calculate the total number of hours, including fractions of an hour
    p_charge := ROUND(EXTRACT(HOUR FROM v_duration) + (EXTRACT(MINUTE FROM v_duration) / 60), 2) * v_rate_per_hour;

    -- Display the calculated charge for debugging (optional)
    DBMS_OUTPUT.PUT_LINE('Parking charge for Vehicle ' || p_vehicle_id || ': $' || p_charge);
END;

--For Example to calculate the parking charge for vehicle_id = 101:

DECLARE
    v_charge NUMBER;
BEGIN
    -- Calculate the parking charge for Vehicle 101
    calculate_parking_charge(101, v_charge);
    DBMS_OUTPUT.PUT_LINE('Total parking charge for Vehicle 101: $' || v_charge);
END;

