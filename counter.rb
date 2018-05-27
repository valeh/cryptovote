#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'optparse'
require './validator'

class Counter

  ELECTION_PRIVATE_KEY_PATH = 'data/election_private.pem'.freeze

  attr_reader :chain, :election_private_key, :validator

  def initialize(chain)
    @chain = chain
    @election_private_key = CryptoHelper.rsa_key(ELECTION_PRIVATE_KEY_PATH)
    @validator = Validator.new(chain)
  end

  def election_results
    'This is not a valid chain' unless validator.valid_chain?
    count_votes
  end

  private

  def count_votes
    results = Hash.new(0)
    current_index = 1

    while current_index < chain.length
      block = chain[current_index]

      vote_ciphertext = block['transaction']['vote']
      vote_plaintext = CryptoHelper.rsa_private_decrypt(vote_ciphertext, election_private_key)
      ring_sig = CryptoHelper.ringsig_from(block['transaction']['ring_signature'])

      if validator.valid_vote?(vote_plaintext, ring_sig.key_image)
        candidate = vote_plaintext.split('|')[1]
        results[candidate] += 1
      end

      current_index += 1
    end
    results
  end

end

if $PROGRAM_NAME == __FILE__
  usage = 'usage: ./counter.rb -c CHAIN_URL'

  options = {}
  OptionParser.new do |opt|
    opt.on('-c', '--chain CHAIN_URL') { |o| options[:chain_url] = o }
  end.parse!

  abort(usage) unless options[:chain_url]

  chain = JSON.parse(RestClient.get(options[:chain_url]))['chain']

  counter = Counter.new(chain)
  start = Time.now
  puts counter.election_results
  finish = Time.now
  puts "Counted in #{finish-start} seconds"
end
