
module DataSet

end

class DataSet::Base
  attr_reader :name,
              :type,
              :developer,
              :content_number,
              :content_efficacy_rate

  def initialize(args)
    raise "name not specified" if ! @name 
    raise "type not specified" if ! @type 
    raise "developer not specified" if ! @developer 

    @content_number = Hash.new
    @content_efficacy_rate = Hash.new
    @datas_number = []
    @datas_efficacy = []
  end

  def name!(input_name)
    @name = input_name
  end

  def add_number_vaccinated_point(year,month,date,number)
    current_time = Time.new(year,month,date).to_i
    @datas_number << { "x" => to_js_time(current_time), "y" => number }
  end

  def add_efficacy_point(days,percent)
    @datas_efficacy << { "x" => days, "y" => percent }
  end

  def to_js_time(input)
    input * 1000
  end

  #{"data":{"datasets":[{"label":"Bugs created","data":[{"y":3,"x":1439355600000,"c":null},{"y":15,"x":1439960400000,"c":null},{"y":25,"x":1440046800000,"c":null},{"y":36,"x":1440133200000,"c":null},{"y":37,"x":1440219600000,"c":null},{"y":37,"x":1440306000000,"c":null},{"y":48,"x":1440392400000,"c":null},{"y":58,"x":1440478800000,"c":null},{"y":69,"x":1440565200000,"c":null},{"y":80,"x":1440651600000,"c":null},{"y":89,"x":1440738000000,"c":null}
  def generate_number_vaccinated(input_name)
    current = Hash.new
    current[:label] = input_name
    #current[:borderColor] = "green"
    current[:data] = @datas_number
    current
  end

  def generate_efficacy_rate(input_name)
    current = Hash.new
    puts "labe is #{input_name}"
    current[:label] = input_name
    #current[:borderColor] = "green"
    current[:data] = @datas_efficacy
    current
  end

  def setup
    add_all_vaccinated
    add_all_efficacy
    generate_all_number_vaccinated
    generate_all_efficacy_rate
  end

  def generate_all_number_vaccinated
    current_data = Hash.new
    @content_number[:data] = current_data
    current_data[:datasets] = []
    current_data[:datasets]  <<  generate_number_vaccinated(@name)
  end
  
  def generate_all_efficacy_rate
    current_data = Hash.new
    @content_efficacy_rate[:data] = current_data
    current_data[:datasets] = []
    current_data[:datasets]  <<  generate_efficacy_rate(@name)
  end

  def merge_data!(input_data)
    puts "merge data #{input_data.name}"
    input_data.content_number[:data][:datasets].each do |current_data_set|
      puts "data set is #{current_data_set}"
      @content_number[:data][:datasets]  <<  current_data_set
    end
    input_data.content_efficacy_rate[:data][:datasets].each do |current_data_set|
      puts "data set is #{current_data_set}"
      @content_efficacy_rate[:data][:datasets]  <<  current_data_set
    end

  end
end

class DataSet::Bnt162b2 < DataSet::Base

  def initialize(args=Hash.new)
    @name = "BNT162b2"
    @type = "mRNA-based vaccine"
    @developer = "Pfizer"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,90); 
    add_efficacy_point(30,80); 
    add_efficacy_point(40,70); 
    add_efficacy_point(80,65); 
	add_efficacy_point(100,60); 
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,1000); 
    add_number_vaccinated_point(2020,12,30,10000); 
    add_number_vaccinated_point(2021,1,01,100000); 
	add_number_vaccinated_point(2021,2,15,300000); 
  end


end

class DataSet::MRNA1273 < DataSet::Base

  def initialize(args=Hash.new)
    @name = "mRNA-1273"
    @type = "mRNA-based vaccine"
    @developer = "Moderna"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,95); 
    add_efficacy_point(30,85); 
    add_efficacy_point(40,76); 
    add_efficacy_point(80,56);
    add_efficacy_point(100,46); 	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,500); 
    add_number_vaccinated_point(2020,12,30,5000); 
    add_number_vaccinated_point(2021,1,01,50000); 
	add_number_vaccinated_point(2021,2,15,100000); 
  end


end

