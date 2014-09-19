module Craps
  class Die
    include Comparable

    attr_reader   :num_sides
    attr_reader   :value

    SIDES=6

    DC='0'
    PATTERNS = [
        " ------- ",         # 0
        "|       |",         # 1
        "| #{DC}     |",     # 2
        "|   #{DC}   |",     # 3
        "|     #{DC} |",     # 4
        "| #{DC}   #{DC} |"  # 5
      ]

    ROWS = [
        [],          # skip
        [0,1,3,1,0], # 1
        [0,2,1,4,0], # 2
        [0,2,3,4,0], # 3
        [0,5,1,5,0], # 4
        [0,5,3,5,0], # 5
        [0,5,5,5,0]  # 6
    ]

    NUM_PATTERN_ROWS=ROWS[1].length

    def initialize(rand_seed=nil)
      @num_sides = SIDES
      seed(rand_seed)
      randomize
    end

    def seed(rand_seed=nil)
      @prng = rand_seed.nil? ? Random.new : Random.new(rand_seed)
    end

    def roll
      randomize
      value
    end

    def randomize
      @value = @prng.rand(1..num_sides)
    end

    def inspect
      value
    end

    def to_s
      value.to_s
    end

    def print
      ROWS[value].each do |i|
        puts PATTERNS[i]
      end
      return
    end

    def pattern(row_number)
      PATTERNS[ROWS[value][row_number]]
    end

    def <=>(other_die)
      value <=> other_die.value
    end
  end
end
