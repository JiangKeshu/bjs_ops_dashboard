def parseDSToList(ds)
  l = []
  ds.each do |r|
    t = []
    r.each do |k,v|
      t << v
    end
    l << t
  end

  l
end

def parseListToHash(l)
  rst = {}
  if l.size > 2
    k = l[0]
    l.shift
    rst = {k => parseListToHash(l)}
  else
    rst = {l[0] => l[1]}
  end

  rst
end

def mergeHash_new(h,l)
  key = l.keys[0]
  value = l.values[0]
  if h[key].nil?
    h[key] = value
  else
    ht = h[key]
    mergeHash(ht, value)
  end
end

def mergeHash(h,l)
  key = l.keys[0]
  value = l.values[0]
  if h[key].nil?
    h[key] = value
  else
    if value.class == Hash
      h[key] = h[key].merge(value)
    else
      ht = h[key]
      mergeHash(ht, value)
    end
  end
end

def genChartRawdataString(chartContainer, team, startDate, endDate)
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
                  window.open('/rawdata/?view=#{chartContainer}&team=#{team}&start_date=#{startDate}&end_date=#{endDate}','_blank');
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
	str_exporting
end
