=begin
Test cards available:
  370000000000002 - American Express Test Card
  6011000000000012 - Discover Test Card
  5424000000000015 - MasterCard Test Card
  4007000000027 - Visa Test Card
  4012888818888 - Visa Test Card II
  3088000000000017 - JCB Test Card (Use expiration date 0905)
  38000000000006 - Diners Club/Carte Blanche Test (Use expiration date 0905) 
=end

require File.dirname(__FILE__) + '/../test_helper'

class AuthorizeNetTest < Test::Unit::TestCase
  CARD = '4012888818888'
  
  # In order to test this code, create a .payment.yml file in the code
  # home directory of the user that will test this that looks like this:
  #
  #     username: my_uname
  #     transaction_key: my_key
  # 
  def setup    
    @transaction = Payment::AuthorizeNet.new(
                      :amount      => '49.95',
                      :expiration  => '0310',
                      :first_name  => 'John',
                      :last_name   => 'Doe',
                      :card_number => '4012888818888',
                      :test_transaction => true
                     )
  end
  
  def test_submit_bad_card
    @transaction.card_number = ''
    assert_raise(Payment::PaymentError) { @transaction.submit }
  end

  def test_submit_good_card
    @transaction.card_number = CARD
    assert_nothing_raised { @transaction.submit }
  end

  def test_authorization
    @transaction.card_number = CARD
    @transaction.submit
    assert_kind_of String, @transaction.authorization    
    assert_nil @transaction.error_message
  end

end
