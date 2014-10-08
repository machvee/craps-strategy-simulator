require 'test_helper'

class CountersStatTest < ActiveSupport::TestCase
  def setup
     @name = 'counter_test_stat'
     @s = CountersStat.new(@name, { counter_names: [:alpha, :beta] })
  end

  def test_prints_correctly
    al=2
    won=0
    lost=0
    @s.won(alpha: al); won += 1
    @s.won; won += 1

    be = 3
    @s.won(beta: be); won += 1
    @s.lost; lost += 1

    ca = 1
    cb = 4
    @s.lost(alpha: ca, beta: cb); lost += 1
    called = won + lost

    assert_match %r{#@name,#{called},#{won}, 60.00,3,#{lost}, 40.00,2,#{al + ca},#{be + cb}}, @s.to_s
  end

  def test_inspect_calls_to_s
    @s.expects(:attrs).once
    @s.inspect
  end

  def test_some_counters
    assert_equal 0, @s.counters(:alpha)
    assert_equal 0, @s.counters(:beta)

    @s.won(alpha: 12)
    @s.lost(beta: 33)
    @s.won(alpha: 8, beta: 7)

    assert_equal 20, @s.counters(:alpha)
    assert_equal 40, @s.counters(:beta)

    @s.reset
    assert_equal 0, @s.counters(:alpha)
    assert_equal 0, @s.counters(:beta)

    assert_raises RuntimeError do
      @s.won(beto: 2)
    end

    assert_raises RuntimeError do
      @s.counters(:alpa)
    end
  end
end
