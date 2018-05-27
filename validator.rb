require './crypto_helper'

class Validator
  attr_reader :chain, :already_voted, :eligible_voters, :candidates

  def initialize(chain)
    @chain = chain
    @already_voted = voters_from_chain
    @eligible_voters = JSON.parse(File.read('data/public_keys.json'))
    @candidates = JSON.parse(File.read('data/candidates.json'))
  end

  def valid_transaction?(vote_cipher, ring_members, ring_sig_hex)
    ring_sig = CryptoHelper.ringsig_from(ring_sig_hex)
    # check if the voter has already voted
    return false if already_voted.include? ring_sig.key_image
    # check if all the ring members are eligible voter
    return false unless (ring_members - eligible_voters).empty?

    ring_members_pks = ring_members.map { |hex| CryptoHelper.public_key_from(hex) }
    ring_sig.verify(vote_cipher, ring_members_pks)
  end

  def valid_chain?
    last_block = chain[0]
    current_index = 1

    while current_index < chain.length
      block = chain[current_index]

      # validate hash of block
      return false if block['previous_hash'] != CryptoHelper.block_hash(last_block)

      transaction = block['transaction']

      # validate the transaction
      return false unless valid_transaction?(transaction['vote'], transaction['ring_members'], transaction['ring_signature'])

      already_voted.push(key_image(transaction['ring_signature']))

      last_block = block
      current_index += 1
    end
    true
  end

  def valid_candidate?(candidate)
    candidates.include? candidate
  end

  def valid_vote?(vote_plaintext, key_image)
    vote_parts = vote_plaintext.split('|')

    vote_parts.length == 3 &&
      vote_parts[0].to_i == (key_image.x + key_image.y) &&
      valid_candidate?(vote_parts[1]) &&
      (vote_parts[2].to_i >= 0 && vote_parts[2].to_i < 10**9)
  end

  def add_voter(voter_key_image)
    already_voted.push(voter_key_image)
  end

  private

  def voters_from_chain
    voter_list = []
    current_index = 1
    while current_index < chain.length
      block = chain[current_index]
      ringsig_hex = block['transaction']['ring_signature']
      ring_sig = CryptoHelper.ringsig_from(ringsig_hex)
      voter_list.push(ring_sig.key_image)
      current_index += 1
    end
    voter_list
  end
end
