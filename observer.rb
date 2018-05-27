#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/json'
require 'securerandom'
require 'json'

require './blockchain'

set :port, ENV['PORT'] || '4567'

# Generate a globally unique address for this node
node_identifier = SecureRandom.uuid.delete('-')

# Instantiate the Blockchain
blockchain = Blockchain.new

# Show all blockchain
get '/chain' do
  response = {
    chain: blockchain.chain,
    length: blockchain.chain.length
  }
  json response, charset: 'utf-8'
end

# Show all eligible voters
get '/voters' do
  response = {
    voters: blockchain.eligible_voters,
    length: blockchain.eligible_voters.length
  }
  json response, charset: 'utf-8'
end

# Create a new transaction
post '/transactions/new', provides: :json do
  params = JSON.parse(request.body.read)

  # Check that the required fields are in the POST'ed data
  required = %w[vote ring_members ring_signature]
  unless required.all? { |key| params.key?(key) }
    status 400
    return 'Missing values'
  end

  # Create a new Transaction
  index = blockchain.new_transaction(
    vote_cipher: params['vote'], ring_members: params['ring_members'], ring_sig_hex: params['ring_signature']
  )

  if index
    msg = 'Transaction is recorded'
    sts = 201
  else
    msg = 'Transaction is not valid'
    sts = 405
  end

  status sts
  json msg, charset: 'utf-8'
end

# Add nodes
post '/nodes/register', provides: :json do
  params = JSON.parse(request.body.read)

  nodes = params['nodes']
  unless nodes
    status 400
    return 'Missing values'
  end

  # Add a node
  nodes.each do |node|
    blockchain.register_node(node)
  end

  response = {
    message: 'New nodes have been added',
    total_nodes: blockchain.nodes.length
  }
  status 201
  json response
end

get '/nodes/resolve' do
  response = if blockchain.resolve_conflicts
               {
                 message: 'Our chain was replaced',
                 new_chain: blockchain.chain
               }
             else
               {
                 message: 'Our chain is authoritative',
                 chain: blockchain.chain
               }
             end
  status 200
  json response
end
