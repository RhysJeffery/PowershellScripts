Automated Microsoft Deployment Toolkit Installer
Scripter: Rhys Jeffery
Email: Rhysj@neweratech.co.nz
Date: 29/03/21

You can download the latest version from here: https://neweraitnz.sharepoint.com/:f:/s/tetaitokerauteam/Eq90-mWR-aFOuWqc8Urd6Z8BDfmdmbs_8LsT1FAuuXZxjw?e=DFLyQO

The script doesn't include a windows image nor does it import one. You can download custom made GOLD wims from here: https://neweraitnz.sharepoint.com/:f:/s/tetaitokerauteam/Epj374VlIcRPoSJAgshO0OwB6tz8Xtly3wx0KxwwNqPGHQ?e=SxQbLY
or you can download a windows 10 Education ISO from VLSC

How to import an WIM or ISO
https://web.sas.upenn.edu/jasonrw/2015/11/02/mdt-importing-an-operating-system/

How to attached OS to task squence
Open Deployment Tool Bench -> Task Squences -> Install Image -> Task Squence -> Install -> Install Operating System -> Browse -> Select imported OS

How to add driver packages
	Firstly you need to get the correct name we will use for the folder. The following command needs to be run on each model we're importing 'WMIC CSPRODUCT GET NAME' we use this EXCAT name.
Open Deployment Tool Bench -> Out-of-Box-Drivers -> Windows 10 x64 -> Create new folder, name it correctly. -> right click folder and go import, import downloaded drivers from folder

The other drivers are for generic driver updates and wine pe drivers, only advanced users should use this.