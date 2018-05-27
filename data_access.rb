#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/json'
require 'json'

# Service used to pick a random private key for testing

set :port, ENV['PORT'] || '4568'

public_private_keys = JSON.parse(File.read('data/public_private_keys.json'))
candidates = JSON.parse(File.read('data/candidates.json'))

get('/pick_key') do
  response = {
      key: public_private_keys.sample
  }
  json response, charset: 'utf-8'
end

get('/candidates') do
  response = {
      candidates: candidates
  }
  json response, charset: 'utf-8'
end
