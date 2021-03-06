# frozen_string_literal: true

module SecureStorage
  module AttributeDefine
    def attribute_define; proc do |attr|
      define_method(attr) do
        begin
          instance_variable_get("@#{attr}") ||
              instance_variable_set("@#{attr}", decrypt(send(secure_name_for attr)))
        rescue ArgumentError, OpenSSL::Cipher::CipherError # invalid base64
          secure_name = secure_name_for attr
          raw_val = send(secure_name)
          update_columns(secure_name => encrypt(raw_val)) if !deleted? && !new_record?
          instance_variable_set("@#{attr}", raw_val)
        end
      end

      define_method("#{attr}=") do |value|
        send("#{secure_name_for(attr)}=", encrypt(value))
        instance_variable_set("@#{attr}", value)
      end

      # TODO
      define_method("#{attr}?") do
        value = send(attr)
        value.respond_to?(:empty?) ? !value.empty? : !!value
      end

      # TODO: group by not selected will raise missing attr
      define_method(:attributes) { super().merge!(attr => send(attr)).stringify_keys! }

      define_singleton_method("find_by_#{attr}") { |value| xfind_by(attr => value) }
    end end
  end
end
