require 'json'
require 'date'
require 'pp'
LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }


def getWeeklyCRSPByQueue(type, startDate, endDate)
	result = {} 
	categories = getCategories(startDate, endDate)
	result["categories"] = categories
	sequel = DBConf.new
	ds = sequel.getWeeklyCRSPByQueue( type, startDate, endDate)
	hashCRSP = {}
	ds.each { |r| 
		queueName = r[:queue_name]
		weekName = r[:week_name]
		ct = r[:ct]
		if hashCRSP[queueName].nil?
			hashCRSP[queueName] = {}
			hashCRSP[queueName] = { weekName => ct}
		else
			hashCRSP[queueName].merge!({weekName => ct})
		end
	}
	sequel.close()
	result["series"] = []
	hashCRSP.each { |k,v| 
		t = {}
		t["name"] = k
		t["data"] = []
		categories.each { |week_name|
			if !v[week_name].nil?
				t["data"] << v[week_name]
			else
				t["data"] << 0
			end
		}
		result["series"] << t
	}
	result
end

def getWeeklyCRSPByType(startDate, endDate)
	result = {}
	categories = getCategories(startDate, endDate)
	result["categories"] = categories
	sequel = DBConf.new
	ds = sequel.getWeeklyCRSPByType(startDate, endDate)
	hashCRSP = {}
	ds.each { |r|
		type = r[:type]
		weekName = r[:week_name]
		ct = r[:ct]
		if hashCRSP[type].nil?
			hashCRSP[type] = {}
			hashCRSP[type] = { weekName => ct }
		else
			hashCRSP[type].merge!({weekName => ct})
		end
	}
	sequel.close()
	result["series"] = []
	hashCRSP.each { |k,v|
		t = {}
		t["name"] = k
		t["data"] = []
		categories.each { |week_name|
			if !v[week_name].nil?
				t["data"] << v[week_name]
			else
				t["data"] << 0
			end
		}
		result["series"] << t
	}
	result
end

def getWeeklyCasesByStatus(team, startDate, endDate)
  result = {}
	categories = getCategories(startDate, endDate)
	result["categories"] = categories
	sequel = DBConf.new
	ds = sequel.getWeeklyCasesByStatus(team, startDate, endDate)
	hashCRSP = {}
	ds.each { |r|
		status = r[:status]
		weekName = r[:week_name]
		ct = r[:ct]
		if hashCRSP[status].nil?
			hashCRSP[status] = {}
			hashCRSP[status] = { weekName => ct }
		else
			hashCRSP[status].merge!({weekName => ct})
		end
	}
	sequel.close()
	result["series"] = []
	hashCRSP.each { |k,v|
		t = {}
		t["name"] = k
		t["data"] = []
		categories.each { |week_name|
			if !v[week_name].nil?
				t["data"] << v[week_name]
			else
				t["data"] << 0
			end
		}
		result["series"] << t
	}
	result

end

def getWeeklyCasesBySeverity(team, startDate, endDate)
  result = {}
	categories = getCategories(startDate, endDate)
	result["categories"] = categories
	sequel = DBConf.new
	ds = sequel.getWeeklyCasesBySeverity(team, startDate, endDate)
	hashCRSP = {}
	ds.each { |r|
		severity = r[:severity]
		weekName = r[:week_name]
		ct = r[:ct]
		if hashCRSP[severity].nil?
			hashCRSP[severity] = {}
			hashCRSP[severity] = { weekName => ct }
		else
			hashCRSP[severity].merge!({weekName => ct})
		end
	}
	sequel.close()
	result["series"] = []
	hashCRSP.each { |k,v|
		t = {}
		t["name"] = k
		t["data"] = []
		categories.each { |week_name|
			if !v[week_name].nil?
				t["data"] << v[week_name]
			else
				t["data"] << 0
			end
		}
		result["series"] << t
	}
	result

end

