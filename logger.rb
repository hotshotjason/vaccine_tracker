
=begin
# different  level of message
# use trace(caller,message)  for debug
# use log(caller,message)  for normal log message

or 
# trace(message)
# log(message)

if you don't want to print the caller info
=end

class MyLogger
  @@debug = false

  def self.log(caller_obj,input=nil)
    if  caller_obj.instance_of? String
      puts caller_obj
    else
      subroutine = parse_caller(caller_obj)
      puts "[#{subroutine} #{Time.now}] #{input}"
    end
  end

  # caller can be nil i
  def self.trace(caller_obj,input=nil)
    if @@debug
      if  caller_obj.instance_of? String
        puts caller_obj
      else
        subroutine = parse_caller(caller_obj)
        puts "[#{subroutine} #{Time.now}] #{input}"
      end
    end
  end

  # return the method of the caller
  def self.parse_caller(caller_obj)
    if ! caller_obj
      return ""
    elsif caller_obj[0] =~ /\/([^\/]+)$/
      return $1      
    else
      raise "unexpected caller id #{caller_obj}"
    end 
  end

  def self.debug?
    @@debug
  end
    
  def self.debug!(input)
    @@debug = input
  end
end
