class OccurrenceStat

  #
  # keep track of the total number of times , consecutive times, the maximum number of consecutive
  # times, and the last 100 results of a win/lose condition evalutes to true and to false
  #
  attr_reader   :name

  attr_reader   :count  # number of times either won or lost
  attr_reader   :longest_streak # holds longest_winning_streak and longest_losing_streak
  attr_reader   :tally  # current counts of WON and LOST
  attr_reader   :streak # current streak of WON and LOST

  attr_reader   :won_condition
  attr_reader   :lost_condition

  WON=true
  LOST=!WON

  HISTORY_LENGTH = 100 # keep the last 100 occurrences

  REPORT_FORMATTER= "%20s    %10s      %10s / %10s      %10s / %10s"

  def initialize(name, lost_condition = Proc.new {true}, &won_condition)
    @name = name
    @won_condition = won_condition
    @lost_condition = lost_condition
    @last_history = RingBuffer.new(HISTORY_LENGTH)
    reset
  end

  def update
    # update counts based on predefined won and lost proc calls
    if won_condition.call
      won 
    elsif lost_condition.call
      lost
    end
    return
  end

  def incr
    # for use like a simple counter
    won
  end

  def won
    bump(WON)
  end

  def lost
    bump(LOST)
  end

  def bump(what_happened)
    @count += 1
    tally[what_happened] += 1
    streak[what_happened] += 1
    streak[!what_happened] = 0  # this ends the streak for what didn't happen

    if streak[what_happened] > longest_streak[what_happened]
      longest_streak[what_happened] = streak[what_happened] 
    end

    @last_history << what_happened
  end

  def total(did=WON)
    tally[did]
  end

  def total_won
    total(WON)
  end

  def total_lost
    total(LOST)
  end

  def longest_winning_streak
    longest_streak[WON]
  end

  def longest_losing_streak
    longest_streak[LOST]
  end

  def current_winning_streak
    streak[WON]
  end

  def current_losing_streak
    streak[LOST]
  end

  def last(n=1)
    h = @last_history[-n,[n, @last_history.length].min]
    n == 1 ? h[0] : h.reverse
  end

  def last_counts(n=HISTORY_LENGTH)
    wants = last(n)
    to_hash(wants.count {|o| o==WON}, wants.count {|o| o=LOST})
  end

  def reset
    @count = 0
    @longest_streak = zero_counter
    @tally          = zero_counter
    @streak         = zero_counter
    @last_history.clear
    return
  end

  def to_s
    REPORT_FORMATTER % [
      name,
      count,
      total_won,
      longest_winning_streak,
      total_lost, 
      longest_losing_streak
    ]
  end

  def inspect
    to_s
  end

  DEFAULT_COLUMN_LABELS = {
    name:          'name',
    count:         'total',
    won:           'won',
    win_streak:    'win streak',
    lost:          'lost',
    losing_streak: 'lose streak'
  }

  def self.print_header(options={})
    column_labels = DEFAULT_COLUMN_LABELS.merge(options)
    REPORT_FORMATTER % [
      column_labels[:name],
      column_labels[:count],
      column_labels[:won],
      column_labels[:win_streak],
      column_labels[:lost],
      column_labels[:losing_streak]
    ]
  end

  private

  def zero_counter
    to_hash(0, 0)
  end

  def to_hash(won_count, lost_count)
    {WON => won_count, LOST => lost_count}
  end

end