def getWorkloadReport(team, startDate, endDate, granu)
	result = [] 
	periodList = getCategories(startDate, endDate)

	sequel = DBConf.new
	dsList = {}
	dsList["dsCreatedCaseCount"] = sequel.getCreatedCaseCount(team, startDate, endDate, granu)
	dsList["dsClosedCaseCount"] = sequel.getClosedCaseCount(team, startDate, endDate, granu)
	dsList["dsCorrespondences"] = sequel.getCorrespondenceCount(team, startDate, endDate, granu)

	arrayWorkload = {}
	dsList.each { |k,v|
		arrayTmp = {}
		v.each {|v2|
			arrayTmp[v2[:period]] = v2[:ct]
		}
		arrayWorkload[k] = arrayTmp
	}
	sequel.close()
	periodList.each { |p|
		r = {}
		r["Reroid"] = p
		r["IncomingCases"] = arrayWorkload["dsCreatedCaseCount"][p].nil?? 0 : arrayWorkload["dsCreatedCaseCount"][p]
		r["ClosedCases"] = arrayWorkload["dsClosedCaseCount"][p].nil?? 0 : arrayWorkload["dsClosedCaseCount"][p]
		r["Correspondences"] = arrayWorkload["dsCorrespondences"][p].nil?? 0 : arrayWorkload["dsCorrespondences"][p]
		arrayTmp = []
		r.each { |k,v|
			arrayTmp << v
		}
		result << arrayTmp	
	}
	result
end

def getOpeningCases(team, chartContainer)
	assigns = {}
	sequel = DBConf.new
	ds = sequel.getOpeningCasesDS(team)
	drillds = sequel.getOpeningCasesDrilldownDS(team) 

	listDS = parseDSToList(ds)
	listDrillDS = parseDSToList(drillds)
	hashResult = {}
	hashDrillResult = {}
	listDS.each do |d|
		h = parseListToHash(d)
		mergeHash(hashResult, h)
	end
	listDrillDS.each do |d|
		h = parseListToHash(d)
		mergeHash(hashDrillResult, h)
	end
	sequel.close()
	assigns[:categories] = hashResult.keys
	assigns[:name] = "Opening cases of #{team}"
	count = 0
	lData = []
	colors = ["#7cb5ec", "#90ed7d", "#f7a35c", "#8085e9", "#f15c80", "#e4d354", "#8085e8", "#8d4653", "#91e8e1", "#434348"]
	totalNum = 0
	hashResult.each do |k,v|
		totalNum = totalNum + v.to_i
		hData = {}
		hData["y"] = v
		hData["color"] = colors[count]
		hData["drilldown"] = {}
		hData["drilldown"]["name"] = k
		hData["drilldown"]["categories"] = hashDrillResult[k].keys
		hData["drilldown"]["data"] = hashDrillResult[k].values
		hData["drilldown"]["color"] = colors[count]
		lData << hData
		count = count + 1
	end

	str_exporting = %Q[
          exporting: {
            buttons: {
              contextButton: {
                enabled: false
              },
              customButton: {
                text: 'Raw data',
                symbol: 'menu',
                //symbolStroke: '#333333',
                height: 50,
                onclick: function () {
									window.open('/rawdata/?view=#{chartContainer}&team=#{team}&start_date=&end_date=','_blank');
                },
                theme: {
                  padding: 3,
                  stroke: '#585858',
                  states: {
                    hover: {
                      fill: '#f5f5f5'
                    }
                  }
                }
              }
            }
          },
	]
	assigns[:data] = lData.to_json
	assigns[:container] = team.downcase+"_"+chartContainer
	assigns[:title] = "#{team}"
	assigns[:ytitle] = "ytitle"
	assigns[:innerName] = "Status"
	assigns[:outerName] = "Queue"
	assigns[:totalNum] = totalNum
	assigns[:rawdata] = str_exporting
	assigns
end


def getCaseDurationChart(team, startDate, endDate, container, granu)
	assigns = {}
	categories = getCategories(startDate, endDate)
	sequel = DBConf.new
	ds = sequel.getCaseDurationDS(team, startDate, endDate, granu)
	listDS = parseDSToList(ds)
	hashResult = {}
	listDS.each do |d|
		h = parseListToHash(d)
		mergeHash(hashResult, h)
	end
	sequel.close()
	data = []
	hashResult.each do |k,v|
		hashTmp = {}
		hashTmp["name"] = k
		listValue = []
		categories.each do |c|
			if v[c].nil?
				listValue << 0
			else
				listValue << v[c]
			end
		end
		hashTmp["data"] = listValue
		data << hashTmp
	end
	assigns[:data] = data.to_json
	assigns[:categories] = categories.to_json	
	assigns[:container] = container	
	assigns
