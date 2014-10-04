class FrequencyCounter
  #
  # keep track of the number of point numbers rolled between when the table
  # is ON and OFF.  This history or the average over the last history_length
  # points can help determine how hot or cold the table is
  #
  attr_reader :numbers    # history of number of rolls between ON and OFF
  attr_reader :roll_count # number of point number rolls between ON and OFF

  DEFAULT_HISTORY_LENGTH = 10

  def initialize(history_length=DEFAULT_HISTORY_LENGTH)
    @numbers = RingBuffer.new(history_length)
    reset
  end

  def commit
    @numbers << roll_count
    reset
  end

  def bump
    @roll_count += 1
  end

  def reset
    @roll_count = 0
  end

  def clear
    numbers.clear
    reset
  end

  def hot_numbers_average
    nl = numbers.length
    return 0.0 if nl.zero?
    sum = numbers.inject(0) {|t, n| t += n}
    (sum * 1.0)/nl
  end
end
