require 'test_helper'


class StatsCollectionTest < ActiveSupport::TestCase
  class TestStatsCollection < StatsCollection
  end

  def setup
    @c = TestStatsCollection('test stats')
  end

  def assert_start_at_zero
    assert_equal 0, @c.alpha.total
    assert_equal 0, @c.beta.total
  end

  def test_won_by_name
    c = TestStatsCollection.new('test2')
    c.add(Stat.new('alpha'))
    c.add(Stat.new('beta'))
    c.won('alpha')
    c.won('alpha')
    c.won('alpha')
    c.won('beta')
    c.won('beta')
    c.won('beta')
    c.incr('beta')
    c.lost('alpha')
    c.lost('beta')
    assert_equal 3, c.alpha.total
    assert_equal 4, c.beta.total
    assert_equal 1, c.stat_by_name('alpha').total_lost
    assert_equal 1, c.stat_by_name('beta').total_lost
  end

end
