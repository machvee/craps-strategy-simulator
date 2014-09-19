module Craps
  class Stat
    #
    # keep track of the total number of times, current and max consecutive times
    # times, and the last 100 results of a win/lose conditions.  Optional counts
    # can be passed in to be accumulated with each win/lost condition
    #
    class OptionalCounts
      attr_reader :counters
      attr_reader :names

      def initialize(counter_names)
        @names = counter_names.map(&:to_s)
        @counters = {}
        names.each do |c|
          counters[c] = nil
        end
        reset
      end

      def update(counts)
        counts.each_pair do |counter_name, value|
          counters[counter_name] += value
        end
      end

      def reset
        counters.keys do |counter_name|
          optional_counters[counter_name] = 0
        end
      end

      def values
        vals = []
        counters.each_pair do |k,v|
          vals << v
        end
        vals
      end
    end

    attr_reader   :name

    attr_reader   :count  # number of times either won or lost
    attr_reader   :longest_streak # holds longest_winning_streak and longest_losing_streak
    attr_reader   :tally  # current counts of WON and LOST
    attr_reader   :streak # current streak of WON and LOST

    attr_reader   :won_condition
    attr_reader   :lost_condition
    attr_reader   :optional_counters

    attr_accessor :parent_stat # all actions will roll up to this stat when set

    WON=true
    LOST=!WON

    DEFAULT_HISTORY_LENGTH = 10 # keep the last 10 results

    def initialize(name, lost_condition = Proc.new {true}, options={}, &won_condition)
      @name = name
      @parent_stat = nil
      @won_condition = won_condition
      @lost_condition = lost_condition
      set_optional_counters(options[:counter_names]) if options[:counter_names]
      @last_history = RingBuffer.new(options[:history_length]||DEFAULT_HISTORY_LENGTH)
      reset
    end

    def set_optional_counters(counter_names)
      @optional_counters = OptionalCounters.new(counter_names)
    end

    def update(counts={})
      # update counts based on predefined won and lost proc calls
      if won_condition.call
        won(counts)
      elsif lost_condition.call
        lose(counts)
      end
      return
    end

    def incr(counts={})
      # for use like a simple counter
      won(counts)
    end

    def won(counts={})
      bump(WON, counts)
    end

    def lost(counts={})
      bump(LOST, counts)
    end

    def bump(what_happened, counts={})
      @count += 1
      tally[what_happened] += 1
      streak[what_happened] += 1
      streak[!what_happened] = 0  # this ends the streak for what didn't happen

      if streak[what_happened] > longest_streak[what_happened]
        longest_streak[what_happened] = streak[what_happened] 
      end

      optional_counters.update(counts)

      @last_history << what_happened

      parent_stat.bump(what_happened, counts) if parent_stat.present?
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
      optional_counters.reset
      return
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
      ] + optional_counters.values
    end

    private

    def zero_counter
      to_hash(0, 0)
    end

    def to_hash(won_count, lost_count)
      {WON => won_count, LOST => lost_count}
    end
  end
end
