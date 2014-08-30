require 'die'

class DefaultDieSeeder

  VERY_BIG_NUMBER=211308946028030853166801005918724002264

  attr_reader :die_seeder

  def initialize(opt_seed=nil)
    # pass in an optional seed argument to guarantee
    # that the Dice will always yield the
    # same roll sequence (useful in testing and for comparing
    # strategy to strategy).  Pass no seed argument to ensure
    # that the Dice will have a 'psuedo-random' roll sequence 
    #
    @die_seeder = Random.new(opt_seed||Random.new_seed)
  end

  def rand
    die_seeder.rand(VERY_BIG_NUMBER)
  end
end

class Dice
  attr_reader   :set
  attr_reader   :value
  attr_accessor :num_rolls

  include Enumerable

  def initialize(set_size, die_seeder=DefaultDieSeeder.new)
    @num_rolls = 0
    @set = []
    set_size.times {set << Die.new(die_seeder.rand)}
    shake_dice
  end

  def min_value
    set.length
  end

  def max_value
    set.length * Die::SIDES
  end

  def extract(options)
    # if options is an Array, remove die at those positions
    new_dice = Dice.new(0)
    case options
      when Array
        sorted_indicies = options.sort
        sorted_indicies.each_with_index do |i,ind|
          new_dice.add(self.remove(i-ind))
        end
      when Fixnum
        # options should be a Fixnum.  remove that many die
        raise "cannot remove #{options} die because only #{count} remain" if options > self.count
        options.times do
          new_dice.add(self.remove)
        end
      else
        raise "invalid argument to extract"
    end
    new_dice
  end

  def join(other_dice)
    other_dice.count.times do
      self.add(other_dice.remove)
    end
  end

  def roll
    @num_rolls += 1
    shake_dice
    @value
  end

  def gather(num_rolls)
    a = []
    num_rolls.times {
      a << roll
    }
    a
  end

  def each
    set.each do |d|
      yield d
    end
  end

  def print(sorted=false, horizontal_print_grouping=6)
    nr = Die::NUM_PATTERN_ROWS
    in_dice_groups_of(sorted, horizontal_print_grouping) do |da|
      0.upto(nr-1) do |i|
        puts da.map {|die| die.pattern(i)}.join("  ")
      end
    end
  end

  def value_range
    min_value..max_value
  end

  def to_s
    inspect
  end

  def inspect
    set.inspect
  end

  def add(dies)
    @set += Array(dies)
  end

  def remove(index=0)
    set.delete_at(index)
  end

  def same?
    set.map(&:value).uniq.length == 1
  end

  def [](index)
    set.at(index)
  end

  def count
    set.size
  end

  private

  def shake_dice
    @value = set.inject(0) { |s, d| s += d.roll }
  end

  def in_dice_groups_of(sorted, n)
    i = 0
    @set = sorted ? set.sort : set
    while i < set.length
      g = set[i,n]
      yield g
      i += n
    end
  end

end
