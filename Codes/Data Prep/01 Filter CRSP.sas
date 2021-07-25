/* The CRSP data set is used to filter the Compustat data. We need only firm-year 
 * observations for which the firm's primary security is an ordinary common stock
 * listed on NYSE, NASDAQ, or AMEX. Also, the stock price at the end of the third
 * month after the fiscal year must be greater than US$1. 
 *
 * To perform these filters, I will filter CRSP then merge the filtered CRSP
 * data set with Compustat.
 *
 * This file performs the CRSP filtering.
*/

LIBNAME RawData 'C:\Users\vanand\OneDrive\Research\Active\Forecasting earnings\Sample creation';

/* Ordinary common shares listed on NYSE, AMEX, or NASDAQ. */

/* According to the CRSP help, if the first digit of share code is 1, it's
 * an ordinary common share. Second digit of 0, 1, or 2 seems appropriate.
 * 0: "Securities which have not been further defined"
 * 1: "Securities which need not be further defined."
 * 2: "Companies incorporated outside the US." */

/* According to CRSP help, exchange codes of 1, 2, and 3 are NYSE, AMEX, 
 * and NASDAQ, respectively. */
DATA CRSP0 (KEEP = PERMNO DATE SHRCD EXCHCD PRC);
	SET RawData.CRSP_12042020;

	IF SHRCD IN (10, 11, 12);
	IF EXCHCD IN (1,2,3);
RUN;


/* Create a flag indicating whether the price is greater than $1.00. */
/* To account for rows where PRC is negative (average of bid/ask, not closing price), 
 * create another field where the flag is true if |PRC| > 1.00. */
DATA CRSP1;
	SET CRSP0;

	PriceGT1 = (PRC > 1.00);
	PriceGT1_ABS = (ABS(PRC) > 1.00);
RUN;


/* Check for duplicates in the key. */
PROC SORT DATA=CRSP1 OUT=CRSP_Final NODUPKEY;
	BY PERMNO Date;
RUN;


