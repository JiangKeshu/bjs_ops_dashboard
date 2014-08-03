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
