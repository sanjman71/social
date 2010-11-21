class Machine
  
  # return top values
  # e.g. load1, load5, load15
  # e.g. load1, load5, load15, swap, free
  def self.top
    # uptime to find load values
    uptime = %x[uptime].split
    load1  = uptime[-3]
    load5  = uptime[-2]
    load15 = uptime[-1]

    begin
      # vmstat to find swap and free memory usage
      vmstat = %x[vmstat].split
      # find 'wa' to mark end of columns
      wa     = vmstat.index('wa')
      swap   = vmstat[wa+3]
      free   = vmstat[wa+4]
      [load1, load5, load15, free, swap]
    rescue
      [load1, load5, load15]
    end
  end
  
end