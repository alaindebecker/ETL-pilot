<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.*" %>

<html>
<head>
	<meta charset='utf8' />
	<style>
		* { font-family: Sans-serif; cursor: default; }
		html, body { margin: 0 }
		#content { width: 80%; margin: 0 auto ;  box-shadow: 10px 0px 1.5em grey, -10px 0px 15px grey; padding: 0 1em 2em; }

		h2 { color: blue; }
		h1 { margin-top: 0; padding-top: .5em; }
		#now {float: right; }
		
		table { width: 100%; }
		th { text-align: left; padding-top: 1em; }		
		td.Transformation { text-align: left; padding-left: 2em; }
		.Date           { text-align: left; }
		.Status         { text-align: center; }
		.Duration       { text-align: right; }
		.Output         { text-align: right; }
		.Errors         { text-align: right; }
		
		textarea { width: 100%; height: 100%; border: 1px solid grey; }
		
		[onclick]:hover { color: #0000EE; text-decoration: underline; }
		.warning { color: red; font-weight: bold; }
		<% //TODO: include something sweet like bootstrap %>
	</style>
	
	
	
	<%  // Get parmeters from config file and from url
		Properties conf = new Properties();
		conf.load(new FileInputStream(getServletContext().getRealPath("/")+"/config.properties"));
		
		String driver = conf.getProperty("driver"); 
		Class.forName(driver);
		Statement db = DriverManager.getConnection(
			conf.getProperty("connection"),
			conf.getProperty("username"),
			conf.getProperty("password")
		).createStatement();
		
		/* GET properties as in kettle.properties to check table names */
		/* TODO: read the kettle.properties 
		   TODO: support schema inside the queries
		*/
		
		String KETTLE_CHANNEL_LOG_SCHEMA = conf.getProperty("KETTLE_CHANNEL_LOG_SCHEMA");
		String KETTLE_CHANNEL_LOG_TABLE = conf.getProperty("KETTLE_CHANNEL_LOG_TABLE");
		String KETTLE_JOBENTRY_LOG_SCHEMA = conf.getProperty("KETTLE_JOBENTRY_LOG_SCHEMA");
		String KETTLE_JOBENTRY_LOG_TABLE = conf.getProperty("KETTLE_JOBENTRY_LOG_TABLE");
		String KETTLE_JOB_LOG_SCHEMA = conf.getProperty("KETTLE_JOB_LOG_SCHEMA");
		String KETTLE_JOB_LOG_TABLE = conf.getProperty("KETTLE_JOB_LOG_TABLE");
		String KETTLE_TRANS_LOG_SCHEMA = conf.getProperty("KETTLE_TRANS_LOG_SCHEMA");
		String KETTLE_TRANS_LOG_TABLE = conf.getProperty("KETTLE_TRANS_LOG_TABLE");
		String KETTLE_STEP_LOG_SCHEMA = conf.getProperty("KETTLE_STEP_LOG_SCHEMA");
		String KETTLE_STEP_LOG_TABLE = conf.getProperty("KETTLE_STEP_LOG_TABLE");
		
		String name  = request.getParameter("name"); 
		String date   = request.getParameter("date");
		String type   = request.getParameter("type");
		String channel_id   = request.getParameter("channel_id");
		
		int limit = 12;
		if(request.getParameter("limit")!=null)
			limit = Integer.parseInt(request.getParameter("limit"));
		
	%>
</head> 



<body>
<div id="content">

	<h1>ETL-Pilot<div id='now'>Date</div></h1>
	
	<table><% 
		//TODO: check tables prior executing queries to avoid ugly messages
		//TODO: handle errors
	    String source = 
    			"SELECT DISTINCT 'trans' as type, t.transname as name, t.replaydate as Date, status, (t.logdate - t.replaydate) as duration, lines_output+lines_updated as Output, Errors, t.channel_id from "+KETTLE_TRANS_LOG_TABLE+" t "
	    			+ "INNER JOIN "+KETTLE_CHANNEL_LOG_TABLE+" c on c.channel_id = t.channel_id "
	    			+ "INNER JOIN "
	    				+ "( select max(replaydate) as replaydate, transname from "+KETTLE_TRANS_LOG_TABLE+" group by transname ) _max "
	    				+ "ON _max.replaydate = t.replaydate and _max.transname = t.transname "
	    			+ "WHERE c.root_channel_id = c.channel_id ";
	    if(KETTLE_JOB_LOG_TABLE!=null && !KETTLE_JOB_LOG_TABLE.trim().equals(""))	
    		source +="UNION "
	    			+"SELECT 'job' as type, j.jobname as name, j.replaydate as Date, status, (j.logdate - j.replaydate) as duration, lines_output+lines_updated as Output, Errors, j.channel_id FROM "+KETTLE_JOB_LOG_TABLE+" j "
		    		+ "INNER JOIN "+KETTLE_CHANNEL_LOG_TABLE+" c on c.channel_id = j.channel_id "
		    		+ "INNER JOIN "
		    			+ "( select max(replaydate) as replaydate, jobname from "+KETTLE_JOB_LOG_TABLE+" group by jobname ) _max "
		    			+ "ON _max.replaydate = j.replaydate and _max.jobname = j.jobname "
		    		+ "WHERE c.root_channel_id = c.channel_id ";
	    source += "ORDER BY type, Date desc ";
		ResultSet rs = db.executeQuery(source);
		int columnCount = rs.getMetaData().getColumnCount();

		out.print("<tr>");
		for(int i=1; i<=columnCount-1; i++)
			out.print("<th class='"+rs.getMetaData().getColumnLabel(i)+"'>"+rs.getMetaData().getColumnLabel(i)+"</th>");
		out.println("</tr>");
		
		String key = "";
		String dir = "";
		while(rs.next())
			if(!rs.getString("name").equals(key)){
				
	                int p = rs.getString("name").lastIndexOf("/");
	                if(p>=0 && !rs.getString("name").substring(0,p).equals(dir)) {
			    out.println("<tr><th class='"+rs.getMetaData().getColumnLabel(2)+"'>"+rs.getString("name").substring(0,p)+"</th></tr>");
                            dir = rs.getString("name").substring(0,p);
			}
			
			out.print("<tr>");
			for(int i=1; i<=columnCount; i++){
			    out.print("<td class='"+rs.getMetaData().getColumnLabel(i));

			    //if(i==2 && !lastNight(rs.getString(2)))
                            //    out.print( " warning");
			    if(i==4 && !rs.getString("status").equals("end"))
			       out.print( " warning");
                            if(i==6 && rs.getInt("Output")==0)
			       out.print( " warning");
                            if(i==7 && rs.getInt("Errors")>0)
			       out.print( " warning");

			    if(i==2)
			        out.print("' onclick='refresh(\""+rs.getString("name")+"\", \""+rs.getString("type")+"\")");
			    if(i==3)
			        out.print("' onclick='refresh(\""+rs.getString("name")+"\", \""+rs.getString("type")+"\", \""+rs.getString("Date")+"\", \""+rs.getString("channel_id")+"\")");
			    if(i==1)
			    {
                    out.println("'>"+rs.getString(i).substring(p+1)+"</td>");
			    }
			    else if(rs.getMetaData().getColumnLabel(i).equals("channel_id"))
			    {
			    	out.println("'></td>");
			    }
			    else
			    {
					out.println("'>"+rs.getString(i)+"</td>");						
                }
			}
            out.println("</tr>"); 
            key = rs.getString(1);
		}
		rs.close();
	%></table>
	
	
	

	<% if(name!=null){ // History %> 
	<br /><hr />
		<span style="float: right;">
			Limit: <input id="limit" type="Number" onchange="refresh('<%= name %>')" value="<%= limit%>">
		</span>
	<h2><%= type+":"+name %></h2>
	<table><%
		//String sql = "SELECT * FROM ("+source+") a WHERE Transformation='"+trans+"' LIMIT "+limit;
		String detail = "SELECT DISTINCT 'trans' as type, t.transname as name, t.replaydate as Date, status, (t.logdate - t.replaydate) as duration, lines_output+lines_updated as Output, Errors, t.channel_id from log_etl_trans t "
				+"LEFT JOIN log_etl_channel c on c.channel_id = t.channel_id "
				+"WHERE c.root_channel_id = c.channel_id ";
		if(KETTLE_JOB_LOG_TABLE!=null && !KETTLE_JOB_LOG_TABLE.trim().equals(""))	
			detail += "UNION "
				   + "SELECT 'job' as type, j.jobname as name, j.replaydate as Date, status, (j.logdate - j.replaydate) as duration, lines_output+lines_updated as Output, Errors, j.channel_id FROM log_etl_job j "
				   + "LEFT JOIN log_etl_channel c on c.channel_id = j.channel_id "
				   +"WHERE c.root_channel_id = c.channel_id ";
		detail += "ORDER BY Date desc"; 
		String sql = "SELECT * FROM ("+detail+") a WHERE name='"+name+"' AND type='"+type+"' ORDER BY Date DESC LIMIT "+limit;
		rs = db.executeQuery(sql);
		columnCount = rs.getMetaData().getColumnCount();

		out.print("<tr>");
		for(int i=2; i<=columnCount; i++)
			out.print("<th class='"+rs.getMetaData().getColumnLabel(i)+"'>"+rs.getMetaData().getColumnLabel(i)+"</th>");
		out.println("</tr>");
		
		while(rs.next())
		{
			if(rs.getString("name").trim().equals(name)){
				
				out.print("<tr>");
				for(int i=2; i<=columnCount-1; i++){
					out.print("<td class='"+rs.getMetaData().getColumnLabel(i));
					if(i==2)
						out.print("' onclick='refresh(\""+rs.getString("name")+"\", \""+rs.getString("type")+"\", \""+rs.getString("Date")+"\", \""+rs.getString("channel_id")+"\")");

					out.print("'>"+rs.getString(i)+"</td>");						
				}
				out.println("</tr>");
			}
		}
		rs.close();	
	%></table><%}%>
	
	<% if(name!=null && type.equals("job") && channel_id!=null){ // Job Detail %> 
	<table><%
		/*String sql = "select c.object_name as name, c.log_date, c.logging_object_type, (t.logdate - t.replaydate) as duration, c.channel_id, c.id_batch  "+
				"from  "+KETTLE_CHANNEL_LOG_TABLE+" c " +
				"LEFT JOIN "+KETTLE_TRANS_LOG_TABLE+" t on c.channel_id = t.channel_id " +
				"where root_channel_id='"+channel_id+"' and logging_object_type IN ('JOB', 'TRANS') order by replaydate,logdate asc";*/
		String sql;
		if(KETTLE_JOB_LOG_TABLE!=null && !KETTLE_JOB_LOG_TABLE.trim().equals(""))
		{
			sql = 	"select c.object_name as name "+
				"  , CASE WHEN t.logdate IS NULL THEN j.logdate ELSE t.logdate END as logdate, c.log_date, c.logging_object_type "+
				"  , CASE WHEN t.replaydate IS NULL THEN j.replaydate ELSE t.replaydate END as replaydate "+
				"  , CASE WHEN t.logdate IS NULL THEN (j.logdate - j.replaydate) ELSE (t.logdate - t.replaydate) END as duration, c.channel_id, c.id_batch from "+KETTLE_CHANNEL_LOG_TABLE+" c "+
				"LEFT JOIN "+KETTLE_TRANS_LOG_TABLE+" t on c.channel_id = t.channel_id  "+
				"LEFT JOIN "+KETTLE_JOB_LOG_TABLE+" j on c.channel_id = j.channel_id  "+
				"where root_channel_id='"+channel_id+"' and logging_object_type IN ('JOB', 'TRANS')  "+
				"order by replaydate, logdate ";
		}else
		{
			sql = 	"select c.object_name as name "+
					"  , t.logdate as logdate, c.log_date, c.logging_object_type "+
					"  , t.replaydate  as replaydate "+
					"  , (t.logdate - t.replaydate) as duration, c.channel_id, c.id_batch from "+KETTLE_CHANNEL_LOG_TABLE+" c "+
					"LEFT JOIN "+KETTLE_TRANS_LOG_TABLE+" t on c.channel_id = t.channel_id  "+
					"where root_channel_id='"+channel_id+"' and logging_object_type IN ('TRANS')  "+
					"order by replaydate, logdate ";
		}
		rs = db.executeQuery(sql);
		columnCount = rs.getMetaData().getColumnCount();

		out.print("<tr>");
		for(int i=1; i<=columnCount; i++)
			out.print("<th class='"+rs.getMetaData().getColumnLabel(i)+"'>"+rs.getMetaData().getColumnLabel(i)+"</th>");
		out.println("</tr>");
		
		while(rs.next())
		{
			out.print("<tr>");
			for(int i=1; i<=columnCount; i++){
				out.print("<td class='"+rs.getMetaData().getColumnLabel(i));
				out.print("'>"+rs.getString(i)+"</td>");						
			}
			out.println("</tr>");
			String trans_detail = "select c.logging_object_type, st.* from "+KETTLE_TRANS_LOG_TABLE+"_step st INNER JOIN "+KETTLE_CHANNEL_LOG_TABLE+" c on c.channel_id = st.channel_id "+
				"WHERE c.parent_channel_id = '"+rs.getString("channel_id")+"' and st.id_batch = '"+rs.getString("id_batch")+"'";
			
			/*ResultSet rs2 = db.executeQuery(trans_detail);
			while (rs2.next()){
				out.print("<tr>");
				for(int i=1; i<=rs.getMetaData().getColumnCount(); i++){
					out.print("<td class='"+rs.getMetaData().getColumnLabel(i));
					//if(i==2)
					//	out.print("' onclick='refresh(\""+rs.getString("name")+"\", \""+rs.getString("type")+"\", \""+rs.getString("Date")+"\")");

					out.print("'>"+rs.getString(i)+"</td>");						
				}
				ou t.println("</tr>");
			}
			rs2.close();*/
		}
		rs.close();	
	%></table><%}%>

	
	

	<% if(name!=null && date!=null){ // Log %> 
	<br /><hr />
	<h2>Run of <%= name %> of <%= date %></h2>

	<%
	String logText = "SELECT log_field FROM "+KETTLE_TRANS_LOG_TABLE+" WHERE transname='"+name+"' AND replaydate='"+date+"' AND 'trans'='"+type+"'"; 
    if(KETTLE_JOB_LOG_TABLE!=null && !KETTLE_JOB_LOG_TABLE.trim().equals(""))
		{
			logText += "UNION "
				+"SELECT log_field FROM log_etl_job WHERE jobname='"+name+"' AND replaydate='"+date+"' AND 'job'='"+type+"'"; 
		}
    	rs = db.executeQuery(logText);
		if(rs.next())
			out.println("<textarea>"+rs.getString(1)+"</textarea>");
		rs.close();
	}
	
	
	db.getConnection().close();
	%>
	
	
	
</div>	
<script>
	<% //TODO: Ajax the instead of reload. Use of jQuery ?  %>
	refresh = (name, type, date, channel_id) => {
		//console.log('refresh '+trans+' '+date);
		var url = '<%= request.getRequestURL() %>?'; //mode=' + document.getElementById("mode").value;
        if(name)
            url += '&name='+name;
		if(type)
            url += '&type='+type;
		if(date)
            url += '&date='+date;
		if(channel_id)
            url += '&channel_id='+channel_id;
		if(document.getElementById('limit'))
			url += '&limit='+document.getElementById('limit').value;
		window.location = url;
	}
	
	onload = () => {
		document.getElementById('now').innerHTML = new Date().toISOString().replace('T', ' ').substr(0,19);
		document.body.scrollTop = sessionStorage.getItem('kettleLogScroll');
	}
	document.body.onscroll = () => {
		sessionStorage.setItem('kettleLogScroll', document.body.scrollTop);
	}

	<%!
	boolean lastNight(String date){
		LocalDateTime yesterday = LocalDate.now().minusDays(1).atTime(20,0);
        	LocalDateTime run = LocalDateTime.parse(date, DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.S"));
		return run.isAfter(yesterday);
	}%>
</script>
</body>
</html>
