<html>
	<meta charset="utf8" />
	<%@ page import="java.io.*" %>
	<%@ page import="java.sql.*" %>
	<%@ page import="java.util.*" %>	

<head>
	<style>
		* { font-family: Sans-serif; }
		canvas { position: absolute; left: 0; top: 0; z-index: -1; }
		#indicator { float: right; }
	</style> 

	
	<%  // Get parmeters from config file and from url
		Properties conf = new Properties();
		conf.load(new FileInputStream(getServletContext().getRealPath("/")+"/config.properties"));
		
		String driver = conf.getProperty("driver"); 
		Class.forName("org.mariadb.jdbc.Driver");
		Statement db = DriverManager.getConnection(
			conf.getProperty("connection"),
			conf.getProperty("username"),
			conf.getProperty("password")
		).createStatement();
		String source  = conf.getProperty("source");
		String trans   = request.getParameter("trans"); 
		String measure = request.getParameter("measure");
		
		int graphDotSize = 3;
		
		String sql;
		ResultSet rs;
	%>
</head>



<body>
	<select id="Transformation" onchange="refresh()" >
	<%
		sql = "SELECT DISTINCT Transformation FROM ("+source+") a ORDER BY 1";
		rs = db.executeQuery(sql);
		out.println("<option disabled selected value=''>Transformation:</option>");
		while(rs.next())
			out.println("<option>"+rs.getString(1)+"</option>");
		rs.close();
	%>
	</select>
	<script>
		document.getElementById('Transformation').value = '<%= trans %>';
	</script>
	
	
	<select id="Measure" onchange="refresh()" >
	<%
		sql = source+" LIMIT 1";
		rs = db.executeQuery(sql);
		ResultSetMetaData meta = rs.getMetaData();
		out.println("<option disabled selected value=''>Measure:</option>");
		out.println("<option value='Date'>Time since last run</option>");
		for(int i=3; i<=meta.getColumnCount(); i++)
			if(isNumeric(meta.getColumnType(i)))
				out.println("<option>"+meta.getColumnLabel(i)+"</option>");
		rs.close();
	%>
	</select>
	<script>
		document.getElementById('Measure').value = '<%= measure %>';
	</script>

	<div id="indicator">
		<input id="fit"       type="checkbox" onchange="graph()" />Fit<br>
		<input id="trend"     type="checkbox" onchange="graph()" />Trend<br>
		<input id="interval"  type="checkbox" onchange="graph()" />Interval<br>
		<input id="smoothing" type="checkbox" onchange="graph()" />Smoothing<br>
		<input id="factor"    type="range"    oninput="graph()" step="any" value="30" >
	</div>
	
	<canvas id="graph"></canvas>
	
