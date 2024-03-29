def number_to_currency(number, options = {:locale=>:th})
  return unless number

  options.symbolize_keys!

  defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
  currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})

  defaults  = DEFAULT_CURRENCY_VALUES.merge(defaults).merge!(currency)
  defaults[:negative_format] = "-" + options[:format] if options[:format]
  options   = defaults.merge!(options)

  unit      = options.delete(:unit)
  format    = options.delete(:format)

  if number.to_f < 0
    format = options.delete(:negative_format)
    number = number.respond_to?("abs") ? number.abs : number.sub(/^-/, '')
  end

  begin
    value = number_with_precision(number, options.merge(:raise => true))
    format.gsub(/%n/, value).gsub(/%u/, unit).html_safe
  rescue InvalidNumberError => e
    if options[:raise]
      raise
    else
      formatted_number = format.gsub(/%n/, e.number).gsub(/%u/, unit)
      e.number.to_s.html_safe? ? formatted_number.html_safe : formatted_number
    end
  end

end
