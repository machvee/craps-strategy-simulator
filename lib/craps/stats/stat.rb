class Stat
  #
  # keep track of the total number of times, current and max consecutive times
  # times, and the last 100 results of a won/lost conditions.
  #
  attr_reader   :name

  attr_reader   :count  # number of times either won or lost
  attr_reader   :longest_streak # holds longest_winning_streak and longest_losing_streak
  attr_reader   :tally  # current counts of WON and LOST
  attr_reader   :streak # current streak of WON and LOST
  attr_accessor :parent_stat # the stat this stat was cloned from.  actions are mirrored on the parent
  attr_accessor :rollup_stat # all actions will roll up to this stat when set

  WON=true
  LOST=!WON

  DEFAULT_HISTORY_LENGTH = 40 # keep the last 40 results

  def initialize(name, options = {})
    @name = name
    @parent_stat = nil
    @rollup_stat = nil
    @last_history = RingBuffer.new(options[:history_length]||DEFAULT_HISTORY_LENGTH)
    reset
  end

  def incr(options={})
    # for use like a simple counter
    won(options)
  end

  def won(options={})
    bump(WON, options)
  end

  def lost(options={})
    bump(LOST, options)
  end

  def set_rollup_stat(stat)
    @rollup_stat = stat
    stat.parent_stat = nil
  end

  def bump(what_happened, options={})
    @count += 1
    tally[what_happened] += 1
    streak[what_happened] += 1
    streak[!what_happened] = 0  # this ends the streak for what didn't happen

    if streak[what_happened] > longest_streak[what_happened]
      longest_streak[what_happened] = streak[what_happened] 
    end

    @last_history << what_happened

    parent_stat.bump(what_happened, options) if parent_stat.present?
    rollup_stat.bump(what_happened, options) if rollup_stat.present?
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
    l = @last_history.last(n)
    n > 1 ? l : l.first
  end

  def last_counts(n=@last_history.max_size)
    wants = last(n)
    to_hash(wants.count {|o| o==WON}, wants.count {|o| o==LOST})
  end

  def reset
    @count          = 0
    @longest_streak = zero_counter
    @tally          = zero_counter
    @streak         = zero_counter

    @last_history.clear
  end

  def to_s
    attrs.map(&:to_s).join(',')
  end

  def inspect
    attrs
  end

  def attrs
    [
      name,
      count,
      total_won,
      longest_winning_streak,
      total_lost, 
      longest_losing_streak
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
