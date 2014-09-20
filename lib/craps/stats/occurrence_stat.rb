require 'stat'

class OccurrenceStat < Stat
  attr_reader   :won_condition
  attr_reader   :lost_condition

  def initialize(name, options={}, &won_condition)
    @won_condition = won_condition
    @lost_condition = options[:lost_condition]||proc{true}
    super(name, options)
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
end
