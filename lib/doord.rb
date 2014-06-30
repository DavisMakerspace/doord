class DoorD
  def initialize(door, server, log, clientid=->(client){client})
    @door = door
    @server = server
    @log = log
    @clientid = clientid
    @clients = []
    @mutex = Mutex.new
  end
  def run
    @log.info "Starting DoorD"
    Thread.new{monitor}.abort_on_exception=true
    loop do
      client = @server.accept
      Thread.new{listen(client)}.abort_on_exception=true
    end
  end
  def monitor
    @log.info "Monitoring door"
    @door.monitor do |type, value|
      @mutex.synchronize { @clients.each { |c| c.puts "! #{type} #{value.inspect}" } }
    end
  end
  def listen client
    clientid = @clientid.call(client)
    lock=->{
      @log.info "Client #{clientid} sending lock signal"
      Thread.new{ @mutex.synchronize{ @door.lock }}.abort_on_exception=true
    }
    unlock=->{
      @log.info "Client #{clientid} sending unlock signal"
      Thread.new{ @mutex.synchronize{ @door.unlock }}.abort_on_exception=true
    }
    @log.info "Client #{clientid} connected"
    @mutex.synchronize { @clients << client }
    client.each do |cmd|
      case cmd.chomp
        when 'lock' then lock.call
        when 'unlock' then unlock.call
        when 'togglelock'
          @log.info "Client #{clientid} requested toggle"
          (@door.unlocked? && @door.closed? ? lock : unlock).call
        when 'opened'
          @log.info "Client #{clientid} queried opened"
          @mutex.synchronize{ client.puts ": opened #{@door.opened?.inspect}" }
        when 'locked'
          @log.info "Client #{clientid} queried locked"
          @mutex.synchronize{ client.puts ": locked #{@door.locked?.inspect}" }
        else
          @mutex.synchronize{ client.puts "? lock unlock togglelock opened locked" }
      end
    end
    @mutex.synchronize{ @clients.delete client }
    @log.info "Client #{clientid} disconnected"
  end
end
