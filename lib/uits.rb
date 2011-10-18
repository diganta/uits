module Uits
  # 
  def get_xmlfile(options = {})
    raise ArgumentError, "Must required some data to get UITS." if options.blank?
    raise ArgumentError, "Must provide Distributor." if options[:distributor].blank?
    raise ArgumentError, "Must provide Product Id." if options[:productid].blank?
    raise ArgumentError, "Must provide Asset ID." if options[:assetid].blank?
    raise ArgumentError, "Must provide either Transaction ID or User ID." if options[:tid].blank? && options[:uid].blank?
    raise ArgumentError, "Must provide Media." if options[:media].blank?
    raise ArgumentError, "Must provide Name to whom get UITS." if options[:uits_for].blank?
    raise ArgumentError, "Must provide Passphrase to get UITS." if options[:passphrase].blank?
    raise ArgumentError, "Passphrase must not be less than 3 charecters." if options[:passphrase].to_s.length < 3.blank?

    nonce = ActiveSupport::SecureRandom.base64(6) # The nonce is a random value generated at the time of sale whose Base64 encoded length is 8 digits
    distributor = options[:distributor].to_s # This is the retailer or distributor’s name or an associated globally unique identifier in clear text example "Sony"
    time = Time.now.iso8601 # The date and time of the purchase (not download or signature) in ISO 8601 format
    productid = options[:productid].to_s # Track XML Product/Track/Metadata/PhysicalProduct/ProductCode example "00602517178656"
    assetid = options[:assetid].to_s # Track XML Catalog/Action/Product/Track/Metadata/ISRC example "USUV70603512"
    tid = !options[:tid].blank? ? options[:tid].to_s : nil # The transaction ID is the unique identifier for the transaction example "39220345237"
    uid = !options[:uid].blank? ? options[:uid].to_s : nil # The User ID is the unique identifier for the user example "A74GHY8976547B"
    media = OpenSSL::Digest::SHA256.digest(options[:media]) # example "d5b17cc1975d3095c6353f3fdced45ae867c06e02c1efb7c09662cdc796724b0"

    first_part = "<uits:UITS xmlns:uits='http://www.udirector.net/schemas/2009/uits/1.1' xmlns:xsi='http://www.w3.org/2001/XMLSchema-­‐instance'>"
    metadata = "<metadata>
  <nonce>#{nonce}</nonce>
  <Distributor>#{distributor.to_s}</Distributor>
  <Time>#{time.to_s}</Time>
  <ProductId type='UPC' completed='false'>#{productid.to_s}</ProductId>
  <AssetID type='ISRC'>#{assetid.to_s}</AssetID>
  <TID version='1'>#{tid.to_s}</TID>
  <UID version='1'>#{uid.to_s}</UID>
  <URL/>
  <PA/>
  <Media algorithm='SHA256'>#{media.to_s}</Media>
</metadata>"
    canonicalization = metadata.to_s
    rsa = RSA2048.new(options[:uits_for].to_s, options[:passphrase].to_s)
    keyid = Base64.encode64(OpenSSL::Digest::SHA1.digest(canonicalization))
    sig = rsa.signature(keyid)
    signature = '<signature keyID="'+keyid.to_s+'" algorithm="RSA2048">'+sig.to_s+'</signature>'
    last_part = '</uits:UITS>'
    xml = first_part.to_s + metadata.to_s + signature.to_s + last_part.to_s
    doc = Nokogiri.XML(xml, nil, 'UTF-8')
    doc.search(%Q{//signature[@keyID]}).each do |n|
      n['canonicalization'] = canonicalization
    end
    return doc.to_xml
  end

  class RSA2048
    def initialize(path, passphrase)
      path.gsub!(/[^0-9A-Za-z]/, '')
      @passphrase = passphrase
      @private_key_path = File.join(Rails.root.to_s, "lib/.rsa", path, "id_rsa")
      @public_key_path = File.join(Rails.root.to_s, "lib/.rsa", path, "id_rsa.pub")
      @private_key = private_key
      @public_key = public_key
    end

    def signature(data)
      Base64.encode64(@private_key.sign(OpenSSL::Digest::SHA1.new, data))
    end

    def varify?(sign, data)
      sign = Base64.decode64(sign)
      @public_key.verify(OpenSSL::Digest::SHA1.new, sign, data)
    end

    private
    
    def private_key
      generate_keypairs unless @private_key.blank?
      return OpenSSL::PKey::RSA.new(File.read(@private_key_path), @passphrase)
    end

    def public_key
      generate_keypairs unless @public_key.blank?
      return OpenSSL::PKey::RSA.new(File.read(@public_key_path))
    end

    def generate_keypairs
      unless File.exist?(@private_key_path) || File.exist?(@public_key_path)
        FileUtils.mkdir_p(File.dirname(@private_key_path)) unless File.exists?(File.dirname(@private_key_path))
        FileUtils.mkdir_p(File.dirname(@public_key_path)) unless File.exists?(File.dirname(@public_key_path))
        rsa_key = OpenSSL::PKey::RSA.generate(2048)
        cipher =  OpenSSL::Cipher::Cipher.new("des3")
        private_key = rsa_key.to_pem(cipher, @passphrase)
        public_key = rsa_key.public_key.to_pem
        rsa_priv = File.new(@private_key_path, "w")
        rsa_priv.puts private_key
        rsa_priv.close
        rsa_priv = File.new(@public_key_path, "w")
        rsa_priv.puts public_key
        rsa_priv.close
      end
    end
  end
end
