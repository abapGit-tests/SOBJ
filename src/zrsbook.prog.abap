*****           Implementation of object type SBOOK                *****
INCLUDE <OBJECT>.
BEGIN_DATA OBJECT. " Do not change.. DATA is generated
* only private members may be inserted into structure private
DATA:
" begin of private,
"   to declare private attributes remove comments and
"   insert private attributes here ...
" end of private,
  BEGIN OF KEY,
      AIRLINEID LIKE SBOOK-CARRID,
      BOOKINGNUMBER LIKE SBOOK-BOOKID,
  END OF KEY,
      FLIGHT TYPE SWC_OBJECT,
      CUSTOMER TYPE SWC_OBJECT,
      TRAVELAGENCY TYPE SWC_OBJECT,
      _SBOOK LIKE SBOOK.
END_DATA OBJECT. " Do not change.. DATA is generated

* ---------------------------------------------------------------

TABLES SBOOK.

* ---------------------------------------------------------------

GET_TABLE_PROPERTY SBOOK.
DATA SUBRC LIKE SY-SUBRC.
* Fill TABLES SBOOK to enable Object Manager Access to Table Properties
  PERFORM SELECT_TABLE_SBOOK USING SUBRC.
  IF SUBRC NE 0.
    EXIT_OBJECT_NOT_FOUND.
  ENDIF.
END_PROPERTY.

* ---------------------------------------------------------------

* Use Form also for other(virtual) Properties to fill TABLES SBOOK
FORM SELECT_TABLE_SBOOK USING SUBRC LIKE SY-SUBRC.
* Select single * from SBOOK, if OBJECT-_SBOOK is initial

  IF OBJECT-_SBOOK-MANDT IS INITIAL
  AND OBJECT-_SBOOK-CARRID IS INITIAL
  AND OBJECT-_SBOOK-CONNID IS INITIAL
  AND OBJECT-_SBOOK-FLDATE IS INITIAL
  AND OBJECT-_SBOOK-BOOKID IS INITIAL
  AND OBJECT-_SBOOK-CUSTOMID IS INITIAL.

    SELECT SINGLE * FROM SBOOK CLIENT SPECIFIED
        WHERE MANDT = SY-MANDT
        AND CARRID = OBJECT-KEY-AIRLINEID
        AND BOOKID = OBJECT-KEY-BOOKINGNUMBER.
    SUBRC = SY-SUBRC.

    IF SUBRC NE 0. EXIT. ENDIF.
    OBJECT-_SBOOK = SBOOK.

  ELSE.

    SUBRC = 0.
    SBOOK = OBJECT-_SBOOK.

  ENDIF.
ENDFORM.

* ---------------------------------------------------------------


* ---------------------------------------------------------------

BEGIN_METHOD DISPLAY CHANGING CONTAINER.

 SET PARAMETER ID 'CAR' FIELD OBJECT-KEY-AIRLINEID.
 SET PARAMETER ID 'BOK' FIELD OBJECT-KEY-BOOKINGNUMBER.

 CALL TRANSACTION 'BC_GLOBAL_SBOOK_DISP' WITH AUTHORITY-CHECK
      AND SKIP FIRST SCREEN.

END_METHOD.

* ---------------------------------------------------------------

GET_PROPERTY FLIGHT CHANGING CONTAINER.

DATA: BEGIN OF SFLIGHT_KEY,
       CARRID LIKE SFLIGHT-CARRID,
       CONNID LIKE SFLIGHT-CONNID,
       FLDATE LIKE SFLIGHT-FLDATE,
      END OF SFLIGHT_KEY.

SWC_GET_PROPERTY SELF 'AirlineID' SFLIGHT_KEY-CARRID.
SWC_GET_PROPERTY SELF 'ConnectionID' SFLIGHT_KEY-CONNID.
SWC_GET_PROPERTY SELF 'FlightDate' SFLIGHT_KEY-FLDATE.

  SWC_CREATE_OBJECT OBJECT-FLIGHT 'SFLIGHT' SFLIGHT_KEY.
  SWC_SET_ELEMENT   CONTAINER     'Flight' OBJECT-FLIGHT.

END_PROPERTY.

* ---------------------------------------------------------------

GET_PROPERTY CUSTOMER CHANGING CONTAINER.

DATA: BEGIN OF SCUSTOM_KEY,
       ID LIKE SCUSTOM-ID,
      END OF SCUSTOM_KEY.

 SWC_GET_PROPERTY SELF 'CustomerNumber' SCUSTOM_KEY-ID.

  SWC_CREATE_OBJECT OBJECT-CUSTOMER 'SCUSTOMER' SCUSTOM_KEY.
  SWC_SET_ELEMENT   CONTAINER       'Customer'  OBJECT-CUSTOMER.

