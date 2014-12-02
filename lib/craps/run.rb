class Run
 
  DEFAULT_OPTIONS = {
    start_bank:     1000,
    bet_unit:       10,
    stop:           {shooters: 10},
    strategy:       BasicStrategy,
    quiet_table:    false,
    pause:          false
  }

  attr_reader       :name
  attr_reader       :player
  attr_reader       :table
  attr_reader       :quiet_table
  attr_reader       :pause
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
    #   pause           when true, newline must be hit to go to the next roll
    #   stop            RunStopper stop. e.g. :down_amount, :up_amount, :down_percent, :up_percent, :points, :shooters
    #
    opts = DEFAULT_OPTIONS.merge(options)

    @name         = name
    @player       = player

    @start_bank   = opts[:start_bank]
    @bet_unit     = opts[:bet_unit]
    @strategy     = opts[:strategy].new(player)
    @quiet_table  = opts[:quiet_table]
    @pause        = opts[:pause]
    @run_stopper  = RunStopper.new(player, opts[:stop])
  end

  def start(seed=nil, &block)
    table.reset(seed)
    setup_player
    table.pause_option = pause
    until run_stopper.stop? do
      table.play(quiet_table)
    end
    table.retire_player_strategy(strategy)
    puts "\n\n" + run_stopper.explain
    return
  end

  def save
  {
    name:          name,
    time:          Time.now.to_s(:db),
    table:         table.name,
    player:        player.name,
    start_bank:    start_bank,
    bet_unit:      bet_unit,
    stop:          stop
  }
  end

  def setup_player
    player.bet_unit = bet_unit
    player.set_rail(start_bank)
    table.set_player_strategy(strategy)
  end

  def to_s
    "'#{name}' for #{player.name}: start_bank: #{start_bank}, bet_unit: #{bet_unit}, stop: #@run_stopper"
  end

  def inspect
    to_s
  end

end
