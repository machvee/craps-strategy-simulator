require 'test_helper'


class TableStatsCollectionTest < Test::Unit::TestCase
  class TestStatsCollection < TableStatsCollection
    def init_stats
      [
        OccurrenceStat.new('alpha') {table.alpha == 100}
      ]
    end
  end

  def setup
    @table = mock()
    @c = TestStatsCollection.new(@table)
    @c.add(OccurrenceStat.new('beta') {@table.beta == 200})

    @total_alpha = 187
    @total_beta = 213
    @total_combined=141
    @total_neither=16
  end

  def assert_start_at_zero
    assert_equal 0, @c.alpha
    assert_equal 0, @c.beta
  end

  def test_convenience_methods
    runit(@c, @table)
    assert_equal @total_alpha+@total_combined, @c.alpha
    assert_equal @total_beta+@total_combined, @c.beta
  end

  def test_reset
    runit(@c, @table)
    assert_equal @total_alpha+@total_combined, @c.alpha
    assert_equal @total_beta+@total_combined, @c.beta
    @c.reset
    assert_equal 0, @c.alpha
    assert_equal 0, @c.beta
  end

  def test_each
    runit(@c, @table)
    assert_equal @total_alpha+@total_combined, @c.alpha
    assert_equal @total_beta+@total_combined, @c.beta
    exp = %w{alpha beta}.each
    @c.each do |stat|
      assert_equal exp.next, stat.name
    end
  end

  def runit(c, table)
    table.expects(:alpha).at_least_once.returns(100)
    table.expects(:beta).at_least_once.returns(100)
    @total_alpha.times {c.update}

    table.expects(:alpha).at_least_once.returns(200)
    table.expects(:beta).at_least_once.returns(200)
    @total_beta.times {c.update}

    table.expects(:alpha).at_least_once.returns(100)
    table.expects(:beta).at_least_once.returns(200)
    @total_combined.times {c.update}

    table.expects(:alpha).at_least_once.returns(0)
    table.expects(:beta).at_least_once.returns(0)
    @total_neither.times {@c.update}
  end
end
