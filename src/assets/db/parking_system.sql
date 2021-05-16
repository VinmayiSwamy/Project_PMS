-- Drop table

-- DROP TABLE parking_system.amenities_bookings

CREATE TABLE parking_system.amenities_bookings (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"data" jsonb NOT NULL
);
CREATE UNIQUE INDEX unique_amenities_booking_id ON parking_system.amenities_bookings (id);

-- Drop table

-- DROP TABLE parking_system.announcement

CREATE TABLE parking_system.announcement (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"data" jsonb NOT NULL
);
CREATE UNIQUE INDEX unique_id_announcement ON parking_system.announcement (id);

-- Drop table

-- DROP TABLE parking_system.bookings

CREATE TABLE parking_system.bookings (
	booking_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	slot_availability_id uuid NOT NULL,
	booking_user_id uuid NOT NULL,
	booking_time timestamptz DEFAULT clock_timestamp() NOT NULL,
	booking_status text(2147483647) NOT NULL,
	attribute1 text(2147483647),
	attribute2 text(2147483647),
	attribute3 text(2147483647),
	attribute4 text(2147483647),
	attribute5 text(2147483647)
);
CREATE UNIQUE INDEX unique_booking_id ON parking_system.bookings (booking_id);

-- Drop table

-- DROP TABLE parking_system.complaints

CREATE TABLE parking_system.complaints (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"data" jsonb NOT NULL
);
CREATE UNIQUE INDEX unique_id_complaints ON parking_system.complaints (id);

-- Drop table

-- DROP TABLE parking_system.login

CREATE TABLE parking_system.login (
	user_id uuid NOT NULL,
	resident_id text(2147483647) NOT NULL,
	"password" text(2147483647) NOT NULL,
	last_login timestamp,
	user_status text(2147483647) NOT NULL,
	role_id text(2147483647) DEFAULT 'RESIDENT'::text,
	CONSTRAINT login_pkey PRIMARY KEY (user_id)
);
CREATE UNIQUE INDEX unique_resident_id ON parking_system.login (resident_id);
CREATE UNIQUE INDEX unique_userid ON parking_system.login (user_id);

-- Drop table

-- DROP TABLE parking_system.maintenance

CREATE TABLE parking_system.maintenance (
	maintenance_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	created_date timestamptz DEFAULT clock_timestamp() NOT NULL,
	owner_id uuid NOT NULL,
	payment_status text(2147483647) NOT NULL,
	maintenance_amount int4 NOT NULL,
	amount_due int4 NOT NULL,
	attribute1 text(2147483647),
	attribute2 text(2147483647),
	attribute3 text(2147483647),
	attribute4 text(2147483647),
	attribute5 text(2147483647)
);
CREATE UNIQUE INDEX unique_id_mainatanance ON parking_system.maintenance (maintenance_id);

-- Drop table

-- DROP TABLE parking_system.parking_availability

CREATE TABLE parking_system.parking_availability (
	"availabilityID" uuid NOT NULL,
	"parkingSlotID" uuid NOT NULL,
	"availabilityStartTime" time NOT NULL,
	"availabilityEndTime" time NOT NULL,
	"availabilityDate" date NOT NULL,
	"slotType" text(2147483647) NOT NULL,
	attribute1 text(2147483647),
	attribute2 text(2147483647),
	attribute3 text(2147483647),
	attribute4 text(2147483647),
	attribute5 text(2147483647),
	"availabilityStatus" text(2147483647) NOT NULL
);
CREATE UNIQUE INDEX pa_unique_id ON parking_system.parking_availability ("availabilityID");

-- Drop table

-- DROP TABLE parking_system.parking_slot

CREATE TABLE parking_system.parking_slot (
	id uuid NOT NULL,
	"data" jsonb NOT NULL
);
CREATE INDEX index_data2 ON parking_system.parking_slot ("data");
CREATE UNIQUE INDEX ps_unique_id ON parking_system.parking_slot (id);
CREATE UNIQUE INDEX ui_slot_no ON parking_system.parking_slot ();

-- Drop table

-- DROP TABLE parking_system.users

