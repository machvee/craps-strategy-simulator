class OccurrenceStat
  #
  # keep track of the total number of times and the maximum number of consecutive
  # times a condition evalutes to true and to false
  #
  attr_reader  :name
  attr_reader  :max_consecs
  attr_reader  :total_counts
  attr_reader  :running_totals
  attr_reader  :occurred_condition
  attr_reader  :not_occurred_condition

  OCCURRED=true
  DID_NOT_OCCUR=!OCCURRED

  REPORT_FORMATTER= "%14s   %7s / %7s      %7s / %7s"

  def initialize(name, not_occurred_condition = Proc.new {true}, &occurred_condition)
    @name = name
    @occurred_condition = occurred_condition
    @not_occurred_condition = not_occurred_condition
    reset
  end

  def update
    # update counts based on predefined occurred and did_not_occur proc calls
    if occurred_condition.call
      occurred 
    elsif not_occurred_condition.call
      did_not_occur
    end
    return
  end

  def incr
    # for use like a simple counter
    occurred
  end

  def occurred
    # manually increment the occurred count
    bump(OCCURRED)
  end

  def did_not_occur
    # manually increment the did not occur count
    bump(DID_NOT_OCCUR)
  end

  def bump(occurrence)
    total_counts[occurrence] += 1
    running_totals[occurrence] += 1
    running_totals[!occurrence] = 0
    if running_totals[occurrence] > max_consecs[occurrence]
      max_consecs[occurrence] = running_totals[occurrence] 
    end
  end

  def max(did=OCCURRED)
    max_consecs[did]
  end

  def total(did=OCCURRED)
    total_counts[did]
  end

  def total_occurred
    total(OCCURRED)
  end

  def total_did_not_occur
    total(DID_NOT_OCCUR)
  end

  def max_consec_occurred
    max(OCCURRED)
  end

  def max_consec_did_not_occur
    max(DID_NOT_OCCUR)
  end

  def reset
    @max_consecs = counter
    @total_counts = counter
    @running_totals = counter
    return
  end

  def to_s
    REPORT_FORMATTER % [name,total,max,total(DID_NOT_OCCUR), max(DID_NOT_OCCUR)]
  end

  def inspect
    to_s
  end

  def self.print_header
    REPORT_FORMATTER % ["name", "occurred", "consec", "not", "consec"]
  end

  private

  def counter
    {OCCURRED => 0, DID_NOT_OCCUR => 0}
  end

end
