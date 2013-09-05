module Hashable
  def self.dashify(s)
    s.split('::').map do |e|
      e.split(/([[:upper:]][[:lower:]]+)/).keep_if { |e| !e.empty? }.map do |e|
        e.size > 1 && e.upcase == e ? e : e.downcase
      end.join('-')
    end.join('_')
  end
  def self.dedashify(s)
    return s if s[0].downcase != s[0]
    s.split('_').map do |e|
      e.split('-').map { |e| e[0] = e[0].upcase; e }.join
    end.join('::')
  end
  def from_hash(hash, namespace: [])
    prefix = namespace.empty? ? '' : namespace.join('::')+'::'
    return hash if self.class.name != prefix + Hashable::dedashify(hash[:class].to_s)
    hash.each do |attr, value|
      next if attr == :class
      attr_name = attr.to_s.prepend('@').to_sym
      attr_setter = attr.to_s.concat('=').to_sym
      attr_value = self.instance_variable_get attr_name
      if
        value.is_a?(Hash) &&
        self.respond_to?(attr) &&
        prefix + Hashable::dedashify(value[:class].to_s) == attr_value.class.name &&
        attr_value.respond_to?(:from_hash)
      then
        (self.public_send attr).public_send(:from_hash, value, namespace: namespace)
      elsif self.respond_to?(attr_setter)
        self.public_send attr_setter, value
      end
    end
    return self
  end
  def to_hash(namespace: [], dashify: false)
    prefix = namespace.empty? ? '' : namespace.join('::')+'::'
    hash = {class: self.class.name.sub(/^#{prefix}/,'')}
    hash[:class] = Hashable::dashify(hash[:class]) if dashify
    self.instance_variables.each do |sym|
      attr_value = self.instance_variable_get sym
      hash[sym.to_s.delete("@").to_sym] = (attr_value.respond_to? :to_hash) ? attr_value.to_hash(namespace: namespace, dashify: dashify) : attr_value
    end
    return hash
  end
end

class Hash
  def from_hash(namespace: [])
    obj = Object
    namespace.each do |name|
      obj = obj.const_get name
    end
    obj = obj.const_get Hashable::dedashify(self[:class])
    return obj.new.from_hash(self, namespace: namespace)
  end
end
