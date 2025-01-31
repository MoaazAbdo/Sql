﻿/****** Script for SelectTopNRows command from SSMS  ******/
Use DigiKeyProject5
----------------------------- 1- Truncate OLD Table -------------------------------
Truncate Table [DigiKeyProject5].[dbo].[DKfeed]

Drop INDEX [FDP1] ON [dbo].[DKfeed] 
Drop INDEX [FDP2] ON [dbo].[DKfeed] 
Drop INDEX [FDP3] ON [dbo].[DKfeed] 

Alter Table [DigiKeyProject5].[dbo].[DKfeed]
Drop Column [Zcompany]  ,[PackLU] ,[NonAlphaPart]

------------------------------ 2- Insert Latest Feed --------------------------------------
Bulk insert DKfeed from '\\192.168.2.116\sourcing\Inventory\Digikey Project\DK Feed\Z2data_Stock_Price.txt'
WITH (FIELDTERMINATOR = '\t',firstrow=2,ROWTERMINATOR = '0x0a')

------------------------------ 3- Add Lookup columns with Indexes ---------------------------

Alter Table DigiKeyProject5.dbo.DKfeed Add Zcompany varchar(255) , PackLU varchar(50) , NonAlphaPart varchar(255)

Create nonclustered Index FDP1 on DigiKeyProject5.dbo.DKfeed (Zcompany)
Create nonclustered Index FDP2 on DigiKeyProject5.dbo.DKfeed (PackLU)
Create nonclustered Index FDP3 on DigiKeyProject5.dbo.DKfeed (NonAlphaPart)

------------------------------ 4- Updating Lookup Columns ------------------------------

Update [DigiKeyProject5].[dbo].[DKfeed]
Set NonAlphaPart = dbo.fnRemovePatternFromString(Manufacturer_Part_Number)

Update [DigiKeyProject5].[dbo].[DKfeed]
Set PackLU = Case when Packaging in ('TR','Tape_Box') then 'Full Reel' else '' End 

Update [DigiKeyProject5].[dbo].[DKfeed]
Set ZCompany = b.[ZCompany] from [DigiKeyProject5].[dbo].[DKfeed] a
Inner Join [Lookup].[dbo].[NewDKMouserCompanies] b  On a.Manufacturer = b.[Given]
Where a.Zcompany is null

--------------------------- 5- Update New added Manufacturers with their Zcompany Names --------------------------

Select distinct Manufacturer from [DigiKeyProject5].[dbo].[DKFeed] Where Zcompany='' or Zcompany is null


/***** selecting the new added MFRs for the Vendor Mapping *************/

select count(distinct [Manufacturer_Part_Number]) TotalCountOfParts, max([Manufacturer_Part_Number]) SamplePart ,Manufacturer 
from [DigiKeyProject5].[dbo].[DKfeed]
where Zcompany='' or Zcompany is null
group by Manufacturer
order by TotalCountOfParts desc

/****************************************************************************/


Update [DigiKeyProject5].[dbo].[DKFeed]  set ZCompany = Manufacturer Where Zcompany='' or Zcompany is null



 Update [DigiKeyProject5].[dbo].[DKFeed] 
Set ZCompany = 'Kübler Group' Where Manufacturer like 'K_BLER'
--Set ZCompany = 'Würth Elektronik GmbH & Co. KG' Where Manufacturer like 'W_RTH ELEKTRONIK'
--Set ZCompany = 'Weidmüller Interface GmbH & Co. KG' Where Manufacturer like 'WEIDM_LLER'

-------------------------- 6- Removing ALL LF And CT from DK Part Number Field -----------------------------------

Select * from  DigiKeyProject5.[dbo].DKfeed
Where Digikey_Part_Number Like '%' + CHAR(10) + '%'

update d
set  [Digikey_Part_Number] =REPLACE([Digikey_Part_Number], CHAR(10), '')
from DigiKeyProject5.[dbo].DKfeed d
Where Digikey_Part_Number Like '%' + CHAR(10) + '%'

select Digikey_Part_Number
from DigiKeyProject5.[dbo].DKfeed
order by Digikey_Part_Number asc


  update DigiKeyProject5.[dbo].DKfeed
  set Digikey_Part_Number =REPLACE(Digikey_Part_Number, '     ', '')
  where Digikey_Part_Number like '     %'


    update DigiKeyProject5.[dbo].DKfeed
  set Digikey_Part_Number =REPLACE(Digikey_Part_Number, ' ', '')
  where Digikey_Part_Number like ' %'



 