CREATE TABLE parking_system.users (
	id uuid NOT NULL,
	"data" jsonb NOT NULL
);
CREATE INDEX index_data ON parking_system.users ("data");
CREATE UNIQUE INDEX ui_reident_id ON parking_system.users ();
CREATE UNIQUE INDEX unique_id ON parking_system.users (id);



CREATE OR REPLACE FUNCTION parking_system."bookParking"(in_availabilityid uuid, in_booking_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
		 DECLARE 
		 count int;
		 out_booking_id Text;
		 out_message TEXT;
		 out_status TEXT;
		 BEGIN		
		 
		 
		 select count(*) into count from parking_system."parking_availability" where "availabilityID" =  in_availabilityId::uuid         and "availabilityStatus" = 'AVAILABLE' ;
		 
		 if(count = 1) then
		 insert into parking_system.bookings (slot_availability_id,booking_user_id,booking_status) values 
		 (in_availabilityId,in_booking_user_id,'BOOKED') RETURNING booking_id::text INTO out_booking_id;
		 
		 update parking_system.parking_availability set "availabilityStatus"='BOOKED' where "availabilityID" =  in_availabilityId;
		 out_message='Booked Successfully';
		 out_status='success';
		 else
		 out_booking_id='';
		 out_message = 'Already Booked';
		 out_status ='fail';
		 
		 
		 end if;
		 	
		return (SELECT row_to_json(r)
FROM (select  out_booking_id::text as "bookingID" , out_message as "message",out_status as status,in_availabilityId as  "availabilityID"
     ) r);
	 
		 
		 END; 
		 
		 	$function$;

CREATE OR REPLACE FUNCTION parking_system."deleteUser"(userid uuid)
 RETURNS TABLE(psdeletedcount integer, userdeletedcount integer)
 LANGUAGE plpgsql
AS $function$	 DECLARE 

ps int ;
userDeleted int;

BEGIN		

WITH parkingSlotsdeleted AS (delete from parking_system.parking_slot where "data"->>'ownerID' = userid::text IS TRUE RETURNING *) SELECT count(*) FROM  parkingSlotsdeleted into ps;

WITH userDeleted AS (DELETE FROM parking_system.users
WHERE id = userid IS TRUE RETURNING *) SELECT count(*) FROM userDeleted into userDeleted;

return query 
   select ps as "parkingSlotDeleted" , userDeleted as "userDeleted" ;
				
END; 	$function$;

CREATE OR REPLACE FUNCTION parking_system."getUsersAll"(ref1 refcursor)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$	 DECLARE 
BEGIN		

OPEN ref1 FOR SELECT * from "parking_system".users;	
RETURN  ref1; 
END; 	$function$;

CREATE OR REPLACE FUNCTION parking_system.maintanence_monthly()
 RETURNS void
 LANGUAGE plpgsql
AS $function$	DECLARE 	

rec_user   RECORD;	
 cur_users CURSOR
 FOR SELECT *
 FROM parking_system.users;
 
  BEGIN				
  
      	
      
      OPEN cur_users;
 
   LOOP
    -- fetch row into the film
      FETCH cur_users INTO rec_user;
    -- exit when no more row to fetch
      EXIT WHEN NOT FOUND;
 
    insert into parking_system.maintenance (owner_id,payment_status,maintenance_amount,amount_due) values(rec_user.id,'PENDING',12345,12345);
    
   END LOOP;
  
   -- Close the cursor
   CLOSE cur_users;
      
      
      	 	END; 		$function$;

CREATE OR REPLACE FUNCTION parking_system."userUpdate"(user_id text, user_data jsonb, parking_slot_data json)
 RETURNS void
 LANGUAGE plpgsql
AS $function$	DECLARE 	 ps json; 		 BEGIN		
	    update parking_system.users set "data"=user_data where id =  user_id::uuid ;
	    
	    
	     FOR ps IN SELECT * FROM json_array_elements(parking_slot_data)         LOOP 
	               Update parking_system.parking_slot set "data" = ps where id = (ps->>'parkingSlotID')::uuid;     
	                         END LOOP;  
	    
	 	END; 		$function$;
