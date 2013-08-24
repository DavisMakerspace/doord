module Hashable
  def from_hash(hash)
    return if self.class.name.to_sym != hash[:class].to_sym
    hash.each do |attr, value|
      next if attr == :class
      attr_name = attr.to_s.prepend('@').to_sym
      attr_setter = attr.to_s.concat('=').to_sym
      attr_value = self.instance_variable_get attr_name
      if value.is_a?(Hash) && self.respond_to?(attr) && value[:class].to_sym == attr_value.class.name.to_sym && attr_value.respond_to?(:from_hash)
        (self.public_send attr).public_send :from_hash, value
      elsif self.respond_to?(attr_setter)
        self.public_send attr_setter, value
      end
    end
    return self
  end
  def to_hash()
    name = self.class.name.to_sym
    hash = {class: name}
    self.instance_variables.each do |sym|
      attr_value = self.instance_variable_get sym
      hash[sym.to_s.delete("@").to_sym] = (attr_value.respond_to? :to_hash) ? attr_value.to_hash : attr_value
    end
    return hash
  end
end
