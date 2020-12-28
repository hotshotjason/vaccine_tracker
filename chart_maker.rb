# this converts data the is "close" to what Chart.js likes to html.    for more info on build chart data, check build_chart.rb
# each ChartMaker object is essentially a polymer (javascript+html)  which you can embed. 
# make sure the final html layout engined embed js/Chart.bundle.min.js  (Chart.js)  http://www.chartjs.org/docs/   to get the effect
#
=begin
  commont api
  title:   <title of the chart>
  y_label: <y left axis title>
  x_label: <x axis title>
  y_right_label: <y right axis title, required if you want to use 2 y axis>
  time:    hour|day|week|month   # x-axis is Time Unit
  horizontal : true         # make it horizontal bar (default vertical bar)
  size:    tiny|small|medium|large  # size of the chart (default medium)
  stacked: true             # make it stacked line chart
  aspect_ratio: true        # maintain aspect ratio.  (default false, which lets the chart fill the canvas as much as possible for max info)
  showLines: true           # default true, make it false if you don't want to show line

  expected format   this is the EXACT SAME format as Chart.js.  except I will auto supply with more default if not specified
  content: {
    data: {
        label: ["abc,"cde"]                  // not required if scatter line
        datasets: [
          {
            label: "My First dataset",
            borderColor: "green",
            data: [10,20,30]                 // if scatter line, then  data: [ { x:10, y:20 } , { x:20, y:40 } }
        },
        {
            label: "My Second dataset",
            borderColor: "red",
            data: [10,20,30,40]
        }
    }
  }
=end



module ChartMaker
end


# storing a collection of json data  charts
# and global charts
# ChartMaker::Charts.new.all   # json data charts
# ChartMaker::Charts.charts    # globals charts
class ChartMaker::Charts
  attr_reader :display_bottom,
              :display_top
  @@charts = Hash.new

  def self.charts
    @@charts
  end
 
  # return nil if can't find chart 
  def self.find_chart(input_name)
    return @@charts[input_chip]
  end

  def initialize
    @display_bottom = true
    @display_true = false
    @charts = [] 
  end

  def do_not_save_chart!
    #puts "not saving charts"
    @do_not_save_chart = true
  end

  # Viewer.current.data.charts.first get first chart
  def first
    @charts.first
  end

  # Viewer.current.data.charts.all   makes more sense
  def all
    @charts
  end

  def size
    @charts.size
  end

  def display_top!
    @display_bottom = false
    @display_true = true
  end

  def <<(input)
    if input.is_a? ChartMaker::Base
      current_chart = input
    elsif input.is_a? BuildChart::Base
      current_chart = input.to_chart
    elsif ! input   # will feed nil if detects an error
      # skip
      return
    else
      raise "input is not a chart. it is #{input.class}"   
    end
    if @do_not_save_chart
      # user generated json should go here to prevent going to global space
      current_chart.do_not_save_chart!   # propagate to actual chart which disables the "Expand" button
    else
      save_chart(current_chart)
    end
    @charts << current_chart
  end

  # save chart globally
  def save_chart(input)
    return if ! input.id   # can not save chart if no global id
    @@charts[input.id[:chip]]     ||= Hash.new
    @@charts[input.id[:chip]][input.id[:doc_type]] ||= Hash.new
    @@charts[input.id[:chip]][input.id[:doc_type]][input.id[:name]] = input
  end

  def to_html
    #puts "chart has #{@charts.size} elements"
    string = ""
    @charts.each do |current|
      string << current.to_html
    end
    string
  end
    
end

module ChartMaker::Constant

   def self.y_right_id   # datasets needs to add yAxisID: ChartMaker::Base.right_id   
    'y-axis-right'
  end
end

# must define a unqiue id:  field if you want to be able to click on "Expand" link for full view
class ChartMaker::Base

  @@colors = ["green","red","orange","blue","brown","black","yellow","grey","purple","darkred","gold","lime","olive","teal","cyan","cornsilk","darkslategray"]
  include HtmlHelper
  def initialize(args)
    @args = args
    @id = @args[:id]      # { chip: chip, type: type, name: name}, note id: is required to save chart
    @colors = @@colors.dup
    @current_color_index = 0
    @content = args[:content]
    #puts "#{self.class} content is #{@content.class}"
  end

  def self.max_colors
    @@colors.size
  end
  
  def id
    @id
  end

  # because chart are not saved, there is not /chart  links
  def do_not_save_chart!
    @do_not_save_chart = true
  end

  def reset_chart(input_args)
    add_title(input_args)
    init_chart_size
    @out = ""
  end

  def check_id(input)
    return if ! id
    raise "id #{input}    needs chip defined" if ! input[:chip]
    raise "id #{input}  needs type defined" if ! input[:doc_type]
    raise "id #{input}  needs name defined" if ! input[:name]
  end

  # :chip/:doc_type/:name
  def chart_url
    @id
  end

  # ruby/perl time => javascript time (secs -> milsecs)
  def to_js_time(input)
    input * 1000
  end
  
  def source 
    @args[:source]
  end

  # input_args, override options from to_html(input_args)
  # e.g.  last_month: true             # show time scale from last month to now
  def add_title(input_args=Hash.new)
    @content[:options] ||= Hash.new
    @content[:options][:scales] ||= Hash.new
    if @args[:title]
      @content[:options][:title] = {
       display: true,
       text: @args[:title]
      }
    end

    # adjust where x-axis start or end
    x_scale_ticks   = {  }     # Note this doesn't work for Time, which needs to specifies its own Time Min and Max
    y_scale_ticks   = {  }

    y_axes_left = { position: 'left', id: 'y-axis-left', ticks: y_scale_ticks}
    y_axes_right =  {position: 'right', id: 'y-axis-right', ticks: y_scale_ticks}
    x_axes = { ticks: x_scale_ticks }

    

    # y_label(left) is always the first color,  and y_label_right is always the second color
    if @args[:y_label]
      y_axes_left[:scaleLabel] = { display: true, labelString: @args[:y_label], fontColor: @colors[0] }
    end
    if @args[:y_right_label]  # Jason 090216 right y axis label doesn't work
      y_axes_right[:scaleLabel] = { display: true, labelString: @args[:y_right_label] , fontColor: @colors[1] }

    end

    if @args[:stacked]  
      x_axes[:stacked] = true
      y_axes_left[:stacked] = true   
    end
    @content[:options][:scales][:yAxes] = [ y_axes_left]
    if @args[:y_right_label]  # Jason 090216 right y axis label doesn't work
      @content[:options][:scales][:yAxes]  << y_axes_right
    end
    @content[:options][:maintainAspectRatio] = @args[:aspect_ratio]
    @content[:options][:showLines] = @args[:showLines]  if @args.has_key? :showLines

    # Chart Zoom plugin options
    @content[:options][:pan] =  { enabled: true, mode: 'xy' }
    @content[:options][:zoom] =  { enabled: true, mode: 'xy'}

    if self.class == ChartMaker::Scatter
      if @args[:time]  # x axis is time (same as localtime, time since 1970) 
        x_axes[:type] = 'time'
      else   # x axis is number
        x_axes[:type] = 'linear'
      end
      x_axes[:position] = 'bottom'
    end
    
    if @args[:x_label]
      x_axes[:scaleLabel] = { display: true, labelString: @args[:x_label] }
    end
    if @args[:time]
      if ! ['hour','day','week','month','year'].include? @args[:time]   # check Chart.js Time Scale for all the different Time Units
        raise "unsupported time format #{@args[:time]}"
      end
      x_axes[:time] = {}
      x_axes[:time][:unit] = @args[:time] 
      x_axes[:time][:tooltipFormat] = "MMMM Do YYYY, h a"   # need this or time will be display in integer in tooltip mode (when you hover over data point),  note this will return invalid  if tooltip doesn't contain time
      if input_args[:last_month]
        #puts "show just last month"
        a_month_ago = Time.now.to_i - (86400 * 30)    # 30 days in terms of seconds
        x_axes[:time][:min] = to_js_time(a_month_ago)
        # also if last_month, then you know a good time unit is week
        x_axes[:time][:unit] = 'week'
      end
    end
    @content[:options][:scales][:xAxes] = [ x_axes]
=begin
    jchen I have my own tooltips callback function, check def script_content()
    so below is not needed
    @content[:options][:tooltips] = Hash.new
    @content[:options][:tooltips][:callbacks] = Hash.new
    @content[:options][:tooltips][:callbacks][:label] = "function(tooltipItem,data) { return \"jason\"; }"
=end

  end

  def add_color(input) 
    input[:borderColor] = @colors[@current_color_index]
    raise "too many line charts, no more color to choose from"  if ! input[:borderColor]
    @current_color_index += 1
    input[:backgroundColor] = input[:borderColor]
  end

  def data
    @content[:data]
  end

  # the javascript code to instanitate the chart is here
  # create a call back function to so I can have customize display.
  # the goal is to match the original tooltip function, but add a "comment" field on a separate line
  def script_content 
    return_val = %{
      $(document).ready(function() {
        var ctx = $("##{@chart_id}");
        var content = #{@content.to_json}
        content["options"]["tooltips"] = { 
          callbacks: {
            label: function(tooltipItem, data) {

               var dataset_label = data.datasets[tooltipItem.datasetIndex].label;
               var data_point = data.datasets[tooltipItem.datasetIndex]["data"][tooltipItem.index];
               var array = [];

               if (typeof data_point == "number") {  // bar chart
                dataset_label = dataset_label + ":" + data_point ;
               }
               else if (data_point.hasOwnProperty("y")) {  // line graph
                dataset_label = dataset_label + ":" + data_point["y"] ;
                if (data_point.hasOwnProperty("c")  && (!(data_point["c"] === null))) { // special comment field for json viewer that we can add to tooltip
                  array.push(data_point["c"]);
                }
               }
               array.unshift(dataset_label);
               var aggregate_string = ""
               for (var i in array) {
                aggregate_string += array[i] + " ";
               }
               var output_string = "(" + aggregate_string + ")"
               $(this).offsetParent().find("#tooltip_info").text(output_string);   // find the current charts tooltip <span> using relative path
                                                                                   // however, this still doesn't work when you have multiple charts
                                                                                   // at the same time
               return array;  // each item is a new line on tooltip
            }
          }
        }
        var myLineChart = new Chart(ctx, content);
      });
    }
    return_val 
  end

  # columns: <bootstrip grid size> 
  # css: <custom_chart.css div class> 
  # note both of these size should be close so it is a match
  def init_chart_size
    @chart_size = {}
    @chart_size["huge"] = { css: "huge_chart", column: "col-lg-12" }
    @chart_size["large"] = { css: "large_chart", column: "col-lg-6" }
    @chart_size["medium"] = { css: "medium_chart", column: "col-lg-4" }
    @chart_size["small"] = { css: "small_chart", column: "col-lg-3" }
    @chart_size["tiny"] = { css: "tiny_chart", column: "col-lg-2" }
    @chart_size["puny"] = { css: "puny", column: "col-lg-1" }
  end

  def get_chart_size(force_size=nil)
    current_size = @args[:size]
    current_size = "medium" if ! current_size 
    current_size  = force_size if force_size
    return_val = @chart_size[current_size]
    raise "unexpected chart size #{current_size}.  valid ones are #{@chart_size.keys}" if ! return_val
    return_val
  end

  # this is like my polymer  element for the chart (html + javascript)
  # to_html(size: 'huge")   # force display to certain size
  def to_html(input_args=Hash.new)
    #puts "to_html arg #{input_args}"

    reset_chart(input_args)
  
    open_tag('script',script_content)
    open_tag('div',"",class:  get_chart_size(input_args[:size])[:column]) do
        if @id
          if @do_not_save_chart
            open_tag('small',"user generated json has no chart expand function") 
          else  
            open_tag('small') do
              #open_tag('span','',class: 'chart_btn') do
               # open_tag('a',"Expand",href: "/chart_expand/#{chart_url}")
              #end
              #if @args[:time]  # if time chart, srg wants to button user can click to show status last month
              #  open_tag('span','',class: 'chart_btn') do
              #    open_tag('a',"last month",href: "/chart_last_month/#{chart_url}")
              #  end
              #end
              if @args[:title]  # jason 111516, intentionally write the chart's title here.  this one is useful when there are a lot of chart and people can search chart by using browser's search function
                open_tag('span',"#{@args[:title]}");
              end
              open_tag('span','',id: 'tooltip_info') do   # this field gets populated when user hovers on tool tip
              end
            end
          end
        end
        open_tag('div',"",class: get_chart_size(input_args[:size])[:css]) do
          open_tag('canvas',"",id: "#{@chart_id}" ) do      # matches the javascript code which expect to populate LineChart
          end 
        end 
    end
    @out
  end
end

#  check Chartjs doc on how to make line chart
class ChartMaker::Line < ChartMaker::Base
  @@id = 0
  def initialize(args=Hash.new)
    super(args)
    fill_content
    @chart_id = get_id
  end

  def get_id   # support multiple charts
    @@id += 1
    "LineChart#{@@id}"
  end


  # auto fill with default
  def fill_content
    @content[:type] = 'line'  if ! @content[:type]

    # data portion
    raise "line chart maker needs labels .  content #{@content}" if ! data[:labels]
    data[:datasets].each do |current|
      puts "current is #{current}"
      add_color(current) if ! current[:borderColor]
      if ! current[:fill]
        current[:fill] = false 
        if @args[:stacked]  # stack chart and fill make more sense together
          current[:fill] = true
        end
      end
      current[:lineTension] = 0.1 if ! current[:lineTension]
      raise "chart maker needs data.  content #{@content}" if ! current[:data]
    end
  end

end

#  check Chartjs doc on how to make scatter line chart
class ChartMaker::Scatter < ChartMaker::Base
  @@id = 0
  def initialize(args=Hash.new)
    super(args)
    fill_content
    @chart_id = get_id
  end

  def get_id   # support multiple charts
    @@id += 1
    "ScatterChart#{@@id}"
  end

  # auto fill with default
  def fill_content
    @content[:type] = 'line'  if ! @content[:type]

    data[:datasets].each do |current|
      add_color(current) if ! current[:borderColor]
      current[:fill] = false if ! current[:fill]
      current[:lineTension] = 0 if ! current[:lineTension]
      raise "chart maker needs data.  content #{@content}" if ! current[:data]
    end

  end

end

#  check Chartjs doc on how to make bar chart
class ChartMaker::Bar < ChartMaker::Base
  @@id = 0
  def initialize(args=Hash.new)
    super(args)
    fill_content
    @chart_id = get_id
  end

  def get_id   # support multiple charts
    @@id += 1
    "BarChart#{@@id}"
  end

  # auto fill with default
  def fill_content
    if ! @content[:type]
      if @args[:horizontal]
        @content[:type] = 'horizontalBar'  
      else
        @content[:type] = 'bar'  
      end
    end

    raise "bar chart maker needs labels .  content #{@content}" if ! data[:labels]
    data[:datasets].each do |current|
      add_color(current) if ! current[:borderColor]
      current[:fill] = false if ! current[:fill]
      current[:lineTension] = 0 if ! current[:lineTension]
      raise "chart maker needs data.  content #{@content}" if ! current[:data]
    end

  end

end

