require 'json'
require 'set'
require './validator'
require './crypto_helper'

class Blockchain
  attr_reader :chain, :validator, :nodes

  def initialize
    @chain = []
    @validator = Validator.new(chain)
    @nodes = Set.new

    # Create the genesis block
    new_block(previous_hash: 1, transaction: {})
  end

  # Create a new block in the blockchain
  def new_block(transaction:, previous_hash: nil)
    block = {
      index: chain.length + 1,
      timestamp: Time.now.to_f,
      transaction: transaction,
      previous_hash: previous_hash || CryptoHelper.block_hash(last_block)
    }

    chain.push(block)
    block
  end

  # Creates a new transaction
  def new_transaction(vote_cipher:, ring_members:, ring_sig_hex:)
    if validator.valid_transaction?(vote_cipher, ring_members, ring_sig_hex)
      transaction = {
        vote: vote_cipher,
        ring_members: ring_members,
        ring_signature: ring_sig_hex
      }

      ring_sig = CryptoHelper.ringsig_from(ring_sig_hex)
      validator.add_voter(ring_sig.key_image)
      new_block(transaction: transaction)
    end
  end

  def last_block
    chain[-1]
  end

  # This is our consensus algorithm, it resolves conflicts
  # by replacing our chain with the longest one in the network.
  # True if our chain was replaced, False if not
  def resolve_conflicts
    neighbors = nodes
    new_chain = nil
    new_validator = nil
    max_length = chain.length

    neighbors.each do |node|
      response = RestClient.get("http://#{node}/chain")
      next unless response.code == '200'
      response_body = JSON.parse(response.body)
      length = response_body['length']
      chain = response_body['chain']

      validator = Validator.new(chain)

      # Check if the length is longer and the chain is valid
      if length > max_length && local_validator.valid_chain?
        max_length = length
        new_chain = chain
        new_validator = validator
      end
    end

    # Replace our chain if we discovered a new, valid chain longer than ours
    if new_chain
      @chain = new_chain
      @validator = new_validator
      true
    else
      false
    end
  end

  # Add a new node to the list of nodes
  # address ex: http://192.168.0.5:5000
  def register_node(address)
    parsed_url = URI.parse(address)
    nodes.add("#{parsed_url.host}:#{parsed_url.port}")
  end
end
