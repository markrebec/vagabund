# Ports over some useful stuff from ActiveSupport for method args
class Hash
  def extractable_options?
    true
  end
end

class Array
  def extract_options!
    if last.is_a?(Hash) && last.extractable_options?
      pop
    else
      {}
    end
  end
end
