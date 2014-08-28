require 'test_helper'

class DiceTest < Test::Unit::TestCase
  def setup
    @seed = 74199164493423645483384711128
    @dice = Dice.new(6, @seed)
  end

  def test_rolls_with_fixed_seed_repeat
    d2 = Dice.new(6, @seed)
    432.times { |i|
      assert_equal @dice.roll, d2.roll, "rolls deviated on roll #{i}"
      assert_equal @dice.map {|v| v}, d2.map {|v| v}
    }
  end

  def test_basic_dice_data
    89.times {@dice.roll}
    assert_equal 89, @dice.num_rolls

    100.times {
      v = @dice.roll
      assert_equal v, @dice.value
    }
    assert_equal 1*6, @dice.min_value
    assert_equal 6*6, @dice.max_value
    assert_equal 6..36, @dice.value_range
  end

  def test_extract_offsets
    v2 = @dice[2].value
    v5 = @dice[5].value

    @new_dice = @dice.extract([2,5])

    @new_dice[0].value == v2
    @new_dice[1].value == v5
  end

  def test_extract_one_amount
    v0 = @dice[0].value
    @new_dice = @dice.extract(1)
    @new_dice[0].value == v0
    assert_equal 5, @dice.count
  end

  def test_join_dice
    d2 = Dice.new(2)
    d2.roll
    v1 = d2[0].value
    v2 = d2[1].value
    @dice.join(d2) # removes 2 from index 0 in @die
    assert_equal 8, @dice.count
    assert_equal v1, @dice[6].value # they got appended during join
    assert_equal v2, @dice[7].value
  end

  def test_rolls_with_random_seed_dont_repeat
    d1 = Dice.new(4)
    d2 = Dice.new(4)
    @deviated = false
    4149.times { |i|
      if d1.roll != d2.roll
        @deviated = true
        break
      end
    }
    assert @deviated, "4149 rolls on random seeded dice didn't deviate"
  end

  def test_same
    d1 = Dice.new(1, 9999)
    d2 = Dice.new(1, 9999)
    d1.roll
    d2.roll
    d2.join(d1)
    assert_equal 2, d2.count
    assert d2.same?
    100.times {
      d2.roll
      assert d2.same?
    }
  end
end
