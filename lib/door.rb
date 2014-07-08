class Door
  SIGNAL_DURATION = 0.5
  def initialize(lock, unlock, locked, unlocked, opened)
    @lock = lock
    @unlock = unlock
    @locked = locked
    @unlocked = unlocked
    @opened = opened
    [@lock,@unlock].each{|g|g.set_output_low}
    [@locked,@unlocked,@opened].each{|g|g.set_input.set_edge_both}
  end
  def lock
    begin
      @lock.set_high
      sleep SIGNAL_DURATION
    ensure
      @lock.set_low
    end
  end
  def unlock
    begin
      @unlock.set_high
      sleep SIGNAL_DURATION
    ensure
      @unlock.set_low
    end
  end
  def locked?
    case
      when @locked.high? && @unlocked.low? then true
      when @locked.low? && @unlocked.high? then false
      else nil
    end
  end
  def unlocked?
    case locked?
      when false then true
      when true then false
      else nil
    end
  end
  def opened?; @opened.high?; end
  def closed?; !opened?; end
  def monitor
    last_msg = {}
    loop do
      @lock.class.select([@opened, @locked, @unlocked]).each do |gpio|
        msg = case gpio
          when @opened then [:opened, opened?]
          when @locked, @unlocked then [:locked, locked?]
        end
        yield msg if msg[1] != last_msg[msg[0]]
        last_msg[msg[0]] = msg[1]
      end
    end
  end
end
