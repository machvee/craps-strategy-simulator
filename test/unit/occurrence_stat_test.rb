class OccurrenceStatTest < Test::Unit::TestCase
  def test_can_reset_and_count_correctly_no_guard
     vals = %w{red red blue blue blue red red blue blue red red red red}
     @val = nil
     @name = 'reds'
     red_count = vals.grep(/red/).length
     blue_count = vals.grep(/blue/).length
     s = OccurrenceStat.new(@name) {@val == 'red'}
     assert_equal @name, s.name
     assert_counts?(s, 0, 0, 0, 0)
     vals.each {|v| @val = v; s.update}
     assert_counts?(s, red_count, blue_count, 4, 3)
     s.reset
     assert_counts?(s, 0, 0, 0, 0)
  end

  def test_can_reset_and_count_correctly_with_guard
     vals  = %w{red red blue blue blue red  red blue blue red red red red red}
     @stops = %w{go  go  stop go   go   stop go  go   go   go  go  go  go  stop}
     @val = nil
     @name = 'reds_with_stopper'
     red_count = vals.grep(/red/).length - 2 # two stops
     blue_count = vals.grep(/blue/).length - 1 # one stop
     s = OccurrenceStat.new(@name, occurrence_guard) {@val == 'red'}
     assert_equal @name, s.name
     assert_counts?(s, 0, 0, 0, 0)
     stopper = @stops.each
     vals.each {|v| @stop = stopper.next; @val = v; s.update}
     assert_counts?(s, red_count, blue_count, 4, 2)
     s.reset
     assert_counts?(s, 0, 0, 0, 0)
  end

  def test_prints_correctly
     vals = %w{red red blue blue blue red red blue blue red red red red}
     @val = nil
     @name = 'reds'
     red_count = vals.grep(/red/).length
     blue_count = vals.grep(/blue/).length
     s = OccurrenceStat.new(@name) {@val == 'red'}
     assert_match %r{#@name.*0 */ *0 *0 */ *0}, s.to_s
     vals.each {|v| @val = v; s.update}
     assert_match %r{#@name *#{red_count} */ *4 *#{blue_count} */ *3}, s.to_s
  end

  def test_inspect_calls_to_s
    s = OccurrenceStat.new(@name) {@val == 'red'}
    s.expects(:to_s).once
    s.inspect
  end

  def occurrence_guard
    Proc.new {@stop == 'go'}
  end

  def assert_counts?(s, otot, dnotot, omax, dnomax)
    assert_equal otot, s.total
    assert_equal otot, s.total(OccurrenceStat::OCCURRED)
    assert_equal dnotot, s.total(OccurrenceStat::DID_NOT_OCCUR)
    assert_equal omax, s.max
    assert_equal omax, s.max(OccurrenceStat::OCCURRED)
    assert_equal dnomax, s.max(OccurrenceStat::DID_NOT_OCCUR)
  end
end
