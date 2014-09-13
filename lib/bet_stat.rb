class BetStat < OccurenceStat
  attr_reader  :amounts

  FORMATTER_WITH_AMTS = "%20s    %10s      %10s / %10s / $%d     %10s / %10s / $%d"

  def bump_amount(what_happened, amount)
    amounts[what_happened] += amount
  end

  def to_s
    FORMATTER_WITH_AMTS % [
      name,
      count,
      total_won,
      longest_winning_streak,
      amounts[WIN],
      total_lost, 
      longest_losing_streak,
      amounts[LOST]
    ]
  end

  def reset
    super
    @amounts = zero_counter
  end

  def self.print_header(options={})
    column_labels = DEFAULT_COLUMN_LABELS.merge(amt_won: 'amt', amt_lost: 'amt').merge(options)
    FORMATTER_WITH_AMTS % [
      column_labels[:name],
      column_labels[:count],
      column_labels[:won],
      column_labels[:win_streak],
      column_labels[:amt_won],
      column_labels[:lost],
      column_labels[:losing_streak],
      column_labels[:amt_lost]
    ]
end
