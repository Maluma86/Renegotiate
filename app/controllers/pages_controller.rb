class PagesController < ApplicationController
  def home; end

  def insights
    # 1️⃣ Time windows users can pick
    periods = {
      '7'   => { label: 'Last 7 days',  range: 7.days.ago..Time.current },
      '30'  => { label: 'Last 30 days', range: 30.days.ago..Time.current },
      '90'  => { label: 'Last 90 days', range: 90.days.ago..Time.current },
      'all' => { label: 'All time',     range: nil }
    }

    # 2️⃣ Which window is selected?
    key      = params[:period] || '7'
    selected = periods[key] || periods['7']
    range    = selected[:range]

    # 3️⃣ DATE-FILTERED scope (used for everything *except* current_total)
    scoped_renegs = range ? Renegotiation.where(created_at: range) : Renegotiation.all

    # ▲ 4️⃣ Un-scoped counts of current renegotiations
    current_scope  = Renegotiation.where(status: %w[pending ongoing escalated])
    pending        = current_scope.pending.count
    ongoing        = current_scope.ongoing.count
    escalated      = current_scope.escalated.count
    total_current  = pending + ongoing + escalated

    # 5️⃣ Completed & discount are still time-filtered
    completed      = scoped_renegs.completed.count
    avg_discount   = scoped_renegs
                       .where.not(current_target_discount_percentage: nil)
                       .average(:current_target_discount_percentage)
                       .to_f.round(2)

    # 6️⃣ Contracts ending in the next 30 days (never date-filtered)
    ending_soon = Product.ending_between(Date.today, Date.today + 30).count

    # 7️⃣ Expose everything
    @period_label = selected[:label]
    @stats = {
      current_total: total_current,      # ← always 33 for your current DB
      breakdown: {
        pending:   pending,
        ongoing:   ongoing,
        escalated: escalated
      },
      completed:    completed,
      avg_discount: avg_discount,
      ending_soon:  ending_soon
    }

    # ─────────── Charts still use scoped_renegs ───────────
    @status_data = {
      "Pending"   => pending,
      "Ongoing"   => ongoing,
      "Escalated" => escalated
    }

    raw_completed = scoped_renegs.completed
      .group(Arel.sql("DATE(created_at)"))
      .order(Arel.sql("DATE(created_at)"))
      .count

    start_date = range ? range.begin.to_date : raw_completed.keys.min || Date.today
    end_date   = Date.today
    @completed_over_time = (start_date..end_date).map { |d|
      [d.to_s, raw_completed[d] || 0]
    }

    raw_weekly = scoped_renegs.where.not(current_target_discount_percentage: nil)
      .group(Arel.sql("DATE_TRUNC('week', created_at)"))
      .order(Arel.sql("DATE_TRUNC('week', created_at)"))
      .average(:current_target_discount_percentage)

    @avg_discount_by_week = raw_weekly.map { |t, avg| [t.to_date.to_s, avg.to_f.round(2)] }

    @renewals_calendar = (Date.today..(Date.today + 29)).map { |d|
      [d.to_s, Product.ending_between(d, d).count]
    }
  end
end
