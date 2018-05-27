#!/usr/bin/env ruby

# Data generator for testing

require 'json'
require 'ring_sig'
require 'securerandom'

if __FILE__ == $0
  keys = []
  public_keys = []
  private_keys = []
  candidates = ['Iron Man', 'Spider Man', 'Hulk', 'Captain America']
  hasher = RingSig::Hasher::Secp256k1_Sha256
  for i in 1..100
    secret = SecureRandom.uuid.gsub("-", "").hex
    private_key = RingSig::PrivateKey.new(secret, hasher)
    entry = {'private_key'=> private_key.to_hex, 'public_key'=> private_key.public_key.to_hex}

    keys.push(entry)
    public_keys.push(entry['public_key'])
    private_keys.push(entry['private_key'])

    File.open('data/public_private_keys.json', 'w') { |file| file.write(keys.to_json) }
    File.open('data/private_keys.json', 'w') { |file| file.write(private_keys.to_json) }
    File.open('data/public_keys.json', 'w') { |file| file.write(public_keys.to_json) }
    File.open('data/candidates.json', 'w') { |file| file.write(candidates.to_json) }
  end
end
