require '/usr/lib/doord/gpio'

class Door
  def initialize(lock: nil, unlock: nil, locked: nil, unlocked: nil, opened: nil)
    @SIGNAL_DURATION = 0.5
    @lock = GPIO.new(lock, :low)
    @unlock = GPIO.new(unlock, :low)
    @locked = GPIO.new(locked, :in, :both)
    @unlocked = GPIO.new(unlocked, :in, :both)
    @opened = GPIO.new(opened, :in, :both)
    @poller = GPIOPoller.new([@opened, @locked, @unlocked])
    @mutex = Mutex.new
    @was_locked = nil
    @lock.clear
    @unlock.clear
  end
  def lock()
    @mutex.synchronize do
      begin
        @lock.set
        sleep @SIGNAL_DURATION
      ensure
        @lock.clear
      end
    end
  end
  def unlock()
    @mutex.synchronize do
      begin
        @unlock.set
        sleep @SIGNAL_DURATION
      ensure
        @unlock.clear
      end
    end
  end
  def locked?()
    if @locked.value && !@unlocked.value
      return true
    elsif !@locked.value && @unlocked.value
      return false
    else
      return nil
    end
  end
  def opened?()
    return @opened.value
  end
  def monitor()
    @poller.run() do |gpio, value|
      case gpio
      when @opened
        yield :opened, value
      when @locked, @unlocked
        yield :locked, locked?
      end
    end
  end
end
