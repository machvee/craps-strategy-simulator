require 'test_helper'

class DieTest < ActiveSupport::TestCase
  def setup
    @seed = 7464493364548338471112
    @die = Die.new(@seed)
  end

  def test_rolls_with_fixed_seed_repeat
    d2 = Die.new(@seed)
    432.times { |i|
      assert_equal @die.roll, d2.roll, "rolls deviated on roll #{i}"
    }
  end

  def test_basic_dice_data
    assert_equal 6, @die.num_sides
    100.times {
      v = @die.roll
      assert_equal v, @die.value
    }
  end

  def test_rolls_with_random_seed_dont_repeat
    d1 = Die.new
    d2 = Die.new
    @deviated = false
    10000.times { |i|
      if d1.roll != d2.roll
        @deviated = true
        break
      end
    }
    assert @deviated, "10000 rolls on random seeded dice didn't deviate"
  end
end
