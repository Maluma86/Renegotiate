module RenegotiationsHelper
  # simple month-difference helper
  def contract_length_months(start_date, end_date)
    months = (end_date.year * 12 + end_date.month) -
             (start_date.year * 12 + start_date.month)
    "#{months} #{'month'.pluralize(months)}"
  end
end
