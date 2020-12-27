
class VaccineService < Sinatra::Application

  helpers do
    def url(*path_parts)
      escaped_path_parts = path_parts.map {|part| part.to_s}
      [ path_prefix, escaped_path_parts ].join("/").squeeze("/")
    end
    alias_method :u, :url
    
    def path_prefix
      request.env['SCRIPT_NAME']
    end

    def session_username
      session['username']
    end

    def set_session_username(username)
      session['username'] = username
    end

    def summarize(text)
      result = text[0..14]
      result += "..." if text.length > 15
      return result
    end

  end

end
