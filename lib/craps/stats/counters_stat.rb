require 'stat'

class CountersStat < Stat
  #
  # keep track of the total number of times, current and max consecutive times
  # times, and the last 100 results of a won/lost conditions.  Counters
  # are passed in to be accumulated with each win/lost condition
  #
  class Counters
    attr_reader :counters
    attr_reader :names

    def initialize(counter_names)
      @names = counter_names
      @counters = {}
      reset
    end

    def update(counts)
      counts.each_pair do |counter_name, value|
        raise "no such counter '#{counter_name}'" unless counters.has_key?(counter_name)
        counters[counter_name] += value
      end
    end

    def reset
      names.each { |counter_name| counters[counter_name] = 0 }
    end

    def values
      vals = []
      counters.each_pair do |k,v|
        vals << v
      end
      vals
    end

    def [](key)
      counters[key]
    end
  end

  def initialize(name, options={})
    set_counters(options[:counter_names]||[])
    super
  end

  def set_counters(counter_names)
    @counters = Counters.new(counter_names)
  end

  def bump(what_happened, counts={})
    @counters.update(counts)
    super
  end

  def counters(key)
    @counters[key] || raise("no such counter with name #{key}")
  end

  def reset
    super
    @counters.reset
    return
  end

  def attrs
    super + @counters.values
  end
end
