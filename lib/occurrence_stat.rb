class OccurrenceStat
  #
  # keep track of the total number of times and the maximum number of consecutive
  # times a condition evalutes to true and to false
  #
  attr_reader  :name
  attr_reader  :max_consecs
  attr_reader  :total_counts
  attr_reader  :running_totals
  attr_reader  :occurred
  attr_reader  :not_occurred

  OCCURRED=true
  DID_NOT_OCCUR=!OCCURRED
  NEITHER=nil

  REPORT_FORMATTER= "%14s   %7s / %7s      %7s / %7s"

  def initialize(name, not_occurred_condition = Proc.new {true}, &occurred_condition)
    @name = name
    @occurred = occurred_condition
    @not_occurred = not_occurred_condition
    reset
  end

  def update
    occurrence = if occurred.call
      OCCURRED
    elsif not_occurred.call
      DID_NOT_OCCUR
    else
      NEITHER
    end

    return if occurrence == NEITHER

    total_counts[occurrence] += 1
    running_totals[occurrence] += 1
    running_totals[!occurrence] = 0
    if running_totals[occurrence] > max_consecs[occurrence]
      max_consecs[occurrence] = running_totals[occurrence] 
    end
    return
  end

  def max(did=OCCURRED)
    max_consecs[did]
  end

  def total(did=OCCURRED)
    total_counts[did]
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
