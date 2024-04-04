# Update list of false values to include Python's False

module ActiveModel::Type
  class Boolean
    existing_values = FALSE_VALUES.dup
    remove_const(:FALSE_VALUES)
    FALSE_VALUES = existing_values + ['False', :False]
  end
end
