class Run
 
  DEFAULT_OPTIONS = {
    start_bank:     1000,
    bet_unit:       10,
    strategy:       BasicStrategy,
    exit_criteria:  {shooters: 5},
    quiet_table:    false
  }

  attr_reader       :name
  attr_reader       :player
  attr_reader       :table
  attr_reader       :quiet_table
  attr_accessor     :start_bank
  attr_accessor     :bet_unit
  attr_accessor     :strategy
  attr_accessor     :run_stopper

  delegate :table, to: :player

  def initialize(name, player, options={})
    #
    # options:
    #   start_bank      in dollars
    #   bet_unit        10,15,25, ...
    #   strategy        class name
    #   quiet_table     when true, eliminate progress and status messages
    #   exit_criteria   RunStopper exit criteria. e.g. :down_amount, :up_amount, :down_percent,
    #                                                  :up_percent, :points, :shooters
    #
    opts = DEFAULT_OPTIONS.merge(options)

    @name         = name
    @player       = player

    @start_bank   = opts[:start_bank]
    @bet_unit     = opts[:bet_unit]
    @strategy     = opts[:strategy]
    @run_stopper  = RunStopper.new(player, opts[:exit_criteria])
  end

  def start(&block)
    table.reset
    setup_player
    table.players_set_your_strategies
    until run_stopper.stop? do
      table.play(quiet_table)
    end
    puts "\n\n" + run_stopper.explain
  end

  def save
  {
    name:          name,
    time:          Time.now.to_s(:db),
    table:         table.name,
    player:        player.name,
    start_bank:    start_bank,
    bet_unit:      bet_unit,
    exit_criteria: exit_criteria
  }
  end

  def setup_player
    player.bet_unit = bet_unit
    player.set_rail(start_bank)
    player.strategy = strategy.new(player) if strategy.present?
  end

  def to_s
    "'#{name}' for #{player.name}: start_bank: #{start_bank}, bet_unit: #{bet_unit}, stop: #@run_stopper"
  end

  def inspect
    to_s
  end

end
