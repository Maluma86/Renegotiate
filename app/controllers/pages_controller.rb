class PagesController < ApplicationController
  def home
  end

  def insights
    # 1️⃣ Define your time windows
    periods = {
      '7'   => { label: 'Last 7 days',  range: 7.days.ago..Time.current },
      '30'  => { label: 'Last 30 days', range: 30.days.ago..Time.current },
      '90'  => { label: 'Last 90 days', range: 90.days.ago..Time.current },
      'all' => { label: 'All time',     range: nil }
    }

    # 2️⃣ Pick the selected window
    key      = params[:period] || '7'
    selected = periods[key] || periods['7']
    range    = selected[:range]

    # 3️⃣ Base scope of renegotiations
    renegos = range ? Renegotiation.where(created_at: range) : Renegotiation.all

    # 4️⃣ Compute raw metrics
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

    # 5️⃣ Always “ending soon” from today → +30d
    ending_soon = Product.ending_between(Date.today, Date.today + 30).count

    # 6️⃣ Expose stats for your cards
    @period_label = selected[:label]
    @stats = {
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

    # 7️⃣ Chartkick: breakdown bar chart
    @status_data = {
      "Pending"        => pending,
      "Ongoing"        => ongoing,
      "Human Required" => human_required
    }

    # 8️⃣ Chartkick: 30-day calendar heatmap
    @renewals_calendar = (Date.today..(Date.today + 29)).map do |date|
      [date, Product.where(contract_end_date: date).count]
    end
  end
end
