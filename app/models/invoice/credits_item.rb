class Invoice::CreditsItem < Invoice::Item
  def formatted_date
    formatted_start_date
  end

  def description
    "Credits #{ amount > 0 ? 'deposited' : 'spent'}"
  end

  def credits
    "#{'+' if amount >= 0}#{formatted_amount}"
  end
end