END_PROPERTY.

* ---------------------------------------------------------------

BEGIN_METHOD EXISTENCECHECK CHANGING CONTAINER.

 SELECT SINGLE       * FROM  SBOOK
        WHERE  CARRID      = OBJECT-KEY-AIRLINEID
        AND    BOOKID      = OBJECT-KEY-BOOKINGNUMBER.

IF SY-SUBRC NE 0.
 EXIT_RETURN 0001 SPACE SPACE SPACE SPACE.
ENDIF.

END_METHOD.

* ---------------------------------------------------------------



GET_PROPERTY TRAVELAGENCY CHANGING CONTAINER.

DATA: BEGIN OF STRAVELAG_KEY,
       AGENCYNUM LIKE STRAVELAG-AGENCYNUM,
      END OF STRAVELAG_KEY.

  SWC_GET_PROPERTY SELF 'Agencynumber' STRAVELAG_KEY-AGENCYNUM.

  SWC_CREATE_OBJECT OBJECT-TRAVELAGENCY 'SAGENCY' STRAVELAG_KEY.
  SWC_SET_ELEMENT CONTAINER 'TravelAgency' OBJECT-TRAVELAGENCY.

END_PROPERTY.
* ---------------------------------------------------------------

BEGIN_METHOD EDIT CHANGING CONTAINER.

 SET PARAMETER ID 'CAR' FIELD OBJECT-KEY-AIRLINEID.
 SET PARAMETER ID 'BOK' FIELD OBJECT-KEY-BOOKINGNUMBER.

 CALL TRANSACTION 'BC_GLOBAL_SBOOK_EDIT' WITH AUTHORITY-CHECK
      AND SKIP FIRST SCREEN.

 SWC_REFRESH_OBJECT SELF.

END_METHOD.
* ---------------------------------------------------------------

* ---------------------------------------------------------------

BEGIN_METHOD CREATE CHANGING CONTAINER.

 CALL TRANSACTION 'BC_GLOBAL_SBOOK_CREA' WITH AUTHORITY-CHECK.

END_METHOD.
* ---------------------------------------------------------------

* ---------------------------------------------------------------


BEGIN_METHOD CREATEFROMDATA CHANGING CONTAINER.
DATA:
      RESERVEONLY LIKE BAPISBODAT-RESERVED,
      BOOKINGDATA LIKE BAPISBONEW,
      TESTRUN LIKE BAPISFLAUX-TESTRUN,
      TICKETPRICE LIKE BAPISBOPRI,
      EXTENSIONIN LIKE BAPIPAREX OCCURS 0,
      RETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'ReserveOnly' RESERVEONLY.
  IF SY-SUBRC <> 0.
    MOVE SPACE TO RESERVEONLY.
  ENDIF.
  SWC_GET_ELEMENT CONTAINER 'BookingData' BOOKINGDATA.
  SWC_GET_ELEMENT CONTAINER 'TestRun' TESTRUN.
  IF SY-SUBRC <> 0.
    MOVE SPACE TO TESTRUN.
  ENDIF.
  SWC_GET_TABLE CONTAINER 'ExtensionIn' EXTENSIONIN.
  CALL FUNCTION 'BAPI_FLBOOKING_CREATEFROMDATA'
    EXPORTING
      RESERVE_ONLY = RESERVEONLY
      BOOKING_DATA = BOOKINGDATA
      TEST_RUN = TESTRUN
    IMPORTING
      TICKET_PRICE = TICKETPRICE
      BOOKINGNUMBER = OBJECT-KEY-BOOKINGNUMBER
      AIRLINEID = OBJECT-KEY-AIRLINEID
    TABLES
      EXTENSION_IN = EXTENSIONIN
      RETURN = RETURN
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_ELEMENT CONTAINER 'TicketPrice' TICKETPRICE.
  SWC_SET_TABLE CONTAINER 'Return' RETURN.
END_METHOD.

BEGIN_METHOD CONFIRM CHANGING CONTAINER.
DATA:
      TESTRUN LIKE BAPISFLAUX-TESTRUN,
      RETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'TestRun' TESTRUN.
  IF SY-SUBRC <> 0.
    MOVE SPACE TO TESTRUN.
  ENDIF.
  CALL FUNCTION 'BAPI_FLBOOKING_CONFIRM'
    EXPORTING
      AIRLINEID = OBJECT-KEY-AIRLINEID
      BOOKINGNUMBER = OBJECT-KEY-BOOKINGNUMBER
      TEST_RUN = TESTRUN
    TABLES
      RETURN = RETURN
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_TABLE CONTAINER 'Return' RETURN.
END_METHOD.

