/* This file creates the sample. It performs some filtering in Compustat then
 * merges with the CRSP file created in the 01 file. */


LIBNAME RawData 'C:\Users\vanand\OneDrive\Research\Active\Forecasting earnings\Sample creation';


/* Fiscal year in [1975, 2018] and currency is USD. */
/* I'm excluding FY 2019 at this time because I don't have CRSP data
 * for March 2020, when most 10-K's are released. */
/* I start at 1975 because that's when Cao and You start. */
DATA Sample0;
	SET RawData.CCM_11132020;

	IF (FYEAR >= 1965) AND (FYEAR <= 2018) AND (CURCD = 'USD');
RUN;

/* Get rid of any duplicate keys. */
PROC SORT DATA=	Sample0 NODUPKEY;
	BY LPERMNO FYEAR;
RUN;


/* Delete observations with missing values in AT, SALE, IB, or CSHO. */
DATA Sample1;
	SET Sample0;

	IF MISSING(AT) OR MISSING(SALE) OR MISSING(IB) OR MISSING(CSHO) THEN DELETE;
RUN;


/* The following code tests the fiscal year correction.
 * It appears that you can just take the YEAR component of
 * the DATADATE field. That gives the exact same result
 * as manually adjusting the FYEAR field. */
/*
DATA Moo;
	SET Sample2 (KEEP = LPERMNO FYEAR FYR DATADATE);

	FYEAR1 = YEAR(datadate);

	FYEAR2 = FYEAR;
	IF (FYR < 6) THEN FYEAR2 = FYEAR2 + 1;

	Check = ABS(FYEAR1 - FYEAR2);
RUN;

PROC SQL;
	SELECT DISTINCT Check, Count(LPERMNO)
	FROM Moo
	GROUP BY Check
	ORDER BY Check;
QUIT;
*/

/* Delete financial and utility firms by SIC code. */
DATA Sample2;
	SET Sample1;

	SIC = INPUT(SIC, 4.);
	
	IF (SIC >= 6000 AND SIC < 7000) THEN DELETE;
	IF (SIC >= 4900 AND SIC < 5000) THEN DELETE;
RUN;


/* Create a fiscal year variable, making the correction for firms with fiscal year end
 * in May or earlier.
 * Compute the fiscal year end date, then create a field that contains 
 * fiscal year end + 3 months. */
DATA Sample3;
	SET Sample2;

	FYEAR_orig = FYEAR;
	IF (FYR < 6) THEN FYEAR = FYEAR + 1;

	FiscalYearEnd = MDY(FYR, 1, FYEAR);
	FiscalYearEnd = INTNX('MONTH', FiscalYearEnd, 0, 'E');
	FORMAT FiscalYearEnd date9.;

	FYEND_plus_3mos = INTNX('MONTH', FiscalYearEnd, 3, 'E');
	FORMAT FYEND_plus_3mos date9.;
RUN;


/* ----------------------------------------------------------------- */
/* Merge CCM and CRSP to apply the CRSP filters. */
/* ----------------------------------------------------------------- */
PROC SQL;
	CREATE TABLE Sample4 AS
		SELECT Sample3.*, CRSP_Final.PERMNO, CRSP_Final.Date, CRSP_Final.Shrcd, CRSP_Final.exchcd, CRSP_Final.PRC
	FROM Sample3 AS a
	INNER JOIN CRSP_Final AS b
	ON (a.LPERMNO = b.PERMNO) AND (MONTH(a.FiscalYearEnd) = MONTH(b.Date)) AND (YEAR(a.FiscalYearEnd) = YEAR(b.Date));
QUIT;


/* Get price 3 months after fiscal year end. */
PROC SQL;
	CREATE TABLE Sample5 AS
		SELECT Sample4.*, CRSP_Final.PriceGT1, CRSP_Final.PriceGT1_ABS
	FROM Sample4 AS a
	LEFT JOIN CRSP_Final AS b
	ON (a.LPERMNO = b.PERMNO) AND (MONTH(a.FYEND_plus_3mos) = MONTH(b.Date)) AND (YEAR(a.FYEND_plus_3mos) = YEAR(b.Date));
QUIT;

/* Filter on observations where the stock price, 3 months after fiscal year end, is greater than $1. */
DATA Sample6;
	SET Sample5;

	IF PriceGT1_ABS = 1;
RUN;