end

def getCaseSLAChart(team, startDate, endDate, container, granu)
	assigns = {}
	categories = getCategories(startDate, endDate)
	sequel = DBConf.new
	ds = sequel.getCaseSLAStatisticsDS(team, startDate, endDate, granu)
	listDS = parseDSToList(ds)
	hashResult = {}
	listDS.each do |d|
		h = parseListToHash(d)
		mergeHash(hashResult, h)
	end
	sequel.close()
	data = []
	hashResult.each do |k,v|
		hashTmp = {}
		hashTmp["name"] = k
		listValue = []
		categories.each do |c|
			if v[c].nil?
				listValue << 0
			else
				listValue << v[c]
			end
		end
		hashTmp["data"] = listValue
		data << hashTmp
	end

	assigns[:data] = data.to_json
	assigns[:categories] = categories.to_json	
	assigns[:container] = container	
	assigns
end

def getCaseDurationChart(team, startDate, endDate, container, granu)
	assigns = {}
	categories = getCategories(startDate, endDate)
	sequel = DBConf.new
	ds = sequel.getCaseDurationDS(team, startDate, endDate, granu)
	listDS = parseDSToList(ds)
	hashResult = {}
	listDS.each do |d|
		h = parseListToHash(d)
		mergeHash(hashResult, h)
	end
	sequel.close()
	data = []
	hashResult.each do |k,v|
		hashTmp = {}
		hashTmp["name"] = k
		listValue = []
		categories.each do |c|
			if v[c].nil?
				listValue << 0
			else
				listValue << v[c]
			end
		end
		hashTmp["data"] = listValue
		data << hashTmp
	end
	assigns[:data] = data.to_json
	assigns[:categories] = categories.to_json	
	assigns[:container] = container	
	assigns
end

def getTTRSeverityChart(team, startDate, endDate, container, granu)
	assigns = {}
	categories = getCategories(startDate, endDate)
	sequel = DBConf.new
	ds = sequel.getTTRSeverityDS(team, startDate, endDate, granu)
	listDS = parseDSToList(ds)
	hashResult = {}
	listDS.each do |d|
		h = parseListToHash(d)
		mergeHash_new(hashResult, h)
	end
	sequel.close()
	pp hashResult
	data = []
	hashResult.each do |k,v|
		v.each do |k2,v2|
			hashTmp = {}
			hashTmp["name"] = k
			hashTmp["stack"] = k2
			listValue = []
			categories.each do |c|
				if v2[c].nil?
					listValue << 0
				else
					listValue << v2[c]
				end
			end
			hashTmp["data"] = listValue
			data << hashTmp
		end
	end
	assigns[:data] = data.to_json
	assigns[:categories] = categories.to_json	
	assigns[:container] = container	
	assigns
end

def getCaseCRSPChart(team, startDate, endDate, container)
	categories = getCategories(startDate, endDate)
	
end

def getCategories(startDate, endDate)
	result = []
	s = DateTime.parse(startDate,"%Y%m%d").strftime("%Y") + "/" + (DateTime.parse(startDate,"%Y%m%d").strftime("%W").to_i+1).to_s+'w'
	e = DateTime.parse(endDate,"%Y%m%d").strftime("%Y") + "/" + (DateTime.parse(endDate,"%Y%m%d").strftime("%W").to_i+1).to_s+'w'
	result << s
	tmpDate = startDate
	t = DateTime.parse(tmpDate,"%Y%m%d").strftime("%Y") + "/" + (DateTime.parse(tmpDate,"%Y%m%d").strftime("%W").to_i+1).to_s+'w'
	while t != e
		tmpDate = (DateTime.parse(tmpDate,"%Y%m%d") + 7).strftime("%Y%m%d")
		t = DateTime.parse(tmpDate,"%Y%m%d").strftime("%Y") + "/" + (DateTime.parse(tmpDate,"%Y%m%d").strftime("%W").to_i+1).to_s+'w'
		result << t
	end
	result
end
