# ETL-pilot
- What to do when your ETL moves into professional production?
- When you coordinate of a bunch of automatic data load running every 
	    now and again on various crontab or carte servers?
- When you need to monitor a migration done by distant developers?
- When you are responsible for the data to be there, on time and correct?

Why, in those case, not to use the logging system which is shipped with your PDI?
The PDI logging system records all the details about every thing that is 
happening during execution and stores it in a database table.

As it is siting in a database, it is easily displayed on a dynamic report or on a web 
page for you to follow the load in real-time. At the same time, you will see the 
load of all the ETL running and recording on the same logging database, weather 
launched by an automatic scheduler or by other developers. It is also pretty easy 
to go back in history and look if and when something went wrong. Additionally you 
can program and schedule a morning mail to yourself in order to know if your data 
server is up and running with the correct data, even before you reach the office.