<script>
	var data = [];
	var stat = {};
	
	onload = () => {
		data = [];
		<% 
		if(trans!=null && measure!=null && !measure.isEmpty()){
			sql = "SELECT Date, "+measure+" FROM ("+source+") a WHERE Transformation='"+trans+"' ORDER BY 1"; 
			rs = db.executeQuery(sql);
			while(rs.next())
				out.println("data.push({t:'"+rs.getString(1)+"',x:'"+rs.getString(2)+"'});");
			rs.close();
		}%>
		if(data.length>0){
			if("<%= measure %>"=="Date"){
				var x_ = 0;
				for(d of data){
					var x = new Date(d.x).getTime();
					d.x = (x-x_) /1000/60/60/24;
					x_ = x;
				}
				data.shift();
			}
			else if(p = data[0].x .match(/^(\d\d):(\d\d):(\d\d)/))
				for(d of data){
					p = d.x .match(/^(\d\d):(\d\d):(\d\d)/);
					if(p)
						d.x = Number(p[1])*3600+Number(p[2])*60+Number(p[3]);
				}
			else for(d of data)
				d.x = Number(d.x);
		stat = computeStatistics(data);
		graph();
		}
	}


	refresh = () => {
		var measure = document.getElementById('Measure').value;
		var url = '<%= request.getRequestURL() %>';
		url += '?trans='+document.getElementById('Transformation').value;
		url += '&measure='+document.getElementById('Measure').value;
		//console.log(url);
		window.location = url;
	}
	
	
	
	<%! 
	boolean isNumeric(int type){
        if(type==Types.BIGINT)
            return true;
        if(type==Types.DECIMAL)
            return true;
        if(type==Types.DOUBLE)
            return true;
        if(type==Types.FLOAT)
            return true;
        if(type==Types.INTEGER)
           return true;
        if(type==Types.NUMERIC)
           return true;
        if(type==Types.REAL)
           return true;
        if(type==Types.SMALLINT)
           return true;
	   if(type==Types.DATE)
           return true;
        if(type==Types.TIME)
           return true;
        if(type==Types.TIMESTAMP)
           return true;
        if(type==Types.TIMESTAMP_WITH_TIMEZONE)
           return true;
        if(type==Types.TIME_WITH_TIMEZONE)
           return true;

        return false;
    } %>

	
	graph = () => {
		g = document.querySelector('canvas').getContext("2d");
		g.canvas.width  = window.innerWidth;
		g.canvas.height = window.innerHeight;
		
		g.tMin = 0.07 * g.canvas.width;
		g.tMax = 0.95 * g.canvas.width;
		g.xMin = 0.8 * g.canvas.height
		g.xMax = 0.1 * g.canvas.height;

		g.dot = <%= graphDotSize %>;
		
		data.tMin = new Date('2017-04-01').getTime();
		data.tMax = new Date('2017-11-01').getTime();
		
		data.xMin = 0;
		data.xMax = 0;
		data.xStep ;
		for(var d of data)
			if(data.xMax<d.x)
				data.xMax = d.x;
		if(data.xMax<=0) data.xMax=1;
		
		var size = Math.pow(10, Math.floor(Math.log10(data.xMax)));
		for(var m of [1.5, 2.0, 2.5, 5.0, 7.5, 10.])
			if(data.xMax < m*size)
				break;
		data.xMax = m*size;
		if(m==1.5) data.xStep = .25*size;
		if(m==2.0) data.xStep = 0.5*size;
		if(m==2.5) data.xStep = 0.5*size;
		if(m==5.0) data.xStep = 1.0*size;
		if(m==7.5) data.xStep = 2.5*size;
		if(m==10.) data.xStep = 2.0*size;

		// tAxis
		g.beginPath();
		g.moveTo(g.tMin, g.xMin); g.lineTo(g.tMin, g.xMax);
		var t = new Date('2017-04-01');
		while(t < new Date('2017-11-30')){
			//console.log(t);
			var gt = (t-data.tMin)/(data.tMax-data.tMin) * (g.tMax-g.tMin) + g.tMin;
			g.moveTo(gt, g.xMin); g.lineTo(gt, g.xMin+10);
			var s = t.toISOString().substring(0,10);
			g.fillText(s, gt-g.measureText(s).width/2, g.xMin+20);
			t.setMonth(t.getMonth()+1);
		}
		g.stroke();

		// xAxis
		g.beginPath();
		g.moveTo(g.tMin, g.xMin); g.lineTo(g.tMax, g.xMin);
		for(var x = data.xMin; x<=data.xMax; x+=data.xStep){
			var gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
			g.moveTo(g.tMin, gx); g.lineTo(g.tMin-10, gx);
			var s = x;
			g.fillText(s, g.tMin-g.measureText(s).width-15, gx+3);
		}	
		g.stroke();
				
		drawData(g,data);
		if(document.getElementById('fit').checked)
			drawFit(g, data);
		if(document.getElementById('smoothing').checked)
			expSmooth(g, data);
		
	}

	drawData = (g, data) => {
		g.beginPath();
		for(var d of data){
			var gt = (new Date(d.t)-data.tMin)/(data.tMax-data.tMin) * (g.tMax-g.tMin) + g.tMin;
			var gx = (d.x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
			g.fillRect(gt-g.dot/2, gx-g.dot/2, g.dot, g.dot);
		}
		g.stroke();
		g.fill();
	}
	
	drawFit = (g, data) => {		
		g.beginPath();
		g.strokeStyle="#FF0000";
		var x, gx;
		var trend = 0;
		var dx = 0;	
			
		if(document.getElementById('trend').checked)
			trend = stat.trend;
		if(document.getElementById('interval').checked)
			dx = 2*stat.xStd; //Math.sqrt(stat.N);
		
		x = trend*(data.tMin-stat.tAvg) + stat.xAvg +dx;
		gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
		g.moveTo(g.tMin, gx);
		x = trend*(data.tMax-stat.tAvg) + stat.xAvg +dx;
		gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
		g.lineTo(g.tMax, gx);

		x = trend*(data.tMin-stat.tAvg) + stat.xAvg -dx;
		gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
		g.moveTo(g.tMin, gx);
		x = trend*(data.tMax-stat.tAvg) + stat.xAvg -dx;
		gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
		g.lineTo(g.tMax, gx);
		
		g.stroke();		
	}
	
	
	expSmooth = (g, data) => {
		g.beginPath();
		g.strokeStyle="#FF0000";
		var smooth = document.getElementById('factor').value /100;
		smooth = smooth*smooth;
		var trend = 0;
		var S   = 0;
		var Se  = 0;
		var See = 0;

/*
		if(document.getElementById('trend').checked)
			trend = stat.trend;
*/
		var x = stat.xAvg;
		if(document.getElementById('interval').checked)
			dx = 4*stat.xStd*stat.xStd;
		
		var gt = (data.tMin-data.tMin)/(data.tMax-data.tMin) * (g.tMax-g.tMin) + g.tMin;
		var gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
		g.moveTo(gt, gx);

		for(var d of data){
			x = x + smooth*(d.x-x);
			gt = (new Date(d.t).getTime()-data.tMin)/(data.tMax-data.tMin) * (g.tMax-g.tMin) + g.tMin;
			gx = (x-data.xMin)/(data.xMax-data.xMin) * (g.xMax-g.xMin) + g.xMin;
			g.lineTo(gt, gx);
		}
		g.stroke();		
	}

	
	computeStatistics = (data) => {
		var S = 0;
		var St = 0;
		var Sx = 0;
		var Stt = 0;
		var Stx = 0;
		var Sxx = 0;
		for(var d of data){
			var t = new Date(d.t).getTime() ;// - data.tMin;
			var x = Number(d.x);
			S  += 1;
			St += t;
			Sx += x;
			Stt += t*t;
			Stx += t*x;
			Sxx += x*x;
		}
		if(S>1){
			St = St /S ; //+ data.tMin;
			Sx = Sx /S;
			Stt = (Stt - S*St*St) /(S-1);
			Stx = (Stx - S*St*Sx) /(S-1);
			Sxx = (Sxx - S*Sx*Sx) /(S-1);
		}
		var trend = Stx / Stt;
		
		return {N: S, tAvg: St, xAvg: Sx, xStd: Math.sqrt(Sxx), trend: trend } ;
	}
	</script>
</body>