BEGIN_METHOD CANCEL CHANGING CONTAINER.
DATA:
      TESTRUN LIKE BAPISFLAUX-TESTRUN,
      RETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'TestRun' TESTRUN.
  IF SY-SUBRC <> 0.
    MOVE SPACE TO TESTRUN.
  ENDIF.
  CALL FUNCTION 'BAPI_FLBOOKING_CANCEL'
    EXPORTING
      AIRLINEID = OBJECT-KEY-AIRLINEID
      BOOKINGNUMBER = OBJECT-KEY-BOOKINGNUMBER
      TEST_RUN = TESTRUN
    TABLES
      RETURN = RETURN
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_TABLE CONTAINER 'Return' RETURN.
END_METHOD.

BEGIN_METHOD GETLIST CHANGING CONTAINER.
DATA:
      AIRLINE LIKE BAPISBOKEY-AIRLINEID,
      TRAVELAGENCY LIKE BAPISBODAT-AGENCYNUM,
      CUSTOMERNUMBER LIKE BAPISCUKEY-CUSTOMERID,
      MAXROWS LIKE BAPISFLAUX-BAPIMAXROW,
      FLIGHTDATERANGE LIKE BAPISFLDRA OCCURS 0,
      BOOKINGDATERANGE LIKE BAPISFLDRA OCCURS 0,
      EXTENSIONIN LIKE BAPIPAREX OCCURS 0,
      BOOKINGLIST LIKE BAPISBODAT OCCURS 0,
      EXTENSIONOUT LIKE BAPIPAREX OCCURS 0,
      RETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'Airline' AIRLINE.
  SWC_GET_ELEMENT CONTAINER 'TravelAgency' TRAVELAGENCY.
  SWC_GET_ELEMENT CONTAINER 'CustomerNumber' CUSTOMERNUMBER.
  SWC_GET_ELEMENT CONTAINER 'MaxRows' MAXROWS.
  SWC_GET_TABLE CONTAINER 'FlightDateRange' FLIGHTDATERANGE.
  SWC_GET_TABLE CONTAINER 'BookingDateRange' BOOKINGDATERANGE.
  SWC_GET_TABLE CONTAINER 'ExtensionIn' EXTENSIONIN.
  CALL FUNCTION 'BAPI_FLBOOKING_GETLIST'
    EXPORTING
      MAX_ROWS = MAXROWS
      CUSTOMER_NUMBER = CUSTOMERNUMBER
      TRAVEL_AGENCY = TRAVELAGENCY
      AIRLINE = AIRLINE
    TABLES
      BOOKING_LIST = BOOKINGLIST
      EXTENSION_OUT = EXTENSIONOUT
      RETURN = RETURN
      EXTENSION_IN = EXTENSIONIN
      BOOKING_DATE_RANGE = BOOKINGDATERANGE
      FLIGHT_DATE_RANGE = FLIGHTDATERANGE
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_TABLE CONTAINER 'BookingList' BOOKINGLIST.
  SWC_SET_TABLE CONTAINER 'ExtensionOut' EXTENSIONOUT.
  SWC_SET_TABLE CONTAINER 'Return' RETURN.
END_METHOD.

BEGIN_METHOD CREATEANDRESPOND CHANGING CONTAINER.
DATA:
      AGENCYDATA LIKE BAPISBOAGN,
      BOOKINGDATA LIKE BAPISBONEW,
      RETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'AgencyData' AGENCYDATA.
  SWC_GET_ELEMENT CONTAINER 'BookingData' BOOKINGDATA.
  CALL FUNCTION 'BAPI_FLBOOKING_CREATEANDRESP'
    EXPORTING
      AGENCY_DATA = AGENCYDATA
      BOOKING_DATA = BOOKINGDATA
    TABLES
      RETURN = RETURN
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_TABLE CONTAINER 'Return' RETURN.
END_METHOD.

BEGIN_METHOD SENDRESPONSE CHANGING CONTAINER.
DATA:
      AGENCYDATA LIKE BAPISBOAGN,
      BOOKINGID LIKE BAPISBOKEY,
      BOOKINGSTATUS TYPE BAPISFLAUX-FBOSTATUS,
      RETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'AgencyData' AGENCYDATA.
  SWC_GET_ELEMENT CONTAINER 'BookingID' BOOKINGID.
  SWC_GET_ELEMENT CONTAINER 'BookingStatus' BOOKINGSTATUS.
  CALL FUNCTION 'BAPI_FLBOOKING_SENDRESPONSE'
    EXPORTING
      AGENCY_DATA = AGENCYDATA
      BOOKING_ID = BOOKINGID
      BOOKING_STATUS = BOOKINGSTATUS
    TABLES
      RETURN = RETURN
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_TABLE CONTAINER 'Return' RETURN.
END_METHOD.
