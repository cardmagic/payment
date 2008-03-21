#!/usr/bin/evn ruby

begin
  require 'rubygems'
  require_gem 'payment'
rescue LoadError
  require 'payment'
end

transaction = Payment::AuthorizeNet.new (
	:login       => 'username', # this is your merchant account login
	:password    => 'password', # this is your merhcant accout password
	:amount      => '49.95',
	:card_number => '4012888818888',
	:expiration  => '03/10',
	:first_name  => 'John',
	:last_name   => 'Doe'
)

begin
  transaction.submit
	puts "Card processed successfully: #{transaction.authorization}"
rescue
	puts "Card was rejected: #{transaction.error_message}"
end
