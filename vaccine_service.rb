

# this must be defined BEFORE require sinatra"  for the exit to happen when webserver goes down
at_exit { 
}

require 'sinatra'

require 'rubygems'
#require 'bundler/setup'
require 'haml'
require 'yaml'
require 'json'
require 'open3'
require 'awesome_print'

#require_relative 'switches'

require_relative 'helpers'
require_relative 'logger'
require_relative 'logger'
require_relative 'override'
require_relative 'data_set'  
require_relative 'html_helper'  
require_relative 'chart_maker'   # for display line/bar chart

############## class #########################
class Vaccine

  attr_reader :name,
              :chart_number,
              :chart_efficacy_rate

  @@all_vaccines_array = []

  def self.add_data!(current_vaccine,current_data)
    new_data = Marshal.load(Marshal.dump(current_data))
    current_vaccine.add_data! new_data
    current_vaccine.make_chart!

    # clone the data to @all_vaccines_chart
    new_data = Marshal.load(Marshal.dump(current_data))
    @@all_vaccines_chart.add_data! new_data

    @@all_vaccines_array << current_vaccine
  end

  def self.init_all_vaccines
    #puts "ruby version #{RUBY_VERSION}"
    @@all_vaccines_chart = Vaccine.new(all: true)  # hold all vaccines data togher so we can draw a chart
    @@all_vaccines_array << @@all_vaccines_chart
  
    ###################  Vaccine ######################
    current_vaccine = Vaccine.new
    current_data = DataSet::Bnt162b2.new
    add_data!(current_vaccine,current_data)

    ###################  Vaccine ######################
    current_vaccine = Vaccine.new
    current_data = DataSet::MRNA1273.new
    add_data!(current_vaccine,current_data)

    ################## VERY END ##########################
    @@all_vaccines_chart.make_chart!
    
  end

  def self.all_vaccines_array
    @@all_vaccines_array
  end

  def self.find_vaccine(input_name)
    @@all_vaccines_array.each do |current|
      if current.name == input_name
        return current
      end
    end
    return nil
  end

  def initialize(args=Hash.new)
    @all = args[:all]
    if @all
      @name  = "all"
    end 
  end
  

  def add_data!(input_chart_data)
    if ! @chart_data
      @chart_data = input_chart_data
    else
      puts "chart data: #{@chart_data.class} merge data #{input_chart_data.class}"
      @chart_data.merge_data! input_chart_data
    end
  end

  def make_chart!
    if ! @name
      @name = @chart_data.name
    end
    #add_color!(@chart_data.content_number)
    #add_color!(@chart_data.contente_efficacy_rate)
    if @all
      current_name = "All vaccines"
      current_developer = ""
    else
      current_name = @name
      current_developer = @chart_data.developer
    end
    @chart_number =   ChartMaker::Scatter.new(id: current_name, title: "#{current_developer} #{current_name} number of people vaccinated", content: @chart_data.content_number, size: "medium", y_label: "number vaccinated", time: "week", source: @source)
    @chart_efficacy_rate =   ChartMaker::Scatter.new(id: current_name, title: "#{current_developer} #{current_name} efficacy rate", content: @chart_data.content_efficacy_rate, size: "medium", y_label: "efficacy rate", source: @source)
  end


  def description
    if @all
      return "all"
    else 
      return "#{@chart_data.developer}(#{@chart_data.name})"
    end
  end

  init_all_vaccines
end


class MessageData

MAX_DATA_SIZE = 200
  attr_reader :data
  
  def initialize(file)
    @file = file
  end

  def load
    if File.exist?  @file
      @data = JSON.parse(IO.read(@file))
    else
      @data = []  # blank
    end
  end

  def save
    File.open(@file,"w") do |handle|
      handle.puts @data.to_json
    end
  end


  def parse(request,input_params)
    #print "param is #{input_params}  class #{input_params.class}\n"
    #current = Marshal.load(Marshal.dump(input_params))
    current = JSON.parse(input_params.to_json)   # deep clone since Marshall doesn't work (this input_param hash is strange)

    current['ip'] = request.ip  # add ip
    current['time'] = Time.now    # add time
    print "current after #{current}\n"

    add(current)
    { result: 'good' }.to_json
  end

  def add(input)
    @data.unshift(input)
    if @data.size > 200  #keep data message small for now because I am storing in file
      @data.pop
    end
    save
  end

end

####### MAIN ########################
#
$start_time = Time.now

$start_time_string = "#{$start_time.mon}/#{$start_time.day} #{$start_time.hour}:#{$start_time.min}"


$message_data = MessageData.new("data/data.json")   # where the data is store
$message_data.load


class VaccineService < Sinatra::Application


  use Rack::Session::Cookie,
  :key => "rack.session",
  :expire_after => 31536000,
  :secret => "earth?",
  :port => 80
  configure :production do
    set :haml, { :ugly => true }
    set :clean_trace, true
  end

  configure :development do

  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end

end

#### make my method which is both get or post #####
def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end


def common_get_chart(input_name,more_options=Hash.new)
  @vaccine = Vaccine.find_vaccine(input_name)
  if ! @vaccine
    raise "can't find vaccine: #{input_name}"
  end
  @chart_number = @vaccine.chart_number
  @chart_efficacy_rate = @vaccine.chart_efficacy_rate
  #puts "vaccine chart is #{@chart.class}"
  @chart_options = { 
                     last_month: more_options[:last_month]
                   }

end

############## important routes #########################

get '/hi' do
  "Hello World!"
end

# set temperture
post '/message/?' do
  #print "post phone. prams is #{params}, client ip #{request.ip}\n"
  $message_data.parse(request,params)
  #redirect "/"
end

# home page page.
get '/?' do
  #common_get_chart("BNT162b2")
  common_get_chart("all")

  haml :default
end

# home page page.
get '/vaccine/:name' do
  common_get_chart(params[:name])
  haml :default
end


######################## LOG ########################################################


######################## LOGIN ########################################################

get "/login/?" do
  @title = "Login"
  haml :login
end


post "/login/?" do
  username = params[:username]
  #print "login user name is #{username}\n"
  set_session_username(username)
  #target = url('all_racks')
  #if session['attempted_url']
  #    target = session['attempted_url']
  #    session['attempted_url'] = nil
  #end
  redirect "/"
end

get '/logout/?' do
    set_session_username(nil)
    redirect request.env['HTTP_REFERER']
end
