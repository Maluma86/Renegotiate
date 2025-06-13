class PagesController < ApplicationController
  def home
  end

  def insights
    # Define all possible periods
    periods = {
      '7'   => { label: 'Last 7 days',  range: 7.days.ago..Time.current },
      '30'  => { label: 'Last 30 days', range: 30.days.ago..Time.current },
      '90'  => { label: 'Last 90 days', range: 90.days.ago..Time.current },
      'all' => { label: 'All time',     range: nil }
    }

    # Pick the period from params (default to '7')
    key = params[:period] || '7'
    selected = periods[key] || periods['7']

    # Build the renegotiation scope
    range   = selected[:range]
    renegos = range ? Renegotiation.where(created_at: range) : Renegotiation.all

    # Compute each metric
    pending        = renegos.pending.count
    ongoing        = renegos.ongoing.count
    human_required = renegos.human_required.count
    total_current  = pending + ongoing + human_required
    completed      = renegos.completed.count
    avg_discount   = renegos
                      .where.not(current_target_discount_percentage: nil)
                      .average(:current_target_discount_percentage)
                      .to_f
                      .round(2)

    # Products ending in next 30 days (from today)
    ending_soon = Product.ending_between(Date.today, Date.today + 30).count

    # Expose to the view
    @period_label = selected[:label]
    @stats        = {
      current_total: total_current,
      breakdown:      {
        pending:        pending,
        ongoing:        ongoing,
        human_required: human_required
      },
      completed:    completed,
      avg_discount: avg_discount,
      ending_soon:  ending_soon
    }
  end
end
