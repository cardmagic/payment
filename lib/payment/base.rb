module Payment

class PaymentError < StandardError#:nodoc:
end

class Base
	attr_reader :response, :error_code, :error_message, :authorization, :transaction_type, :result_code
	attr_accessor :url
	attr_accessor :require_avs, :test_transaction
	attr_accessor :method, :type, :login, :password, :action, :description, :amount, :invoice_number, :customer_id, :name, :address, :city, :state, :zip, :country, :phone, :fax, :email, :card_number, :expiration, :account_number, :routing_code, :bank_name
	
	# Set the variables and get default variables from the :prefs file.
	# This method will be overriden by each gateway to set sensible defaults
	# for each gateway.
	#
	def initialize(options = {}) #:nodoc:
		# set some sensible defaults
		@type = 'normal authorization'
		
		# get defaults from a preference file
		prefs = File.expand_path(options[:prefs] || "~/.payment.yml")
		YAML.load(File.open(prefs)).each {|pref, value| instance_variable_set("@#{pref}", value) } if File.exists?(prefs)
		
		# include all provided data
		options.each { |pref, value| instance_variable_set("@#{pref}", value) }

		@required = Array.new
	end

	def submit #:nodoc:
		raise PaymentError, "No gateway specified"
	end
	
	private
	
	# Make sure that the required fields are not empty
	def check_required
	   for var in @required
	      raise PaymentError, "The #{var} variable needs to be set" if eval("@#{var}").nil?
	   end
	end

	# Goes out, posts the data, and sets the @response variable with the information
	def get_response(url)
	   check_required
	   uri            = URI.parse url
	   http           = Net::HTTP.new uri.host, uri.port
	   if uri.port == 443
	      http.use_ssl	= true
	      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	   end
	   @response_plain = http.post(uri.path, @data).body
	   @response       = @response_plain.include?('<?xml') ? REXML::Document.new(@response_plain) : @response_plain
	   
	   @response.instance_variable_set "@response_plain", @response_plain
	   def @response.plain; @response_plain; end
	end

end

end
