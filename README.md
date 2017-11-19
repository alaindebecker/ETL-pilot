# ETL-pilot
- What to do when your ETL moves into professional production?
- When you coordinate of a bunch of automatic data load running every 
	    now and again on various crontab or carte servers?
- When you need to monitor a migration done by distant developers?
- When you are responsible for the data to be there, on time and correct?

Why, in those case, not to use the logging system which is shipped with your PDI?
The PDI logging system records all the details about every thing that is 
happening during execution and stores it in a database table.

# Logging with the PDI
As it is siting in a database, it is easily displayed on a dynamic report or on a web 
page for you to follow the load in real-time. At the same time, you will see the 
load of all the ETL running and recording on the same logging database, weather 
launched by an automatic scheduler or by other developers. It is also pretty easy 
to go back in history and look if and when something went wrong. Additionally you 
can program and schedule a morning mail to yourself in order to know if your data 
server is up and running with the correct data, even before you reach the office.

Enabling PDI loggings is a 7 clicks operation explained 
[here](https://help.pentaho.com/Documentation/5.3/0P0/0U0/0A0/000), 
with best practices [here](https://help.pentaho.com/Documentation/5.3/0P0/0U0/0A0/050).

# Monitoring your ETL
All you need to monitor for the ETL automated loads is the logging of the 
transformations. As a matter of facts, during consultancies for customers with 
heavily automated ETL systems, we discovered that <i>in fine</i> what you are 
after is how much data per table is loaded, and this data is always loaded by 
a transformation. To log at job level is useful during coding, synchronization 
and optimization, but it does not give you the helicopter view you need to 
quickly review the nightly ETL. And if you have some authority on the developers,
then try to simplify your life with a simple a convention: as far as possible, 
each transformation loads only one table and has the same name as this table.

# Displaying the loggins real-time on a web page
On the `logging.jsp` in this account  displays continuously the logging table on a 
web page. Slip the page in a tomcat/webapps/etl folder then type 
yourhost:8080/etl/loggings.jsp in your browser. We made sure to use the PDI 
defaults and no jar libraries so that it should work as soon as the 
config.properties points to the database connection of yours.

The information displayed was selected after numerous trials and errors. 
They are, for each transformation the date of the run, the state (running, 
finished,...), the duration, the number of record written or updated and the 
number of errors. The transformation name is a link redirecting to the recent 
history load so that you can immediately see if the last number of output records 
is suspicious and if load time is increasing. And selecting the date of the run 
sends you to the detailed log, which you can follow real-time.

# The Morning Mail
You'll also find `MorningMail.ktr`, a PDI transformation which sends you a small report 
of the previous 24h loads and makes a little bit of clean up in the historical data. 
Schedule it on your crontab server for a time which is convenient to you, for example 
on your smartphone on the way to the office.

# A graphical view
The `graph.jsp` is a work-in-progress piece of code, that will eventually 
replace the history log by a more graphical view. Watch for the updates.
In the meanwhile, send me your feedback. So much can be done, and it so much 
more productive to be driven by the users' needs on that respect.

# To pilot the ETL from a web page  
The next step is to enable stop and restart your ETL from the logging display 
page. We are blocked by two requests still open in the Vantara-Pentaho jira:

- PDI-16549 to record the transformation path instead of the transformation 
name. If the name is enough to see which and when a transformation did not 
performed its job correctly, you definitely need to put the hands on the actual 
ktr to restart it, hence the need of the full path.

- PDI-16550 to record the parameters of the transformation at the time of the 
run so that you can restart it in the same conditions. As sometimes the 
parameter values are given by an orchestrating job, so to guess them on the next 
day is not always an easy task.

# Conclusion
In conclusion, setup your PDI logging, install the ETL-pilot on your server, 
watch in real-time what you and your colleagues are loading, enjoy its 
MIT license to make it suits to your own needs. And when you have a few month 
of data tell me what you think about the graphs, and do not forget to help 
the community to develop further by voting for the JIRA-16549 and the JIRA-16550 
as massively as possible.
