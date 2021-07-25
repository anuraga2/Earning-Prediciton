/* This file creates 28 features and their first differences. */


LIBNAME OutLib 'C:\Users\vanand\OneDrive\Research\Active\Forecasting earnings\Sample creation';


/* First, "set the missing values of some line items to zero before computing
 * the first-order differences of the 28 items in Appendix 1". See footnote 5. */
/* NOTE: for definitions of the Compustat items, see Appendix 1 of Cao and You. */
DATA Sample7(DROP = i);
	SET Sample6;

	ARRAY SetMissingToZero (18) SPI AP TXP XINT IVAO 
								XSGA INTAN IVST XRD XAD 
								LCT ACT DVPSX_F OANCF XIDOC 
								CHE DLC DP;

	DO i = 1 TO 18;
		IF SetMissingToZero(i)=. THEN SetMissingToZero(i)=0.0;
	END;
RUN;


/* Create the 28 input features. */
/* Keep only needed variables. */
DATA Sample8;
	Set Sample7;

	E = IB - SPI;

	IF (OANCF=.) THEN 
		DO;
			ACC = (ACT - CHE) - (LCT - DLC - TXP) - DP;
			CFO = IB - ACC;
		END;
	ELSE
		CFO = OANCF - XIDOC;

	KEEP GVKEY LPERMNO CONM TIC CUSIP SIC
		 SHRCD EXCHCD
		 FYEAR FYR FiscalYearEnd FYEND_plus_3mos DATADATE
		 CSHO
		 SALE COGS XSGA XAD XRD DP XINT NOPIO TXT XIDO E DVC
		 CHE INVT RECT ACT PPENT IVAO INTAN AT AP DLC TXP LCT DLTT LT CEQ
		 CFO;
RUN;


/* Normalize all features: divide by CSHO (p. 18 of paper). */
DATA Sample9(DROP = i);
	SET Sample8;

	ARRAY FeaturesAndTarget (28) 
		SALE COGS XSGA XAD XRD DP XINT NOPIO TXT XIDO E DVC
		CHE INVT RECT ACT PPENT IVAO INTAN AT AP DLC TXP LCT DLTT LT CEQ
		CFO;
		
	/* CSHO is in millions. */
	IF CSHO=0.0 THEN DELETE;

	DO i = 1 TO 28;
		FeaturesAndTarget(i) = FeaturesAndTarget(i) / CSHO;
	END;
RUN;

PROC SORT DATA=Sample9 NODUPKEY;
	BY LPERMNO FYEAR;
RUN;


/* Get one-year ahead values of dependent variable, E. */
DATA OneYearAhead;
	SET Sample9(KEEP = LPERMNO FYEAR E
				RENAME=(E=E_F1));

	FYEAR = FYEAR - 1;
RUN;

PROC SQL;
	CREATE TABLE Sample10 AS
		SELECT Sample9.*, OneYearAhead.E_F1
		FROM Sample9 as a
		INNER JOIN OneYearAhead as b
		ON (a.LPERMNO = b.LPERMNO) AND (a.FYEAR = b.FYEAR);
QUIT;

PROC SORT DATA=Sample10 NODUPKEY;
	BY LPERMNO FYEAR;
RUN;


/* Create first differences of all features. */
DATA Sample11;
	SET Sample10;
	BY LPERMNO;

	SALE_D1 = DIF(SALE);
	COGS_D1 = DIF(COGS);
	XSGA_D1 = DIF(XSGA);
	XAD_D1 = DIF(XAD);
	XRD_D1 = DIF(XRD);
	DP_D1 = DIF(DP);
	XINT_D1 = DIF(XINT);
	NOPIO_D1 = DIF(NOPIO);
	TXT_D1 = DIF(TXT);
	XIDO_D1 = DIF(XIDO);
	E_D1 = DIF(E);
	DVC_D1 = DIF(DVC);
	CHE_D1 = DIF(CHE);
	INVT_D1 = DIF(INVT);
	RECT_D1 = DIF(RECT);
	ACT_D1 = DIF(ACT);
	PPENT_D1 = DIF(PPENT);
	IVAO_D1 = DIF(IVAO);
	INTAN_D1 = DIF(INTAN);
	AT_D1 = DIF(AT);
	AP_D1 = DIF(AP);
	DLC_D1 = DIF(DLC);
	TXP_D1 = DIF(TXP);
	LCT_D1 = DIF(LCT);
	DLTT_D1 = DIF(DLTT);
	LT_D1 = DIF(LT);
	CEQ_D1 = DIF(CEQ);
	CFO_D1 = DIF(CFO);

	IF FIRST.LPERMNO THEN DO;
		SALE_D1 = .;
		COGS_D1 = .;
		XSGA_D1 = .;
		XAD_D1 = .;
		XRD_D1 = .;
		DP_D1 = .;
		XINT_D1 = .;
		NOPIO_D1 = .;
		TXT_D1 = .;
		XIDO_D1 = .;
		E_D1 = .;
		DVC_D1 = .;
		CHE_D1 = .;
		INVT_D1 = .;
		RECT_D1 = .;
		ACT_D1 = .;
		PPENT_D1 = .;
		IVAO_D1 = .;
		INTAN_D1 = .;
		AT_D1 = .;
		AP_D1 = .;
		DLC_D1 = .;
		TXP_D1 = .;
		LCT_D1 = .;
		DLTT_D1 = .;
		LT_D1 = .;
		CEQ_D1 = .;
		CFO_D1 = .;
	END;
RUN;


/* Drop rows with missing values. */
DATA OutLib.CaoYouSample(DROP = i COMPRESS = YES);
	SET Sample11;

	ARRAY Features (57)
		E_F1
		SALE COGS XSGA XAD XRD DP XINT NOPIO TXT XIDO E DVC CHE INVT RECT ACT PPENT IVAO INTAN AT AP DLC TXP LCT DLTT LT CEQ CFO
		SALE_D1 COGS_D1 XSGA_D1 XAD_D1 XRD_D1 DP_D1 XINT_D1 NOPIO_D1 TXT_D1 XIDO_D1 E_D1 DVC_D1 CHE_D1 INVT_D1 RECT_D1 ACT_D1 PPENT_D1 IVAO_D1 INTAN_D1 AT_D1 AP_D1 DLC_D1 TXP_D1 LCT_D1 DLTT_D1 LT_D1 CEQ_D1 CFO_D1;

	DO i = 1 TO 57;
		IF Features(i)=. THEN DELETE;
	END;
RUN;
