require 'openssl'
require 'ring_sig'
require 'base64'
require 'digest'
require 'json'

class CryptoHelper

  HASHER = RingSig::Hasher::Secp256k1_Sha256.freeze

  # creates a ring signature object from its hex representation
  def self.ringsig_from(hex)
    RingSig::Signature.from_hex(hex, HASHER)
  end

  # creates a public key object from its hex representation
  def self.public_key_from(hex)
    RingSig::PublicKey.from_hex(hex, HASHER)
  end

  # creates a private key object from its hex representation
  def self.private_key_from(hex)
    RingSig::PrivateKey.from_hex(hex, HASHER)
  end

  # creates a SHA-256 hash of the block
  def self.block_hash(block)
    block_str = JSON.dump(block)
    Digest::SHA256.hexdigest(block_str)
  end

  def self.rsa_key(path)
    OpenSSL::PKey::RSA.new(File.read(path))
  end

  def self.rsa_public_encrypt(plaintext, public_key)
    Base64.encode64(public_key.public_encrypt(plaintext))
  end

  def self.rsa_private_decrypt(ciphertext, private_key)
    private_key.private_decrypt(Base64.decode64(ciphertext))
  end
end
