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
		String source = conf.getProperty("source");
		String trans  = request.getParameter("trans"); 
		String date   = request.getParameter("date");
		String logText = conf.getProperty("logText");
		
		int limit = 12;
		if(request.getParameter("limit")!=null)
			limit = Integer.parseInt(request.getParameter("limit"));
		
	%>
</head>



<body><div id="content">

	<h1>Load Status Dashboard<div id='now'>Date</div></h1>
	<table><% 
		ResultSet rs = db.executeQuery(source);
		int columnCount = rs.getMetaData().getColumnCount();

		out.print("<tr>");
		for(int i=1; i<=columnCount; i++)
			out.print("<th class='"+rs.getMetaData().getColumnLabel(i)+"'>"+rs.getMetaData().getColumnLabel(i)+"</th>");
		out.println("</tr>");
		
		String key = "";
		String dir = "";
		while(rs.next())
			if(!rs.getString(1).equals(key)){
				
	                int p = rs.getString(1).lastIndexOf("/");
	                if(p>=0 && !rs.getString(1).substring(0,p).equals(dir)) {
			    out.println("<tr><th class='"+rs.getMetaData().getColumnLabel(1)+"'>"+rs.getString(1).substring(0,p)+"</th></tr>");
                            dir = rs.getString(1).substring(0,p);
			}
			
			out.print("<tr>");
			for(int i=1; i<=columnCount; i++){
			    out.print("<td class='"+rs.getMetaData().getColumnLabel(i));

			    //if(i==2 && !lastNight(rs.getString(2)))
                            //    out.print( " warning");
			    if(i==3 && !rs.getString(3).equals("end"))
			       out.print( " warning");
                            if(i==5 && rs.getInt(5)==0)
			       out.print( " warning");
                            if(i==6 && rs.getInt(6)>0)
			       out.print( " warning");

			    if(i==1)
			        out.print("' onclick='refresh(\""+rs.getString(1)+"\")");
			    if(i==2)
			        out.print("' onclick='refresh(\""+rs.getString(1)+"\", \""+rs.getString(2)+"\")");

                            if(i==1)
                                out.println("'>"+rs.getString(i).substring(p+1)+"</td>");
			    else
				out.println("'>"+rs.getString(i)+"</td>");						
                        }
                        out.println("</tr>");
                        key = rs.getString(1);
		}
		rs.close();
	%></table>
	
	
	

	<% if(trans!=null){ // History %> 
	<br /><hr />
		<span style="float: right;">
			Limit: <input id="limit" type="Number" onchange="refresh('<%= trans%>')" value="<%= limit%>">
		</span>
	<h2><%= trans %></h2>
	<table><%
		//String sql = "SELECT * FROM ("+source+") a WHERE Transformation='"+trans+"' LIMIT "+limit;
		String sql = "SELECT * FROM ("+source+") a WHERE Transformation='"+trans+"' ORDER BY 2 DESC LIMIT "+limit;
		rs = db.executeQuery(sql);
		columnCount = rs.getMetaData().getColumnCount();

		out.print("<tr>");
		for(int i=2; i<=columnCount; i++)
			out.print("<th class='"+rs.getMetaData().getColumnLabel(i)+"'>"+rs.getMetaData().getColumnLabel(i)+"</th>");
		out.println("</tr>");
		
		while(rs.next())
			if(rs.getString(1).equals(trans)){
				
				out.print("<tr>");
				for(int i=2; i<=columnCount; i++){
					out.print("<td class='"+rs.getMetaData().getColumnLabel(i));
					if(i==2)
						out.print("' onclick='refresh(\""+rs.getString(1)+"\", \""+rs.getString(2)+"\")");

					out.print("'>"+rs.getString(i)+"</td>");						
				}
				out.println("</tr>");
		}
		rs.close();	
	%></table><%}%>

	
	

	<% if(trans!=null && date!=null){ // Log %> 
	<br /><hr />
	<h2>Run of <%= trans %> of <%= date %></h2>

	<%
		PreparedStatement stmt = db.getConnection().prepareStatement(logText);
		stmt.setString(1, trans);
		stmt.setString(2, date);
		rs = stmt.executeQuery();
		if(rs.next())
			out.println("<textarea>"+rs.getString(1)+"</textarea>");
		rs.close();
	}
	
	
	db.getConnection().close();
	%>
	
	
	
	
<script>
	refresh = (trans, date) => {
		//console.log('refresh '+trans+' '+date);
		var url = '<%= request.getRequestURL() %>?'; //mode=' + document.getElementById("mode").value;
        if(trans)
            url += '&trans='+trans;
		if(date)
            url += '&date='+date;
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
