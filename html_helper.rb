module HtmlHelper

  # so attrib of { border: 1 }   =>  border=1
  def to_tag_attrib(input_attrib)
    return_val = ""
    input_attrib.each do |key,val|
      if val.is_a? Fixnum
        return_val << " #{key}=#{val}"
      elsif val.is_a? String
        return_val << " #{key}=\"#{val}\""
      else
        raise "unexpected attrib type #{val.class}"
      end
    end
    return_val
  end


  # Jason make open_tag as fast as possible . forget support haml
  def open_tag(tag,value=nil,attrib=nil,&block)
    if attrib
      @out << "<#{tag} #{to_tag_attrib(attrib)} > #{value}\n"
      yield if block_given?
      @out << "</#{tag}> \n"
    else   # no attrib fast path
      @out << "<#{tag}> #{value}\n"
      yield if block_given?
      @out << "</#{tag}> \n"
    end
  end

  # this returns the tag as string
  def tag_to_s(tag,value=nil,attrib=Hash.new)
    string = "<#{tag} #{to_tag_attrib(attrib)} > #{value}"
    string << "</#{tag}>"
    return string
  end
end