class DataSet::SputnikV < DataSet::Base

  def initialize(args=Hash.new)
    @name = "Sputnik-V"
    @type = "Non Replicating Viral Vector"
    @developer = "Gamaleya"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,80); 
    add_efficacy_point(30,79); 
    add_efficacy_point(40,70); 
    add_efficacy_point(80,40);
    add_efficacy_point(100,35);	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,7000); 
    add_number_vaccinated_point(2020,12,30,70000); 
    add_number_vaccinated_point(2021,1,01,700000); 
	add_number_vaccinated_point(2021,2,15,800000); 
	add_number_vaccinated_point(2021,2,28,1000000); 
  end


end


class DataSet::EpiVacCorona < DataSet::Base

  def initialize(args=Hash.new)
    @name = "EpiVacCorona"
    @type = "Peptide vaccine"
    @developer = "Federal Research Institution of Russia"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,77); 
    add_efficacy_point(30,75); 
    add_efficacy_point(40,74); 
    add_efficacy_point(80,70);
    add_efficacy_point(100,68);	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,6000); 
    add_number_vaccinated_point(2020,12,30,40000); 
    add_number_vaccinated_point(2021,1,01,400000); 
	add_number_vaccinated_point(2021,2,15,800000); 
	add_number_vaccinated_point(2021,2,28,1000000); 
  end


end



class DataSet::BBIBPCorV < DataSet::Base

  def initialize(args=Hash.new)
    @name = "BBIBPCorV"
    @type = "Inactivated"
    @developer = "Sinopharm"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,90); 
    add_efficacy_point(30,70); 
    add_efficacy_point(40,40); 
    add_efficacy_point(80,20);
    add_efficacy_point(100,0);	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,5000); 
    add_number_vaccinated_point(2020,12,30,70000); 
    add_number_vaccinated_point(2021,1,01,700000); 
	add_number_vaccinated_point(2021,2,15,1000000); 
	add_number_vaccinated_point(2021,2,28,2000000); 
  end


end



class DataSet::NVXCoV2373 < DataSet::Base

  def initialize(args=Hash.new)
    @name = "NVX-CoV2373"
    @type = "Protein Subunit"
    @developer = "Novavax"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,60); 
    add_efficacy_point(30,50); 
    add_efficacy_point(40,45); 
    add_efficacy_point(80,25);
    add_efficacy_point(100,15);	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,4000); 
    add_number_vaccinated_point(2020,12,30,70000); 
    add_number_vaccinated_point(2021,1,01,700000); 
	add_number_vaccinated_point(2021,2,15,800000); 
	add_number_vaccinated_point(2021,2,28,1000000); 
  end


end



class DataSet::RBDDimer < DataSet::Base

  def initialize(args=Hash.new)
    @name = "RBD-Dimer"
    @type = "Protein Subunit"
    @developer = "Anhui Zhifei Longcom"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,70); 
    add_efficacy_point(30,68); 
    add_efficacy_point(40,67); 
    add_efficacy_point(80,63);
    add_efficacy_point(81,20);	
    add_efficacy_point(100,18);	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,6000); 
    add_number_vaccinated_point(2020,12,30,6500); 
    add_number_vaccinated_point(2021,1,01,7000); 
	add_number_vaccinated_point(2021,2,15,9000); 
	add_number_vaccinated_point(2021,2,28,10000); 
  end


end



class DataSet::PlantbasedVLP < DataSet::Base

  def initialize(args=Hash.new)
    @name = "Plant-based VLP"
    @type = "VLP"
    @developer = "Medicago"
    super
    setup
  end

  def add_all_efficacy
    add_efficacy_point(10,55); 
    add_efficacy_point(30,50); 
    add_efficacy_point(50,45); 
    add_efficacy_point(70,40);
    add_efficacy_point(90,35);	
    add_efficacy_point(100,33);	
  end

  def add_all_vaccinated
    add_number_vaccinated_point(2020,12,01,4000); 
    add_number_vaccinated_point(2020,12,30,6500); 
    add_number_vaccinated_point(2021,1,01,6700); 
	add_number_vaccinated_point(2021,2,15,9000); 
	add_number_vaccinated_point(2021,2,28,9300); 
  end


end



