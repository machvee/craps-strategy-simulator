require 'test_helper'
require 'table_state'

class PointNumbersCounterTest < ActiveSupport::TestCase
  def setup
    @hist_len = 13
    @pnc = PointNumbersCounter.new(@hist_len)
  end

  def test_instantiation
    assert @pnc
    assert_equal 0, @pnc.numbers.length
    assert_equal 0, @pnc.roll_count
  end

  def test_bump
    @n = 5
    @n.times { @pnc.bump}
    assert_equal @n, @pnc.roll_count
  end

  def test_empty_commit
    @pnc.commit
    assert_equal 1, @pnc.numbers.length 
    assert_equal 0, @pnc.numbers[0]
  end

  def test_commit
    test_bump
    @pnc.commit
    assert_equal 1, @pnc.numbers.length 
    assert_equal @n, @pnc.numbers[0]
  end

  def test_commit_reset_commit
    test_commit
    @pnc.reset
    @pnc.commit
    assert_equal 2, @pnc.numbers.length 
    assert_equal [@n, 0], @pnc.numbers
  end

  def test_reset
    test_bump
    @pnc.reset
    assert_equal 0, @pnc.roll_count
  end

  def test_clear
    test_commit
    @pnc.clear
    assert_equal 0, @pnc.numbers.length
    assert_equal 0, @pnc.roll_count
  end

  def test_sequence
    count = 12
    count.times {test_bump; @pnc.commit}
    assert_equal count, @pnc.numbers.length 
    assert @pnc.numbers.all? {|e| e==@n}
  end

  def test_hot_numbers_average
    @nums = [4,7,3,0,1,1,7,0,0,2,8,11,2,3,6,9,17]
    @ring_nums = @nums[-@hist_len, @hist_len]
    @nums.each do |n|
      n.times {@pnc.bump}
      @pnc.commit
    end

    assert_equal @ring_nums.length, @pnc.numbers.length
    assert_equal @ring_nums, @pnc.numbers
    sum = @ring_nums.inject(0) {|t,n| t += n}
    avg = (sum*1.0)/@ring_nums.length
    assert_equal avg, @pnc.hot_numbers_average
  end
end
