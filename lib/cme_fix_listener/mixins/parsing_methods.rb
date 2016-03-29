module CmeFixListener
  # Parsing helper methods
  module ParsingMethods
    def xpath_value(doc, field, method)
      value = doc.xpath(field).first.try!(:value).to_s
      value.send(method || :to_s) if value.present?
    end

    def attributes_hash(trade_capture_report)
      Hash[*name.constantize::MAPPINGS.map do |mapping|
        [mapping.first, xpath_value(trade_capture_report, "@#{mapping.second}", mapping.third)]
      end.flatten]
    end

    def deep_delete(hash)
      hash.each do |_key, value|
        if value.instance_of?(Hash)
          deep_delete(value)
        elsif value.instance_of?(Array)
          value.each { |v| deep_delete(v) }
        else
          hash.delete_if { |_key, inner_value| inner_value.blank? }
        end
      end
    end
  end
end
