# Author::    Lucas Carlson  (mailto:lucas@rufy.com)
# Copyright:: Copyright (c) 2005 Lucas Carlson
# License::   Distributes under the same terms as Ruby

require 'cgi'
require 'csv'

require 'payment/base'

module Payment

class AuthorizeNet < Base
	attr_reader :server_response, :avs_code, :order_number, :md5, :cvv2_response, :cavv_response
	attr_accessor :first_name, :last_name, :transaction_key, :transaction_id, :invoice_num, :description
	
	# version of the gateway's API	
	API_VERSION = '3.1'
	
	# Set some sensible defaults for Authorize.Net
	#    transaction = Payment::AuthorizeNet.new (
  #                    :login       => 'username',
  #                    :password    => 'password',
  #                    :amount      => '49.95',
  #                    :card_number => '4012888818888',
  #                    :expiration  => '03/10',
  #                    :first_name  => 'John',
  #                    :last_name   => 'Doe'
  #                   )
  #
	def initialize(options = {})
		# set some sensible defaults
		@url = 'https://secure.authorize.net/gateway/transact.dll'
		@delim_data = 'TRUE'
		@relay_response = 'FALSE'
		@version = API_VERSION
		
		# include all provided data
		super options
	end
	
	# Submit the order to be processed. If it is not fulfilled for any reason
	# this method will raise an exception.
	def submit
		set_post_data
    get_response @url
    parse_response
	end
	
  private
  
  def set_post_data
  	prepare_data

  	post_array = Array.new
  	FIELDS.each do |loc_var, gate_var|
  		if @required.include?(loc_var) && eval("@#{loc_var}").nil?
  			raise PaymentError, "The required variable '#{loc_var}' was left empty"
  		else
  			value = eval "CGI.escape(@#{loc_var}.to_s)"
  			post_array << "#{gate_var}=#{value}" unless value.empty?
  		end
  	end

  	@data = post_array.join('&')
  end

  def parse_response
    data = @response.plain.split(',').unshift nil

    @result_code = data[1].to_i
    @result_reason_code = data[3]
    @result_reason = data[4]
  	@authorization = data[5]
  	@avs_code = data[6]
  	@transaction_id = @order_number = data[7]
  	@md5 = data[38]
  	@cvv2_response = data[39]
  	@cavv_response = data[40]

  	if @result_code == 1 # Approved/Pending/Test
  		return @transaction_id
  	else
  		@error_code = data[3]
  		@error_message = data[4]
  		raise PaymentError, @error_message
  	end

  end	
  
  # make sensible changes to data
  def prepare_data
  	@card_number = @card_number.to_s.gsub(/[^\d]/, "") unless @card_number.nil?
  	
  	@test_request = @test_transaction.to_s.downcase == 'true' ? 'TRUE' : 'FALSE'

  	if @recurring_billing.class != String
  		if @recurring_billing == true
  			@recurring_billing = "YES"
  		elsif @recurring_billing == false
  			@recurring_billing = "NO"
  		end
  	end
  	
  	@expiration = @expiration.strftime "%m/%y" rescue nil # in case a date or time is passed
  	
  	@method = (@method.nil? || @card_number) ? 'CC' : @method.upcase
  	
  	# convert the action
  	if TYPES.include?(@type)
  		@type = TYPES[@type]
  	elsif ! TYPES.has_value?(@type)
  		raise PaymentError, "The type '#{@type}' is not valid"
  	end		
  	
  	# add some required fields specific to this payment gateway and the provided data
  	@required += %w(method type login test_request delim_data relay_response)
    
    # If a transaction key is specified, use that instead
  	if @transaction_key.nil?
  	  @transaction_key = nil
  		@required += %w(password)
  	else
  	  @password = nil
  		@required += %w(transaction_key)
  	end
  	
  	unless @method == 'VOID'
  		if @method == 'ECHECK'
  			@required += %w(amount routing_code account_number account_type bank_name account_name account_type)
  			@required += %w(customer_org customer_ssn) unless @customer_org.nil?
  		elsif @method == 'CC'
  			@required += %w(amount)
  			if @type == 'PRIOR_AUTH_CAPTURE'
  				@required += @order_number ? %w(order_number) : %w(card_number expiration)
  			else
  				@required += %w(card_number expiration)
  			end
  		else
  			raise PaymentError, "Can't handle transaction method: #{@method}"
  		end
  	end
  	
  	@required.uniq!
  end

  # map the instance variable names to the gateway's requested variable names
  FIELDS = {
  	'method' => 'x_Method',
  	'type' => 'x_Type',
  	'login' => 'x_Login',
  	'password' => 'x_Password',
  	'transaction_key' => 'x_Tran_Key',
  	'description' => 'x_Description',
  	'amount' => 'x_Amount',
  	'currency_code' => 'x_Currency_Code',
  	'invoice_num' => 'x_Invoice_Num',
  	'transaction_id' => 'x_Trans_ID',
  	'auth_code' => 'x_Auth_Code',
  	'cust_id' => 'x_Cust_ID',
  	'customer_ip' => 'x_Customer_IP',
  	'last_name' => 'x_Last_Name',
  	'first_name' => 'x_First_Name',
  	'company' => 'x_Company',
  	'address' => 'x_Address',
  	'city' => 'x_City',
  	'state' => 'x_State',
  	'zip' => 'x_Zip',
  	'country' => 'x_Country',
  	'ship_to_last_name' => 'x_Ship_To_Last_Name',
  	'ship_to_first_name' => 'x_Ship_To_First_Name',
  	'ship_to_address' => 'x_Ship_To_Address',
  	'ship_to_city' => 'x_Ship_To_City',
  	'ship_to_state' => 'x_Ship_To_State',
  	'ship_to_zip' => 'x_Ship_To_Zip',
  	'ship_to_country' => 'x_Ship_To_Country',
  	'phone' => 'x_Phone',
  	'fax' => 'x_Fax',
  	'email' => 'x_Email',
  	'card_number' => 'x_Card_Num',
  	'expiration' => 'x_Exp_Date',
  	'card_code' => 'x_Card_Code',
  	'echeck_type' => 'x_Echeck_Type',
  	'account_name' => 'x_Bank_Acct_Name',
  	'account_number' => 'x_Bank_Acct_Num',
  	'account_type' => 'x_Bank_Acct_Type',
  	'bank_name' => 'x_Bank_Name',
  	'bank_aba_code' => 'x_Bank_ABA_Code',
  	'customer_org' => 'x_Customer_Organization_Type', 
  	'customer_ssn' => 'x_Customer_Tax_ID',
  	'drivers_license_num' => 'x_Drivers_License_Num',
  	'drivers_license_state' => 'x_Drivers_License_State',
  	'drivers_license_dob' => 'x_Drivers_License_DOB',
  	'recurring_billing' => 'x_Recurring_Billing',
  	'test_request' => 'x_Test_Request',
  	'delim_data' => 'x_Delim_Data',
  	'relay_response' => 'x_Relay_Response',
  	'version' => 'x_Version',
  }

  # map the types to the merchant's action names
  TYPES = {
  	'normal authorization' => 'AUTH_CAPTURE',
  	'authorization only'   => 'AUTH_ONLY',
  	'credit'               => 'CREDIT',
  	'post authorization'   => 'PRIOR_AUTH_CAPTURE',
  	'void'                 => 'VOID',
  }

end

end