class PagesController < ApplicationController
  def home
  end

  def insights
    # 1️⃣ Define time windows
    periods = {
      '7'   => { label: 'Last 7 days',  range: 7.days.ago..Time.current },
      '30'  => { label: 'Last 30 days', range: 30.days.ago..Time.current },
      '90'  => { label: 'Last 90 days', range: 90.days.ago..Time.current },
      'all' => { label: 'All time',     range: nil }
    }

    # 2️⃣ Pick the selected window (default = 7 days)
    key      = params[:period] || '7'
    selected = periods[key] || periods['7']
    range    = selected[:range]

    # 3️⃣ Base scope of renegotiations
    scope = range ? Renegotiation.where(created_at: range) : Renegotiation.all

    # 4️⃣ Compute summary metrics
    pending        = scope.pending.count
    ongoing        = scope.ongoing.count
    human_required = scope.human_required.count
    total_current  = pending + ongoing + human_required
    completed      = scope.completed.count
    avg_discount   = scope
                       .where.not(current_target_discount_percentage: nil)
                       .average(:current_target_discount_percentage)
                       .to_f
                       .round(2)

    # 5️⃣ Contracts ending in the next 30 days (always from today)
    ending_soon = Product.ending_between(Date.today, Date.today + 30).count

    # 6️⃣ Expose stats & labels
    @period_label = selected[:label]
    @stats = {
      current_total: total_current,
      breakdown: {
        pending:        pending,
        ongoing:        ongoing,
        human_required: human_required
      },
      completed:    completed,
      avg_discount: avg_discount,
      ending_soon:  ending_soon
    }

    # ─────────────── Chartkick data ───────────────

    # 7️⃣ Bar chart: status breakdown
    @status_data = {
      "Pending"        => pending,
      "Ongoing"        => ongoing,
      "Human Required" => human_required
    }

    # 8️⃣ Bar chart: completed per day over the selected period
    raw_completed = scope
      .completed
      .group(Arel.sql("DATE(created_at)"))
      .order(Arel.sql("DATE(created_at)"))
      .count

    # Build a full series for Chartkick: [["2025-06-10", 2], ["2025-06-11", 0], …]
    start_date = range ? range.begin.to_date : raw_completed.keys.min || Date.today
    end_date   = Date.today
    @completed_over_time = (start_date..end_date).map do |date|
      [date.strftime("%Y-%m-%d"), raw_completed[date] || 0]
    end

    # 9️⃣ Area chart: avg discount per week (SQL grouping by week)
    discount_scope = scope.where.not(current_target_discount_percentage: nil)
    raw = discount_scope
      .group(Arel.sql("DATE_TRUNC('week', created_at)"))
      .order(Arel.sql("DATE_TRUNC('week', created_at)"))
      .average(:current_target_discount_percentage)
    # Transform keys (Time → "YYYY-MM-DD") for Chartkick
    @avg_discount_by_week = raw.map do |time, avg|
      [time.to_date.strftime("%Y-%m-%d"), avg.to_f.round(2)]
    end

    # 🔟 Column chart data: renewals for each of the next 30 days
    @renewals_calendar = (Date.today..(Date.today + 29)).map do |date|
      [date.strftime("%Y-%m-%d"), Product.ending_between(date, date).count]
    end
  end
end
