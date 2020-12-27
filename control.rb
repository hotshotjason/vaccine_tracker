require_relative  'piface/piface'

module Control

end


# any control
class Control::Base
  attr_reader :input,
              :output,
              :error

  # contains the input/output unique to each control.
  # this is dervied from setup.yaml
  @@controls = Hash.new
  @@debug_val = true

  def initialize
    class_name_string = self.class.to_s
    @name  =  @@controls[class_name_string]['name']
    @debug = true
    raise "no name" if ! @name

    @error = false
    @disable = false  # true means button can't work (usb device not detected)
    @usb = false
  end


  def self.load(input_cfg)
    class_name_string = self.to_s  # raw class name as input
    #puts "write to #{class_name_string}"
    @@controls[class_name_string] = input_cfg
  end

  # use @name for consist route to check device
  def route_check
    #print "route_check name is #{@name}. class is #{self.class}\n"
    @name + "/check" 
  end

  # use @name for consist route to check device
  def route_toggle
    @name + "/toggle"
  end

  def error?
    @error
  end

  def usb?
    @usb
  end
end

require_relative 'blackbox'

# piface standarod controls
class Control::PiFace   < Control::Base
              
  def initialize
    super
    class_name_string = self.class.to_s
    if !  @@controls.has_key? class_name_string
      raise "class #{class_name_string} needs to be added into  Control::Setup"
    end
    
    @input =  @@controls[class_name_string]['input']
    @input2 =  @@controls[class_name_string]['input2']
    @output = @@controls[class_name_string]['output']
    @invert = @@controls[class_name_string]['invert']
    # usb device don't have output
    raise "no output" if ! @output
    @error = false   # error message is true
  end

  # takes the elerical signal (1 or 0) and convert it to logical boolean
  def logical(input)
    if @invert
      if input == 0
        return true
      else
        return false
      end
    else
      if input == 0
        return false
      else
        return true
      end
    end
  end

  # default use @output as status
  # unless @input is specified.  
  # if @input2 is specified, then the value is the or of @input , @input2
  def status
    if @input
      puts "#{self.class} read from input #{@input}" if @debug
      return_val =  false

      if logical(Piface.read(@input))
        return_val = true
      end 
      if @input2
        puts "#{self.class} read from input2 #{@input2}" if @debug
        if logical(Piface.read(@input2))
          return_val = true
        end 
      end
    else
      return_val = logical(Piface.read_output(@output))
    end
    puts "#{self.class}  input #{@input}. output #{@output}.  invert is #{@invert}. pre status is #{return_val}" if @debug
    return_val
  end

  # call by /check/all 
  # return a hash which will be coverted to json
  def status_hash
    return_val = { status: status ,
                   post: true,      # settable
                   disable: @disable,
                   error: @error }
    return_val
  end

  # debug version
  def status_debug
    if @@debug_val
      @@debug_val = false
    else
      @@debug_val = true
    end
    @@debug_val
  end

  def on!
    Piface.write @output, 1
  end

  def off!
    Piface.write @output, 0
  end

  # read the actual status to determine on or off
  def toggle!
    if status
      off!
      return false
    else
      on!
      return true
    end
  end
  
  alias_method :toggle_super!, :toggle!

  


  


end
####################################################
#  USB
# currently just used to check if the USB device is plugged in
################################################

module Control::USB
end

# this is class that basically run lsusb and returns the status of all usb devices
# then individual usb device and lookup this class
class Control::USB::ALL

  def initialize
    load  
  end

  def load
    output =   `lsusb`
    lines = output.split(/\n/)
    @devices = []
    lines.each do |current_line|
      #puts current_line
      if current_line =~ /^Bus\s+(\d+)\s+Device\s+(\d+):\s+ID\s+(\S+)\s+(.*)/
        current_usb = { bus: $1.to_i, device: $2.to_i, id: $3, description: $4 }
      else
        raise "unexpected lsusb format #{current_line}"
      end
      @devices << current_usb
    end  
  end

  # return false if can't find this pattern
  def find(input_pattern)
    @devices.each do |current_device|
      if current_device[:description] =~ /#{input_pattern}/i
        return true
      end
    end
    return false
  end

end

class Control::USB::Base < Control::Base

  def initialize
    super
    @error = false   
    @usb = true
  end

  def common_status(result)
    @usb_device = result
    @disable = ! @usb_device
    @usb_device
  end

  def status_hash
    status
    return_val = { status: @usb_device,
                   disable: @disable
                }
  end

  # since it is just a status
  # on! off! toggle!  doesn't realy do anything
  def on!
    return false
  end

  def off!
    return false
  end

  def toggle!
    return false
  end
end

class Control::USB::Pclmsi < Control::USB::Base
  def initialize 
    super
  end

  def status
    common_status(Control::Manager.usb.find("Netchip Technology"))
  end
end

class Control::USB::Flashrom < Control::USB::Base
  def initialize 
    super
  end

  def status
    common_status(Control::Manager.usb.find("SGS Thomson Microelectronics"))
  end
end



######################
#  BUTTONS 
####################

module Control::Button
end

class Control::Button::Reset < Control::PiFace
  def initialize 
    super
  end

  def toggle!
    Piface.write @output, 1
    sleep 1
    Piface.write @output, 0
  end 
end

class Control::Button::Power < Control::PiFace
  def initialize 
    super
  end

  def toggle!
    if status  
      sleep_time = 5 # soft power need to hold power off button longer
    else
      sleep_time = 1 # turn on is much faster
    end
    Piface.write @output, 1
    sleep sleep_time
    Piface.write @output, 0
    sleep 1  # since the power button is looking at the INPUT pin from reset, there is a lag
             # from turning power on  to sensing it. so sleep 1 here so when webpage reloads after toggle, it will pick up right value
  end 

end

##### POWER ######
module Control::Power
end

##### AC POWER ######
class Control::Power::AC < Control::PiFace
  def initialize
    super
  end

  def toggle!
    toggle_super!
    puts "power ac sleep 1"   if @debug
    # need to sleep 1 so when you turn of ac power, the  Control::Button::Power will reflect off as well (it is an input there is a lag)
    sleep  1
  end
    
end

##### VNC POWER ######
class Control::Power::VNC < Control::PiFace
  def initialize
    super
  end
end

##### setup controls  ######
# read setup.yaml and
# make all the class match the cfg 
class Control::Manager
  
  @@controls = Hash.new
  @@controls['vnc'] = Control::Power::VNC
  @@controls['ac'] = Control::Power::AC
  @@controls['reset'] = Control::Button::Reset
  @@controls['power'] = Control::Button::Power
  @@controls['flashrom'] = Control::USB::Flashrom
  @@controls['pclmsi'] = Control::USB::Pclmsi
  @@controls['peltier'] = BlackBox

  @@usb = []

  def initialize
    cfg = YAML::load( File.open("setup.yaml") )
    cfg.each do |control_cfg|
      control_name = control_cfg['name']
      raise "can't find control #{control_name}"  if ! @@controls.has_key? control_name
      #puts "load #{@@controls[control_name].to_s}. cfg is #{control_cfg}" 
      @@controls[control_name].load(control_cfg)
    end
    #@@controls.each do |key,val|
    #  obj = @@controls[key].new
    #  print "instantiate #{obj.class}. input #{obj.input}. output #{obj.output}\n"
    #end
  end

  def self.controls
    @@controls
  end

  def run

  end

  def self.load
    obj = Control::Manager.new
    obj.run
  end

  # make it a usb hash file
  def self.lsusb
    @@usb = Control::USB::ALL.new
  end



  def self.usb
    @@usb
  end



end

