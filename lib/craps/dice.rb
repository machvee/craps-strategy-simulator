require 'die'
class DefaultSeeder

  VERY_BIG_NUMBER=211308946028030853166801005918724002264

  attr_reader :prng
  attr_reader :seed

  def initialize(opt_seed=nil)
    # pass in an optional seed argument to guarantee
    # that the Dice will always yield the
    # same roll sequence (useful in testing and for comparing
    # strategy to strategy).  Pass no seed argument to ensure
    # that the Dice will have a 'psuedo-random' roll sequence 
    #
    @seed = opt_seed || Random.new_seed
    @prng = Random.new(seed)
  end

  def rand
    prng.rand(VERY_BIG_NUMBER)
  end
end


class Dice
  attr_reader   :set
  attr_reader   :value
  attr_reader   :seeder
  attr_accessor :num_rolls

  delegate :seed, to: :seeder

  include Enumerable

  def initialize(set_size, seeder=nil)
    @seeder = seeder||DefaultSeeder.new
    @num_rolls = 0
    @set = []
    set_size.times {set << Die.new(@seeder.rand)}
    shake_dice
  end

  def min_value
    set.length
  end

  def max_value
    set.length * Die::SIDES
  end

  def extract(arg)
    offsets = if arg.is_a? Fixnum
      raise "cannot remove #{arg} die because only #{count} remain" if arg > self.count
      random_offsets(arg)
    elsif arg.is_a? Array
      raise "only #{count} die remain in dice" if arg.length > count
      arg
    else
      raise "invalid argument to extract"
    end

    self.class.new(0).tap do |new_dice|
      sorted_indicies = offsets.sort
      sorted_indicies.each_with_index do |i,ind|
        new_dice.add(self.remove(i-ind))
      end
    end
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

  def random_offsets(number_of_dice)
    [*0..(count-1)].shuffle(random: Random.new(@seeder.rand))[0,number_of_dice]
  end
end
