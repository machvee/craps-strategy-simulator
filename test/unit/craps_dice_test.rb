require 'test_helper'

class SameDieSeeder
  attr_reader  :returns
  def initialize
    @returns = [9123439, 9123439].each
  end

  def rand
    @returns.next
  end
end

class CrapsDiceTest < Test::Unit::TestCase
  def setup
    @dice = CrapsDice.new(2, seeder)
  end

  def test_seven
    @dice.expects(:value).returns(7).at_least_once
    assert @dice.seven?
  end

  def test_eleven
    @dice.expects(:value).returns(11).at_least_once
    assert @dice.eleven?
  end

  def test_yo
    @dice.expects(:value).returns(11, 8).at_least_once
    assert @dice.yo?
    assert !@dice.yo?
  end

  def test_seven_yo
    @dice.expects(:value).returns(11, 7, 4).at_least_once
    assert @dice.seven_yo?
    assert @dice.seven_yo?
    assert !@dice.seven_yo?
  end

  def test_winner
    @dice.expects(:value).returns(11, 7, 3).at_least_once
    assert @dice.winner?
    assert @dice.winner?
    assert !@dice.winner?
  end

  def test_craps
    @dice.expects(:value).returns(2, 3, 12, 7).at_least_once
    assert @dice.craps?
    assert @dice.craps?
    assert @dice.craps?
    assert !@dice.craps?
  end

  def test_hard
    d1 = CrapsDice.new(2, same_seeder)
    [4,6,8,10].each do |n|
      while d1.roll != n do; end 
      assert d1.hard?(n)
    end
  end

  def test_easy
    d1 = CrapsDice.new(2)

    [4,6,8,10].each do |n|
      while d1.roll != n || (d1[0].value == n/2 && d1[1].value == n/2) do ; end
      assert d1.easy?(n)
    end
  end

  def test_points
    @dice.expects(:value).returns(4,5,6,8,9,10,2,7).at_least_once
    assert @dice.points?
    assert @dice.points?
    assert @dice.points?
    assert @dice.points?
    assert @dice.points?
    assert @dice.points?
    assert !@dice.points?
    assert !@dice.points?
  end

  def test_fields
    @dice.expects(:value).returns(2,3,4,9,10,11,12,*[*5..8]).at_least_once
    assert @dice.fields?
    assert @dice.fields?
    assert @dice.fields?
    assert @dice.fields?
    assert @dice.fields?
    assert @dice.fields?
    assert @dice.fields?
    assert !@dice.fields?
    assert !@dice.fields?
    assert !@dice.fields?
    assert !@dice.fields?
  end

  def same_seeder
    SameDieSeeder.new
  end

  def seeder
    DefaultDieSeeder.new(11299264293323345443354711128)
  end

end
