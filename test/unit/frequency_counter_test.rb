require 'test_helper'

class FrequencyCounterTest < ActiveSupport::TestCase
  def setup
    @hist_len = 13
    @fc = FrequencyCounter.new(@hist_len)
  end

  def test_instantiation
    assert @fc
    assert_equal 0, @fc.numbers.length
    assert_equal 0, @fc.roll_count
  end

  def test_bump
    @n = 5
    @n.times { @fc.bump}
    assert_equal @n, @fc.roll_count
  end

  def test_empty_commit
    @fc.commit
    assert_equal 1, @fc.numbers.length 
    assert_equal 0, @fc.numbers[0]
  end

  def test_commit
    test_bump
    @fc.commit
    assert_equal 1, @fc.numbers.length 
    assert_equal @n, @fc.numbers[0]
  end

  def test_commit_reset_commit
    test_commit
    @fc.reset
    @fc.commit
    assert_equal 2, @fc.numbers.length 
    assert_equal [@n, 0], @fc.numbers
  end

  def test_reset
    test_bump
    @fc.reset
    assert_equal 0, @fc.roll_count
  end

  def test_clear
    test_commit
    @fc.clear
    assert_equal 0, @fc.numbers.length
    assert_equal 0, @fc.roll_count
  end

  def test_sequence
    count = 12
    count.times {test_bump; @fc.commit}
    assert_equal count, @fc.numbers.length 
    assert @fc.numbers.all? {|e| e==@n}
  end

  def test_hot_numbers_average
    @nums = [4,7,3,0,1,1,7,0,0,2,8,11,2,3,6,9,17]
    @ring_nums = @nums[-@hist_len, @hist_len]
    @nums.each do |n|
      n.times {@fc.bump}
      @fc.commit
    end

    assert_equal @ring_nums.length, @fc.numbers.length
    assert_equal @ring_nums, @fc.numbers
    sum = @ring_nums.inject(0) {|t,n| t += n}
    avg = (sum*1.0)/@ring_nums.length
    assert_equal avg, @fc.hot_numbers_average
  end
end
